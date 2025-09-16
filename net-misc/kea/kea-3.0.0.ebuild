# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit eapi9-ver fcaps flag-o-matic meson python-r1 systemd tmpfiles toolchain-funcs

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
# For 3.0.0 sphinx is needs to build man pages which are always needed
# Note: In 2.6.x the man files came prebuilt in the tarball release file
BDEPEND="
	>=dev-build/meson-1.8
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	${PYTHON_DEPS}
	doc? (
		$(python_gen_any_dep '
			dev-python/sphinx[${PYTHON_USEDEP}]
			dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]
		')
	)
	man? (
		$(python_gen_any_dep '
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
	# Remove building and install html documentation
	if use !doc; then
		PATCHES+=( "${FILESDIR}"/${P}-strip-doc.patch )
	fi
	default

	# Fix up all doc paths, whether or not we are installing full set of docs
	sed -e "s:'doc/kea':'doc/${PF}':" \
		-i meson.build || die
	sed -e "s:'share/doc/kea':'share/doc/${PF}':" \
		-i doc/meson.build || die
	sed -e "s:'doc/kea':'doc/${PF}':" \
		-i doc/sphinx/meson.build || die
	sed -e "s:share/doc/kea/:share/doc/${PF}/:" \
		-i doc/sphinx/arm/install.rst || die
	sed -e "s:share/doc/kea/examples:share/doc/${PF}/examples:" \
		-i doc/sphinx/arm/config.rst || die

	# set shebang before meson whether or not we are installing the shell
	sed -e 's:^#!@PYTHON@:#!/usr/bin/env python3:' \
		-i src/bin/shell/kea-shell.in || die

	# Don't allow meson to install shell, we shall do that if required
	sed -e 's:install\: true:install\: false:' \
		-i src/bin/shell/meson.build || die

	# do not create /run
	sed -e '/^install_emptydir(RUNSTATEDIR)$/d' \
		-i meson.build || die
}

src_configure() {
	# https://bugs.gentoo.org/861617
	# https://gitlab.isc.org/isc-projects/kea/-/issues/3946
	#
	# Kea Devs say no to LTO
	filter-lto

	local emesonargs=(
		--localstatedir="${EPREFIX}/var"
		-Drunstatedir="${EPREFIX}/var/run"
		$(meson_feature kerberos krb5)
		$(meson_feature netconf)
		-Dcrypto=$(usex openssl openssl botan)
		$(meson_feature mysql)
		$(meson_feature postgres postgresql)
		$(meson_feature test tests)
	)
	if use debug; then
		emesonargs+=(
			--debug
		)
	fi
	meson_src_configure
}

src_compile() {
	meson_src_compile

	if use doc || use man; then
		# We have do doc target for man pages
		meson_src_compile doc
	fi
}

src_test() {
	# Get list of all test suites into an associative array
	# the meson test --list returns either "kea / test_suite", "kea:shell-tests / test_suite" or
	# "kea:python-tests / test_suite"
	# Discard the shell tests as we can't run shell tests in sandbox

	pushd "${BUILD_DIR}" || die
	local -A TEST_SUITES
	while IFS=" / " read -r subsystem test_suite ; do
		if [[ ${subsystem} != "kea:shell-tests" ]]; then
			TEST_SUITES["$test_suite"]=1
		fi
	done < <(meson test --list || die)
	popd

	# Some other tests will fail for interface access restrictions, we have to remove the test suites those tests
	# belong to
	local SKIP_TESTS=(
		dhcp-radius-tests
		kea-log-buffer_logger_test.sh
		kea-log-console_test.sh
		dhcp-lease-query-tests
		kea-dhcp6-tests
		kea-dhcp-tests
	)

	# skip shell tests that require a running instance of MySQL
	if use mysql; then
		SKIP_TESTS+=(
			kea-mysql-tests
			dhcp-mysql-lib-tests
			dhcp-forensic-log-libloadtests
			kea-dhcp4-tests
		)
	fi

	# skip shell tests that require a running instance of PgSQL
	if use postgres; then
		SKIP_TESTS+=(
			kea-pgsql-tests
			dhcp-pgsql-lib-tests
			dhcp-forensic-log-libloadtests
			kea-dhcp4-tests
		)
	fi

	if [[ $(tc-get-ptr-size) -eq 4 ]]; then
		# see https://bugs.gentoo.org/958171 for reason for skipping these tests
		SKIP_TESTS+=(
			kea-util-tests
			kea-dhcp4-tests
			kea-dhcpsrv-tests
			dhcp-ha-lib-tests
			kea-d2-tests
		)
	fi

	for SKIP in ${SKIP_TESTS[@]}; do
		unset TEST_SUITES["${SKIP}"]
	done

	meson_src_test ${!TEST_SUITES[@]}
}

install_shell() {
	python_domodule "${ORIG_BUILD_DIR}/src/bin/shell/"*.py
	python_doscript "${ORIG_BUILD_DIR}/src/bin/shell/kea-shell"

	# fix path to import kea modules
	sed -e "/^sys.path.append/s|(.*)|('$(python_get_sitedir)/${PN}')|" \
		-i "${ED}"/usr/lib/python-exec/${EPYTHON}/kea-shell || die
}

src_install() {
	local f=''

	meson_install

	# Tidy up
	rm -r "${ED}"/usr/share/kea/meson-info || die
	if use !mysql; then
		rm -r "${ED}"/usr/share/kea/scripts/mysql || die
	fi
	if use !postgres; then
		rm -r "${ED}"/usr/share/kea/scripts/pgsql || die
	fi
	if use !mysql && use !postgres; then
		rm "${ED}"/usr/share/kea/scripts/admin-utils.sh
	fi

	# No easy way to control how meson_install sets permissions in
	# meson < 1.9 so make sure permissions are same as in previous versions
	# of kea to avoid any differences between an update versus a first time
	# install
	#fperms -R 0755 /usr/sbin
	#fperms -R 0755 /usr/bin
	#fperms -R 0755 "/usr/$(get_libdir)"

	if [[ -d "${ED}"/usr/share/doc/kea ]]; then
		mv "${ED}"/usr/share/doc/kea "${ED}/usr/share/doc/${P}" || die
	else
		dodir "/usr/share/doc/${P}"
	fi

	for f in AUTHORS code_of_conduct CONTRIBUTING COPYING platforms.rst SECURITY; do
		rm "${ED}/usr/share/doc/${P}/${f}"* || die
	done

	if use doc && use examples ; then
		dodoc -r "${S}"/doc/examples || die
	fi
	if [[ -d "${ED}/usr/share/doc/${P}/examples" ]]; then
		use examples || rm -r "${ED}/usr/share/doc/${P}/examples"
	fi

	rmdir --ignore-fail-on-non-empty --parents \
		"${ED}"/usr/share/kea/scripts

	#if use samples; then
	#	diropts -m 0750 -o root -g dhcp
	#	dodir /etc/kea
	#	insopts -m 0640 -o root -g dhcp
	#	insinto /etc/kea
	#	for f in ctrl-agent ddns-server dhcp4 dhcp6; do
	#		sed -e "s|@libdir@|/$(get_libdir)|g ; s|@localestatedir@|/var|g" \
	#			"${FILESDIR}/${PN}-${f}.conf" > "${T}/${PN}-${f}.conf"
	#		doins "${T}/${PN}-${f}.conf"
	#	done
	#	newins "${S}"/doc/examples/agent/comments.json kea-ctrl-agent.conf.sample
	#	newins "${S}"/doc/examples/kea6/simple.json kea-dhcp6.conf.sample
	#	newins "${S}"/doc/examples/kea4/single-subnet.json kea-dhcp4.conf.sample
	#	newins "${S}"/doc/examples/ddns/comments.json kea-dhcp-ddns.conf.sample
	#
	#	# set log to syslog by default
	#	sed -e 's/"output": "stdout"/"output": "syslog"/' \
	#		-i "${ED}"/etc/kea/*.conf.sample || die
	#fi

	if use shell; then
		python_moduleinto ${PN}
		ORIG_BUILD_DIR="${BUILD_DIR}" python_foreach_impl install_shell
	fi

	# We don't use keactrl.conf so move to reduce confusion
	if [[ -e "${ED}/etc/${PN}/keactrl.conf" ]]; then
		dodir "/usr/share/doc/${PF}/examples"
		mv "${ED}/etc/${PN}/keactrl.conf" "${ED}/usr/share/doc/${PF}/examples/keactrl.conf" || die
	fi

	fowners -R root:dhcp "/etc/${PN}"

	# Install a conf per service and a linked init script per service
	newinitd "${FILESDIR}/${PN}-initd-r3" "${PN}"
	local svc
	for svc in dhcp4 dhcp6 dhcp-ddns ctrl-agent; do
		newconfd "${FILESDIR}/${PN}-confd-r3" "kea-${svc}"
		sed \
			-e "s:@KEA_SVC@:${svc}:g" \
			-i "${ED}/etc/conf.d/kea-${svc}" || die
		dosym kea "${EPREFIX}/etc/init.d/kea-${svc}"
	done

	if use systemd; then
		systemd_newunit "${FILESDIR}/${PN}-ctrl-agent.service-r2" "${PN}-ctrl-agent.service"
		systemd_newunit "${FILESDIR}/${PN}-dhcp-ddns.service-r2" "${PN}-dhcp-ddns.service"
		systemd_newunit "${FILESDIR}/${PN}-dhcp4.service-r2" "${PN}-dhcp4.service"
		systemd_newunit "${FILESDIR}/${PN}-dhcp6.service-r2" "${PN}-dhcp6.service"
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

	if ver_replacing -lt 3.0; then
		ewarn "If using openrc;"
		ewarn "  There are now separate conf.d scripts and associated init.d per daemon!"
		ewarn "    Each Daemon needs to be launched separately, i.e. the daemons are"
		ewarn "      kea-dhcp4"
		ewarn "      kea-dhcp6"
		ewarn "      kea-dhcp-ddns"
		ewarn "      kea-ctrl"
		ewarn "Please adjust your service startups appropriately"
	fi

	if ! has_version net-misc/kea; then
		if use doc || use samples; then
			elog "See examples of config files in:"
			elog "  ${EROOT}/usr/share/doc/${PF}/examples"
		fi
	fi
}

# vi: set diffopt=filler,iwhite:
