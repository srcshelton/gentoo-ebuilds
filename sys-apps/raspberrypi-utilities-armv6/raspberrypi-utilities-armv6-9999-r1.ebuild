# Copyright 2015 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

DESCRIPTION="Raspberry Pi closed-source userspace tools"
HOMEPAGE="https://github.com/raspberrypi/firmware"
SRC_URI=""

LICENSE="Broadcom"
SLOT="0/1"
KEYWORDS="-*"
IUSE=""

DEPEND="media-libs/raspberrypi-userland"
RDEPEND=""

EGIT_REPO_URI="https://github.com/raspberrypi/firmware"
# The current repo is ~4GB in size, but contains only ~200MB of data - the rest
# is (literally) history :(
EGIT_CLONE_TYPE="shallow"

RESTRICT="strip"
QA_PREBUILT="
	/usr/bin/edidparser
	/usr/sbin/vcdbg
"

src_install() {
	dobin hardfp/opt/vc/bin/edidparser
	dosbin hardfp/opt/vc/bin/vcdbg
}
