# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A container init that is so simple it's effectively brain-dead"
HOMEPAGE="https://github.com/openSUSE/catatonit"
SRC_URI="https://github.com/openSUSE/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"

DEPEND="
	sys-devel/autogen
	sys-devel/libtool
"

PATCHES=(
	"${FILESDIR}/${P}-AM_INIT_AUTOMAKE.patch"
)

src_configure() {
	./autogen.sh || die
	default
}

src_install() {
	default
	dodir /usr/libexec/podman
	ln -s ../../bin/catatonit "${ED}"/usr/libexec/podman/catatonit || die
}
