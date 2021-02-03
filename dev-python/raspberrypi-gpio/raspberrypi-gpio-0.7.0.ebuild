# Copyright 2015-2021 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{7..9} )

inherit distutils-r1 eutils

MY_P=${P/raspberrypi-gpio/RPi.GPIO}

DESCRIPTION="A Python module to control the GPIO on a Raspberry Pi"
HOMEPAGE="https://sourceforge.net/projects/raspberry-gpio-python/"
SRC_URI="https://downloads.sourceforge.net/project/raspberry-gpio-python/RPi.GPIO-${PV}.tar.gz"
RESTRICT="mirror test"

LICENSE="MIT"
SLOT="0"
KEYWORDS="arm"
IUSE="doc"

S="${WORKDIR}/${MY_P}"

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
