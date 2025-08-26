# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MODULES_KERNEL_MIN=3.3

inherit flag-o-matic linux-mod-r1 systemd toolchain-funcs

DESCRIPTION="top-like CPU monitoring software designed for 64-bits processors"
HOMEPAGE="https://www.cyring.fr/"
SRC_URI="https://github.com/cyring/$PN/archive/$PV.tar.gz -> $P.tar.gz"
S="${WORKDIR}/CoreFreq-${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"

IUSE="doc dracut intel systemd"

DEPEND="
	kernel_linux? ( virtual/linux-sources )
"

BDEPEND="
	dev-build/make
	dev-vcs/git
"

#QA_PREBUILT="
#	usr/bin/${PN}d
#	/usr/bin/${PN}-cli
#"

pkg_setup() {
	local option='' CONFIG_CHECK=''

	# Mandatory : MODULES, SMP, X86_MSR
	# Optionally: HOTPLUG_CPU, CPU_IDLE, CPU_FREQ, PM_SLEEP, DMI, HAVE_NMI,
	#             XEN, AMD_NB, SCHED_MUQSS, SCHED_BMQ, SCHED_PDS, SCHED_ALT,
	#             SCHED_BORE, CACHY, ACPI, ACPI_CPPC_LIB
	# Forbidden : TRIM_UNUSED_KSYMS

	# Does this not work with uniprocessor systems?
	for option in MODULES SMP $(usev amd64 X86_MSR); do
		CONFIG_CHECK="${CONFIG_CHECK:+"${CONFIG_CHECK} "}~${option}"
		eval "ERROR_${option}=\"CONFIG_${option} is mandatory\""
	done
	for option in \
			HOTPLUG_CPU CPU_IDLE CPU_FREQ DMI HAVE_NMI ACPI ACPI_CPPC_LIB
	do
		CONFIG_CHECK="${CONFIG_CHECK:+"${CONFIG_CHECK} "}~${option}"
		eval "WARNING_${option}=\"CONFIG_${option} is optional\""
	done
	# No longer present in 6.13.x?
	#PM_SLEEP XEN AMD_NB SCHED_MUQSS SCHED_BMQ SCHED_PDS SCHED_ALT SCHED_BORE
	#CACHY
	for option in TRIM_UNUSED_KSYMS; do
		CONFIG_CHECK="${CONFIG_CHECK:+"${CONFIG_CHECK} "}~!${option}"
		eval "ERROR_${option}=\"CONFIG_${option} is forbidden\""
	done

	get_version
	require_configured_kernel
	linux-mod-r1_pkg_setup

	#einfo "linux-mod-r1_pkg_setup results:"
	#env | grep -- '^KERNEL_' | xargs -rn 1 einfo " "
}

src_prepare() {
	local -i pagesz=4096

	default

	if ! [[ -s "${KV_OUT_DIR}"/.config ]]; then
		die "Cannot read kernel configuration from '${KV_OUT_DIR}/.config'"
	fi

	if grep -Fqx 'CONFIG_ARM64_16K_PAGES=y' "${KV_OUT_DIR}"/.config; then
		pagesz=16384
	elif grep -Fqx 'CONFIG_ARM64_64K_PAGES=y' "${KV_OUT_DIR}"/.config; then
		pagesz=65535
	fi

	sed -e "s#sysconf(_SC_PAGESIZE) > 0 ? sysconf(_SC_PAGESIZE) : 4096#${pagesz}#" \
		-i aarch64/corefreqd.c || die
	if (( pagesz != 4096 )); then
		sed -e 's#Bit32	Status;#Bit64	Status;#' \
			-i aarch64/corefreq-ui.c || die
	fi

	if ! tc-is-gcc; then
		sed -e '/fp.r/d' \
			-i aarch64/corefreqk.c || die
	fi
}

src_compile() {
	local flag=''

	local -a modlist=(
		corefreqk="extra:${S}:build"
	)
	local -a modargs=(
		KERNELDIR="/lib/modules/${KV_FULL}/build"
		V=1
		# Set the maximum number of supported CPUs...
		CORE_COUNT=64
		# Minimum of 4850000000(Hz) default 7125000000...
		MAX_FREQ_HZ=4850000000
	)
	if use intel; then
		modargs+=(
			MSR_CORE_PERF_UCC="MSR_CORE_PERF_FIXED_CTR1"
			MSR_CORE_PERF_URC="MSR_CORE_PERF_FIXED_CTR2"
		)
	else
		:
		#modargs+=(
		#	MSR_CORE_PERF_UCC=''
		#	MSR_CORE_PERF_URC=''
		#)
	fi

	# Without hacking the Makefile, this is the only way to pass *FLAGS to the
	# build :o
	#
	# N.B. asm-operand-widths warnings are actually generated when the target
	#      kernel-source has a different page-size from the build host, and so
	#      are genuine errors!
	#
	for flag in unused-command-line-argument; do  # asm-operand-widths
		if test-flag-CC "-Wno-${flag}"; then
			append-cflags "-Wno-${flag}"
		fi
	done
	modargs+=(
		WARNING="-Wall -Wfatal-errors ${CPPFLAGS} ${CFLAGS} ${LDFLAGS}"
	)

	if is-flagq -O0; then
		modargs+=( OPTIM_LVL=0 )
	elif is-flagq -O1; then
		modargs+=( OPTIM_LVL=1 )
	elif is-flagq -O2; then
		modargs+=( OPTIM_LVL=2 )
	elif is-flagq -O3; then
		modargs+=( OPTIM_LVL=3 )
	fi

	make "${modargs[@]}" info
	emake "${modargs[@]}" corefreqd corefreq-cli || die "emake failed: ${?}"

	tc-export

	#einfo "linux-mod-r1_src_compile environment:"
	#env | grep -- '^KERNEL_' | xargs -rn 1 einfo " "
	#linux-mod-r1_src_compile
	set -x
	#emake "${modargs[@]}" CC="${CC}" LD="${LD}" AS="${AS}" \
	emake "${modargs[@]}" CC="${CC}" LD="ld" AS='as' LLVM_IAS=0 \
			corefreqk.ko ||
		die "emake failed: ${?}"
	set +x
}

src_install() {
	linux-mod-r1_src_install

	dobin build/corefreqd build/corefreq-cli || die

	if ! use dracut; then
		rm "${ED}/usr/lib/dracut/dracut.conf.d/10-corefreq.conf" || die
		rmdir --parents --ignore-fail-on-non-empty \
				"${ED}/usr/lib/dracut/dracut.conf.d" ||
			die
	fi

	newconfd "${FILESDIR}/${PN}.conf" "${PN}" || die
	doinitd "${FILESDIR}/${PN}" || die

	# 'make install' unconditionally installs corefreqd.service iff
	# /usr/lib/systemd/system/ exists...
	use systemd && systemd_dounit ${PN}d.service
	use doc && dodoc README.md
}

pkg_postinst() {
	linux-mod-r1_pkg_postinst

	elog "To be able to use corefreq, you need to load kernel module:"
	elog
	elog "  modprobe corefreqk"
	elog
	elog "... then start the service:"
	elog
	elog "  rc-service corefreq start"
	elog
	elog "... then you may start corefreq-cli"

	if use intel && [[ -s /proc/cmdline ]] &&
			! grep -Fwq -- 'nmi_watchdog=0' /proc/cmdline
	then
		elog "For Intel hosts, please add 'nmi_watchdog=0' to the kernel" \
			"command-line"
	fi
}
