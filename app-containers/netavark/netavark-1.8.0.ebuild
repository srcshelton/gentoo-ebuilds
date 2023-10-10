# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Auto-Generated by cargo-ebuild 0.5.4-r1

EAPI=8
EGIT_COMMIT='837f1f3fb77aa61656a0f561769446453655663e'

CRATES="
	addr2line@0.21.0
	adler@1.0.2
	aho-corasick@1.1.1
	android-tzdata@0.1.1
	android_system_properties@0.1.5
	anstream@0.3.2
	anstyle@1.0.2
	anstyle-parse@0.2.1
	anstyle-query@1.0.0
	anstyle-wincon@1.0.2
	anyhow@1.0.75
	arrayvec@0.7.4
	async-broadcast@0.5.1
	async-channel@1.9.0
	async-executor@1.5.3
	async-fs@1.6.0
	async-io@1.13.0
	async-lock@2.8.0
	async-process@1.8.0
	async-recursion@1.0.5
	async-signal@0.2.1
	async-stream@0.3.5
	async-stream-impl@0.3.5
	async-task@4.4.1
	async-trait@0.1.73
	atomic-waker@1.1.2
	autocfg@1.1.0
	axum@0.6.20
	axum-core@0.3.4
	backtrace@0.3.69
	base64@0.21.4
	bitflags@1.3.2
	bitflags@2.4.0
	block-buffer@0.10.4
	blocking@1.4.0
	bumpalo@3.14.0
	byteorder@1.4.3
	bytes@1.5.0
	cc@1.0.83
	cfg-if@1.0.0
	chrono@0.4.31
	clap@4.3.24
	clap_builder@4.3.24
	clap_derive@4.3.12
	clap_lex@0.5.0
	colorchoice@1.0.0
	concurrent-queue@2.3.0
	core-foundation-sys@0.8.4
	cpufeatures@0.2.9
	crossbeam-utils@0.8.16
	crypto-common@0.1.6
	data-encoding@2.4.0
	derivative@2.2.0
	dhcproto@0.9.0
	dhcproto-macros@0.1.0
	digest@0.10.7
	either@1.9.0
	enum-as-inner@0.5.1
	enumflags2@0.7.8
	enumflags2_derive@0.7.8
	env_logger@0.10.0
	equivalent@1.0.1
	errno@0.3.3
	errno-dragonfly@0.1.2
	etherparse@0.13.0
	ethtool@0.2.5
	event-listener@2.5.3
	event-listener@3.0.0
	fastrand@1.9.0
	fastrand@2.0.1
	fixedbitset@0.4.2
	fnv@1.0.7
	form_urlencoded@1.2.0
	fs2@0.4.3
	futures@0.3.28
	futures-channel@0.3.28
	futures-core@0.3.28
	futures-executor@0.3.28
	futures-io@0.3.28
	futures-lite@1.13.0
	futures-macro@0.3.28
	futures-sink@0.3.28
	futures-task@0.3.28
	futures-util@0.3.28
	generic-array@0.14.7
	genetlink@0.2.5
	getrandom@0.2.10
	gimli@0.28.0
	h2@0.3.21
	hashbrown@0.12.3
	hashbrown@0.14.0
	heck@0.4.1
	hermit-abi@0.3.3
	hex@0.4.3
	home@0.5.5
	http@0.2.9
	http-body@0.4.5
	httparse@1.8.0
	httpdate@1.0.3
	humantime@2.1.0
	hyper@0.14.27
	hyper-timeout@0.4.1
	iana-time-zone@0.1.57
	iana-time-zone-haiku@0.1.2
	idna@0.2.3
	idna@0.4.0
	indexmap@1.9.3
	indexmap@2.0.0
	instant@0.1.12
	io-lifetimes@1.0.11
	ipnet@2.8.0
	iptables@0.5.1
	is-terminal@0.4.9
	itertools@0.11.0
	itoa@1.0.9
	js-sys@0.3.64
	lazy_static@1.4.0
	libc@0.2.148
	linux-raw-sys@0.3.8
	linux-raw-sys@0.4.7
	log@0.4.20
	matches@0.1.10
	matchit@0.7.3
	memchr@2.6.3
	memoffset@0.7.1
	mime@0.3.17
	miniz_oxide@0.7.1
	mio@0.8.8
	mozim@0.2.2
	mptcp-pm@0.1.3
	multimap@0.8.3
	netlink-packet-core@0.7.0
	netlink-packet-generic@0.3.3
	netlink-packet-route@0.17.1
	netlink-packet-utils@0.5.2
	netlink-proto@0.11.2
	netlink-sys@0.8.5
	nispor@1.2.14
	nix@0.26.4
	nix@0.27.1
	num-traits@0.2.16
	num_cpus@1.16.0
	object@0.32.1
	once_cell@1.18.0
	ordered-float@2.10.0
	ordered-stream@0.2.0
	parking@2.1.1
	paste@1.0.14
	percent-encoding@2.3.0
	petgraph@0.6.4
	pin-project@1.1.3
	pin-project-internal@1.1.3
	pin-project-lite@0.2.13
	pin-utils@0.1.0
	piper@0.2.1
	polling@2.8.0
	ppv-lite86@0.2.17
	prettyplease@0.2.15
	proc-macro-crate@1.3.1
	proc-macro2@1.0.67
	prost@0.12.1
	prost-build@0.12.1
	prost-derive@0.12.1
	prost-types@0.12.1
	quote@1.0.33
	rand@0.8.5
	rand_chacha@0.3.1
	rand_core@0.6.4
	redox_syscall@0.3.5
	regex@1.9.5
	regex-automata@0.3.8
	regex-syntax@0.7.5
	rtnetlink@0.13.1
	rustc-demangle@0.1.23
	rustix@0.37.23
	rustix@0.38.14
	rustversion@1.0.14
	ryu@1.0.15
	same-file@1.0.6
	serde@1.0.188
	serde-value@0.7.0
	serde_derive@1.0.188
	serde_json@1.0.107
	serde_repr@0.1.16
	sha1@0.10.6
	sha2@0.10.7
	signal-hook-registry@1.4.1
	slab@0.4.9
	smallvec@1.11.1
	socket2@0.4.9
	socket2@0.5.4
	static_assertions@1.1.0
	strsim@0.10.0
	syn@1.0.109
	syn@2.0.37
	sync_wrapper@0.1.2
	sysctl@0.5.4
	tempfile@3.8.0
	termcolor@1.3.0
	thiserror@1.0.48
	thiserror-impl@1.0.48
	tinyvec@1.6.0
	tinyvec_macros@0.1.1
	tokio@1.32.0
	tokio-io-timeout@1.2.0
	tokio-macros@2.1.0
	tokio-stream@0.1.14
	tokio-util@0.7.9
	toml_datetime@0.6.3
	toml_edit@0.19.15
	tonic@0.10.1
	tonic-build@0.10.1
	tower@0.4.13
	tower-layer@0.3.2
	tower-service@0.3.2
	tracing@0.1.37
	tracing-attributes@0.1.26
	tracing-core@0.1.31
	trust-dns-proto@0.22.0
	try-lock@0.2.4
	typenum@1.17.0
	uds_windows@1.0.2
	unicode-bidi@0.3.13
	unicode-ident@1.0.12
	unicode-normalization@0.1.22
	url@2.4.1
	utf8parse@0.2.1
	version_check@0.9.4
	waker-fn@1.1.1
	walkdir@2.4.0
	want@0.3.1
	wasi@0.11.0+wasi-snapshot-preview1
	wasm-bindgen@0.2.87
	wasm-bindgen-backend@0.2.87
	wasm-bindgen-macro@0.2.87
	wasm-bindgen-macro-support@0.2.87
	wasm-bindgen-shared@0.2.87
	which@4.4.2
	winapi@0.3.9
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-util@0.1.6
	winapi-x86_64-pc-windows-gnu@0.4.0
	windows@0.48.0
	windows-sys@0.48.0
	windows-targets@0.48.5
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_msvc@0.48.5
	windows_i686_gnu@0.48.5
	windows_i686_msvc@0.48.5
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_msvc@0.48.5
	winnow@0.5.15
	xdg-home@1.0.0
	zbus@3.14.1
	zbus_macros@3.14.1
	zbus_names@2.6.0
	zvariant@3.15.0
	zvariant_derive@3.15.0
	zvariant_utils@1.0.1
"

inherit cargo

DESCRIPTION="A container network stack"
HOMEPAGE="https://github.com/containers/netavark"
SRC_URI="
	https://github.com/containers/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	$(cargo_crate_uris)"
RESTRICT="mirror"
LICENSE="0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD Boost-1.0 MIT Unicode-DFS-2016 Unlicense ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"
IUSE="+dns"

BDEPEND="dev-go/go-md2man
	dev-libs/protobuf"
RDEPEND="dns? ( app-containers/aardvark-dns )"

QA_FLAGS_IGNORED="usr/bin/${PN}
	usr/bin/${PN}-dhcp-proxy-client"

src_prepare() {
	sed -e "/println/s|GIT_COMMIT={commit}\"|GIT_COMMIT={}\", \"${EGIT_COMMIT}\"|" \
		-i build.rs

	default
}

src_compile() {
	cargo_src_compile

	cd docs || die
	for f in *.1.md; do
		go-md2man -in ${f} -out ${f%%.md} || die
	done
}

src_install() {
	cargo_src_install

	doman docs/*.1
	dodir /usr/libexec/podman
	dosym -r /bin/"${PN}" /usr/libexec/podman/"${PN}" || die
}
