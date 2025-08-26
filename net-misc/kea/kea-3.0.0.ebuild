# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit eapi9-ver fcaps flag-o-matic meson-multilib python-r1 systemd tmpfiles toolchain-funcs

DESCRIPTION="High-performance production grade DHCPv4 & DHCPv6 server"
HOMEPAGE="https://www.isc.org/kea/"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.isc.org/isc-projects/kea.git"
else
	SRC_URI="https://downloads.isc.org/isc/${PN}/${PV}/${P}.tar.xz"
	# odd minor version = development release
	if [[ $(( $(ver_cut 2) % 2 )) -ne 1 ]] ; then
		if ! [[ "${PV}" == *_beta* || "${PV}" == *_rc* ]] ; then
			 KEYWORDS="~amd64 ~arm ~arm64 ~x86"
		fi
	fi
fi

LICENSE="MPL-2.0"
SLOT="0"
IUSE="benchmark debug doc examples filecaps kerberos +man mysql -netconf +openssl postgres +samples +shell systemd tmpfiles test"

REQUIRED_USE="shell? ( ${PYTHON_REQUIRED_USE} )"
RESTRICT="!test? ( test )"

COMMON_DEPEND="
	acct-group/dhcp
	acct-user/dhcp
	>=dev-libs/boost-1.67:=
	>=dev-libs/log4cplus-1.0.3:=
	kerberos? ( virtual/krb5 )
	mysql? (
		app-arch/zstd:=
		dev-db/mysql-connector-c:=
		dev-libs/openssl:=
		sys-libs/zlib:=
	)
	netconf? (
		>=net-libs/libyang-1.0.240
		>=net-misc/sysrepo-1.4.140
	)
	!openssl? ( dev-libs/botan:2=[boost] )
	openssl? ( dev-libs/openssl:0= )
	postgres? ( dev-db/postgresql:* )
	shell? ( ${PYTHON_DEPS} )
"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	doc? (
		$(python_gen_cond_dep '
			dev-python/sphinx[${PYTHON_USEDEP}]
			dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]
		')
	)
	man? (
		$(python_gen_cond_dep '
			dev-python/sphinx[${PYTHON_USEDEP}]
			dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]
		')
	)
	test? ( >=dev-cpp/gtest-1.8 )
"

python_check_deps() {
	if use doc || use man; then
		python_has_version "dev-python/sphinx[${PYTHON_USEDEP}]" \
			"dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]"
	fi
}

pkg_setup() {
	if use doc || use man || use shell; then
		python_setup
	fi
}

src_prepare() {
	default

	if use shell; then
		sed -e 's:^#!@PYTHON@:#!/usr/bin/env python3:' \
			-i src/bin/shell/kea-shell.in || die
	fi
}

multilib_src_configure() {
	# -Werror=odr
	# https://bugs.gentoo.org/861617
	#
	# I would truly love to submit an upstream bug but their self-hosted gitlab
	# won't let me sign up. -- Eli
	filter-lto

	local emesonargs=(
		$(meson_native_use_feature kerberos krb5)
		$(meson_native_use_feature mysql)
		$(meson_native_use_feature netconf)
		$(meson_native_use_feature postgres postgresql)
	)

	meson_src_configure
}

install_shell() {
	python_domodule src/bin/shell/*.py
	python_doscript src/bin/shell/kea-shell

	# fix path to import kea modules
	sed -e "/^sys.path.append/s|(.*)|('$(python_get_sitedir)/${PN}')|" \
		-i "${ED}"/usr/lib/python-exec/${EPYTHON}/kea-shell || die
}

multilib_src_compile() {
	meson_src_compile
	if use doc || use man; then
		meson_src_compile doc
	fi
}

multilib_src_install() {
	local f=''

	meson_src_install

	if use shell; then
		python_moduleinto ${PN}
		python_foreach_impl install_shell
	fi

	if [[ -d "${ED%/}"/usr/share/doc/kea/html ]]; then
		use doc || rm -r "${ED%/}"/usr/share/doc/kea/html || die
	fi
	if [[ -d "${ED}"/usr/share/doc/kea ]]; then
		mv "${ED}"/usr/share/doc/kea "${ED}/usr/share/doc/${P}" || die

		for f in AUTHORS code_of_conduct CONTRIBUTING COPYING platforms.rst SECURITY; do
			rm "${ED}/usr/share/doc/${P}/${f}"* || die
		done
	fi

	if [[ -d "${S}"/doc/examples ]]; then
		if use doc && use examples ; then
			dodoc -r "${S}"/doc/examples || die
		fi
		if [[ -d "${ED}/usr/share/doc/${P}/examples" ]]; then
			use examples || rm -r "${ED}/usr/share/doc/${P}/examples"
		fi
	fi

	if [[ -d "${ED}"/usr/share/kea ]]; then
		rm -r "${ED}"/usr/share/kea/meson-info || die
		use postgres || rm -r "${ED}"/usr/share/kea/scripts/pgsql
		use mysql || rm -r "${ED}"/usr/share/kea/scripts/mysql
		if use !mysql && use !postgres; then
			rm "${ED}"/usr/share/kea/scripts/admin-utils.sh
		fi
		rmdir --ignore-fail-on-non-empty --parents "${ED}"/usr/share/kea/scripts
	fi

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
		newins "${S}"/doc/examples/agent/comments.json kea-ctrl-agent.conf.sample
		newins "${S}"/doc/examples/kea6/simple.json kea-dhcp6.conf.sample
		newins "${S}"/doc/examples/kea4/single-subnet.json kea-dhcp4.conf.sample
		newins "${S}"/doc/examples/ddns/comments.json kea-dhcp-ddns.conf.sample

		# set log to syslog by default
		sed -e 's/"output": "stdout"/"output": "syslog"/' \
			-i "${ED}"/etc/kea/*.conf.sample || die
	fi

	newconfd "${FILESDIR}"/${PN}-confd-r2 ${PN}
	newinitd "${FILESDIR}"/${PN}-initd-r2 ${PN}

	if use systemd; then
		systemd_dounit "${FILESDIR}"/${PN}-ctrl-agent.service-r2
		systemd_dounit "${FILESDIR}"/${PN}-dhcp-ddns.service-r2
		systemd_dounit "${FILESDIR}"/${PN}-dhcp4.service-r2
		systemd_dounit "${FILESDIR}"/${PN}-dhcp6.service-r2
	fi

	if use tmpfiles; then
		newtmpfiles "${FILESDIR}"/${PN}.tmpfiles.conf ${PN}.conf
	fi

	keepdir /var/lib/${PN} /var/log/${PN}
	fowners -R dhcp:dhcp /var/lib/${PN} /var/log/${PN}
	fperms 750 /var/lib/${PN} /var/log/${PN}

	find "${ED}" -type f -name "*.la" -delete || die
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process ${PN}.conf

	fcaps cap_net_bind_service,cap_net_raw=+ep usr/sbin/kea-dhcp4
	fcaps cap_net_bind_service=+ep usr/sbin/kea-dhcp6

	if ver_replacing -lt 2.6; then
		ewarn "Several changes have been made for daemons:"
		ewarn "  To comply with common practices for this package,"
		ewarn "  config paths by default has been changed as below:"
		ewarn "    /etc/kea/kea-dhcp4.conf"
		ewarn "    /etc/kea/kea-dhcp6.conf"
		ewarn "    /etc/kea/kea-dhcp-ddns.conf"
		ewarn "    /etc/kea/kea-ctrl-agent.conf"
		ewarn
		ewarn "  Daemons are launched by default with the unprivileged user 'dhcp'"
		ewarn
		ewarn "Please check your configuration!"
	fi

	if ! has_version net-misc/kea; then
		if use doc || use samples; then
			elog "See config files in:"
			elog "  ${EROOT}/etc/kea/*.sample"
			elog "  ${EROOT}/usr/share/doc/${PF}/examples"
		fi
	fi
}

# vi: set diffopt=filler,iwhite:
