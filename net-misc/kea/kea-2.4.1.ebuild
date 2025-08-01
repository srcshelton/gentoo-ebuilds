# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PV="${PV//_p/-P}"
MY_PV="${MY_PV/_/-}"
MY_P="${PN}-${MY_PV}"

PYTHON_COMPAT=( python3_{11..13} )
inherit autotools fcaps flag-o-matic python-single-r1 systemd tmpfiles

DESCRIPTION="High-performance production grade DHCPv4 & DHCPv6 server"
HOMEPAGE="https://www.isc.org/kea/"

if [[ ${PV} == *9999* ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.isc.org/isc-projects/kea.git"
else
	SRC_URI="https://downloads.isc.org/isc/kea/${MY_P}.tar.gz
		https://downloads.isc.org/isc/kea/${MY_PV}/${MY_P}.tar.gz"
	# odd minor version = development release
	if [[ $(( $(ver_cut 2) % 2 )) -ne 1 ]] ; then
		if ! [[ "${PV}" == *_beta* || "${PV}" == *_rc* ]] ; then
			 KEYWORDS="amd64 arm arm64 x86"
		fi
	fi
fi
S="${WORKDIR}/${MY_P}"

LICENSE="ISC BSD SSLeay GPL-2" # GPL-2 only for init script
SLOT="0"
IUSE="benchmark debug doc examples filecaps mysql +openssl postgres +samples +shell systemd tmpfiles test"

REQUIRED_USE="shell? ( ${PYTHON_REQUIRED_USE} )"
RESTRICT="!test? ( test )"

COMMON_DEPEND="
	<dev-libs/boost-1.85:=
	dev-libs/log4cplus
	doc? (
		$(python_gen_cond_dep '
			dev-python/sphinx[${PYTHON_USEDEP}]
			dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]
		')
	)
	mysql? ( dev-db/mysql-connector-c )
	!openssl? ( dev-libs/botan:2= )
	openssl? ( dev-libs/openssl:0= )
	postgres? ( dev-db/postgresql:* )
	shell? ( ${PYTHON_DEPS} )
"
DEPEND="${COMMON_DEPEND}
	test? ( dev-cpp/gtest )
"
RDEPEND="${COMMON_DEPEND}
	acct-group/dhcp
	acct-user/dhcp"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${PN}-2.2.0-openssl-version.patch
)

pkg_setup() {
	use shell && python-single-r1_pkg_setup
}

src_prepare() {
	default

	if use test; then
		cp "${FILESDIR}"/ax_gtest.m4 "${S}"/m4macros/ax_gtest.m4 || die 'Replace gtest m4 macro failed'
	fi

	# brand the version with Gentoo
	sed -i \
		-e 's/KEA_SRCID="tarball"/KEA_SRCID="gentoo"/g' \
		-e 's/AC_MSG_RESULT("tarball")/AC_MSG_RESULT("gentoo")/g' \
		-e "s/EXTENDED_VERSION=\"\${EXTENDED_VERSION} (\$KEA_SRCID)\"/EXTENDED_VERSION=\"${PVR} (\$KEA_SRCID)\"/g" \
		configure.ac || die

	sed -i \
		-e '/mkdir -p $(DESTDIR)${runstatedir}\/${PACKAGE_NAME}/d' \
		Makefile.am || die "Fixing Makefile.am failed"

	eautoreconf
}

src_configure() {
	# -Werror=odr
	# https://bugs.gentoo.org/861617
	#
	# I would truly love to submit an upstream bug but their self-hosted gitlab
	# won't let me sign up. -- Eli
	filter-lto

	local myeconfargs=(
		--disable-install-configurations
		--disable-rpath
		--disable-static
		--enable-generate-messages
		--localstatedir="${EPREFIX}/var"
		--runstatedir="${EPREFIX}/var/run"
		--without-werror
		--with-log4cplus
		$(use_enable benchmark perfdhcp)
		$(use_enable debug)
		$(use_enable doc generate-docs)
		$(use_enable shell)
		$(use_with mysql)
		$(use_with openssl)
		$(use_with postgres pgsql)
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	local f=''

	emake -j1 install DESTDIR="${D}"

	for f in code_of_conduct COPYING CONTRIBUTING AUTHORS; do
		rm "${ED}/usr/share/doc/${P}/${f}"*
	done

	use postgres || rm -r "${ED}"/usr/share/kea/scripts/pgsql
	use mysql || rm -r "${ED}"/usr/share/kea/scripts/mysql
	use examples || rm -r "${ED}/usr/share/doc/${P}/examples"

	newconfd "${FILESDIR}"/${PN}-confd-r1 ${PN}
	newinitd "${FILESDIR}"/${PN}-initd-r1 ${PN}

	if use samples; then
		diropts -m 0750 -o root -g dhcp
		dodir /etc/kea
		insopts -m 0640 -o root -g dhcp
		insinto /etc/kea
		for f in ctrl-agent ddns-server dhcp4 dhcp6; do
			sed -e "s|@libdir@|/$(get_libdir)|g ; s|@localestatedir@|/var|g" \
				"${FILESDIR}/${PN}-${f}.conf" > "${T}/${PN}-${f}.conf"
			doins "${T}/${PN}-${f}.conf"
		done
	fi

	if use systemd; then
		systemd_dounit "${FILESDIR}"/${PN}-ctrl-agent.service
		systemd_dounit "${FILESDIR}"/${PN}-ddns-server.service
		systemd_dounit "${FILESDIR}"/${PN}-dhcp4-server.service
		systemd_dounit "${FILESDIR}"/${PN}-dhcp6-server.service
	fi

	if use tmpfiles; then
		newtmpfiles "${FILESDIR}"/${PN}.tmpfiles.conf ${PN}.conf
	fi

	keepdir /var/lib/${PN} /var/log/${PN}
	find "${ED}" -type f -name "*.la" -delete || die
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process ${PN}.conf
	fcaps cap_net_bind_service,cap_net_raw=+ep usr/sbin/kea-dhcp{4,6}
}
