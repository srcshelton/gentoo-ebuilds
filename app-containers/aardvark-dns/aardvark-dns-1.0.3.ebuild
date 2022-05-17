# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Auto-Generated by cargo-ebuild 0.5.1

EAPI=8
EGIT_COMMIT='a92337b08fbd88c9eb10c1a5ebce2bf61aa59a7b'

# WARNING: Found 2 vulnerabilities:
#
# Crate:    chrono
# Version:  0.4.19
# Title:    Potential segfault in `localtime_r` invocations
# Date:     2020-11-10
# ID:       RUSTSEC-2020-0159
# URL:      https://rustsec.org/advisories/RUSTSEC-2020-0159
# Solution: No solution available
#
# Crate:    time
# Version:  0.1.43
# Title:    Potential segfault in the time crate
# Date:     2020-11-18
# ID:       RUSTSEC-2020-0071
# URL:      https://rustsec.org/advisories/RUSTSEC-2020-0071
# Solution: Upgrade to >=0.2.23

CRATES="
	aho-corasick-0.7.18
	anyhow-1.0.57
	async-broadcast-0.4.0
	async-trait-0.1.53
	atty-0.2.14
	autocfg-1.1.0
	bitflags-1.3.2
	bytes-1.1.0
	cfg-if-1.0.0
	chrono-0.4.19
	clap-3.1.15
	clap_derive-3.1.7
	clap_lex-0.2.0
	data-encoding-2.3.2
	easy-parallel-3.2.0
	endian-type-0.1.2
	enum-as-inner-0.3.4
	enum-as-inner-0.4.0
	env_logger-0.9.0
	error-chain-0.12.4
	event-listener-2.5.2
	form_urlencoded-1.0.1
	futures-channel-0.3.21
	futures-core-0.3.21
	futures-executor-0.3.21
	futures-io-0.3.21
	futures-macro-0.3.21
	futures-task-0.3.21
	futures-util-0.3.21
	getrandom-0.2.6
	hashbrown-0.11.2
	heck-0.4.0
	hermit-abi-0.1.19
	hostname-0.3.1
	humantime-2.1.0
	idna-0.2.3
	indexmap-1.8.1
	instant-0.1.12
	ipnet-2.5.0
	itoa-1.0.1
	lazy_static-1.4.0
	libc-0.2.125
	lock_api-0.4.7
	log-0.4.17
	match_cfg-0.1.0
	matches-0.1.9
	memchr-2.5.0
	mio-0.8.2
	miow-0.3.7
	nibble_vec-0.1.0
	ntapi-0.3.7
	num-integer-0.1.45
	num-traits-0.2.15
	num_cpus-1.13.1
	num_threads-0.1.6
	once_cell-1.10.0
	os_str_bytes-6.0.0
	parking_lot-0.11.2
	parking_lot-0.12.0
	parking_lot_core-0.8.5
	parking_lot_core-0.9.3
	percent-encoding-2.1.0
	pin-project-lite-0.2.9
	pin-utils-0.1.0
	ppv-lite86-0.2.16
	proc-macro-error-1.0.4
	proc-macro-error-attr-1.0.4
	proc-macro2-1.0.37
	quick-error-1.2.3
	quote-1.0.18
	radix_trie-0.2.1
	rand-0.8.5
	rand_chacha-0.3.1
	rand_core-0.6.3
	redox_syscall-0.2.13
	regex-1.5.5
	regex-syntax-0.6.25
	resolv-conf-0.7.0
	scopeguard-1.1.0
	serde-1.0.137
	serde_derive-1.0.137
	signal-hook-0.3.13
	signal-hook-registry-1.4.0
	slab-0.4.6
	smallvec-1.8.0
	socket2-0.4.4
	strsim-0.10.0
	syn-1.0.92
	syslog-6.0.1
	termcolor-1.1.3
	textwrap-0.15.0
	thiserror-1.0.31
	thiserror-impl-1.0.31
	time-0.1.43
	time-0.3.9
	tinyvec-1.6.0
	tinyvec_macros-0.1.0
	tokio-1.18.1
	tokio-macros-1.7.0
	toml-0.5.9
	trust-dns-client-0.20.4
	trust-dns-client-0.21.2
	trust-dns-proto-0.20.4
	trust-dns-proto-0.21.2
	trust-dns-server-0.21.2
	unicode-bidi-0.3.8
	unicode-normalization-0.1.19
	unicode-xid-0.2.3
	url-2.2.2
	version_check-0.9.4
	wasi-0.10.2+wasi-snapshot-preview1
	wasi-0.11.0+wasi-snapshot-preview1
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
	$(cargo_crate_uris ${CRATES})"
RESTRICT="mirror"
LICENSE="Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD MIT Unlicense ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"

src_prepare() {
	cargo_src_prepare

	sed -e "/println/s|commit|\"${EGIT_COMMIT}\"|" \
		-i build.rs

	default
}


src_install() {
	cargo_src_install

	dodir /usr/libexec/podman
	ln -s ../../bin/"${PN}" "${ED}"/usr/libexec/podman/"${PN}" || die
}