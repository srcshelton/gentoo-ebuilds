# Copyright 2018-2021 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{7..8} pypy3 )

inherit distutils-r1

# No branches, no tags, no releases - ugh :(
commit='7b125acf41702cb82679dcf56aaf6a14d34bd785'

DESCRIPTION="Utility library for gitignore style pattern matching of file paths"
HOMEPAGE="https://github.com/cpburnz/python-path-specification"
SRC_URI="https://github.com/cpburnz/python-path-specification//archive/${commit}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MPL-2"
SLOT="0"
KEYWORDS="amd64 arm64 arm x86 ~amd64-linux ~x86-linux x64-macos"
#IUSE="doc"

S="${WORKDIR}/python-path-specification-${commit}"

python_install_all() {
	local DOCS=( README.rst )
	distutils-r1_python_install_all
}
