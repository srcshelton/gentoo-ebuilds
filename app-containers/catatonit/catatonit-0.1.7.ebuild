# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="A container init that is so simple it's effectively brain-dead"
HOMEPAGE="https://github.com/openSUSE/catatonit"
SRC_URI="https://github.com/openSUSE/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/openSUSE/catatonit/pull/18.patch -> ${P}-automake.patch"
RESTRICT="mirror"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="amd64 arm64 ~ppc64 ~riscv"

DEPEND="
	sys-devel/autogen
	sys-devel/libtool
"

PATCHES=(
	"${DISTDIR}/${P}-automake.patch"
)

src_prepare() {
	default

	eautoreconf
}

src_install() {
	default
	dodir /usr/libexec/podman

	# Deploy symlink in place of hardlink...
	#ln "${ED}/usr/"{bin,libexec/podman}/catatonit || die
	ln -s ../../bin/catatonit "${ED}"/usr/libexec/podman/catatonit || die
}
