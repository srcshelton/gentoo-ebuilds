# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit linux-info systemd tmpfiles udev

DESCRIPTION="APC UPS daemon with integrated tcp/ip remote shutdown"
HOMEPAGE="http://www.apcupsd.org/"
SRC_URI="https://downloads.sourceforge.net/apcupsd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ppc ~riscv x86"
IUSE="cgi dumb +modbus +net +powerchute selinux +smart snmp systemd tmpfiles +tools udev +usb"

COMMON_DEPEND="
	cgi? ( >=media-libs/gd-1.8.4 )
	modbus? ( usb? ( virtual/libusb:0 ) )
	snmp? ( >=net-analyzer/net-snmp-5.7.2 )
"

# apcupsd requires 'shutdown', 'wall', sendmail...
DEPEND="${COMMON_DEPEND}
	virtual/mailx
	>=sys-apps/util-linux-2.23[tty-helpers(-)]
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

DOCS=( ChangeLog ReleaseNotes )
HTML_DOCS=( doc/manual )

PATCHES=(
	"${FILESDIR}"/${PN}-3.14.9-aliasing.patch
	"${FILESDIR}"/${PN}-3.14.9-close-on-exec.patch
	"${FILESDIR}"/${PN}-3.14.9-commfailure.patch
	"${FILESDIR}"/${PN}-3.14.9-fix-nologin.patch
	"${FILESDIR}"/${PN}-3.14.9-gapcmon.patch
	"${FILESDIR}"/${PN}-3.14.9-wall-on-mounted-usr.patch
)

pkg_setup() {
	local CONFIG_CHECK="~USB_HIDDEV ~HIDRAW"

	local ERROR_USB_HIDDEV="CONFIG_USB_HIDDEV:	needed to access USB-attached UPSes"
	local ERROR_HIDRAW="CONFIG_HIDRAW:		needed to access USB-attached UPSes"

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
	local myconf="--disable-test"

	use cgi && myconf="${myconf} --enable-cgi --with-cgi-bin=/usr/libexec/${PN}/cgi-bin"
	if use usb; then
		myconf="${myconf} --with-upstype=usb --with-upscable=usb --with-dev= "
	elif use modbus; then
		myconf="${myconf} --with-upstype=modbus --with-upscable=modbus"
	else
		myconf="${myconf} --with-upstype=apcsmart --with-upscable=smart"
	fi

	if use net; then
		myconf="${myconf} --with-nis-port=3551 $(use_enable powerchute pcnet )"
	else
		sed -i -e '/^NISSRV_ENABLED=yes$/{s:yes:no:}' configure || die "NIS patch failed"
	fi

	# We force the DISTNAME to gentoo so it will use gentoo's layout also
	# when installed on non-linux systems.
	econf \
		--sbindir=/sbin \
		--sysconfdir=/etc/apcupsd \
		--with-pwrfail-dir=/etc/apcupsd \
		--with-lock-dir=/var/lock \
		--with-pid-dir=/var/run/apcupsd \
		--with-log-dir=/var/log \
		--with-distname=gentoo \
		$(use_enable dumb) \
		$(use_enable modbus) \
		$(use_enable net) \
		$(use_enable smart apcsmart) \
		$(use_enable snmp) \
		$(use_enable usb) \
		--disable-gapcmon \
		${myconf} \
		APCUPSD_MAIL=$(type -p mail)
}

src_compile() {
	# Workaround for bug #280674; upstream should really just provide
	# the text files in the distribution, but I wouldn't count on them
	# doing that anytime soon.
	MANPAGER=$(type -p cat) \
		emake VERBOSE=2 || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" VERBOSE=2 install || die "installation failed"
	rm "${ED}"/etc/init.d/halt || die

	insinto /etc/apcupsd
	newins examples/safe.apccontrol safe.apccontrol
	doins "${FILESDIR}"/apcupsd.conf

	doman doc/*.8 doc/*.5

	einstalldocs

	rm "${ED}"/etc/init.d/apcupsd || die
	newinitd "${FILESDIR}/${PN}.init" "${PN}"
	newinitd "${FILESDIR}/${PN}.powerfail.init" "${PN}".powerfail

	use systemd && systemd_dounit "${FILESDIR}"/${PN}.service
	use tmpfiles && dotmpfiles "${FILESDIR}"/${PN}-tmpfiles.conf

	# Remove HAL settings, we don't really want to have it around still.
	rm -r "${D}"/usr/share/hal || die

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
