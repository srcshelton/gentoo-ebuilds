# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A container init that is so simple it's effectively brain-dead"
HOMEPAGE="https://github.com/openSUSE/catatonit"
SRC_URI="https://github.com/openSUSE/${PN}/archive/v${PV}.tar.gz -> ${PV}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	sys-devel/autogen
	sys-devel/libtool
"

src_configure() {
	./autogen.sh

	default
}
