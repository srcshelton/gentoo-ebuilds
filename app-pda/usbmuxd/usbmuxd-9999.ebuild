# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools git-r3 systemd udev

DESCRIPTION="USB multiplex daemon for use with Apple iPhone/iPod Touch devices"
HOMEPAGE="https://www.libimobiledevice.org/"
EGIT_REPO_URI="https://github.com/libimobiledevice/usbmuxd.git"

# src/utils.h is LGPL-2.1+, rest is found in COPYING*
LICENSE="GPL-2 GPL-3 LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="systemd udev +worker"

DEPEND="
	acct-user/usbmux
	worker? ( >=app-pda/libusbmuxd-1.0.9 )
	>=app-pda/libimobiledevice-1.2.1_pre0:=
	>=app-pda/libplist-2.0:=
	virtual/libusb:1"

RDEPEND="
	${DEPEND}
	|| ( sys-apps/busybox[mdev] virtual/udev )
"

BDEPEND="
	virtual/pkgconfig
"

DOCS=""

src_prepare() {
	default
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
