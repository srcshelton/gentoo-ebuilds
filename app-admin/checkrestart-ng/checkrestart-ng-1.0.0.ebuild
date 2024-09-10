# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Report on or restart updated services on SysV/OpenRC-based systems"
HOMEPAGE="https://github.com/srcshelton/checkrestart"
SRC_URI="https://github.com/srcshelton/checkrestart/archive/v1.0.0.tar.gz -> checkrestart-v1.0.0.tar.gz"
RESTRICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm x86"

RDEPEND="
	>=app-shells/bash-4.0
	sys-apps/findutils
	sys-libs/ncurses"

S="${WORKDIR}/${PN%-ng}-${PV}"

src_install() {
	exeinto "/usr/local/sbin"
	doexe "checkrestart"
}
