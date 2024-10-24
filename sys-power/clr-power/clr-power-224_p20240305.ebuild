# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

COMMIT="2da77180ba997e9b5a6229cd03bcc624371a3698"

DESCRIPTION="Set reasonable power management defaults for platform devices"
HOMEPAGE="https://github.com/clearlinux/clr-power-tweaks"
SRC_URI="https://github.com/clearlinux/clr-power-tweaks/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"

PATCHES=(
	"${FILESDIR}/${P%_*}-no-systemd.patch"
	"${FILESDIR}/${P%_*}-no-clear-linux.patch"
)

S="${WORKDIR}/clr-power-tweaks-${COMMIT}"

src_prepare() {
	default

	rm clr-power-tweaks.conf.5 template *.service *.timer src/verifytime.c
	eautoreconf
}