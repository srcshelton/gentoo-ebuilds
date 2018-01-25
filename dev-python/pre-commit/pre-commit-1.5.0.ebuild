# Copyright 1999-2018 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python2_7 pypy )

inherit distutils-r1

DESCRIPTION="A framework for managing and maintaining multi-language pre-commit hooks"
HOMEPAGE="https://github.com/pre-commit/pre-commit"
SRC_URI="https://github.com/pre-commit/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm x86 ~amd64-linux ~x86-linux x64-macos"
IUSE="developer"

DEPEND="
	dev-python/aspy_yaml
	dev-python/cached-property
	dev-python/identify
	dev-python/nodeenv
	dev-python/six
	dev-python/virtualenv
	developer? (
		dev-python/coverage
		dev-python/flake8
		dev-python/mock
		dev-python/pytest
	)
"

python_install_all() {
	local DOCS=( README.md )
	distutils-r1_python_install_all
}
