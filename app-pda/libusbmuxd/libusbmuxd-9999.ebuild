# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# $Header: app-pda/libusbmuxd/libusbmuxd-9999.ebuild,v 1.0 2013/10/31 16:34:12 srcs Exp $

EAPI=6
inherit autotools eutils git-r3

DESCRIPTION="USB multiplex daemon for use with Apple iPhone/iPod Touch devices"
HOMEPAGE="http://www.libimobiledevice.org/"
#SRC_URI=""
EGIT_REPO_URI="https://github.com/libimobiledevice/libusbmuxd.git"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~arm ~ppc ~ppc64 x86"
IUSE=""

RDEPEND=">=app-pda/libplist-1.9"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS=( AUTHORS README.md )

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	econf --disable-static
}

src_install() {
	default

	#prune_libtool_files --all
	find "${ED}" -type f -name "*.la" -delete
}
