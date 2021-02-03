# Copyright 2018-2021 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{7..9} pypy3 )

inherit distutils-r1

DESCRIPTION="A framework for managing and maintaining multi-language pre-commit hooks"
HOMEPAGE="https://github.com/pre-commit/pre-commit"
SRC_URI="https://github.com/pre-commit/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm64 arm x86 ~amd64-linux ~x86-linux x64-macos"
IUSE="developer"

DEPEND="
	>=dev-python/cfgv-2.0.0
	>=dev-python/identify-1.0.0
	>=dev-python/nodeenv-0.11.1
	>=dev-python/pyyaml-5.1
	dev-python/toml
	>=dev-python/virtualenv-20.0.8
	python_targets_python3_7? ( dev-python/importlib_metadata )
	developer? (
		dev-python/covdefaults
		dev-python/coverage
		dev-python/distlib
		dev-python/pytest
		dev-python/pytest-env
		dev-python/re-assert
	)
"

python_install_all() {
	local DOCS=( README.md )
	distutils-r1_python_install_all
}
