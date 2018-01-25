# Copyright 1999-2018 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python2_7 pypy )

inherit distutils-r1

DESCRIPTION="Some extensions to pyyaml"
HOMEPAGE="https://github.com/asottile/aspy.yaml"
SRC_URI="https://github.com/asottile/${PN/_/.}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm x86 ~amd64-linux ~x86-linux x64-macos"

S="${WORKDIR}/${PN/_/.}-${PV}"

python_install_all() {
	local DOCS=( README.md )
	distutils-r1_python_install_all
}
