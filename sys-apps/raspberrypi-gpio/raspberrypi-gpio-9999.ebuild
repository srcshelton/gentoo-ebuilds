# Copyright 2023 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools git-r3

DESCRIPTION="raspi-gpio: Tool to help debug / hack at the BCM283x GPIO"
HOMEPAGE="https://github.com/RPi-Distro/raspi-gpio"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS="-* ~arm64 ~arm"

EGIT_REPO_URI="https://github.com/RPi-Distro/raspi-gpio.git"
EGIT_CLONE_TYPE="shallow"

DOCS=( README.md )
