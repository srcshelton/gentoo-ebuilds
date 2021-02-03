# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="A tiny bespoke webserver for adblock with HTTP/1.1 and HTTPS support"
HOMEPAGE="https://kazoo.ga/pixelserv-tls/"
SRC_URI="https://github.com/kvic-z/pixelserv-tls/archive/v2.3.1.tar.gz -> ${PF}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"
#IUSE=""

#DEPEND=""
#RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-tls-${PV}"

src_prepare() {
	default

	eautoreconf
}
