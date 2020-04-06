# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="QR Code Generator"
HOMEPAGE="https://github.com/endroid/qr-code"
SRC_URI="https://github.com/endroid/qr-code/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND=">=dev-lang/php-5.3.0[gd]"

S="${WORKDIR}/qr-code${PV}"

src_install() {
	insinto "/usr/share/php/Enroid/QrCode"
	doins -r src/Exceptions QrCode.php
	dodoc README.md
}
