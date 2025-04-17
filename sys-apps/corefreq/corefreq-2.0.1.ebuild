# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MODULES_KERNEL_MIN=3.3

inherit linux-mod-r1 systemd

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
	local option=''

	# Does this not work with uniprocessor systems?
	local CONFIG_CHECK=''
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
	#PM_SLEEP XEN AMD_NB SCHED_MUQSS SCHED_BMQ SCHED_PDS SCHED_ALT SCHED_BORE CACHY
	for option in TRIM_UNUSED_KSYMS; do
		CONFIG_CHECK="${CONFIG_CHECK:+"${CONFIG_CHECK} "}~!${option}"
		eval "ERROR_${option}=\"CONFIG_${option} is forbidden\""
	done

	get_version
	require_configured_kernel
	linux-mod-r1_pkg_setup
}

src_compile() {
	local -a modlist=(
		corefreqk="extra:${S}:build"
	)
	local -a modargs=(
		KERNELDIR="/lib/modules/${KV_FULL}/build"
		V=1
		# Set the maximum number of supported CPUs...
		CORE_COUNT=64
	)
	if use intel; then
		modargs+=(
			MSR_CORE_PERF_UC="MSR_CORE_PERF_FIXED_CTR1"
			MSR_CORE_PERF_URC="MSR_CORE_PERF_FIXED_CTR2"
		)
	fi

	emake prepare

	linux-mod-r1_src_compile
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
	# /usr//lib/systemd/system/ exists...
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
}
