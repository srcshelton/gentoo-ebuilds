# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic systemd tmpfiles toolchain-funcs

DESCRIPTION="IPsec implementation for Linux, fork of Openswan"
HOMEPAGE="https://libreswan.org/"
SRC_URI="https://download.libreswan.org/${P}.tar.gz"

LICENSE="GPL-2 BSD-4 RSA DES"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc x86"
IUSE="caps curl dnssec +ikev1 ldap networkmanager pam seccomp selinux systemd test"
RESTRICT="!test? ( test )"

COMMON_DEPEND="
	dev-libs/gmp:0=
	dev-libs/libevent:0=
	dev-libs/nspr
	>=dev-libs/nss-3.42
	virtual/libcrypt:=
	caps? ( sys-libs/libcap-ng )
	curl? ( net-misc/curl )
	dnssec? ( >=net-dns/unbound-1.9.1-r1:= net-libs/ldns:= net-dns/dnssec-root )
	ldap? ( net-nds/openldap:= )
	pam? ( sys-libs/pam )
	seccomp? ( sys-libs/libseccomp )
	selinux? ( sys-libs/libselinux )
	systemd? ( sys-apps/systemd:0= )
"
BDEPEND="
	app-text/docbook-xml-dtd:4.1.2
	app-text/xmlto
	dev-libs/nss
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	test? ( dev-python/setproctitle )
"
RDEPEND="${COMMON_DEPEND}
	dev-libs/nss[utils(+)]
	sys-apps/iproute2
	!net-vpn/strongswan
	selinux? ( sec-policy/selinux-ipsec )
"
DEPEND="${COMMON_DEPEND}
	virtual/os-headers:41900
	elibc_musl? ( sys-libs/queue-standalone )
"

usetf() {
	usex "$1" true false
}

src_prepare() {
	sed -i -e 's:/sbin/runscript:/sbin/openrc-run:' initsystems/openrc/ipsec.init.in || die
	sed -i -e '/^install/ s/postcheck//' -e '/^doinstall/ s/oldinitdcheck//' initsystems/systemd/Makefile || die
	default
}

src_configure() {
	tc-export AR CC

	use elibc_musl && append-cflags -DGLIBC_KERN_FLIP_HEADERS

	export PREFIX=/usr
	export DEFAULT_DNSSEC_ROOTKEY_FILE=/etc/dnssec/icannbundle.pem
	export EXAMPLE_IPSEC_SYSCONFDIR=/usr/share/doc/${PF}
	export FINALEXAMPLECONFDIR=/usr/share/doc/${PF}
	export INITSYSTEM=$(usex systemd systemd openrc)
	export INITDDIRS=
	export INITDDIR_DEFAULT=/etc/init.d
	export USERCOMPILE=${CFLAGS}
	export USERLINK=${LDFLAGS}
	export USE_DNSSEC=$(usetf dnssec)
	export USE_IKEV1=$(usetf ikev1)
	export USE_LABELED_IPSEC=$(usetf selinux)
	export USE_LIBCAP_NG=$(usetf caps)
	export USE_LIBCURL=$(usetf curl)
	export USE_LINUX_AUDIT=$(usetf selinux)
	export USE_LDAP=$(usetf ldap)
	export USE_NM=$(usetf networkmanager)
	export USE_SECCOMP=$(usetf seccomp)
	export USE_SYSTEMD_WATCHDOG=$(usetf systemd)
	export SD_WATCHDOGSEC=$(usex systemd 200 0)
	export USE_AUTHPAM=$(usetf pam)
	export DEBUG_CFLAGS=
	export OPTIMIZE_CFLAGS=
	export WERROR_CFLAGS=
}

src_compile() {
	emake all
	emake -C initsystems \
		INITSYSTEM=systemd \
		SYSTEMUNITDIR="$(systemd_get_systemunitdir)" \
		SYSTEMTMPFILESDIR="/usr/lib/tmpfiles.d" \
		all
}

src_test() {
	: # integration tests only that require set of kvms to be set up
}

src_install() {
	default
	emake -C initsystems \
		  INITSYSTEM=systemd \
		  SYSTEMUNITDIR="$(systemd_get_systemunitdir)" \
		  SYSTEMTMPFILESDIR="/usr/lib/tmpfiles.d" \
		  DESTDIR="${D}" \
		  install

	echo "include /etc/ipsec.d/*.secrets" > "${D}"/etc/ipsec.secrets
	fperms 0600 /etc/ipsec.secrets

	keepdir /var/lib/ipsec/nss
	fperms 0700 /var/lib/ipsec/nss

	dodoc -r docs

	find "${D}" -type d -empty -delete || die
}

pkg_postinst() {
	tmpfiles_process libreswan.conf

	local IPSEC_CONFDIR=${ROOT}/var/lib/ipsec/nss
	if [[ ! -f ${IPSEC_CONFDIR}/cert8.db && ! -f ${IPSEC_CONFDIR}/cert9.db ]] ; then
		ebegin "Setting up NSS database in ${IPSEC_CONFDIR} with empty password"
		certutil -N -d "${IPSEC_CONFDIR}" --empty-password
		eend $?
		einfo "To set a password: certutil -W -d sql:${IPSEC_CONFDIR}"
	fi
}
