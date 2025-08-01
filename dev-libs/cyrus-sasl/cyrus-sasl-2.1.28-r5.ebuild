# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools db-use edos2unix flag-o-matic multilib pam systemd tmpfiles toolchain-funcs multilib-minimal

SASLAUTHD_CONF_VER="2.1.26"
MY_PATCH_VER="${PN}-2.1.28-r4-patches"
DESCRIPTION="The Cyrus SASL (Simple Authentication and Security Layer)"
HOMEPAGE="https://www.cyrusimap.org/sasl/"
SRC_URI="https://github.com/cyrusimap/${PN}/releases/download/${P}/${P}.tar.gz
	https://dev.gentoo.org/~grobian/distfiles/${MY_PATCH_VER}.tar.xz"

LICENSE="BSD-with-attribution"
SLOT="2"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="authdaemond berkdb gdbm kerberos ldapdb mysql openldap pam postgres sample selinux sqlite srp ssl static-libs systemd +tmpfiles urandom"
REQUIRED_USE="ldapdb? ( openldap )"

# See bug #855890 for sys-libs/db slot
DEPEND="net-mail/mailbase
	virtual/libcrypt:=
	authdaemond? ( || ( net-mail/courier-imap mail-mta/courier ) )
	berkdb? ( >=sys-libs/db-4.8.30-r1:4.8[${MULTILIB_USEDEP}] )
	gdbm? ( >=sys-libs/gdbm-1.10-r1:=[${MULTILIB_USEDEP}] )
	kerberos? ( >=virtual/krb5-0-r1[${MULTILIB_USEDEP}] )
	openldap? ( >=net-nds/openldap-2.4.38-r1:=[${MULTILIB_USEDEP}] )
	mysql? ( dev-db/mysql-connector-c:0=[${MULTILIB_USEDEP}] )
	pam? ( >=sys-libs/pam-0-r1[${MULTILIB_USEDEP}] )
	postgres? ( dev-db/postgresql:* )
	sqlite? ( >=dev-db/sqlite-3.8.2:3[${MULTILIB_USEDEP}] )
	ssl? ( >=dev-libs/openssl-1.0.1h-r2:0=[${MULTILIB_USEDEP}] )"
RDEPEND="${DEPEND}
	selinux? ( sec-policy/selinux-sasl )"
BDEPEND="virtual/libcrypt
	berkdb? ( >=sys-libs/db-4.8.30-r1:4.8 )
	gdbm? ( >=sys-libs/gdbm-1.10-r1 )"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/sasl/md5global.h
)

PATCHES=(
	"${WORKDIR}"/${MY_PATCH_VER}/
)

src_prepare() {
	default

	# Use plugindir for sasldir
	# https://github.com/cyrusimap/cyrus-sasl/issues/339 (I think)
	sed -i '/^sasldir =/s:=.*:= $(plugindir):' \
		"${S}"/plugins/Makefile.{am,in} || die "sed failed"

	# bug #486740 and bug #468556 (dropped AM_CONFIG_HEADER sed in 2.1.28)
	sed -i -e 's:AC_CONFIG_MACRO_DIR:AC_CONFIG_MACRO_DIRS:g' configure.ac || die

	eautoreconf
}

src_configure() {
	export CC_FOR_BUILD="$(tc-getBUILD_CC)"

	# Fails with C23 because of decls
	append-flags -std=gnu17

	# -Werror=lto-type-mismatch
	# https://bugs.gentoo.org/894684
	# https://github.com/cyrusimap/cyrus-sasl/pull/771
	#
	# Fixed upstream in git master but not released.
	use srp && filter-lto

	if [[ ${CHOST} == *-solaris* ]] ; then
		# getpassphrase is defined in /usr/include/stdlib.h
		append-cppflags -DHAVE_GETPASSPHRASE
	else
		# this horrendously breaks things on Solaris
		append-cppflags -D_XOPEN_SOURCE -D_XOPEN_SOURCE_EXTENDED -D_BSD_SOURCE -DLDAP_DEPRECATED
		# replaces BSD_SOURCE (bug #579218)
		append-cppflags -D_DEFAULT_SOURCE
	fi

	multilib-minimal_src_configure

	if ( use berkdb || use gdbm ) && tc-is-cross-compiler ; then
		mkdir -p "${WORKDIR}"/${P}-build || die
		cd "${WORKDIR}"/${P}-build || die
		# We don't care which berkdb version is used as this build is
		# only temporary for generating an empty sasldb2 later...
		ECONF_SOURCE="${S}" econf_build \
			--with-dblib=$(usex berkdb berkeley gdbm)
	fi
}

multilib_src_configure() {
	local myeconfargs=(
		--enable-login
		--enable-ntlm
		--enable-auth-sasldb
		--disable-cmulocal
		--disable-krb4
		--disable-macos-framework
		--enable-otp
		--without-sqlite
		--with-saslauthd="${EPREFIX}"/var/lib/saslauthd
		--with-pwcheck="${EPREFIX}"/var/lib/saslauthd
		--with-configdir="${EPREFIX}"/etc/sasl2
		--with-plugindir="${EPREFIX}/usr/$(get_libdir)/sasl2"
		--with-dbpath="${EPREFIX}"/etc/sasl2/sasldb2
		--with-sphinx-build=no
		$(use_with ssl openssl)
		$(use_with pam)
		$(use_with openldap ldap)
		$(use_enable ldapdb)
		$(multilib_native_use_enable sample)
		$(use_enable kerberos gssapi)
		$(multilib_native_use_with mysql mysql "${EPREFIX}/usr/$(get_libdir)")
		$(multilib_native_use_with postgres pgsql "${EPREFIX}/usr/$(get_libdir)/postgresql")
		$(use_with sqlite sqlite3 "${EPREFIX}/usr/$(get_libdir)")
		$(use_enable srp)
		$(use_enable static-libs static)

		# Add authdaemond support (bug #56523).
		$(usex authdaemond --with-authdaemond="${EPREFIX}"/var/lib/courier/authdaemon/socket '')

		# Fix for bug #59634.
		$(usex ssl '' --without-des)

		# Use /dev/urandom instead of /dev/random (bug #46038).
		$(usex urandom --with-devrandom=/dev/urandom '')
	)

	if use sqlite || { multilib_is_native_abi && { use mysql || use postgres; }; } ; then
		myeconfargs+=( --enable-sql )
	else
		myeconfargs+=( --disable-sql )
	fi

	# Default to GDBM if both 'gdbm' and 'berkdb' are present.
	if use gdbm ; then
		einfo "Building with GNU DB as database backend for your SASLdb"
		myeconfargs+=( --with-dblib=gdbm )
	elif use berkdb ; then
		einfo "Building with BerkeleyDB as database backend for your SASLdb"
		myeconfargs+=(
			--with-dblib=berkeley
			--with-bdb-incdir="$(db_includedir)"
		)
	else
		einfo "Building without SASLdb support"
		myeconfargs+=( --with-dblib=none )
	fi

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

src_compile() {
	multilib-minimal_src_compile

	if ( use berkdb || use gdbm ) && tc-is-cross-compiler ; then
		emake -C "${WORKDIR}/${P}-build"
	fi
}

multilib_src_install() {
	default

	if multilib_is_native_abi; then
		if use sample ; then
			docinto sample
			dodoc "${S}"/sample/*.c
			exeinto /usr/share/doc/${P}/sample
			doexe sample/client sample/server
		fi

		dosbin saslauthd/testsaslauthd
		keepdir /etc/sasl2

	fi
}

multilib_src_install_all() {
	doman man/*

	# Reset docinto to default value (bug #674296)
	docinto
	dodoc AUTHORS ChangeLog doc/legacy/TODO
	newdoc pwcheck/README README.pwcheck

	newdoc docsrc/sasl/release-notes/$(ver_cut 1-2)/index.rst release-notes
	edos2unix "${ED}/usr/share/doc/${PF}/release-notes"

	docinto html
	dodoc doc/html/*.html

	if use pam; then
		newpamd "${FILESDIR}"/saslauthd.pam-include saslauthd
	fi

	newinitd "${FILESDIR}"/pwcheck.rc6 pwcheck
	newinitd "${FILESDIR}"/saslauthd2.rc7 saslauthd
	newconfd "${FILESDIR}/saslauthd-${SASLAUTHD_CONF_VER}.conf" saslauthd

	if use systemd; then
		systemd_dounit "${FILESDIR}"/pwcheck.service
		systemd_dounit "${FILESDIR}"/saslauthd.service
	fi

	if use tmpfiles; then
		dotmpfiles "${FILESDIR}/${PN}.conf"
	fi

	# The get_modname bit is important: do not remove the .la files on
	# platforms where the lib isn't called .so for cyrus searches the .la to
	# figure out what the name is supposed to be instead
	if ! use static-libs && [[ $(get_modname) == .so ]] ; then
		find "${ED}" -name "*.la" -delete || die
	fi
}

pkg_config() {
	if ! use berkdb && ! use gdbm; then
		return 0
	fi
	# Generate an empty sasldb2 with correct permissions.
	if [[ ! -f "${EROOT%/}/etc/sasl2/sasldb2" ]] ; then
		if [ "${EROOT:-/}" != '/' ]; then
			local -x LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${EROOT%/}/$(get_libdir):${EROOT%/}/usr/$(get_libdir)"
		fi

		einfo "Generating an empty sasldb2 with correct permissions ..."

		saslpasswd2 -f "${EROOT}/etc/sasl2/sasldb2-empty" \
				-p login <<<'p' ||
			die "Failed to generate sasldb2"

		saslpasswd2 -f "${EROOT}/etc/sasl2/sasldb2-empty" \
				-d login ||
			die "Failed to delete temp user"

		use prefix || chown root:mail "${EROOT}/etc/sasl2/sasldb2-empty" ||
			die "Failed to chown ${EROOT}/etc/sasl2/sasldb2"

		chmod 0640 "${EROOT}/etc/sasl2/sasldb2-empty" ||
			die "Failed to chmod ${EROOT}/etc/sasl2/sasldb2"

		cp -av "${EROOT}"/etc/sasl2/sasldb2{-empty,} || die
	else
		ewarn "You appear to already have a '${EROOT%/}/etc/sasl2/sasldb2' file"
		ewarn "Backup and remove this file in order to create a clean database"
	fi
}

pkg_postinst() {
	use !tmpfiles || tmpfiles_process "${PN}.conf"

	if [[ "${MERGE_TYPE}" != 'binary' ]] ; then
		( use berkdb || use gdbm ) && pkg_config
	fi

	if use authdaemond ; then
		elog "You need to add a user running a service using Courier's"
		elog "authdaemon to the 'mail' group. For example, do:"
		elog "	gpasswd -a postfix mail"
		elog "to add the 'postfix' user to the 'mail' group."
	fi
}

# vi: set diffopt=filler,iwhite:
