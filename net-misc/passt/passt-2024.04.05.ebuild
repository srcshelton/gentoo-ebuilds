# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="User-mode networking daemons for VMs and namespaces, replacement for Slirp"
HOMEPAGE="https://passt.top/"

RELEASE_COMMIT="954589b"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://passt.top/passt"
else
	SRC_URI="https://passt.top/passt/snapshot/passt-${RELEASE_COMMIT}.tar.xz -> ${P}.tar.xz"
	S="${WORKDIR}/${PN}-${RELEASE_COMMIT}"
	KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~x86"
fi

LICENSE="BSD GPL-2+"
SLOT="0"
IUSE="cpu_flags_x86_avx2 qemu static"

PATCHES=(
	"${FILESDIR}"/Makefile-2024.03.20.patch
)

src_prepare() {
	default
	tc-export CC
}

src_compile() {
	[[ ${PV} != 9999* ]] && export VERSION="${PV}"
	export prefix="${EPREFIX}/usr" docdir="${EPREFIX}/usr/share/doc/${P}"

	emake $(usev static)
}

src_install() {
	default

	if use cpu_flags_x86_avx2; then
		rm "${ED}"/usr/bin/passt "${ED}"/usr/bin/pasta
		mv "${ED}"/usr/bin/passt.avx2 "${ED}"/usr/bin/passt
		mv "${ED}"/usr/bin/pasta.avx2 "${ED}"/usr/bin/pasta
	else
		rm "${ED}"/usr/bin/passt.avx2 "${ED}"/usr/bin/pasta.avx2
	fi
	if ! use qemu; then
		rm "${ED}"/usr/bin/qrap "${ED}"/usr/share/man/man1/qrap.1
	fi

	mv "${ED}/usr/share/doc/${P}/README.plain.md" \
		"${ED}/usr/share/doc/${P}/README.md"
	rm "${ED}/usr/share/doc/${P}/demo.sh"
}
