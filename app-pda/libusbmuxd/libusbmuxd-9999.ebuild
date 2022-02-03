# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools git-r3

DESCRIPTION="USB multiplex daemon for use with Apple iPhone/iPod Touch devices"
HOMEPAGE="https://www.libimobiledevice.org/"
EGIT_REPO_URI="https://github.com/libimobiledevice/libusbmuxd.git"

LICENSE="GPL-2+ LGPL-2.1+" # tools/*.c is GPL-2+, rest is LGPL-2.1+
SLOT="0/2.0-6" # based on SONAME of libusbmuxd-2.0.so
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="static-libs"

RDEPEND="
	>=app-pda/libplist-2.2.0:=
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(usex kernel_linux '' --without-inotify)
}

src_install() {
	default
	find "${ED}" -name '*.la' -type f -delete || die
}
