# Copyright 1999-2018 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python2_7 pypy )

inherit distutils-r1

DESCRIPTION="Virtual environment for Node.js & integrator with virtualenv"
HOMEPAGE="http://ekalinin.github.io/nodeenv/"
SRC_URI="https://github.com/ekalinin/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="Clear-BSD"
SLOT="0"
KEYWORDS="amd64 arm x86 ~amd64-linux ~x86-linux x64-macos"

python_install_all() {
	local DOCS=( README.rst )
	distutils-r1_python_install_all
}
