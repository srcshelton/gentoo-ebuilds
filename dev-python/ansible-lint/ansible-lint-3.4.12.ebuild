# Copyright 1999-2017 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python2_7 pypy )

inherit distutils-r1

DESCRIPTION="Best practices checker for Ansible"
HOMEPAGE="https://github.com/willthames/ansible-lint"
SRC_URI="https://github.com/willthames/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm x86 ~amd64-linux ~x86-linux x64-macos"

DEPEND=""
RDEPEND=""

python_install_all() {
	local DOCS=( README.md )
	distutils-r1_python_install_all
}
