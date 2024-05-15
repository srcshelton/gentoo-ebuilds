# Copyright 2019-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit autotools udev

DESCRIPTION="iPhone USB Ethernet Driver for Linux pairing helper"
HOMEPAGE="https://web.archive.org/web/20120202011551/http://giagio.com/wiki/moin.cgi/iPhoneEthernetDriver"
EGIT_REPO_URI="https://github.com/dgiagio/ipheth"
EGIT_COMMIT="06f5d7d159852e2c3d7aff0d565b6ed4966c9539"
SRC_URI="${EGIT_REPO_URI}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="udev"

RDEPEND="app-pda/libimobiledevice"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}"/Makefile.patch
)

S="${WORKDIR}/ipheth-${EGIT_COMMIT}"

src_compile() {
	emake -C ipheth-pair || die
}

src_install() {
	emake -C ipheth-pair DESTDIR="${ED}" UDEV_RULES_PATH="$(get_udevdir)" install || die

	if ! use udev; then
		rm "${ED}$(get_udevdir)"/rules.d/90-iphone-tether.rules
		rmdir -p "${ED}$(get_udevdir)"/rules.d
	fi
}

pkg_postinst() {
	use !udev || udev_reload
}
