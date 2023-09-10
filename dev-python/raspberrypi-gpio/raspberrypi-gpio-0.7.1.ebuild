# Copyright 2015-2021 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1

MY_PN='RPi.GPIO'

DESCRIPTION="A Python module to control the GPIO on a Raspberry Pi"
HOMEPAGE="https://sourceforge.net/projects/raspberry-gpio-python/"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_PN}-${PV}.tar.gz"
RESTRICT="test"

LICENSE="MIT"
SLOT="0"
KEYWORDS="arm arm64"
IUSE="doc"

S="${WORKDIR}/${MY_PN}-${PV}"

python_test() {
	cd test || die
	"${PYTHON}" test.py || die "Tests fail with ${EPYTHON}"
}

python_install_all() {
	distutils-r1_python_install_all

	if use doc; then
		dodoc README.txt
		dodoc CHANGELOG.txt
	fi
}
