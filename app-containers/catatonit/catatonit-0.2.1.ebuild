# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="A container init that is so simple it's effectively brain-dead"
HOMEPAGE="https://github.com/openSUSE/catatonit"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/openSUSE/catatonit.git"
else
	SRC_URI="https://github.com/openSUSE/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm64 ~loong ~ppc64 ~riscv"
	RESTRICT="mirror"
fi

LICENSE="GPL-2+"
SLOT="0"

DEPEND="
	sys-devel/autogen
	dev-build/libtool
"

src_prepare() {
	default
	#sed -i -e '/^AM_INIT_AUTOMAKE$/d' configure.ac || die
	eautoreconf
}

src_install() {
	default
	dodir /usr/libexec/podman
	dosym -r /usr/bin/"${PN}" /usr/libexec/podman/"${PN}"
}
