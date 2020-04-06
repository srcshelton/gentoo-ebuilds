# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit autotools eutils git-r3 udev

DESCRIPTION="iPhone USB Ethernet Driver for Linux pairing helper"
HOMEPAGE="http://giagio.com/wiki/moin.cgi/iPhoneEthernetDriver"
SRC_URI=""
EGIT_REPO_URI="https://github.com/dgiagio/ipheth.git/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="udev"

RDEPEND="app-pda/libimobiledevice"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/Makefile.patch
}

src_compile() {
	emake -C ipheth-pair || die
}

src_install() {
	emake -C ipheth-pair DESTDIR="${ED}" UDEV_RULES_PATH="$(get_udevdir)" install || die

	if ! use udev; then
		rm "${ED}"/$(get_udevdir)/rules.d/90-iphone-tether.rules
		rmdir -p "${ED}"/$(get_udevdir)/rules.d
	fi
}

pkg_postinst() {
	if use udev; then
		udevadm control --reload-rules && udevadm trigger
	fi
}
