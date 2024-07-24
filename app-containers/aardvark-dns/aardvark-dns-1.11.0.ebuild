# Copyright 2023-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

[[ ${PV} == 9999* ]] || CRATES="${PN}@${PV}"
inherit cargo

DESCRIPTION="A container-focused DNS server"
HOMEPAGE="https://github.com/containers/aardvark-dns"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/aardvark-dns.git"
else
	SRC_URI="${CARGO_CRATE_URIS}
		https://github.com/containers/aardvark-dns/releases/download/v${PV}/${PN}-v${PV}-vendor.tar.gz"
	RESTRICT="mirror"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"
fi

LICENSE="0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions MIT Unlicense Unicode-DFS-2016 ZLIB"
SLOT="0"
QA_FLAGS_IGNORED="usr/libexec/podman/${PN}"
QA_PRESTRIPPED="usr/libexec/podman/${PN}"
ECARGO_VENDOR="${WORKDIR}/vendor"

BDEPEND=">=virtual/rust-1.70.0"

src_unpack() {
	if [[ ${PV} == 9999* ]]; then
		git-r3_src_unpack
		cargo_live_src_unpack
	else
		cargo_src_unpack
	fi
}

src_prepare() {
	default
	sed -i -e "s|m0755 bin|m0755 $(cargo_target_dir)|g;" Makefile || die
}

src_install() {
	export PREFIX="${EPREFIX}"/usr
	default

	dodir /usr/bin
	mv "${ED}/usr/libexec/podman/${PN}" "${ED}/usr/bin"

	dodir /usr/libexec/podman
	dosym -r "/usr/bin/${PN}" "/usr/libexec/podman/${PN}" || die
}
