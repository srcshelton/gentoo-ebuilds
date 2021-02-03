# Copyright 2018-2021 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{7..9} )

inherit distutils-r1

DESCRIPTION="A linter for YAML files"
HOMEPAGE="https://github.com/adrienverge/yamllint"
SRC_URI="https://github.com/adrienverge/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm x86 ~amd64-linux ~x86-linux x64-macos"
#IUSE="doc"

#DEPEND="doc? ( dev-python/sphinx )"
DEPEND="
	>=dev-python/pathspec-0.5.3
	dev-python/pyyaml
	dev-python/setuptools
"

python_install_all() {
	local DOCS=( README.rst )
	distutils-r1_python_install_all
}
