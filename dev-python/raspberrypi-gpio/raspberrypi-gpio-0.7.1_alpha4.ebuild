# Copyright 2015-2021 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{7..9} )

inherit distutils-r1 eutils

MY_PN=${PN/raspberrypi-gpio/RPi.GPIO}
MY_PV='0.7.0'

DESCRIPTION="A Python module to control the GPIO on a Raspberry Pi"
HOMEPAGE="https://sourceforge.net/projects/raspberry-gpio-python/"
SRC_URI="https://downloads.sourceforge.net/project/raspberry-gpio-python/RPi.GPIO-${MY_PV}.tar.gz"
RESTRICT="mirror test"

LICENSE="MIT"
SLOT="0"
KEYWORDS="arm arm64"
IUSE="doc"

S="${WORKDIR}/${MY_PN}-${MY_PV}"

PATCHES=(
	"${FILESDIR}/${PN}-${MY_PV}-gcc10.patch"
	"${FILESDIR}/${PN}-${MY_PV}-python3_9.patch"
	"${FILESDIR}/${PN}-${MY_PV}-pi4.patch"
)

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
