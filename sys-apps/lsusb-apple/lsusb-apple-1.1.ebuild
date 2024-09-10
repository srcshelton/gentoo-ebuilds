# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COMMIT="9da9755fed9f9279366aa262a4c81166fd283dac"
DESCRIPTION="lsusb command for Mac OS X"
HOMEPAGE="https://github.com/jlhonora/lsusb"
SRC_URI="https://github.com/jlhonora/lsusb/archive/${COMMIT}.zip -> lsusb-apple-1.1.zip"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* x64-macos"
IUSE=""

S="${WORKDIR}/${PN/-apple}-${COMMIT}"

src_install() {
	doman man/lsusb.8

	dobin lsusb
}
