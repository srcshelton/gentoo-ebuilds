# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info systemd tmpfiles udev

DESCRIPTION="APC UPS daemon with integrated tcp/ip remote shutdown"
HOMEPAGE="http://www.apcupsd.org/"
SRC_URI="https://downloads.sourceforge.net/apcupsd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ppc ~riscv x86"
IUSE="cgi doc dumb +modbus net nis powerchute selinux +smart snmp systemd tmpfiles +tools udev +usb"
REQUIRED_USE="
	|| ( cgi dumb modbus net smart usb )
"

COMMON_DEPEND="
	cgi? ( media-libs/gd:2= )
	modbus? (
		usb? ( virtual/libusb:0= )
	)
	snmp? ( net-analyzer/net-snmp )
"

# apcupsd requires 'shutdown', 'wall', sendmail...
DEPEND="${COMMON_DEPEND}
	virtual/mailx
	sys-apps/util-linux[tty-helpers]
	|| (
		sys-apps/sysvinit
		>=sys-apps/openrc-0.48[sysv-utils(-)]
		sys-apps/openrc-navi[sysv-utils(-)]
		sys-apps/s6-linux-init[sysv-utils(-)]
		sys-apps/systemd[sysv-utils(-)]
	)
"

# ... but we don't necessarily want these in, e.g., a container where we're
# primarily after the CGI components
RDEPEND="${COMMON_DEPEND}
	selinux? ( sec-policy/selinux-apcupsd )
	tools? ( ${DEPEND} )
"

CONFIG_CHECK="~USB_HIDDEV ~HIDRAW"
ERROR_USB_HIDDEV="CONFIG_USB_HIDDEV:	needed to access USB-attached UPSes"
ERROR_HIDRAW="CONFIG_HIDRAW:		needed to access USB-attached UPSes"

PATCHES=(
	"${FILESDIR}"/${PN}-3.14.9-aliasing.patch
	"${FILESDIR}"/${PN}-3.14.9-close-on-exec.patch
	"${FILESDIR}"/${PN}-3.14.9-commfailure.patch
	"${FILESDIR}"/${PN}-3.14.9-fix-nologin.patch
	"${FILESDIR}"/${PN}-3.14.9-gapcmon.patch
	"${FILESDIR}"/${PN}-3.14.9-wall-on-mounted-usr.patch
	"${FILESDIR}"/${PN}-3.14.14-lto.patch
)

pkg_setup() {
	if use kernel_linux && use usb && linux_config_exists ; then
		check_extra_config
	fi
}

src_prepare() {
	default
	# skip this specific doc step as produced files never installed
	# this avoids calling the col command not available on musl based system.
	sed -i "/^SUBDIRS/ s/doc//g" Makefile || die
}

src_configure() {
	local -a myeconfargs=()

	if ! use usb; then
		ewarn "Configuring ${PN} for serial device on /dev/ttyS0"
	fi

	# We force the DISTNAME to gentoo so it will use gentoo's layout also
	# when installed on non-linux systems.
	myeconfargs=(
		APCUPSD_MAIL="$(type -p mail)"
		# Build GTK/GUI front-end to apcupsd...
		--disable-gapcmon
		--sbindir="/sbin"
		--sysconfdir="${EPREFIX}/etc/apcupsd"
		--with-distname="gentoo"
		--with-lock-dir="${EPREFIX}/var/lock"
		--with-log-dir="${EPREFIX}/var/log"
		--with-pid-dir="${EPREFIX}/var/run/apcupsd"
		--with-pwrfail-dir="${EPREFIX}/etc/apcupsd"
		$(use_enable dumb)
		$(use_enable modbus)
		$(use_enable net)
		$(use_enable powerchute pcnet)
		$(use_enable smart apcsmart)
		$(use_enable snmp)
		$(use_enable usb )
		$(usex usb "--without-serial-dev" "--with-serial-dev=/dev/ttyS0")
		$(usex usb '--with-dev=""' "--with-dev=/dev/ttyS0")
	)

	use cgi && myeconfargs+=(
		--enable-cgi
		--with-cgi-bin="${EPREFIX}/usr/libexec/${PN}/cgi-bin"
	)

	if use usb && use modbus; then
		myeconfargs+=( --enable-modbus-usb )
	else
		myeconfargs+=( --disable-modbus-usb )
	fi

	# Type options:  apcsmart, usb, net, snmp, dumb, pcnet, modbus
	# Cable options: simple, smart, ether, usb or specific cable model number
	if use usb; then
		myeconfargs+=(
			--with-upscable="usb"
			--with-upstype="usb"
		)
	elif use modbus; then
		myeconfargs+=(
			--with-upscable="smart"
			--with-upstype="modbus"
		)
	elif use smart; then
		myeconfargs+=(
			--with-upscable="smart"
			--with-upstype="apcsmart"
		)
	elif use net; then
		myeconfargs+=(
			--with-upscable="ether"
			--with-upstype="net"
		)
	else
		myeconfargs+=(
			--with-upscable="simple"
			--with-upstype="dumb"
		)
	fi

	if use nis; then
		myeconfargs+=(
			# Specify the IP address to bind to...
			--with-nisip="127.0.0.1"
			--with-nis-port="3551"
		)
	else
		sed -i -e '/^NISSRV_ENABLED=yes$/{s:yes:no:}' configure ||
			die "NIS patch failed"
	fi

	econf "${myeconfargs[@]}"
}

src_compile() {
	emake VERBOSE="2" || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" VERBOSE="2" install || die "installation failed"

	rm "${ED}"/etc/init.d/apcupsd || die
	rm "${ED}"/etc/init.d/halt || die
	rm -r "${ED}"/usr/share/hal || die

	insinto /etc/apcupsd
	newins examples/safe.apccontrol safe.apccontrol
	if ! [[ -s "${ED}"/etc/apcupsd/apcupsd.conf ]]; then
		doins "${FILESDIR}"/apcupsd.conf
	fi

	doman doc/*.8 doc/*.5

	if use doc; then
		docinto html
		dodoc -r doc/manual/.
	fi
	einstalldocs

	newinitd "${FILESDIR}"/apcupsd.init apcupsd
	newinitd "${FILESDIR}"/apcupsd.powerfail.init-r1 apcupsd.powerfail

	use systemd && systemd_dounit "${FILESDIR}"/apcupsd.service
	use tmpfiles && dotmpfiles "${FILESDIR}"/apcupsd-tmpfiles.conf

	# replace it with our udev rules if we're in Linux
	if use udev && use kernel_linux; then
		udev_newrules "${FILESDIR}"/apcupsd-udev.rules 60-${PN}.rules
	fi

}

pkg_postinst() {
	use udev && use kernel_linux && udev_reload

	use tmpfiles && tmpfiles_process ${PN}-tmpfiles.conf

	if use cgi ; then
		elog "The cgi-bin directory for ${PN} is /usr/libexec/${PN}/cgi-bin."
		elog "Set up your ScriptAlias or symbolic links accordingly."
	fi

	elog ""
	elog "Since version 3.14.0 you can use multiple apcupsd instances to"
	elog "control more than one UPS in a single box with openRC."
	elog "To do this, create a link between /etc/init.d/apcupsd to a new"
	elog "/etc/init.d/apcupsd.something, and it will then load the"
	elog "configuration file at /etc/apcupsd/something.conf."
	elog ""

	elog 'If you want apcupsd to power off your UPS when it'
	elog 'shuts down your system in a power failure, you must'
	elog 'add apcupsd.powerfail to your shutdown runlevel:'
	elog ''
	elog ' \e[01m rc-update add apcupsd.powerfail shutdown \e[0m'
	elog ''

	if use udev && use kernel_linux; then
		elog "Starting from version 3.14.9-r1, ${PN} installs udev rules"
		elog "for persistent device naming. If you have multiple UPS"
		elog "connected to the machine, you can point them to the devices"
		elog "in /dev/apcups/by-id directory."
	fi
}

pkg_postrm() {
	use udev && use kernel_linux && udev_reload
}

# vi: set diffopt=filler,iwhite:
