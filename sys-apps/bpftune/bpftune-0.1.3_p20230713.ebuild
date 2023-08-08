# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit fcaps

EGIT_COMMIT='9c99014b7febb0d4724288006cec4695ef858efa'

DESCRIPTION="BPF driven auto-tuning"
HOMEPAGE="https://github.com/oracle-samples/bpftune"
SRC_URI="https://github.com/oracle-samples/bpftune/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2-with-exceptions"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	>=sys-devel/llvm-11
	>=sys-devel/clang-11
	dev-python/docutils
"
DEPEND="
	>=dev-libs/libnl-3:=
	dev-libs/elfutils:=
	dev-libs/libbpf:=
	dev-util/bpftool:=
	sys-libs/libcap:=
	sys-libs/libcap-ng:=
	sys-libs/zlib:=
"
RDEPEND="${DEPEND}"

S="${WORKDIR}/bpftune-${EGIT_COMMIT}"

FILECAPS=(
	'cap_pbf,cap_tracing=+ep' usr/sbin/bpftune
)

src_prepare() {
	default

	sed \
		-e 's/--analyze/--analyze --analyzer-output text/' \
		-i src/Makefile || die

	sed \
		-e 's/rst2man/rst2man.py/' \
		-i docs/Makefile || die
}

src_install() {
	default

	rm -r "${ED}"/etc/ld.so.conf.d || die
}

pkg_postinst() {
	if use filecaps; then
		fcaps_pkg_postinst
	else
		elog "Please set CAP_BPF and CAP_TRACING on the bpftune binary"
		elog "  e.g. setcap cap_pbf,cap_tracing+ep /usr/sbin/bpftune"
	fi
}
