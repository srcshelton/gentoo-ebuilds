# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Top-like interface for container-metrics"
HOMEPAGE="https://ctop.sh https://github.com/bcicen/ctop"
SRC_URI="https://github.com/bcicen/ctop/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-deps.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="hardened"

src_compile() {
	sed \
		-e '/go mod download/d' \
		-e 's/LD_FLAGS="/LD_FLAGS="-bindnow -s /' \
		-e 's/ -o / -buildvcs=false -modcacherw -v -x -trimpath -o /' \
		-i Makefile || die

	export CGO_LDFLAGS="$(usex hardened '-fno-PIC ' '')"
	emake VERSION="${PV}" BUILD="${PVR}" build
}

src_install() {
	dobin ${PN}
	dodoc README.md
}
