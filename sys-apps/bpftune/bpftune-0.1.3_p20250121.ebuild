# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=({11..19})

inherit fcaps linux-info llvm-r1

EGIT_COMMIT='d38eac6ff6f9ff654e401ba84d03a51b8295e7b0'

DESCRIPTION="BPF driven auto-tuning"
HOMEPAGE="https://github.com/oracle/bpftune"
SRC_URI="https://github.com/oracle/bpftune/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2-with-exceptions"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

BDEPEND="
	dev-python/docutils
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}=
		llvm-core/llvm:${LLVM_SLOT}=
	')
"
DEPEND="
	>=dev-libs/libnl-3:=
	dev-libs/elfutils:=
	>=dev-libs/libbpf-0.6:=
	>=dev-util/bpftool-4.18:=
	sys-libs/libcap-ng:=
	sys-libs/zlib:=
"
RDEPEND="${DEPEND}"

S="${WORKDIR}/bpftune-${EGIT_COMMIT}"

FILECAPS=(
	'cap_bpf,cap_perfmon+ep' usr/sbin/bpftune
)

pkg_setup() {
	local CONFIG_CHECK="
		~DEBUG_INFO ~!DEBUG_INFO_SPLIT ~!DEBUG_INFO_REDUCED ~DEBUG_INFO_BTF
		~BPF_SYSCALL
		~KPROBES
	"
	local ERROR_DEBUG_INFO="CONFIG_DEBUG_INFO is required by CONFIG_DEBUG_INFO_BTF"
	local ERROR_DEBUG_INFO_SPLIT="CONFIG_DEBUG_INFO_SPLIT cannot be selected if CONFIG_DEBUG_INFO_BTF is active"
	local ERROR_DEBUG_INFO_REDUCED="CONFIG_DEBUG_INFO_REDUCED cannot be selected if CONFIG_DEBUG_INFO_BTF is active"
	local ERROR_DEBUG_INFO_BTF="CONFIG_DEBUG_INFO_BTF is required to enable access to /sys/kernel/btf/vmlinux"
	local ERROR_BPF_SYSCALL="CONFIG_BPF_SYSCALL is required by ${CATEGORY}/${PN}"
	local WARNING_KPROBES="CONFIG_KPROBES is a legacy alternative to CONFIG_DEBUG_INFO_BTF"

	if kernel_is -lt 5 6; then
		eerror "Kernel support for BPF Ring Buffer is required, and was"
		eerror "first available with Linux 5.6"
		die "Kernel too old"
	fi

	linux-info_pkg_setup
	llvm-r1_pkg_setup
}

src_prepare() {
	default

	sed \
		-e 's/--analyze/--analyze --analyzer-output text/' \
		-i src/Makefile || die
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
		elog "  e.g. setcap cap_bpf,cap_perfmon=+ep /usr/sbin/bpftune"
	fi
}
