# Copyright 2019-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit autotools git-r3 multilib

DESCRIPTION="Support library to communicate with Apple iPhone/iPod Touch devices"
HOMEPAGE="https://www.libimobiledevice.org/"
EGIT_REPO_URI="https://github.com/libimobiledevice/libimobiledevice-glue.git"

LICENSE="LGPL-2.1"
SLOT="0/0.0.0" # based on SONAME of libimobiledevice-1.0.so
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

RDEPEND=">=app-pda/libplist-2.2.0"
BDEPEND="virtual/pkgconfig"

DOCS=""

src_prepare() {
	default
	eautoreconf
}

src_install() {
	default

	find "${ED}" -type f -name "*.la" -delete
}
