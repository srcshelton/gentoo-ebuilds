# Copyright 2023 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_COMMIT="94f77d5c3e7736723950e624d846222eb2f1a379"
EGIT_REPO="raspi-gpio"

inherit autotools

DESCRIPTION="raspi-gpio: Tool to help debug / hack at the BCM283x GPIO"
HOMEPAGE="https://github.com/RPi-Distro/raspi-gpio"
SRC_URI="https://github.com/RPi-Distro/${EGIT_REPO}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="-* arm64 arm"

S="${WORKDIR}/${EGIT_REPO}-${EGIT_COMMIT}"
DOCS=( README.md )
