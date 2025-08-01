# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# As with sys-libs/libcap-ng, same maintainer in Fedora as upstream, so
# check Fedora's packaging (https://src.fedoraproject.org/rpms/audit/tree/rawhide)
# on bumps (or if hitting a bug) to see what they've done there.

PYTHON_COMPAT=( python3_{10..13} )

inherit autotools flag-o-matic linux-info python-r1 systemd toolchain-funcs usr-ldscript multilib-minimal

DESCRIPTION="Userspace utilities for storing and processing auditing records"
HOMEPAGE="https://people.redhat.com/sgrubb/audit/"
SRC_URI="https://people.redhat.com/sgrubb/audit/${P}.tar.gz"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="gssapi io-uring ldap python static-libs systemd test zos"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
	zos? ( ldap )"
RESTRICT="!test? ( test )"

RDEPEND="
	sys-libs/libcap-ng
	gssapi? ( virtual/krb5 )
	ldap? ( net-nds/openldap:= )
	python? ( ${PYTHON_DEPS} )
"
DEPEND="
	${RDEPEND}
	virtual/os-headers:50000
	test? ( dev-libs/check )
"
BDEPEND="
	python? (
		dev-lang/swig
		$(python_gen_cond_dep '
			dev-python/setuptools[${PYTHON_USEDEP}]
		' python3_12 python3_13)
	)
"

CONFIG_CHECK="~AUDIT"

QA_CONFIG_IMPL_DECL_SKIP=(
	# missing on musl. Uses handrolled AC_LINK_IFELSE but fails at link time
	# for older compilers regardless. bug #898828
	strndupa
)

PATCHES=(
	"${FILESDIR}/${PN}-4.0.1-musl-basename.patch"
)

src_prepare() {
	# audisp-remote moved in multilib_src_install_all
	sed -i \
		-e "s,/sbin/audisp-remote,${EPREFIX}/usr/sbin/audisp-remote," \
		audisp/plugins/remote/au-remote.conf || die

	# Disable installing sample rules so they can be installed as docs.
	echo -e '%:\n\t:' | tee rules/Makefile.{am,in} >/dev/null || die

	default
	eautoreconf
}

multilib_src_configure() {
	if use amd64 || use x86; then
		# With -z,max-page-size=0x200000 set (for x86_64), tiny binaries bloat
		# to 6.1MB each :o
		#
		filter-ldflags *-z,max-page-size=*
	fi

	local -a myeconfargs=(
		--sbindir="${EPREFIX}"/sbin
		--localstatedir="${EPREFIX}"/var
		--runstatedir="${EPREFIX}"/var/run
		$(use_enable gssapi gssapi-krb5)
		$(use_enable zos zos-remote)
		$(use_enable static-libs static)
		$(use_with arm)
		$(use_with arm64 aarch64)
		$(use_with io-uring io_uring)
		--without-golang
		--without-libwrap
		--without-python3
	)

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"

	if multilib_is_native_abi && use python; then
		python_configure() {
			mkdir -p "${BUILD_DIR}" || die
			pushd "${BUILD_DIR}" &>/dev/null || die

			ECONF_SOURCE="${S}" econf "${myeconfargs[@]}" --with-python3
			find . -type f -name 'Makefile' -exec sed -i "s;-I/usr/include/python;-I${SYSROOT}/usr/include/python;g" {} +

			popd &>/dev/null || die
		}

		python_foreach_impl python_configure
	fi

	# Make target bindings/python/auparse_python.c doesn't get copied to ${BUILD_DIR}. bug #944338
	ln -s "${S}/bindings/python/auparse_python.c" "${BUILD_DIR}/bindings/python/auparse_python.c" || die
}

src_configure() {
	tc-export_build_env BUILD_{CC,CPP}

	local -x CC_FOR_BUILD="${BUILD_CC}"
	local -x CPP_FOR_BUILD="${BUILD_CPP}"

	multilib-minimal_src_configure
}

multilib_src_compile() {
	if multilib_is_native_abi; then
		default

		local native_build="${BUILD_DIR}"

		python_compile() {
			emake -C "${BUILD_DIR}"/bindings/swig top_builddir="${native_build}"
			emake -C "${BUILD_DIR}"/bindings/python/python3 top_builddir="${native_build}"
		}

		use python && python_foreach_impl python_compile
	else
		emake -C common
		emake -C lib
		emake -C auparse
	fi
}

multilib_src_install() {
	if multilib_is_native_abi; then
		emake DESTDIR="${D}" initdir="$(systemd_get_systemunitdir)" install

		local native_build="${BUILD_DIR}"

		python_install() {
			emake -C "${BUILD_DIR}"/bindings/swig DESTDIR="${D}" top_builddir="${native_build}" install
			emake -C "${BUILD_DIR}"/bindings/python/python3 DESTDIR="${D}" top_builddir="${native_build}" install
			python_optimize
		}

		use python && python_foreach_impl python_install

		# Things like shadow use this so we need to be in /
		gen_usr_ldscript -a audit auparse
	else
		emake -C lib DESTDIR="${D}" install
		emake -C auparse DESTDIR="${D}" install
	fi
}

multilib_src_install_all() {
	dodoc AUTHORS ChangeLog README* THANKS
	docinto contrib
	dodoc contrib/avc_snap
	docinto contrib/plugin
	dodoc contrib/plugin/*
	docinto rules
	dodoc rules/*rules

	newinitd "${FILESDIR}"/auditd-init.d-2.4.3 auditd
	newconfd "${FILESDIR}"/auditd-conf.d-2.1.3 auditd

	if [[ -f "${ED}"/sbin/audisp-remote ]] ; then
		dodir /usr/sbin
		mv "${ED}"/{sbin,usr/sbin}/audisp-remote || die
	fi

	if ! use systemd; then
		if [[ -d "${ED}"/usr/libexec/initscripts/legacy-actions/auditd ]]; then
			rm -r "${ED}"/usr/libexec/initscripts/legacy-actions/auditd
			rmdir --ignore-fail-on-non-empty --parents \
				"${ED}"/usr/libexec/initscripts/legacy-actions
		fi
	fi

	# Gentoo rules
	insinto /etc/audit
	newins "${FILESDIR}"/audit.rules-2.1.3 audit.rules
	doins "${FILESDIR}"/audit.rules.stop*
	keepdir /etc/audit/rules.d

	# audit logs go here
	keepdir /var/log/audit

	find "${ED}" -type f -name '*.la' -delete || die

	# Security
	lockdown_perms "${ED}"
}

pkg_postinst() {
	lockdown_perms "${EROOT}"
}

lockdown_perms() {
	# Upstream wants these to have restrictive perms.
	# Should not || die as not all paths may exist.
	local basedir="${1}"
	chmod 0750 "${basedir}"/sbin/au{ditctl,ditd,report,search,trace} 2>/dev/null
	chmod 0750 "${basedir}"/var/log/audit 2>/dev/null
	chmod 0640 "${basedir}"/etc/audit/{auditd.conf,audit*.rules*} 2>/dev/null
}
