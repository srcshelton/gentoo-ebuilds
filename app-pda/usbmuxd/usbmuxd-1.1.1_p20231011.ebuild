# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools systemd udev

MY_COMMIT=360619c5f721f93f0b9d8af1a2df0b926fbcf281

DESCRIPTION="USB multiplex daemon for use with Apple iPhone/iPod Touch devices"
HOMEPAGE="https://libimobiledevice.org/"
SRC_URI="https://github.com/libimobiledevice/usbmuxd/archive/${MY_COMMIT}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"
S="${WORKDIR}"/${PN}-${MY_COMMIT}

# src/utils.h is LGPL-2.1+, rest is found in COPYING*
LICENSE="|| ( GPL-2 GPL-3 ) LGPL-2.1+"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ~ppc64 x86"
IUSE="selinux systemd dev +worker"

DEPEND="
	acct-user/usbmux
	worker? ( >=app-pda/libusbmuxd-2.0.0 )
	>=app-pda/libimobiledevice-1.3.0:=
	app-pda/libimobiledevice-glue:=
	>=app-pda/libplist-2.3:=
	virtual/libusb:1=
"
RDEPEND="
	${DEPEND}
	|| ( sys-apps/busybox[mdev] virtual/udev )
	selinux? ( sec-policy/selinux-usbmuxd )
	systemd? ( sys-apps/systemd )
"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default
	echo ${PV} > "${S}"/.tarball-version
	eautoreconf
}

src_configure() {
	local -a myconf=()

	myconf=(
		$(use_with systemd)
		$(usex worker '' '--without-preflight')
		$(use_with systemd systemdsystemunitdir "$(systemd_get_systemunitdir)")
		$(use_with udev udevrulesdir "$(get_udevdir)"/rules.d)
	)

	econf ${myconf[@]}
}

src_install() {
	default

	if ! use udev; then
		# There appears to be some disagreement as to where rules live :(
		if [[ -e "${ED}"/$(get_udevdir)/rules.d/39-usbmuxd.rules ]]; then
			rm "${ED}"/$(get_udevdir)/rules.d/39-usbmuxd.rules
			rmdir -p "${ED}"/$(get_udevdir)/rules.d
		elif [[ -e "${ED}"/usr/lib/udev/rules.d/39-usbmuxd.rules ]]; then
			rm "${ED}"/usr/lib/udev/rules.d/39-usbmuxd.rules
			rmdir -p "${ED}"/usr/lib/udev/rules.d
		fi
	fi
}

pkg_postrm() {
	! use udev || udev_reload
}

pkg_postinst() {
	! use udev || udev_reload
}
