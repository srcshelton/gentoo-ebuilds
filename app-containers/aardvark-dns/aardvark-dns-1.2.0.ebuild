# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Auto-Generated by cargo-ebuild 0.5.1

EAPI=8
EGIT_COMMIT='cb1a462dd8427e33355f6907394a0646f5a26bf2'

# Error: Found 1 vulnerability:
#
# Crate:    time
# Version:  0.1.44
# Title:    Potential segfault in the time crate
# Date:     2020-11-18
# ID:       RUSTSEC-2020-0071
# URL:      https://rustsec.org/advisories/RUSTSEC-2020-0071
# Solution: Upgrade to >=0.2.23

CRATES="
	anyhow-1.0.65
	async-broadcast-0.4.1
	async-trait-0.1.56
	atty-0.2.14
	autocfg-1.1.0
	bitflags-1.3.2
	bumpalo-3.10.0
	bytes-1.1.0
	cfg-if-1.0.0
	chrono-0.4.20
	clap-3.2.22
	clap_derive-3.2.18
	clap_lex-0.2.4
	data-encoding-2.3.2
	endian-type-0.1.2
	enum-as-inner-0.3.4
	enum-as-inner-0.5.1
	error-chain-0.12.4
	event-listener-2.5.2
	form_urlencoded-1.0.1
	futures-channel-0.3.21
	futures-core-0.3.24
	futures-executor-0.3.21
	futures-io-0.3.21
	futures-macro-0.3.24
	futures-task-0.3.24
	futures-util-0.3.24
	getrandom-0.2.7
	hashbrown-0.12.2
	heck-0.4.0
	hermit-abi-0.1.19
	hostname-0.3.1
	idna-0.2.3
	indexmap-1.9.1
	ipnet-2.5.0
	itoa-1.0.2
	js-sys-0.3.59
	lazy_static-1.4.0
	libc-0.2.133
	lock_api-0.4.7
	log-0.4.17
	match_cfg-0.1.0
	matches-0.1.9
	memchr-2.5.0
	memoffset-0.6.5
	mio-0.8.4
	nibble_vec-0.1.0
	nix-0.25.0
	num-integer-0.1.45
	num-traits-0.2.15
	num_cpus-1.13.1
	num_threads-0.1.6
	once_cell-1.13.0
	os_str_bytes-6.1.0
	parking_lot-0.12.1
	parking_lot_core-0.9.3
	percent-encoding-2.1.0
	pin-project-lite-0.2.9
	pin-utils-0.1.0
	ppv-lite86-0.2.16
	proc-macro-error-1.0.4
	proc-macro-error-attr-1.0.4
	proc-macro2-1.0.40
	quick-error-1.2.3
	quote-1.0.20
	radix_trie-0.2.1
	rand-0.8.5
	rand_chacha-0.3.1
	rand_core-0.6.3
	redox_syscall-0.2.13
	resolv-conf-0.7.0
	scopeguard-1.1.0
	serde-1.0.139
	serde_derive-1.0.139
	signal-hook-0.3.14
	signal-hook-registry-1.4.0
	slab-0.4.6
	smallvec-1.9.0
	socket2-0.4.4
	strsim-0.10.0
	syn-1.0.98
	syslog-6.0.1
	termcolor-1.1.3
	textwrap-0.15.1
	thiserror-1.0.31
	thiserror-impl-1.0.31
	time-0.1.44
	time-0.3.11
	tinyvec-1.6.0
	tinyvec_macros-0.1.0
	tokio-1.21.1
	tokio-macros-1.8.0
	toml-0.5.9
	tracing-0.1.36
	tracing-attributes-0.1.22
	tracing-core-0.1.29
	trust-dns-client-0.20.4
	trust-dns-client-0.22.0
	trust-dns-proto-0.20.4
	trust-dns-proto-0.22.0
	trust-dns-server-0.22.0
	unicode-bidi-0.3.8
	unicode-ident-1.0.1
	unicode-normalization-0.1.21
	url-2.2.2
	version_check-0.9.4
	wasi-0.10.0+wasi-snapshot-preview1
	wasi-0.11.0+wasi-snapshot-preview1
	wasm-bindgen-0.2.82
	wasm-bindgen-backend-0.2.82
	wasm-bindgen-macro-0.2.82
	wasm-bindgen-macro-support-0.2.82
	wasm-bindgen-shared-0.2.82
	winapi-0.3.9
	winapi-i686-pc-windows-gnu-0.4.0
	winapi-util-0.1.5
	winapi-x86_64-pc-windows-gnu-0.4.0
	windows-sys-0.36.1
	windows_aarch64_msvc-0.36.1
	windows_i686_gnu-0.36.1
	windows_i686_msvc-0.36.1
	windows_x86_64_gnu-0.36.1
	windows_x86_64_msvc-0.36.1
"

inherit cargo

DESCRIPTION="Authoritative DNS server for A/AAAA container records"
HOMEPAGE="https://github.com/containers/aardvark-dns"
SRC_URI="
	https://github.com/containers/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	$(cargo_crate_uris)"
RESTRICT="mirror"
LICENSE="Apache-2.0 Apache-2.0-with-LLVM-exceptions MIT Unlicense ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"

src_prepare() {
	sed -e "/println/s|commit|\"${EGIT_COMMIT}\"|" \
		-i build.rs

	default
}

src_install() {
	cargo_src_install

	dodir /usr/libexec/podman
	ln -s ../../bin/"${PN}" "${ED}"/usr/libexec/podman/"${PN}" || die
}
