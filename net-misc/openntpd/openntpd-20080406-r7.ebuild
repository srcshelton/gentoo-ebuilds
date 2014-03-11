# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/openntpd/openntpd-20080406-r7.ebuild,v 1.6 2014/03/08 13:19:23 maekke Exp $

EAPI=5

inherit autotools eutils toolchain-funcs systemd user

MY_P="${P/-/_}p"
DEB_VER="6"
DESCRIPTION="Lightweight NTP server ported from OpenBSD"
HOMEPAGE="http://www.openntpd.org/"
SRC_URI="mirror://debian/pool/main/${PN:0:1}/${PN}/${MY_P}.orig.tar.gz
	mirror://debian/pool/main/${PN:0:1}/${PN}/${MY_P}-${DEB_VER}.debian.tar.gz"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~mips ppc ~ppc64 ~s390 ~sh ~sparc x86 ~x86-fbsd"
IUSE="ssl selinux systemd"

RDEPEND="ssl? ( dev-libs/openssl )
	selinux? ( sec-policy/selinux-ntp )
	!<=net-misc/ntp-4.2.0-r2
	!net-misc/ntp[-openntpd]"
DEPEND="${RDEPEND}
	virtual/yacc"

S="${WORKDIR}/${MY_P/_/-}"

export NTP_HOME="${NTP_HOME:=/var/lib/openntpd/chroot}"

pkg_setup() {
	enewgroup ntp
	enewuser ntp -1 -1 "${NTP_HOME}" ntp

	# make sure user has correct HOME as flipng between
	# the standard ntp pkg and this one was possible in
	# the past
	if [[ $(egethome ntp) != ${NTP_HOME} ]]; then
		ewarn "From this version on, the homedir of the ntp user cannot be changed"
		ewarn "dynamically after the installation. For a home directory other than"
		ewarn "'/var/lib/openntpd/chroot', set NTP_HOME in your make.conf and re-emerge."
		esethome ntp "${NTP_HOME}"
	fi
}

src_prepare() {
	sed -i '/NTPD_USER/s:_ntp:ntp:' ntpd.h || die

	epatch "${WORKDIR}"/debian/patches/*.patch
	epatch "${FILESDIR}/${P}-pidfile.patch"
	epatch "${FILESDIR}/${P}-signal.patch"
	epatch "${FILESDIR}/${P}-dns-timeout.patch"
	sed -i 's:debian:gentoo:g' ntpd.conf || die
	eautoreconf # deb patchset touches .ac files and such
}

src_configure() {
	econf \
		--disable-strip \
		$(use_with !ssl builtin-arc4random) \
		AR="$(type -p $(tc-getAR))"
}

src_install() {
	default

	newinitd "${FILESDIR}/${PN}.init.d-${PV}-r6" ntpd
	newconfd "${FILESDIR}/${PN}.conf.d-${PV}-r6" ntpd

	use systemd && systemd_newunit "${FILESDIR}/${PN}.service-${PV}-r3" ntpd.service
}

pkg_config() {
	[[ -n "${NTP_HOME:-}" ]] || return 1

	export NTP_HOME="${NTP_HOME%%/}/"

	einfo "Setting up chroot for ntp in '${NTP_HOME}'"

	# Remove localtime file from previous installations...
	rm -f "${EROOT:-/}${NTP_HOME}"etc/localtime
	mkdir -p "${EROOT:-/}${NTP_HOME}"etc
	if ! ln "${EROOT:-/}"etc/localtime "${EROOT:-/}${NTP_HOME}"etc/localtime >/dev/null 2>&1 ; then
		cp "${EROOT:-/}"etc/localtime "${EROOT:-/}${NTP_HOME}"etc/localtime >/dev/null 2>&1 || \
			die "Could not link '${EROOT:-/}${NTP_HOME}etc/localtime' to '${EROOT:-/}etc/localtime' by any method"
		einfo "Could not create a hardlink from '/etc/localtime' to '${NTP_HOME:-/}etc/localtime',"
		einfo "please run 'emerge --config =${CATEGORY}/${PF}' whenever you change"
		einfo "your timezone."
	fi
	chown -R root:root "${EROOT:-/}${NTP_HOME:-}" || die "Setting owner for '${EROOT:-/}${NTP_HOME:-}' failed: $?"
}

pkg_postinst() {
	pkg_config

	[[ -f "${EROOT:-/}"var/log/ntpd.log ]] && \
		ewarn "There is an orphaned logfile '${EROOT:-/}var/log/ntpd.log', please remove it!"
}

pkg_postrm() {
	# remove localtime file from previous installations
	rm -f "${EROOT:-/}${NTP_HOME:-}"etc/localtime
}
