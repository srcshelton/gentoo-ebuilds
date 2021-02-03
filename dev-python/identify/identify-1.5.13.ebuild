# Copyright 2018-2021 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7
#PYTHON_COMPAT=( python2_7 python3_{5..6} pypy )
PYTHON_COMPAT=( python3_{7..9} pypy3 )

inherit distutils-r1

DESCRIPTION="File identification library for Python"
HOMEPAGE="https://github.com/chriskuehl/identify"
SRC_URI="https://github.com/chriskuehl/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm x86 ~amd64-linux ~x86-linux x64-macos"

python_install_all() {
	local DOCS=( README.md )
	distutils-r1_python_install_all
}
