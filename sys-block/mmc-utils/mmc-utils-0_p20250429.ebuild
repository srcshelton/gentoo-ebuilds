# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Userspace tools for MMC/SD devices"
HOMEPAGE="https://git.kernel.org/pub/scm/utils/mmc/mmc-utils.git/"

MY_COMMIT="a23ad7875b89df0dedc23f0b173926374f01bc76"

SRC_URI="https://git.kernel.org/pub/scm/utils/mmc/mmc-utils.git/snapshot/mmc-utils-${MY_COMMIT}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${PN}-${MY_COMMIT}"

LICENSE="GPL-2 BSD"
SLOT="0"
IUSE="html sparse"

KEYWORDS="amd64 arm arm64"

BDEPEND="
	html? ( dev-python/sphinx )
	sparse? ( sys-devel/sparse )
"
#RDEPEND="!dev-lang/mercury"  # ????

src_prepare() {
	default
	sed -e 's/-Werror //' \
		-e 's/-D_FORTIFY_SOURCE=2 //' \
		-e "s/-DVERSION=.*/-DVERSION=\\\\\"gentoo-${PVR}\\\\\"/" \
		-e '/^GIT_VERSION := /d' \
		-i Makefile || die
}

src_configure() {
	tc-export CC
}

src_compile() {
	emake C=$(usex sparse '1' '0') all $(usex html 'html-docs' '') ||
		die "emake failed"
}

src_install() {
	dosbin mmc || die
	dodoc README
	doman man/mmc.1 || die

	if use html; then
		# Avoid Sphinx inventory...
		rm docs/_build/html/objects.inv

		docinto "html"
		dodoc -r docs/_build/html/*
	fi
}
