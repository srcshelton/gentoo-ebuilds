# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools eapi9-ver systemd tmpfiles toolchain-funcs

MY_PV="${PV/_p/-P}"
MY_PV="${MY_PV/_rc/rc}"

DESCRIPTION="Berkeley Internet Name Domain - Name Server"
HOMEPAGE="https://www.isc.org/software/bind"
SRC_URI="https://downloads.isc.org/isc/bind9/${PV}/${P}.tar.xz"
S="${WORKDIR}/${PN}-${MY_PV}"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="+caps dnstap doc doh fixed-rrset geoip gssapi idn jemalloc lmdb selinux +server static-libs systemd test +tools xml"
REQUIRED_USE="
	dnstap? ( server )
	doh? ( server )
	fixed-rrset? ( server )
	geoip? ( server )
	jemalloc? ( server )
	lmdb? ( server )
"
RESTRICT="!test? ( test )"

DEPEND="
	acct-group/named
	acct-user/named
	dev-libs/json-c:=
	>=dev-libs/libuv-1.37.0:=
	sys-libs/zlib:=
	dev-libs/openssl:=[-bindist(-)]
	caps? ( >=sys-libs/libcap-2.1.0 )
	dnstap? (
		dev-libs/fstrm
		dev-libs/protobuf-c
	)
	doh? ( net-libs/nghttp2:= )
	geoip? ( dev-libs/libmaxminddb )
	gssapi? ( virtual/krb5 )
	idn? ( net-dns/libidn2 )
	jemalloc? ( dev-libs/jemalloc:= )
	lmdb? ( dev-db/lmdb )
	xml? ( dev-libs/libxml2:= )
"
RDEPEND="
	${DEPEND}
	selinux? ( sec-policy/selinux-bind )
	sys-process/psmisc
	!<net-dns/bind-tools-9.18.0
"
# sphinx required for man-page and html creation
BDEPEND="
	dev-lang/perl
	virtual/pkgconfig
	doc? ( dev-python/sphinx )
	test? (
		dev-util/cmocka
	)
"

src_prepare() {
	default

	# Don't clobber our toolchain defaults
	sed -i -e '/FORTIFY_SOURCE=/d' configure || die

	# Fix hard-coding of .../lib/
	sed -ri "s:(openssl|geoip|gssapi|kame_path|prefix|libiconv|idn_path|atf)/lib([/ ]):\1/$(get_libdir)\2:g" \
		configure.ac || die
	sed -ri "s:\{use_libjson\}/lib\":{use_libjson}/$(get_libdir)\":g" \
		configure.ac || die

	# Test is (notoriously) slow/resource intensive
	sed -i -e 's:ISC_TEST_MAIN:int main(void) { exit(77); }:' tests/isc/netmgr_test.c || die

	# Relies on -Wl,--wrap (bug #877741)
	if tc-is-lto ; then
		sed -i -e 's:ISC_TEST_MAIN:int main(void) { exit(77); }:' tests/ns/query_test.c || die
	fi

	sed -ri "/\\\$d\/lib(\/|$)/s:d/lib:d/$(get_libdir):g" \
		configure || die

	eautoreconf
}

src_configure() {
	# configure automagically uses sphinx even if prebuilt man pages
	# are available. Force fallback to prebuilt ones.
	use doc || export ac_cv_path_SPHINX_BUILD= SPHINX_BUILD=

	local myeconfargs=(
		--prefix="${EPREFIX%/}"/usr
		--sysconfdir="${EPREFIX%/}"/etc/bind
		--localstatedir="${EPREFIX%/}"/var/state
		--enable-full-report
		--without-readline
		--with-openssl="${ESYSROOT%/}"/usr
		--with-json-c
		--with-zlib
		$(use_enable caps linux-caps)
		--disable-dnsrps
		$(use_enable dnstap)
		$(use_enable doh)
		$(use_with doh libnghttp2)
		$(use_enable fixed-rrset)
		$(use_enable static-libs static)
		$(use_enable geoip)
		$(use_with test cmocka)
		$(use_with geoip maxminddb)
		$(use_with gssapi)
		$(use_with idn libidn2)
		$(use_with jemalloc)
		$(use_with lmdb)
		$(use_with xml libxml2)
	)

	econf "${myeconfargs[@]}"
}

src_test() {
	# system tests ('emake test') require network configuration for IPs etc
	# so we run the unit tests instead.
	CI=1 emake unit V=1

	# libtest is an internal test helper library, it has no tests,
	# so suppress the QA warning.
	rm tests/libtest/test-suite.log || die
}

src_install() {
	default

	dodoc README.md

	if use tools && ! use server; then
		# This isn't going to be as easy(!) as it looked - the
		# build-tree contents are now actually libtool wrapper scripts
		# and so rather than installing what we need, we actually have
		# to do a full installation and then remove the superfluous
		# elements :(
		#

		# Required libraries:
		#
		# /usr/lib64/libbind9-9.18.29.so
		# /usr/lib64/libdns-9.18.29.so
		# /usr/lib64/libirs-9.18.29.so
		# /usr/lib64/libisc-9.18.29.so
		# /usr/lib64/libisccc-9.18.29.so
		# /usr/lib64/libisccfg-9.18.29.so
		# /usr/lib64/libns-9.18.29.so
		#

		mkdir "${T}"/image
		mv "${ED}"/* "${T}"/image/

		local dir=''
		for dir in bin "$(get_libdir)" share/man/man1; do
			mkdir -p "${ED%/}/usr/${dir}" ||
				die "mkdir failed: ${?}"
			chmod "${ED%/}/usr/${dir}" --reference "${T%/}/image/usr/${dir}" ||
				die "chmod failed: ${?}"
			chown "${ED%/}/usr/${dir}" --reference "${T%/}/image/usr/${dir}" ||
				die "chmod failed: ${?}"
		done

		docinto html

		# TODO: Make this dynamic based on 'ldd' output?
		local lib=''
		for lib in bind9 dns irs isc isccc isccfg ns; do
			mv "${T%/}"/image/usr/$(get_libdir)/lib${lib}-${PV}.so* \
					"${ED%/}"/usr/$(get_libdir)/ ||
				die "Failed moving library lib${lib}-${PV}.so from" \
					"'${T%/}/image/usr/$(get_libdir)/' to" \
					"'${ED%/}/usr/$(get_libdir)/'"
		done

		local cmd=''
		for cmd in delv dig host nslookup nsupdate; do
			mv "${T%/}/image/usr/bin/${cmd}" "${ED%/}"/usr/bin/
			mv "${T%/}/image/usr/share/man/man1/${cmd}.1"* \
				"${ED}"/usr/share/man/man1/
			if use doc && [[ "${cmd}" == 'nsupdate' ]]; then
				dodoc "${T%/}/image/usr/share/doc/${PVR}/html/${cmd}.html" ||
					die
			fi
		done
		for cmd in dsfromkey importkey keyfromlabel keygen revoke settime \
				signzone verify
		do
			mv "${T%/}/image/usr/bin/dnssec-${cmd}" "${ED%/}"/usr/bin/
			mv "${T%/}/image/usr/share/man/man1/${cmd}.1"* \
				"${ED%/}"/usr/share/man/man1/
			if use doc; then
				dodoc "${T%/}/image/usr/share/doc/${PVR}/html/dnssec-${cmd}.html" ||
					die
			fi
		done

		if ! use static-libs ; then
			if find "${ED}"/usr/lib* -name '*.la' -quit; then
				find "${ED}"/usr/lib* -name '*.la' -delete || die
			fi
		fi

		return 0
	fi

	if use doc; then
		docinto misc
		dodoc -r doc/misc/

		docinto html
		dodoc -r doc/arm/

		docinto dnssec-guide
		dodoc -r doc/dnssec-guide/

		docinto contrib
		dodoc contrib/scripts/nanny.pl
	fi

	insinto /etc/bind
	newins "${FILESDIR}"/named.conf-r9 named.conf
	newins "${FILESDIR}"/named.conf.auth named.conf.auth

	newinitd "${FILESDIR}"/named.init-r15 named
	newconfd "${FILESDIR}"/named.confd-r8 named

	newenvd "${FILESDIR}"/10bind.env 10bind

	if ! use static-libs ; then
		if find "${ED}"/usr/lib* -name '*.la' -quit; then
			find "${ED}"/usr/lib* -name '*.la' -delete || die
		fi
	fi

	#
	# /var/state/bind
	#
	# These need to remain for now because CONFIG_PROTECT won't
	# save them and we shipped configs for years containing references
	# to them.
	#
	# ftp://ftp.rs.internic.net/domain/named.cache:
	insinto /var/state/bind
	newins "${FILESDIR}"/named.cache-r4 named.cache
	# bug #450406
	dosym named.cache /var/state/bind/root.cache
	#
	insinto /var/state/bind/pri
	newins "${FILESDIR}"/localhost.zone-r3 localhost.zone

	dosym -r /var/state/bind/pri /etc/bind/pri
	dosym -r /var/state/bind/sec /etc/bind/sec
	dosym -r /var/state/bind/dyn /etc/bind/dyn
	keepdir /var/state/bind/{pri,sec,dyn} /var/log/named

	# /etc/bind is set to root:named by acct-user/named
	fowners root:named /{etc,var/state}/bind /var/log/named \
		/var/state/bind/{sec,pri,dyn}
	fowners root:named /etc/bind/{bind.keys,named.conf,named.conf.auth}
	fperms 0640 /etc/bind/{bind.keys,named.conf,named.conf.auth}
	fperms 0750 /etc/bind /var/state/bind/pri
	fperms 0770 /var/log/named /var/state/bind/{,sec,dyn}

	use systemd && systemd_newunit "${FILESDIR}/named.service-r2" named.service
	use tmpfiles && dotmpfiles "${FILESDIR}"/named.conf
	exeinto /usr/libexec
	doexe "${FILESDIR}/generate-rndc-key.sh"

	if ! use tools; then
		local tool=''
		for tool in delv dig host nslookup nsupdate; do
			rm "${ED%/}/usr/bin/${tool}" \
					"${ED%/}/usr/share/man/man1/${tool}.1"* ||
				die "Failed to remove ${PN} tool '${tool}': ${?}"
		done
		if use doc; then
			rm "${ED%/}/usr/share/doc/${PF}/html/nsupdate.html" ||
				die "Failed to remove ${PN} HTML document" \
					"'dnssec-${tool}.html': ${?}"
		fi
		for tool in dsfromkey importkey keyfromlabel keygen revoke settime \
				signzone verify
		do
			rm "${ED%/}/usr/bin/dnssec-${tool}" \
					"${ED%/}/usr/share/man/man1/dnssec-${tool}.1"* ||
				die "Failed to remove ${PN} tool '${tool}': ${?}"
			if use doc; then
				rm "${ED%/}/usr/share/doc/${PF}/html/dnssec-${tool}.html" ||
					die "Failed to remove ${PN} HTML document" \
						"'dnssec-${tool}.html': ${?}"
			fi
		done
	fi
}

pkg_postinst() {
	use !server && return 0

	use tmpfiles && tmpfiles_process named.conf

	if ! [[ -f "${EROOT}/etc/bind/rndc.key" ]]; then
		if [[ -f /etc/bind/rndc.conf ]]; then
			ewarn "'/etc/bind/rndc.conf' exists - not generating" \
				"new 'rndc.key'"
		elif [[ -f "${EROOT}/etc/bind/rndc.conf" ]]; then
			ewarn "'${EROOT}/etc/bind/rndc.conf' exists - not" \
				"generating new 'rndc.key'"
		else
			if ! [[ -f /etc/bind/rndc.key ]]; then
				if [[ "${ROOT}" != '/' ]]; then
					local -x LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${ROOT%/}/$(get_libdir):${ROOT%/}/usr/$(get_libdir)"
				fi
				einfo "Generating rndc.key"
				if "${EROOT}"/usr/sbin/rndc-confgen -a; then
					# rndc-confgen always creates files in
					# /etc/bind/...
					chown root:named /etc/bind/rndc.key || die
					chmod 0640 /etc/bind/rndc.key || die
				fi
			fi
		fi
		if [[ -f /etc/bind/rndc.key ]] &&
				[[ ! -f "${ROOT}"/etc/bind/rndc.key ]]
		then
			cp -a /etc/bind/rndc.key \
				"${EROOT}"/etc/bind/rndc.key
		fi
	fi

	einfo
	einfo "You can edit /etc/conf.d/named to customize named settings"
	einfo

	einfo "If you'd like to run bind in a chroot AND this is a new"
	einfo "install OR your bind doesn't already run in a chroot:"
	einfo "1) Uncomment and set the CHROOT variable in /etc/conf.d/named."
	einfo "2) Run \`emerge --config '=${CATEGORY}/${PF}'\`"
	einfo

	CHROOT=$(source "${EROOT}"/etc/conf.d/named 2>/dev/null; echo ${CHROOT})
	if [[ -n "${CHROOT:-}" ]]; then
		elog "NOTE: As of net-dns/bind-9.4.3_p5-r1 the chroot part" \
			"of the init-script got some major changes!"
		elog "To enable the old behaviour (without using mount)" \
			"uncomment the"
		elog "CHROOT_NOMOUNT option in your /etc/conf.d/named config."
		elog "If you decide to use the new/default method, ensure to" \
			"make backup"
		elog "first and merge your existing configs/zones to" \
			"/etc/bind and"
		elog "/var/state/bind because bind will now mount the" \
			"needed directories into"
		elog "the chroot dir."
	fi

	# show only when upgrading to 9.18
	if ver_replacing -lt 9.18; then
		elog "As this is a major bind version upgrade, please read:"
		elog "   https://kb.isc.org/docs/changes-to-be-aware-of-when-moving-from-bind-916-to-918"
		elog "for differences in functionality."
		elog ""
		ewarn "In particular, please note that bind-9.18 does not" \
			"need a root hints file anymore"
		ewarn "and we only ship with one as a stop-gap. If your" \
			"current configuration specifies a"
		ewarn "root hints file - usually called named.cache - bind" \
			"will not start as it will not be able"
		ewarn "to find the specified file. Best practice is to" \
			"delete the offending lines that"
		ewarn "reference named.cache file from your configuration."
	fi
}

pkg_config() {
	if ! use server; then
		eerror "pkg_config() is only valid for bind/named server installations"
		die "Need USE='server'"
	fi

	CHROOT=$(source "${EROOT}"/etc/conf.d/named; echo ${CHROOT})
	CHROOT_NOMOUNT=$(source "${EROOT}"/etc/conf.d/named; echo ${CHROOT_NOMOUNT})
	CHROOT_GEOIP=$(source "${EROOT}"/etc/conf.d/named; echo ${CHROOT_GEOIP})

	if [[ -z "${CHROOT:-}" ]]; then
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

	mkdir -m 0750 -p "${CHROOT}" || die
	mkdir -m 0755 -p "${CHROOT}"/{dev,etc,var/log,var/run} || die
	mkdir -m 0750 -p "${CHROOT}"/etc/bind || die
	mkdir -m 0770 -p "${CHROOT}"/var/{state/bind,log/named} \
		"${CHROOT}"/var/run/named/ || die

	chown root:named \
		"${CHROOT}" \
			"${CHROOT}"/var/{state/bind,log/named} \
		"${CHROOT}"/run/named/ \
			"${CHROOT}"/etc/bind ||
		die

	[[ -e "${CHROOT}"/dev/null ]] && rm "${CHROOT}"/dev/null
	mknod "${CHROOT}"/dev/null c 1 3 || die
	chmod 0666 "${CHROOT}"/dev/null || die

	[[ -e "${CHROOT}"/dev/zero ]] && rm "${CHROOT}"/dev/zero
	mknod "${CHROOT}"/dev/zero c 1 5 || die
	chmod 0666 "${CHROOT}"/dev/zero || die

	[[ -e "${CHROOT}"/dev/urandom ]] && rm "${CHROOT}"/dev/urandom
	mknod ${CHROOT}/dev/urandom c 1 9 || die
	chmod 0666 ${CHROOT}/dev/urandom || die

	if [[ "${CHROOT_NOMOUNT:-"0"}" -ne 0 ]]; then
		cp -a /etc/bind "${CHROOT}"/etc/ || die
		cp -a /var/state/bind "${CHROOT}"/var/state/ || die
	fi

	if [[ "${CHROOT_GEOIP:-"0"}" -eq 1 ]]; then
		# The 'geoip2' USE flag no longer exists - let's assume it is
		# now the intended option when 'geoip' is specified...
		#
		#if use geoip; then
		#	mkdir -m 0755 -p "${CHROOT}"/usr/share/GeoIP || die
		#elif use geoip2; then
			mkdir -m 0755 -p "${CHROOT}"/usr/share/GeoIP2 || die
		#fi
	fi

	elog "You may need to add the following line to your syslog-ng.conf:"
	elog "source jail { unix-stream(\"${CHROOT}/dev/log\"); };"
}

# vi: set diffopt=filler,iwhite:
