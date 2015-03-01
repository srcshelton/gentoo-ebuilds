# Copyright 2015 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python{2_6,2_7} )

inherit distutils-r1 eutils

MY_P=${P/raspberrypi-gpio/RPi.GPIO}

DESCRIPTION="A collection of libraries to process XML with Python"
HOMEPAGE="http://pyxml.sourceforge.net/"
SRC_URI="https://downloads.sourceforge.net/project/raspberry-gpio-python/RPi.GPIO-0.5.11.tar.gz"
RESTRICT="mirror
	test"

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
