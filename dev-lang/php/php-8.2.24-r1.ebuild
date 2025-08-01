# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

WANT_AUTOMAKE="none"

inherit autotools flag-o-matic multilib systemd

DESCRIPTION="The PHP language runtime engine"
HOMEPAGE="https://www.php.net/"
SRC_URI="https://www.php.net/distributions/${P}.tar.xz"

LICENSE="PHP-3.01
	BSD
	Zend-2.0
	bcmath? ( LGPL-2.1+ )
	fpm? ( BSD-2 )
	gd? ( gd )
	unicode? ( BSD-2 LGPL-2.1 )"

SLOT="$(ver_cut 1-2)"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos"

# We can build the following SAPIs in the given order
SAPIS="embed cli cgi fpm apache2 phpdbg"

# SAPIs and SAPI-specific USE flags (cli SAPI is default on):
IUSE="acl apache2 apparmor argon2 avif bcmath berkdb bzip2 calendar cdb cgi cjk +cli +ctype curl debug embed enchant exif ffi +fileinfo +filter firebird +flatfile fpm ftp gd gdbm gmp +iconv imap inifile intl iodbc ipv6 +jit kerberos ldap ldap-sasl libedit lmdb mhash mssql mysql mysqli nls oci8-instant-client odbc +opcache pcntl pdo +phar phpdbg +posix postgres qdbm readline selinux +session session-mm sharedmem +simplexml snmp soap sockets sodium spell sqlite ssl systemd sysvipc test threads tidy +tokenizer tokyocabinet truetype unicode valgrind webp +xml xmlreader xmlwriter xpm xslt zip zlib"

# Without USE=readline or libedit, the interactive "php -a" CLI will hang.
# The Oracle instant client provides its own incompatible ldap library.
REQUIRED_USE="
	|| ( cli cgi fpm apache2 embed phpdbg )
	avif? ( gd zlib )
	cli? ( ^^ ( readline libedit ) )
	!cli? ( ?? ( readline libedit ) )
	truetype? ( gd zlib )
	webp? ( gd zlib )
	cjk? ( gd zlib )
	exif? ( gd zlib )
	xpm? ( gd zlib )
	gd? ( zlib )
	simplexml? ( xml )
	soap? ( xml )
	xmlreader? ( xml )
	xmlwriter? ( xml )
	xslt? ( xml )
	ldap-sasl? ( ldap )
	oci8-instant-client? ( !ldap )
	qdbm? ( !gdbm )
	session-mm? ( session !threads )
	mysql? ( || ( mysqli pdo ) )
	firebird? ( pdo )
	mssql? ( pdo )
	test? ( cli )
"

RESTRICT="!test? ( test )"

# The supported (that is, autodetected) versions of BDB are listed in
# the ./configure script. Other versions *work*, but we need to stick to
# the ones that can be detected to avoid a repeat of bug #564824.
COMMON_DEPEND="
	>=app-eselect/eselect-php-0.9.7[apache2?,fpm?]
	>=dev-libs/libpcre2-10.30[jit?,unicode]
	virtual/libcrypt:=
	fpm? ( acl? ( sys-apps/acl ) apparmor? ( sys-libs/libapparmor ) selinux? ( sys-libs/libselinux ) )
	apache2? ( www-servers/apache[apache2_modules_unixd(+),threads=] )
	argon2? ( app-crypt/argon2:= )
	avif? ( media-libs/libavif:= )
	berkdb? ( || (	sys-libs/db:5.3 sys-libs/db:4.8 ) )
	bzip2? ( app-arch/bzip2:0= )
	cdb? ( || ( dev-db/cdb dev-db/tinycdb ) )
	curl? ( >=net-misc/curl-7.29.0 )
	enchant? ( app-text/enchant:2 )
	ffi? ( >=dev-libs/libffi-3.0.11:= )
	firebird? ( dev-db/firebird )
	gd? ( media-libs/libjpeg-turbo:0= media-libs/libpng:0= )
	gdbm? ( >=sys-libs/gdbm-1.8.0:0= )
	gmp? ( dev-libs/gmp:0= )
	iconv? ( virtual/libiconv )
	imap? ( net-libs/c-client[kerberos=,ssl=] )
	intl? ( dev-libs/icu:= )
	kerberos? ( virtual/krb5 )
	ldap? ( >=net-nds/openldap-1.2.11:= )
	ldap-sasl? ( dev-libs/cyrus-sasl )
	libedit? ( dev-libs/libedit )
	lmdb? ( dev-db/lmdb:= )
	mssql? ( dev-db/freetds[mssql] )
	nls? ( sys-devel/gettext )
	oci8-instant-client? ( dev-db/oracle-instantclient[sdk] )
	odbc? ( iodbc? ( dev-db/libiodbc ) !iodbc? ( >=dev-db/unixODBC-1.8.13 ) )
	postgres? ( >=dev-db/postgresql-9.1:* )
	qdbm? ( dev-db/qdbm )
	readline? ( sys-libs/readline:0= )
	session-mm? ( dev-libs/mm )
	snmp? ( >=net-analyzer/net-snmp-5.2 )
	sodium? ( dev-libs/libsodium:=[-minimal(-)] )
	spell? ( >=app-text/aspell-0.50 )
	sqlite? ( >=dev-db/sqlite-3.7.6.3 )
	ssl? ( >=dev-libs/openssl-1.0.2:0= )
	tidy? ( app-text/htmltidy )
	tokyocabinet? ( dev-db/tokyocabinet )
	truetype? ( =media-libs/freetype-2* )
	unicode? ( dev-libs/oniguruma:= )
	valgrind? ( dev-debug/valgrind )
	webp? ( media-libs/libwebp:0= )
	xml? ( >=dev-libs/libxml2-2.9.0:= )
	xpm? ( x11-libs/libXpm )
	xslt? ( dev-libs/libxslt )
	zip? ( >=dev-libs/libzip-1.2.0:= )
	zlib? ( >=sys-libs/zlib-1.2.0.4:0= )
"

IDEPEND=">=app-eselect/eselect-php-0.9.7[apache2?,fpm?]"

RDEPEND="${COMMON_DEPEND}
	virtual/mta
	fpm? (
		selinux? ( sec-policy/selinux-phpfpm )
		systemd? ( sys-apps/systemd ) )"

# Bison isn't actually needed when building from a release tarball
# However, the configure script will warn if it's absent or if you
# have an incompatible version installed. See bug 593278.
DEPEND="${COMMON_DEPEND}
	app-arch/xz-utils
	>=sys-devel/bison-3.0.1"

BDEPEND="virtual/pkgconfig"

PHP_MV="$(ver_cut 1)"

PATCHES=(
	"${FILESDIR}/php-iodbc-header-location.patch"
	"${FILESDIR}/php-capstone-optional.patch"
	"${FILESDIR}/php-8.2.8-openssl-tests.patch"
	"${FILESDIR}/php-8.2.20-implicit-printf.patch"
	"${FILESDIR}/php-8.2.23-fix-ub.patch"
)

# ARM/Windows functions (bug 923335)
QA_CONFIG_IMPL_DECL_SKIP=(
	__crc32d
	_controlfp
	_controlfp_s
)

# Functions from alternate iconv implementations (bug 925268)
QA_CONFIG_IMPL_DECL_SKIP+=(
	iconv_ccs_init
	cstoccsid
)

php_install_ini() {
	local phpsapi="${1}"

	# work out where we are installing the ini file
	php_set_ini_dir "${phpsapi}"

	# Always install the production INI file, bug 611214.
	local phpinisrc="php.ini-production-${phpsapi}"
	cp php.ini-production "${phpinisrc}" || die

	# default to /tmp for save_path, bug #282768
	sed -e 's|^;session.save_path .*$|session.save_path = "'"${EPREFIX}"'/tmp"|g' -i "${phpinisrc}" || die

	# Set the extension dir
	sed -e "s|^extension_dir .*$|extension_dir = ${extension_dir}|g" \
		-i "${phpinisrc}" || die

	# Set the include path to point to where we want to find PEAR packages
	sed -e 's|^;include_path = ".:/php/includes".*|include_path = ".:'"${EPREFIX}"'/usr/share/php'${PHP_MV}':'"${EPREFIX}"'/usr/share/php"|' -i "${phpinisrc}" || die

	insinto "${PHP_INI_DIR#${EPREFIX}}"
	newins "${phpinisrc}" php.ini

	elog "Installing php.ini for ${phpsapi} into ${PHP_INI_DIR#${EPREFIX}}"
	elog

	dodir "${PHP_EXT_INI_DIR#${EPREFIX}}"
	dodir "${PHP_EXT_INI_DIR_ACTIVE#${EPREFIX}}"

	if use opcache; then
		elog "Adding opcache to $PHP_EXT_INI_DIR"
		echo "zend_extension=${PHP_DESTDIR}/$(get_libdir)/opcache.so" >> \
			 "${D}/${PHP_EXT_INI_DIR}"/opcache.ini
		dosym "../ext/opcache.ini" \
			  "${PHP_EXT_INI_DIR_ACTIVE#${EPREFIX}}/opcache.ini"
	fi

	# SAPI-specific handling
	if [[ "${sapi}" == "fpm" ]] ; then
		einfo "Installing FPM config files php-fpm.conf and www.conf"
		insinto "${PHP_INI_DIR#${EPREFIX}}"
		doins sapi/fpm/php-fpm.conf
		insinto "${PHP_INI_DIR#${EPREFIX}}/fpm.d"
		doins sapi/fpm/www.conf
	fi

	dodoc php.ini-{development,production}
}

php_set_ini_dir() {
	PHP_INI_DIR="${EPREFIX}/etc/php/${1}-php${SLOT}"
	PHP_EXT_INI_DIR="${PHP_INI_DIR}/ext"
	PHP_EXT_INI_DIR_ACTIVE="${PHP_INI_DIR}/ext-active"
}

src_prepare() {
	default

	# In php-7.x, the FPM pool configuration files have been split off
	# of the main config. By default the pool config files go in
	# e.g. /etc/php-fpm.d, which isn't slotted. So here we move the
	# include directory to a subdirectory "fpm.d" of $PHP_INI_DIR. Later
	# we'll install the pool configuration file "www.conf" there.
	php_set_ini_dir fpm
	sed -i "s~^include=.*$~include=${PHP_INI_DIR}/fpm.d/*.conf~" \
		sapi/fpm/php-fpm.conf.in \
		|| die 'failed to move the include directory in php-fpm.conf'

	# Emulate buildconf to support cross-compilation
	rm -fr aclocal.m4 autom4te.cache config.cache \
		configure main/php_config.h.in || die
	eautoconf --force
	eautoheader

	# missing skipif; fixed upstream already
	rm sapi/cgi/tests/005.phpt || die

	# These three get BORKED on no-ipv6 systems,
	#
	#   https://github.com/php/php-src/pull/11651
	#
	rm ext/sockets/tests/mcast_ipv6_recv.phpt \
	   ext/sockets/tests/mcast_ipv6_recv_limited.phpt \
	   ext/sockets/tests/mcast_ipv6_send.phpt \
	   || die

	# fails in a network sandbox,
	#
	#   https://github.com/php/php-src/issues/11662
	#
	rm ext/sockets/tests/bug63000.phpt || die

	# expected output needs to be updated,
	#
	#   https://github.com/php/php-src/pull/11648
	#
	rm ext/dba/tests/dba_tcadb.phpt || die

	# Two IMAP tests missing SKIPIFs,
	#
	#   https://github.com/php/php-src/pull/11654
	#
	rm ext/imap/tests/imap_mutf7_to_utf8.phpt \
	   ext/imap/tests/imap_utf8_to_mutf7_basic.phpt \
	   || die

	# broken upstream with icu-73.x,
	#
	#   https://github.com/php/php-src/issues/11128
	#
	rm ext/intl/tests/calendar_clear_variation1.phpt || die

	# overly sensitive to INI values; fixes sent upstream:
	#
	#  https://github.com/php/php-src/pull/11631
	#
	rm ext/session/tests/{bug74514,bug74936,gh7787}.phpt || die

	# This is sensitive to the current "nice" level:
	#
	#   https://github.com/php/php-src/issues/11630
	#
	rm ext/standard/tests/general_functions/proc_nice_basic.phpt || die

	# Tests ignoring the "-n" flag we pass to run-tests.php,
	#
	#   https://github.com/php/php-src/pull/11669
	#
	rm ext/standard/tests/file/bug60120.phpt \
	   ext/standard/tests/general_functions/proc_open_null.phpt \
	   ext/standard/tests/general_functions/proc_open_redirect.phpt \
	   ext/standard/tests/general_functions/proc_open_sockets1.phpt \
	   ext/standard/tests/general_functions/proc_open_sockets2.phpt \
	   ext/standard/tests/general_functions/proc_open_sockets3.phpt \
	   ext/standard/tests/ini_info/php_ini_loaded_file.phpt \
	   sapi/cli/tests/016.phpt \
	   sapi/cli/tests/023.phpt \
	   sapi/cli/tests/bug65275.phpt \
	   sapi/cli/tests/bug74600.phpt \
	   sapi/cli/tests/bug78323.phpt \
	   || die

	# Same TEST_PHP_EXTRA_ARGS (-n) issue with this one, but it's
	# already been fixed upstream.
	rm sapi/cli/tests/017.phpt || die

	# Most Oracle tests are borked,
	#
	#  * https://github.com/php/php-src/issues/11804
	#  * https://github.com/php/php-src/pull/11820
	#  * https://github.com/php/php-src/issues/11819
	#
	rm ext/oci8/tests/*.phpt || die

	# https://github.com/php/php-src/issues/12801
	rm ext/pcre/tests/gh11374.phpt || die

	# This is a memory usage test with hard-coded limits. Whenever the
	# limits are surpassed... they get increased... but in the meantime,
	# the tests fail. This is not really a test that end users should
	# be running pre-install, in my opinion. Bug 927461.
	rm ext/fileinfo/tests/bug78987.phpt || die

	# glibc-2.39 compatibility, fixed upstream in
	# https://github.com/php/php-src/pull/14097
	rm ext/standard/tests/strings/setlocale_variation3.phpt || die

	# The expected warnings aren't triggered in this test because we
	# define session.save_path on the CLI:
	#
	#   https://github.com/php/php-src/issues/14368
	#
	rm ext/session/tests/gh13856.phpt || die

	# Bug 935382, fixed eventually by
	#
	# - https://github.com/php/php-src/pull/14788
	# - https://github.com/php/php-src/pull/14814
	#
	rm ext/standard/tests/strings/chunk_split_variation1_32bit.phpt || die
	rm ext/standard/tests/strings/wordwrap_memory_limit.phpt || die

	# Bug 935379, not yet fixed upstream but looks harmless (ordering
	# of keys isn't guaranteed AFAICS):
	#
	# - https://github.com/php/php-src/issues/14786
	#
	rm ext/dba/tests/dba_gdbm.phpt || die

	# https://github.com/php/php-src/pull/14439
	rm ext/openssl/tests/bug74341.phpt || die
}

src_configure() {
	addpredict /usr/share/snmp/mibs/.index #nowarn
	local varlib="/var/lib"
	if [[ -L "${varlib}" ]]; then
		varlib="$( readlink -e "${varlib}" )"
	fi
	addpredict "${varlib}"/net-snmp/mib_indexes #nowarn
	unset varlib

	# https://bugs.gentoo.org/866683, https://bugs.gentoo.org/913527
	filter-lto

	PHP_DESTDIR="${EPREFIX}/usr/$(get_libdir)/php${SLOT}"

	# Don't allow ./configure to detect and use an existing version
	# of PHP; this can lead to all sorts of weird unpredictability
	# as in bug 900210.
	export ac_cv_prog_PHP=""

	# The php-fpm config file wants localstatedir to be ${EPREFIX}/var
	# and not the Gentoo default ${EPREFIX}/var/lib. See bug 572002.
	local our_conf=(
		--prefix="${PHP_DESTDIR}"
		--mandir="${PHP_DESTDIR}/man"
		--infodir="${PHP_DESTDIR}/info"
		--libdir="${PHP_DESTDIR}/lib"
		--with-libdir="$(get_libdir)"
		--localstatedir="${EPREFIX}/var"
		--without-pear
		--without-valgrind
		--with-external-libcrypt
		$(use_enable threads zts)
	)

	# The slotted man/info pages will be missed by the default list of
	# docompress paths.
	docompress "${PHP_DESTDIR}/man" "${PHP_DESTDIR}/info"

	our_conf+=(
		$(use_with apparmor fpm-apparmor)
		$(use_with argon2 password-argon2 "${EPREFIX}/usr")
		$(use_with avif)
		$(use_enable bcmath)
		$(use_with bzip2 bz2 "${EPREFIX}/usr")
		$(use_enable calendar)
		$(use_enable ctype)
		$(use_with curl)
		$(use_enable xml dom)
		$(use_with enchant)
		$(use_enable exif)
		$(use_with ffi)
		$(use_enable fileinfo)
		$(use_enable filter)
		$(use_enable ftp)
		$(use_with nls gettext "${EPREFIX}/usr")
		$(use_with gmp gmp "${EPREFIX}/usr")
		$(use_with mhash mhash "${EPREFIX}/usr")
		$(use_with iconv iconv \
			$(use elibc_glibc || use elibc_musl || echo "${EPREFIX}/usr"))
		$(use_enable intl)
		$(use_enable ipv6)
		$(use_with kerberos)
		$(use_with xml libxml)
		$(use_enable unicode mbstring)
		$(use_with ssl openssl)
		$(use_enable pcntl)
		$(use_enable phar)
		$(use_enable pdo)
		$(use_enable opcache)
		$(use_with postgres pgsql "${EPREFIX}/usr")
		$(use_enable posix)
		$(use_with selinux fpm-selinux)
		$(use_with spell pspell "${EPREFIX}/usr")
		$(use_enable simplexml)
		$(use_enable sharedmem shmop)
		$(use_with snmp snmp "${EPREFIX}/usr")
		$(use_enable soap)
		$(use_enable sockets)
		$(use_with sodium)
		$(use_with sqlite sqlite3)
		$(use_enable sysvipc sysvmsg)
		$(use_enable sysvipc sysvsem)
		$(use_enable sysvipc sysvshm)
		$(use_with tidy tidy "${EPREFIX}/usr")
		$(use_enable tokenizer)
		$(use_enable xml)
		$(use_enable xmlreader)
		$(use_enable xmlwriter)
		$(use_with xslt xsl)
		$(use_with zip)
		$(use_with zlib zlib "${EPREFIX}/usr")
		$(use_enable debug)
		$(use_with valgrind)
	)

	# DBA support
	if use cdb || use berkdb || use flatfile || use gdbm || use inifile \
		|| use qdbm || use lmdb || use tokyocabinet ; then
		our_conf+=( "--enable-dba" )
	fi

	# DBA drivers support
	our_conf+=(
		$(use_with cdb)
		$(use_with berkdb db4 "${EPREFIX}/usr")
		$(use_enable flatfile)
		$(use_with gdbm gdbm "${EPREFIX}/usr")
		$(use_enable inifile)
		$(use_with qdbm qdbm "${EPREFIX}/usr")
		$(use_with tokyocabinet tcadb "${EPREFIX}/usr")
		$(use_with lmdb lmdb "${EPREFIX}/usr")
	)

	# Support for the GD graphics library
	our_conf+=(
		$(use_with truetype freetype)
		$(use_enable cjk gd-jis-conv)
		$(use_with gd jpeg)
		$(use_with xpm)
		$(use_with webp)
	)
	# enable gd last, so configure can pick up the previous settings
	our_conf+=( $(use_enable gd) )

	# IMAP support
	if use imap ; then
		our_conf+=(
			$(use_with imap imap "${EPREFIX}/usr")
			$(use_with ssl imap-ssl "${EPREFIX}/usr")
		)
	fi

	# LDAP support
	if use ldap ; then
		our_conf+=(
			$(use_with ldap ldap "${EPREFIX}/usr")
			$(use_with ldap-sasl)
		)
	fi

	# MySQL support
	our_conf+=( $(use_with mysqli) )

	local mysqlsock="${EPREFIX}/var/run/mysqld/mysqld.sock"
	if use mysql || use mysqli ; then
		our_conf+=( $(use_with mysql mysql-sock "${mysqlsock}") )
	fi

	# ODBC support
	if use odbc && use iodbc ; then
		our_conf+=(
			--without-unixODBC
			--with-iodbc
			$(use_with pdo pdo-odbc "iODBC,${EPREFIX}/usr")
		)
	elif use odbc ; then
		our_conf+=(
			--with-unixODBC="${EPREFIX}/usr"
			--without-iodbc
			$(use_with pdo pdo-odbc "unixODBC,${EPREFIX}/usr")
		)
	else
		our_conf+=(
			--without-unixODBC
			--without-iodbc
			--without-pdo-odbc
		)
	fi

	# Oracle support
	our_conf+=( $(use_with oci8-instant-client oci8) )

	# PDO support
	if use pdo ; then
		our_conf+=(
			$(use_with mssql pdo-dblib "${EPREFIX}/usr")
			$(use_with mysql pdo-mysql "mysqlnd")
			$(use_with postgres pdo-pgsql)
			$(use_with sqlite pdo-sqlite)
			$(use_with firebird pdo-firebird "${EPREFIX}/usr")
			$(use_with oci8-instant-client pdo-oci)
		)
	fi

	# readline/libedit support
	our_conf+=(
		$(use_with readline readline "${EPREFIX}/usr")
		$(use_with libedit)
	)

	# Session support
	if use session ; then
		our_conf+=( $(use_with session-mm mm "${EPREFIX}/usr") )
	else
		our_conf+=( $(use_enable session) )
	fi

	# Use pic for shared modules such as apache2's mod_php
	our_conf+=( --with-pic )

	# we use the system copy of pcre
	# --with-external-pcre affects ext/pcre
	our_conf+=(
		--with-external-pcre
		$(use_with jit pcre-jit)
	)

	# Catch CFLAGS problems
	# Fixes bug #14067.
	# Changed order to run it in reverse for bug #32022 and #12021.
	replace-cpu-flags "k6*" "i586"

	# Cache the ./configure test results between SAPIs.
	our_conf+=( --cache-file="${T}/config.cache" )

	# Support user-passed configuration parameters
	our_conf+=( ${EXTRA_ECONF:-} )

	# Support the Apache2 extras, they must be set globally for all
	# SAPIs to work correctly, especially for external PHP extensions

	# Create separate build trees for each enabled SAPI. The upstream
	# build system doesn't do this, but we have to do it to use a
	# different php.ini for each SAPI (see --with-config-file-path and
	# --with-config-file-scan-dir below). The path winds up define'd
	# in main/build-defs.h which is included in main/php.h which is
	# included by basically everything; so, avoiding a rebuild after
	# changing it is not an easy job.
	local one_sapi
	local sapi
	mkdir "${WORKDIR}/sapis-build" || die
	for one_sapi in $SAPIS ; do
		use "${one_sapi}" || continue
		php_set_ini_dir "${one_sapi}"

		# The BUILD_DIR variable is used to determine where to output
		# the files that autotools creates. This was all originally
		# based on the autotools-utils eclass.
		BUILD_DIR="${WORKDIR}/sapis-build/${one_sapi}"
		cp -a "${S}" "${BUILD_DIR}" || die

		local sapi_conf=(
			--with-config-file-path="${PHP_INI_DIR}"
			--with-config-file-scan-dir="${PHP_EXT_INI_DIR_ACTIVE}"
		)

		for sapi in $SAPIS ; do
			case "$sapi" in
				cli|cgi|embed|fpm|phpdbg)
					if [[ "${one_sapi}" == "${sapi}" ]] ; then
						sapi_conf+=( "--enable-${sapi}" )
						if [[ "fpm" == "${sapi}" ]] ; then
							sapi_conf+=(
								$(use_with acl fpm-acl)
								$(use_with systemd fpm-systemd)
							)
						fi
					else
						sapi_conf+=( "--disable-${sapi}" )
					fi
					;;

				apache2)
					if [[ "${one_sapi}" == "${sapi}" ]] ; then
						sapi_conf+=( --with-apxs2="${EPREFIX}/usr/bin/apxs" )
					else
						sapi_conf+=( --without-apxs2 )
					fi
					;;
			esac
		done

		# Construct the $myeconfargs array by concatenating $our_conf
		# (the common args) and $sapi_conf (the SAPI-specific args).
		local myeconfargs=( "${our_conf[@]}" )
		myeconfargs+=( "${sapi_conf[@]}" )

		pushd "${BUILD_DIR}" > /dev/null || die
		einfo "Running econf in ${BUILD_DIR}"
		econf "${myeconfargs[@]}"
		popd > /dev/null || die
	done
}

src_compile() {
	# snmp seems to run during src_compile, too (bug #324739)
	addpredict /usr/share/snmp/mibs/.index #nowarn
	local varlib="/var/lib"
	if [[ -L "${varlib}" ]]; then
		varlib="$( readlink -e "${varlib}" )"
	fi
	addpredict "${varlib}"/net-snmp/mib_indexes #nowarn
	unset varlib

	if use oci8-instant-client && use kerberos && use imap && use phar; then
		# A conspiracy takes place when the first three of these flags
		# are set together, causing the newly-built "php" to open
		# /dev/urandom with mode rw when it starts. That's not actually
		# a problem... unless you also have USE=phar, which runs that
		# "php" to build some phar thingy in src_compile(). Later in
		# src_test(), portage (at least) sets "addpredict /" so the
		# problem does not repeat.
		addpredict /dev/urandom #nowarn
	fi

	local sapi
	for sapi in ${SAPIS} ; do
		use "${sapi}" && emake -C "${WORKDIR}/sapis-build/${sapi}"
	done
}

src_install() {
	# see bug #324739 for what happens when we don't have that
	addpredict /usr/share/snmp/mibs/.index #nowarn

	# grab the first SAPI that got built and install common files from there
	local first_sapi="", sapi=""
	for sapi in $SAPIS ; do
		if use $sapi ; then
			first_sapi=$sapi
			break
		fi
	done

	# Makefile forgets to create this before trying to write to it...
	dodir "${PHP_DESTDIR#${EPREFIX}}/bin"

	# Install php environment (without any sapis)
	cd "${WORKDIR}/sapis-build/$first_sapi" || die
	emake INSTALL_ROOT="${D}" \
		install-build install-headers install-programs

	local extension_dir="$("${ED}/${PHP_DESTDIR#${EPREFIX}}/bin/php-config" --extension-dir)"

	# Create the directory where we'll put version-specific php scripts
	keepdir "/usr/share/php${PHP_MV}"

	local file=""
	local sapi_list=""

	for sapi in ${SAPIS}; do
		if use "${sapi}" ; then
			einfo "Installing SAPI: ${sapi}"
			cd "${WORKDIR}/sapis-build/${sapi}" || die

			if [[ "${sapi}" == "apache2" ]] ; then
				# We're specifically not using emake install-sapi as libtool
				# may cause unnecessary relink failures (see bug #351266)
				insinto "${PHP_DESTDIR#${EPREFIX}}/apache2/"
				newins ".libs/libphp$(get_libname)" \
					   "libphp${PHP_MV}$(get_libname)"
				keepdir "/usr/$(get_libdir)/apache2/modules"
			else
				# needed each time, php_install_ini would reset it
				local dest="${PHP_DESTDIR#${EPREFIX}}"
				into "${dest}"
				case "$sapi" in
					cli)
						source="sapi/cli/php"
						# Install the "phar" archive utility.
						if use phar ; then
							emake INSTALL_ROOT="${D}" install-pharcmd
							dosym "..${dest#/usr}/bin/phar" "/usr/bin/phar${SLOT}"
						fi
						;;
					cgi)
						source="sapi/cgi/php-cgi"
						;;
					fpm)
						source="sapi/fpm/php-fpm"
						;;
					embed)
						source="libs/libphp$(get_libname)"
						;;
					phpdbg)
						source="sapi/phpdbg/phpdbg"
						;;
					*)
						die "unhandled sapi in src_install"
						;;
				esac

				if [[ "${source}" == *"$(get_libname)" ]]; then
					dolib.so "${source}"
				else
					dobin "${source}"
					local name="$(basename ${source})"
					dosym "..${dest#/usr}/bin/${name}" "/usr/bin/${name}${SLOT}"
				fi
			fi

			php_install_ini "${sapi}"

			# construct correct SAPI string for php-config
			# thanks to ferringb for the bash voodoo
			if [[ "${sapi}" == "apache2" ]]; then
				sapi_list="${sapi_list:+${sapi_list} }apache2handler"
			else
				sapi_list="${sapi_list:+${sapi_list} }${sapi}"
			fi
		fi
	done

	# Installing opcache module
	if use opcache ; then
		into "${PHP_DESTDIR#${EPREFIX}}"
		dolib.so "modules/opcache$(get_libname)"
	fi

	# Install env.d files
	newenvd "${FILESDIR}/20php5-envd" "20php${SLOT}"
	sed -e "s|/lib/|/$(get_libdir)/|g" -i "${ED}/etc/env.d/20php${SLOT}" || die
	sed -e "s|php5|php${SLOT}|g" -i "${ED}/etc/env.d/20php${SLOT}" || die

	# set php-config variable correctly (bug #278439)
	sed -e "s:^\(php_sapis=\)\".*\"$:\1\"${sapi_list}\":" -i \
		"${ED}/usr/$(get_libdir)/php${SLOT}/bin/php-config" || die

	if use fpm ; then
		if use systemd; then
			systemd_newunit "${FILESDIR}/php-fpm_at.service" \
							"php-fpm@${SLOT}.service"
		fi
	fi
}

src_test() {
	export TEST_PHP_EXECUTABLE="${WORKDIR}/sapis-build/cli/sapi/cli/php"

	# Sometimes when the sub-php launches a sub-sub-php, it uses these.
	# Without an "-n" in all instances, the *live* php.ini can be loaded,
	# pulling in *live* zend extensions. And those can be incompatible
	# with the thing we just built.
	export TEST_PHP_EXTRA_ARGS="-n"

	if [[ -x "${WORKDIR}/sapis-build/cgi/sapi/cgi/php-cgi" ]] ; then
		export TEST_PHP_CGI_EXECUTABLE="${WORKDIR}/sapis-build/cgi/sapi/cgi/php-cgi"
	fi

	if [[ -x "${WORKDIR}/sapis-build/phpdbg/sapi/phpdbg/phpdbg" ]] ; then
		export TEST_PHPDBG_EXECUTABLE="${WORKDIR}/sapis-build/phpdbg/sapi/phpdbg/phpdbg"
	fi

	# The sendmail override prevents ext/imap/tests/bug77020.phpt from
	# actually trying to send mail, and will be fixed upstream soon:
	#
	#   https://github.com/php/php-src/issues/11629
	#
	# The IO capture tests need to be disabled because they fail when
	# std{in,out,err} are redirected (as they are within portage).
	#
	# One -n applies to the top-level "php", while the other applies
	# to any sub-php that get invoked by the test runner.
	SKIP_IO_CAPTURE_TESTS=1 SKIP_PERF_SENSITIVE=1 REPORT_EXIT_STATUS=1 \
		"${TEST_PHP_EXECUTABLE}" -n \
		"${WORKDIR}/sapis-build/cli/run-tests.php" --offline -n -q \
		-d "session.save_path=${T}" \
		-d "sendmail_path=echo >/dev/null" \
		|| die "tests failed"
}

pkg_postinst() {
	# Output some general info to the user
	if use apache2 ; then
		elog
		elog "To enable PHP in apache, you will need to add \"-D PHP\" to"
		elog "your apache2 command. OpenRC users can append that string to"
		elog "APACHE2_OPTS in /etc/conf.d/apache2."
		elog
		elog "The apache module configuration file 70_mod_php.conf is"
		elog "provided (and maintained) by eselect-php."
		elog
	fi

	# Create the symlinks for php
	local m
	for m in ${SAPIS}; do
		[[ ${m} == 'embed' ]] && continue;
		if use $m ; then
			local ci=$(eselect php show $m)
			if [[ -z $ci ]]; then
				einfo "Switching ${m} to use php:${SLOT} ..."
				eselect php set $m php${SLOT} || die
				einfo "Switched ${m} to use php:${SLOT}"
				einfo
			elif [[ $ci != "php${SLOT}" ]] ; then
				elog "To switch $m to use php:${SLOT}, run"
				elog "    eselect php set $m php${SLOT}"
				elog
			fi
		fi
	done

	# Remove dead symlinks for SAPIs that were just disabled. For
	# example, if the user has the cgi SAPI enabled, then he has an
	# eselect-php symlink for it. If he later reinstalls PHP with
	# USE="-cgi", that symlink will break. This call to eselect is
	# supposed to remove that dead link per bug 572436.
	eselect php cleanup || die

	if ! has "php${SLOT/./-}" ${PHP_TARGETS}; then
	   elog "To build extensions for this version of PHP, you will need to"
	   elog "add php${SLOT/./-} to your PHP_TARGETS USE_EXPAND variable."
	   elog
	fi

	# Warn about the removal of PHP_INI_VERSION if the user has it set.
	if [[ -n "${PHP_INI_VERSION}" ]]; then
		ewarn 'The PHP_INI_VERSION variable has been phased out. You may'
		ewarn 'remove it from your configuration at your convenience. See'
		ewarn
		ewarn '  https://bugs.gentoo.org/611214'
		ewarn
		ewarn 'for more information.'
	fi

	elog "For details on how version slotting works, please see"
	elog "the wiki:"
	elog
	elog "  https://wiki.gentoo.org/wiki/PHP"
	elog
}

pkg_postrm() {
	# This serves two purposes. First, if we have just removed the last
	# installed version of PHP, then this will remove any dead symlinks
	# belonging to eselect-php. Second, if a user upgrades slots from
	# (say) 5.6 to 7.0 and depcleans the old slot, then this will update
	# his existing symlinks to point to the new 7.0 installation. The
	# latter is bug 432962.
	#
	# Note: the eselect-php package may not be installed at this point,
	# so we can't die() if this command fails.
	eselect php cleanup
}
