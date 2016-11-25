# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/openntpd/openntpd-20080406-r9.ebuild,v 1.4 2014/11/02 09:10:58 swift Exp $

EAPI=5

inherit autotools eutils toolchain-funcs systemd user

MY_P="${P/0.2008/2008}"
MY_P="${MY_P/-/_}p"
DEB_VER="10"
DESCRIPTION="Lightweight NTP server ported from OpenBSD"
HOMEPAGE="http://www.openntpd.org/"
SRC_URI="mirror://debian/pool/main/${PN:0:1}/${PN}/${MY_P}.orig.tar.gz
	mirror://debian/pool/main/${PN:0:1}/${PN}/${MY_P}-${DEB_VER}.debian.tar.xz"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~x86-fbsd"
IUSE="ssl selinux systemd"

CDEPEND="ssl? ( dev-libs/openssl )
	!<=net-misc/ntp-4.2.0-r2
	!net-misc/ntp[-openntpd]"
DEPEND="${CDEPEND}
	virtual/yacc"
RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-ntp )
"

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
		ewarn "dynamically after the installation. For any home directory other than"
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
	rmdir "${ED}"/{var/empty,var}

	newinitd "${FILESDIR}/${PN}.init.d-${PV}-r6" ntpd
	newconfd "${FILESDIR}/${PN}.conf.d-${PV}-r6" ntpd

	use systemd && systemd_newunit "${FILESDIR}/${PN}.service-${PV}-r4" ntpd.service
}

pkg_config() {
	local eroot="" home=""

	[[ -n "${NTP_HOME:-}" ]] || return 1

	[[ -n "${EROOT:-}" ]] && eroot="${EROOT%%/}"
	home="${NTP_HOME%%/}"

	if [[ -z "${eroot:-}" && -z "${home:-}" ]]; then
		return 1
	fi

	[[ -r "$( readlink -e "${eroot:-}"/etc/localtime )" ]] || \
		die "${eroot:-}/etc/localtime does not exist - please set your" \
			"timezone, then re-run 'emerge --config =${CATEGORY}/${PF}'"

	einfo "Setting up chroot for ntp in '${eroot:-}${home}/'"

	# Remove localtime file from previous installations...
	mkdir -p "${eroot:-}${home}"/etc || die "Could not create directory '${eroot:-}${home}/etc': $?"
	[[ -e "${eroot:-}${home}"/etc/localtime || -L "${eroot:-}${home}"/etc/localtime ]] && \
		rm -f "${eroot:-}${home}"/etc/localtime
	if ! ln "${eroot:-}"/etc/localtime "${eroot:-}${home}"/etc/localtime >/dev/null 2>&1 ; then
		cp -L "${eroot:-}"/etc/localtime "${eroot:-}${home}"/etc/localtime >/dev/null 2>&1 || \
			die "Could not create link '${eroot:-}${home}/etc/localtime' from '${eroot:-}/etc/localtime' by any method"
		einfo "Could not create a hardlink from '${eroot:-}/etc/localtime' to '${home}/etc/localtime',"
		einfo "please run 'emerge --config =${CATEGORY}/${PF}' whenever you change"
		einfo "your timezone."
	fi
	chown -R root:root "${eroot:-}${home}"/ || die "Setting owner for '${eroot:-}${home}/' failed: $?"
}

pkg_postinst() {
	local eroot="" home=""

	pkg_config

	[[ -n "${EROOT:-}" ]] && eroot="${EROOT%%/}"
	[[ -n "${NTP_HOME:-}" ]] && home="${NTP_HOME%%/}"
	[[ -f "${eroot:-}"/var/log/ntpd.log ]] && \
		ewarn "There is an orphaned logfile '${eroot:-}/var/log/ntpd.log', please remove it!"

	# bug #226491, remove <=openntpd-20080406-r7 trash
	if [[ -n "${eroot:-}" || -n "${home:-}" ]]; then
		rm -f "${eroot}${home}"/etc/localtime
		rmdir "${eroot}${home}"/etc
	fi
}

pkg_postrm() {
	local eroot="" home=""

	# remove localtime file from previous installations
	[[ -n "${EROOT:-}" ]] && eroot="${EROOT%%/}"
	[[ -n "${NTP_HOME:-}" ]] && home="${NTP_HOME%%/}"

	if [[ -n "${eroot:-}" || -n "${home:-}" ]]; then
		rm -f "${eroot:-}${home:-}"/etc/localtime
	fi
}
