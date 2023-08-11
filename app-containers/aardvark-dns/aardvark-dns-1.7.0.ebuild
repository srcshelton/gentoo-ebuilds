# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Auto-Generated by cargo-ebuild 0.5.4

EAPI=8
EGIT_COMMIT='d27d3b39b519d4a2db3ae322c0d62846772a8624'

# Error: Found 1 vulnerability:
#
# Crate:    time
# Version:  0.1.45
# Title:    Potential segfault in the time crate
# Date:     2020-11-18
# ID:       RUSTSEC-2020-0071
# URL:      https://rustsec.org/advisories/RUSTSEC-2020-0071
# Solution: Upgrade to >=0.2.23

CRATES="
	addr2line-0.19.0
	adler-1.0.2
	android-tzdata-0.1.1
	android_system_properties-0.1.5
	anstream-0.3.2
	anstyle-1.0.0
	anstyle-parse-0.2.0
	anstyle-query-1.0.0
	anstyle-wincon-1.0.1
	anyhow-1.0.71
	async-broadcast-0.5.1
	async-trait-0.1.68
	autocfg-1.1.0
	backtrace-0.3.67
	bitflags-1.3.2
	bumpalo-3.13.0
	bytes-1.4.0
	cc-1.0.79
	cfg-if-1.0.0
	chrono-0.4.26
	clap-4.3.8
	clap_builder-4.3.8
	clap_derive-4.3.2
	clap_lex-0.5.0
	colorchoice-1.0.0
	core-foundation-sys-0.8.4
	data-encoding-2.4.0
	endian-type-0.1.2
	enum-as-inner-0.5.1
	errno-0.3.1
	errno-dragonfly-0.1.2
	error-chain-0.12.4
	event-listener-2.5.3
	form_urlencoded-1.2.0
	futures-channel-0.3.28
	futures-core-0.3.28
	futures-executor-0.3.28
	futures-io-0.3.28
	futures-task-0.3.28
	futures-util-0.3.28
	getrandom-0.2.10
	gimli-0.27.3
	heck-0.4.1
	hermit-abi-0.2.6
	hermit-abi-0.3.1
	hostname-0.3.1
	iana-time-zone-0.1.57
	iana-time-zone-haiku-0.1.2
	idna-0.2.3
	idna-0.4.0
	io-lifetimes-1.0.11
	ipnet-2.7.2
	is-terminal-0.4.7
	itoa-1.0.6
	js-sys-0.3.64
	lazy_static-1.4.0
	libc-0.2.146
	linux-raw-sys-0.3.8
	log-0.4.19
	match_cfg-0.1.0
	matches-0.1.10
	memchr-2.5.0
	memoffset-0.7.1
	miniz_oxide-0.6.2
	mio-0.8.8
	nibble_vec-0.1.0
	nix-0.26.2
	num-traits-0.2.15
	num_cpus-1.15.0
	num_threads-0.1.6
	object-0.30.4
	once_cell-1.18.0
	percent-encoding-2.3.0
	pin-project-lite-0.2.9
	pin-utils-0.1.0
	ppv-lite86-0.2.17
	proc-macro2-1.0.60
	quick-error-1.2.3
	quote-1.0.28
	radix_trie-0.2.1
	rand-0.8.5
	rand_chacha-0.3.1
	rand_core-0.6.4
	resolv-conf-0.7.0
	rustc-demangle-0.1.23
	rustix-0.37.20
	serde-1.0.164
	serde_derive-1.0.164
	signal-hook-0.3.15
	signal-hook-registry-1.4.1
	slab-0.4.8
	smallvec-1.10.0
	socket2-0.4.9
	static_assertions-1.1.0
	strsim-0.10.0
	syn-1.0.109
	syn-2.0.18
	syslog-6.1.0
	thiserror-1.0.40
	thiserror-impl-1.0.40
	time-0.1.45
	time-0.3.22
	time-core-0.1.1
	time-macros-0.2.9
	tinyvec-1.6.0
	tinyvec_macros-0.1.1
	tokio-1.29.0
	tokio-macros-2.1.0
	toml-0.5.11
	tracing-0.1.37
	tracing-attributes-0.1.24
	tracing-core-0.1.31
	trust-dns-client-0.22.0
	trust-dns-proto-0.22.0
	trust-dns-server-0.22.1
	unicode-bidi-0.3.13
	unicode-ident-1.0.9
	unicode-normalization-0.1.22
	url-2.4.0
	utf8parse-0.2.1
	version_check-0.9.4
	wasi-0.10.0+wasi-snapshot-preview1
	wasi-0.11.0+wasi-snapshot-preview1
	wasm-bindgen-0.2.87
	wasm-bindgen-backend-0.2.87
	wasm-bindgen-macro-0.2.87
	wasm-bindgen-macro-support-0.2.87
	wasm-bindgen-shared-0.2.87
	winapi-0.3.9
	winapi-i686-pc-windows-gnu-0.4.0
	winapi-x86_64-pc-windows-gnu-0.4.0
	windows-0.48.0
	windows-sys-0.48.0
	windows-targets-0.48.0
	windows_aarch64_gnullvm-0.48.0
	windows_aarch64_msvc-0.48.0
	windows_i686_gnu-0.48.0
	windows_i686_msvc-0.48.0
	windows_x86_64_gnu-0.48.0
	windows_x86_64_gnullvm-0.48.0
	windows_x86_64_msvc-0.48.0
"

inherit cargo

DESCRIPTION="A container-focused DNS server"
HOMEPAGE="https://github.com/containers/aardvark-dns"
SRC_URI="
	https://github.com/containers/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	$(cargo_crate_uris)"
RESTRICT="mirror"
LICENSE="0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions MIT Unicode-DFS-2016 Unlicense ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"

QA_FLAGS_IGNORED="usr/bin/${PN}
	/usr/libexec/podman/${PN}"

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