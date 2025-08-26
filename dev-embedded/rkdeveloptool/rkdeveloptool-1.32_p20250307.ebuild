# Copyright 2019-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="${P%"_p"*}"

inherit autotools udev

EGIT_COMMIT="304f073752fd25c854e1bcf05d8e7f925b1f4e14"
DESCRIPTION="A tool to communicate with Rockusb devices"
HOMEPAGE="https://opensource.rock-chips.com/wiki_Rkdeveloptool"
#SRC_URI="https://github.com/radxa/rkdeveloptool/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://github.com/rockchip-linux/rkdeveloptool/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="udev"

S="${WORKDIR}/${PN}-${EGIT_COMMIT}"

DEPEND="virtual/libusb"
RDEPEND="${CDEPEND}"

PATCHES=(
	"${FILESDIR}/${MY_P}-LOADER_OPTION-index.patch"
	"${FILESDIR}/${MY_P}-rockusb.rules.patch-r1"
	"${FILESDIR}/${MY_P}-CMakeLists.txt.patch"
	"${FILESDIR}/${MY_P}-README.md.patch-r1"
	#"${FILESDIR}/${MY_P}-mingw-w64.patch"
	"${FILESDIR}/${MY_P}-nSectorSize.patch"
	#"${FILESDIR}/${MY_P}-radxa-memcpy.patch"
	#"${FILESDIR}/${MY_P}-radxa-snprintf.patch"
)

src_prepare() {
	default

	cat >"${S}/autogen.sh" <<-EOF
		#! /bin/sh
		autoreconf --force --install
	EOF
	chmod 0755 "${S}/autogen.sh"

	eautoreconf
}

src_install() {
	default

	if use udev; then
		udev_dorules 99-rk-rockusb.rules
	fi
}

pkg_postinst() {
	use !udev || udev_reload
}

pkg_postrm() {
	use !udev || udev_reload
}
