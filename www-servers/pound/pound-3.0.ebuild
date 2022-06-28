# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake

MY_P="${P/p/P}"

DESCRIPTION="An HTTP/HTTPS reverse-proxy and load-balancer"
HOMEPAGE="https://www.apsis.ch/pound.html"
SRC_URI="https://www.apsis.ch/pound/${MY_P}.tgz"

LICENSE="BSD GPL-3"
SLOT="0"
KEYWORDS="amd64 ~hppa ~ppc x86"

DEPEND="
	dev-libs/libpcre:=
	dev-libs/libyaml:=
	dev-libs/nanomsg:=
	net-libs/mbedtls:=
	elibc_musl? ( sys-libs/queue-standalone )
"

RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}/${P}-daemonise.patch"
)

DOCS=( README.md )

src_install() {
	rm GPL.txt || die

	dosbin "${BUILD_DIR}"/pound
	doman "${S}"/man/pound.8
	einstalldocs

	newinitd "${FILESDIR}"/pound.init-1.9 pound

	insinto /etc/pound
	newins "${FILESDIR}"/pound-3.0.cfg.yaml pound.yaml
}

pkg_postinst() {
	elog "No demo-/sample-configfile is included in the distribution;"
	elog "read the man-page for more info."
	elog "A sample (localhost:8888 -> localhost:80)"
	elog "for gentoo is given in \"/etc/pound.cfg\"."
}
