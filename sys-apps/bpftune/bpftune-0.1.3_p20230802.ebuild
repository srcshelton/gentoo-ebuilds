# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit fcaps linux-info

EGIT_COMMIT='f7e051a011d581a3c667b7f7b769862407d85f04'

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
	'cap_pbf,cap_tracing+ep' usr/sbin/bpftune
)

pkg_setup() {
	local CONFIG_CHECK="~DEBUG_INFO ~!DEBUG_INFO_SPLIT ~!DEBUG_INFO_REDUCED ~BPF_SYSCALL ~DEBUG_INFO_BTF ~KPROBES"
	local ERROR_DEBUG_INFO="CONFIG_DEBUG_INFO is required by CONFIG_DEBUG_INFO_BTF"
	local ERROR_DEBUG_INFO_SPLIT="CONFIG_DEBUG_INFO_SPLIT cannot be selected if CONFIG_DEBUG_INFO_BTF is active"
	local ERROR_DEBUG_INFO_REDUCED="CONFIG_DEBUG_INFO_REDUCED cannot be selected if CONFIG_DEBUG_INFO_BTF is active"
	local ERROR_BPF_SYSCALL="CONFIG_BPF_SYSCALL is required by ${CATEGORY}/${PN}"
	local ERROR_DEBUG_INFO_BTF="CONFIG_DEBUG_INFO_BTF is required to enable access to /sys/kernel/btf/vmlinux"
	local WARNING_KPROBES="CONFIG_KPROBES is a legacy alternative to CONFIG_DEBUG_INFO_BTF"

	linux-info_pkg_setup
}

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
		elog "  e.g. setcap cap_pbf,cap_tracing=+ep /usr/sbin/bpftune"
	fi
}
