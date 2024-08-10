# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="A tiny bespoke webserver for adblock with HTTP/1.1 and HTTPS support"
HOMEPAGE="https://github.com/kvic-z/pixelserv-tls"
SRC_URI="https://github.com/kvic-z/pixelserv-tls/archive/${PV}.tar.gz -> ${PF}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"

DEPEND="dev-libs/openssl:="
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-ccTLD.patch"
	"${FILESDIR}/${P}-openssl.patch"
)

S="${WORKDIR}/${PN}-tls-${PV}"

src_prepare() {
	default

	eautoreconf
}
