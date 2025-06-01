# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="User-mode networking daemons for VMs and namespaces, replacement for Slirp"
HOMEPAGE="https://passt.top/"

RELEASE_COMMIT="a1e48a0"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://passt.top/passt"
else
	SRC_URI="https://passt.top/passt/snapshot/passt-${RELEASE_COMMIT}.tar.xz -> ${P}.tar.xz"
	S="${WORKDIR}/${PN}-${PV//./_}.${RELEASE_COMMIT}"
	KEYWORDS="amd64 arm64 ~loong ~riscv"
fi

LICENSE="BSD GPL-2+"
SLOT="0"
IUSE="cpu_flags_x86_avx2 qemu static"

src_prepare() {
	default
	tc-export CC
	# Do not install doc/demo.sh
	sed -i -e "/demo/d" Makefile || die
}

src_compile() {
	[[ ${PV} != 9999* ]] && export VERSION="${PV}"
	export prefix="${EPREFIX}/usr" docdir="${EPREFIX}/usr/share/doc/${PF}"

	emake $(usev static)
}

src_install() {
	default

	# N.B. 'pasta' is a symlink to 'passt'...
	# N.B. passt/pasta *requires* two executables which differ by '.avx2'
	#      extension in order to run AVX2 code :o
	if ! use cpu_flags_x86_avx2; then
		rm "${ED}"/usr/bin/passt.avx2 "${ED}"/usr/bin/pasta.avx2
	fi
	if ! use qemu; then
		rm "${ED}"/usr/bin/qrap "${ED}"/usr/share/man/man1/qrap.1
	fi

	mv "${ED}/usr/share/doc/${P}/README.plain.md" \
		"${ED}/usr/share/doc/${P}/README.md"
	rm "${ED}/usr/share/doc/${P}/demo.sh"
}
