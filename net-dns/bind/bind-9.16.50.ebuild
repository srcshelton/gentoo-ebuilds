# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Re: dlz/mysql and threads, needs to be verified.
# MySQL uses thread local storage in its C api. Thus MySQL
# requires that each thread of an application execute a MySQL
# thread initialization to setup the thread local storage.
# This is impossible to do safely while staying within the DLZ
# driver API. This is a limitation caused by MySQL, and not the DLZ API.
# Because of this BIND MUST only run with a single thread when
# using the MySQL driver.

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/isc.asc
inherit autotools db-use flag-o-matic multiprocessing python-r1 systemd tmpfiles toolchain-funcs verify-sig

MY_PV="${PV/_p/-P}"
MY_PV="${MY_PV/_rc/rc}"
MY_P="${PN}-${MY_PV}"

SDB_LDAP_VER="1.1.0-fc14"

RRL_PV="${MY_PV}"

# SDB-LDAP: http://bind9-ldap.bayour.com/

DESCRIPTION="Berkeley Internet Name Domain - Name Server"
HOMEPAGE="https://www.isc.org/software/bind https://gitlab.isc.org/isc-projects/bind9"
SRC_URI="
	https://downloads.isc.org/isc/bind9/${PV}/${P}.tar.xz
	doc? ( mirror://gentoo/dyndns-samples.tbz2 )
	verify-sig? ( https://downloads.isc.org/isc/bind9/${PV}/${P}.tar.xz.asc )
"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0 BSD BSD-2 GPL-2 HPND ISC MPL-2.0"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm arm64 ~hppa ~mips ppc ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux"
# -berkdb by default re bug #602682
IUSE="berkdb +caps +dlz dnsrps dnstap doc fixed-rrset geoip geoip2 gssapi json ldap lmdb mysql odbc postgres python selinux static-libs systemd test +tmpfiles xml +zlib"
# sdb-ldap - patch broken
# no PKCS11 currently as it requires OpenSSL to be patched, also see bug #409687
RESTRICT="!test? ( test )"

# Upstream dropped the old geoip library, but the BIND configuration for using
# GeoIP remains the same.
REQUIRED_USE="
	postgres? ( dlz )
	berkdb? ( dlz )
	mysql? ( dlz )
	odbc? ( dlz )
	ldap? ( dlz )
	dnsrps? ( dlz )
	python? ( ${PYTHON_REQUIRED_USE} )
"

DEPEND="
	acct-group/named
	acct-user/named
	dev-libs/libuv:=
	berkdb? ( sys-libs/db:= )
	dev-libs/openssl:=[-bindist(-)]
	mysql? ( dev-db/mysql-connector-c:0= )
	odbc? ( >=dev-db/unixODBC-2.2.6 )
	ldap? ( net-nds/openldap:= )
	postgres? ( dev-db/postgresql:= )
	caps? ( >=sys-libs/libcap-2.1.0 )
	xml? ( dev-libs/libxml2 )
	geoip? ( dev-libs/libmaxminddb:= )
	geoip2? ( dev-libs/libmaxminddb:= )
	gssapi? ( virtual/krb5 )
	json? ( dev-libs/json-c:= )
	lmdb? ( dev-db/lmdb:= )
	zlib? ( sys-libs/zlib )
	dnstap? ( dev-libs/fstrm dev-libs/protobuf-c:= )
	python? (
		${PYTHON_DEPS}
		dev-python/ply[${PYTHON_USEDEP}]
	)
"
RDEPEND="
	${DEPEND}
	sys-process/psmisc
	selinux? ( sec-policy/selinux-bind )
"
BDEPEND="
	test? (
		dev-util/cmocka
		dev-util/kyua
	)
	verify-sig? ( sec-keys/openpgp-keys-isc )
"

PATCHES=(
	"${FILESDIR}/ldap-library-path-on-multilib-machines.patch"
)

src_unpack() {
	if use verify-sig; then
		verify-sig_verify_detached "${DISTDIR}"/${P}.tar.xz{,.asc}
	fi
	default
}

src_prepare() {
	default

	# Should be installed by bind-tools
	sed -i -r -e "s:(nsupdate|dig|delv) ::g" bin/Makefile.in || die

	# Fix hard-coding of .../lib/
	sed -ri "s:(openssl|geoip|gssapi|kame_path|prefix|libiconv|idn_path|atf)/lib([/ ]):\1/$(get_libdir)\2:g" \
		configure.ac || die
	sed -ri "s:\{use_libjson\}/lib\":{use_libjson}/$(get_libdir)\":g" \
		configure.ac || die

	# Slow tests
	sed -i "s/{name='mem_test'}/{name='mem_test',timeout=900}/" "lib/isc/tests/Kyuafile" || die
	sed -i "s/{name='timer_test'}/{name='timer_test',timeout=900}/" "lib/isc/tests/Kyuafile" || die

	# Conditionally broken
	use sparc && ( sed -i "/{name='netmgr_test'}/d" "lib/isc/tests/Kyuafile" || die )

	# bug #220361
	rm aclocal.m4 configure || die
	rm -rf libtool.m4/ || die
	eautoreconf

	sed -ri "/\\\$d\/lib(\/|$)/s:d/lib:d/$(get_libdir):g" \
		configure || die

	use python && python_copy_sources
}

src_configure() {
	bind_configure --without-python
	use python && python_foreach_impl python_configure
}

bind_configure() {
	local myeconfargs=(
		AR="$(type -P $(tc-getAR))"
		--prefix="${EPREFIX%/}"/usr
		--sysconfdir=/etc/bind
		--localstatedir=/var
		--with-libtool
		--enable-full-report
		--without-readline
		--with-openssl="${ESYSROOT%/}"/usr
		$(use_with test cmocka)
		# Removed in 9.17, drags in libunwind dependency too
		--disable-backtrace
		$(use_enable caps linux-caps)
		$(use_enable dnsrps)
		$(use_enable dnstap)
		$(use_enable fixed-rrset)
		$(use_with berkdb dlz-bdb "${ESYSROOT%/}"/usr)
		$(use_with dlz dlopen)
		$(use_with dlz dlz-filesystem)
		$(use_with dlz dlz-stub)
		$(use_with gssapi)
		$(use_with json json-c)
		$(use_with ldap dlz-ldap)
		$(use_with mysql dlz-mysql)
		$(use_with odbc dlz-odbc)
		$(use_with postgres dlz-postgres)
		$(use_with lmdb)
		$(use_with xml libxml2)
		$(use_with zlib)
		"${@}"
	)

	# This is for users to start to migrate back to USE=geoip, rather than
	# USE=geoip2
	if use geoip ; then
		myeconfargs+=( $(use_with geoip maxminddb) --enable-geoip )
	elif use geoip2 ; then
		# Added 2020/09/30
		# Remove USE=geoip2 support after 2020/03/01
		ewarn "USE=geoip2 is deprecated; update your USE flags!"
		myeconfargs+=( $(use_with geoip2 maxminddb) --enable-geoip )
	else
		myeconfargs+=( --without-maxminddb --disable-geoip )
	fi

	# bug #158664
	#gcc-specs-ssp && replace-flags -O[23s] -O

	# To include db.h from proper path
	use berkdb && append-flags "-I$(db_includedir)"

	export BUILD_CC=$(tc-getBUILD_CC)
	econf "${myeconfargs[@]}"

	# bug #151839
	echo '#undef SO_BSDCOMPAT' >> config.h || die
}

python_configure() {
	pushd "${BUILD_DIR}" >/dev/null || die
	bind_configure --with-python
	popd >/dev/null || die
}

src_compile() {
	default
	use python && python_foreach_impl python_compile
}

python_compile() {
	emake -C "${BUILD_DIR}"/bin/python
}

src_test() {
	# system tests ('emake test') require network configuration for IPs etc
	# so we run the unit tests instead.
	TEST_PARALLEL_JOBS="$(makeopts_jobs)" emake -Onone unit
}

src_install() {
	default

	dodoc CHANGES README

	if use doc; then
		docinto misc
		dodoc -r doc/misc/

		# might a 'html' useflag make sense?
		docinto html
		dodoc -r doc/arm/

		docinto contrib
		dodoc contrib/scripts/{nanny.pl,named-bootconf.sh}

		# some handy-dandy dynamic dns examples
		pushd "${ED}/usr/share/doc/${PF}" 1>/dev/null || die
		tar xf "${DISTDIR}"/dyndns-samples.tbz2 || die
		popd 1>/dev/null || die
	fi

	insinto /etc/bind
	newins "${FILESDIR}"/named.conf-r8 named.conf

	# ftp://ftp.rs.internic.net/domain/named.cache:
	insinto /var/bind
	newins "${FILESDIR}"/named.cache-r4 named.cache

	insinto /var/bind/pri
	newins "${FILESDIR}"/localhost.zone-r3 localhost.zone

	newinitd "${FILESDIR}"/named.init-r14 named
	newconfd "${FILESDIR}"/named.confd-r7 named

	newenvd "${FILESDIR}"/10bind.env 10bind

	# Let's get rid of those tools and their manpages since they're provided by bind-tools
	rm -f "${ED}"/usr/share/man/man1/{dig,host,nslookup,delv,nsupdate}.1* || die
	rm -f "${ED}"/usr/share/man/man8/nsupdate.8* || die
	rm -f "${ED}"/usr/bin/{dig,host,nslookup,nsupdate} || die
	rm -f "${ED}"/usr/sbin/{dig,host,nslookup,nsupdate} || die
	for tool in dsfromkey importkey keyfromlabel keygen \
	revoke settime signzone verify; do
		rm -f "${ED}"/usr/{,s}bin/dnssec-"${tool}" || die
		rm -f "${ED}"/usr/share/man/man8/dnssec-"${tool}".8* || die
	done

	# bug 405251, library archives aren't properly handled by --enable/disable-static
	if ! use static-libs; then
		find "${ED}" -type f -name '*.a' -delete || die
	fi

	# bug 405251
	find "${ED}" -type f -name '*.la' -delete || die

	use python && python_foreach_impl python_install

	# bug 450406
	dosym named.cache /var/bind/root.cache

	dosym ../../var/bind/pri /etc/bind/pri
	dosym ../../var/bind/sec /etc/bind/sec
	dosym ../../var/bind/dyn /etc/bind/dyn
	keepdir /var/bind/{pri,sec,dyn} /var/log/named

	# /etc/bind is set to root:named by acct-user/named
	fowners root:named /{etc,var}/bind /var/log/named /var/bind/{sec,pri,dyn}
	fowners root:named /var/bind/named.cache /var/bind/pri/localhost.zone /etc/bind/{bind.keys,named.conf}
	fperms 0640 /var/bind/named.cache /var/bind/pri/localhost.zone /etc/bind/{bind.keys,named.conf}
	fperms 0750 /etc/bind /var/bind/pri
	fperms 0770 /var/log/named /var/bind/{,sec,dyn}

	use systemd && systemd_newunit "${FILESDIR}/named.service-r1" named.service
	use tmpfiles && dotmpfiles "${FILESDIR}"/named.conf
	exeinto /usr/libexec
	doexe "${FILESDIR}/generate-rndc-key.sh"
}

python_install() {
	pushd "${BUILD_DIR}"/bin/python >/dev/null || die
	emake DESTDIR="${D}" install
	python_scriptinto /usr/sbin
	python_doscript dnssec-{checkds,coverage}
	python_optimize
	popd >/dev/null || die
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process named.conf

	if [[ ! -f "${ROOT}/etc/bind/rndc.key" ]]; then
		if [[ -f "${ROOT}/etc/bind/rndc.conf" ]]; then
			ewarn "'${ROOT}/etc/bind/rndc.conf' exists - not generating new 'rndc.key'"
		else
			if [ "${ROOT}" != '/' ]; then
				local -x LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${ROOT%/}/$(get_libdir):${ROOT%/}/usr/$(get_libdir)"
			fi
			if "${ROOT}"/usr/sbin/rndc-confgen -a; then
				# rndc-confgen always creates files in /etc/bind/...
				chown root:named /etc/bind/rndc.key || die
				chmod 0640 /etc/bind/rndc.key || die
			fi
			if [ -f /etc/bind/rndc.key ] && [ ! -f "${ROOT}"/etc/bind/rndc.key ]; then
				cp -a /etc/bind/rndc.key "${ROOT}"/etc/bind/rndc.key
			fi
		fi
	fi

	einfo
	einfo "You can edit /etc/conf.d/named to customize named settings"
	einfo
	use mysql || use postgres || use ldap && {
		elog "If your named depends on MySQL/PostgreSQL or LDAP,"
		elog "uncomment the specified rc_named_* lines in your"
		elog "/etc/conf.d/named config to ensure they'll start before bind"
		einfo
	}
	einfo "If you'd like to run bind in a chroot AND this is a new"
	einfo "install OR your bind doesn't already run in a chroot:"
	einfo "1) Uncomment and set the CHROOT variable in /etc/conf.d/named."
	einfo "2) Run \`emerge --config '=${CATEGORY}/${PF}'\`"
	einfo

	CHROOT=$(source "${EROOT}"/etc/conf.d/named 2>/dev/null; echo ${CHROOT})
	if [[ -n ${CHROOT} ]]; then
		elog "NOTE: As of net-dns/bind-9.4.3_p5-r1 the chroot part of the init-script got some major changes!"
		elog "To enable the old behaviour (without using mount) uncomment the"
		elog "CHROOT_NOMOUNT option in your /etc/conf.d/named config."
		elog "If you decide to use the new/default method, ensure to make backup"
		elog "first and merge your existing configs/zones to /etc/bind and"
		elog "/var/bind because bind will now mount the needed directories into"
		elog "the chroot dir."
	fi
}

pkg_config() {
	CHROOT=$(source "${EROOT}"/etc/conf.d/named; echo ${CHROOT})
	CHROOT_NOMOUNT=$(source "${EROOT}"/etc/conf.d/named; echo ${CHROOT_NOMOUNT})
	CHROOT_GEOIP=$(source "${EROOT}"/etc/conf.d/named; echo ${CHROOT_GEOIP})

	if [[ -z "${CHROOT}" ]]; then
		eerror "This config script is designed to automate setting up"
		eerror "a chrooted bind/named. To do so, please first uncomment"
		eerror "and set the CHROOT variable in '/etc/conf.d/named'."
		die "Unset CHROOT"
	fi
	if [[ -d "${CHROOT}" ]]; then
		ewarn "NOTE: As of net-dns/bind-9.4.3_p5-r1 the chroot part of the init-script got some major changes!"
		ewarn "To enable the old behaviour (without using mount) uncomment the"
		ewarn "CHROOT_NOMOUNT option in your /etc/conf.d/named config."
		ewarn
		ewarn "${CHROOT} already exists... some things might become overridden"
		ewarn "press CTRL+C if you don't want to continue"
		sleep 10
	fi

	echo; einfo "Setting up the chroot directory..."

	mkdir -m 0750 -p ${CHROOT} || die
	mkdir -m 0755 -p ${CHROOT}/{dev,etc,var/log,var/run} || die
	mkdir -m 0750 -p ${CHROOT}/etc/bind || die
	mkdir -m 0770 -p ${CHROOT}/var/{bind,log/named} ${CHROOT}/var/run/named/ || die

	chown root:named \
		${CHROOT} \
		${CHROOT}/var/{bind,log/named} \
		${CHROOT}/var/run/named/ \
		${CHROOT}/etc/bind \
		|| die

	[[ -e ${CHROOT}/dev/null ]] && rm ${CHROOT}/dev/null
	mknod ${CHROOT}/dev/null c 1 3 || die
	chmod 0666 ${CHROOT}/dev/null || die

	[[ -e ${CHROOT}/dev/zero ]] && rm ${CHROOT}/dev/zero
	mknod ${CHROOT}/dev/zero c 1 5 || die
	chmod 0666 ${CHROOT}/dev/zero || die

	[[ -e ${CHROOT}/dev/urandom ]] && rm ${CHROOT}/dev/urandom
	mknod ${CHROOT}/dev/urandom c 1 9 || die
	chmod 0666 ${CHROOT}/dev/urandom || die

	if [ "${CHROOT_NOMOUNT:-0}" -ne 0 ]; then
		cp -a /etc/bind ${CHROOT}/etc/ || die
		cp -a /var/bind ${CHROOT}/var/ || die
	fi

	if [ "${CHROOT_GEOIP:-0}" -eq 1 ]; then
		if use geoip; then
			mkdir -m 0755 -p ${CHROOT}/usr/share/GeoIP || die
		elif use geoip2; then
			mkdir -m 0755 -p ${CHROOT}/usr/share/GeoIP2 || die
		fi
	fi

	elog "You may need to add the following line to your syslog-ng.conf:"
	elog "source jail { unix-stream(\"${CHROOT}/dev/log\"); };"
}

# vi: set diffopt=filler,iwhite:
