# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER=98
#K_BASE_VER="${PV}"

K_SECURITY_UNSUPPORTED=1

##EXTRAVERSION="-${PN}/-*"
#K_NODRYRUN=1  # Fail early rather than trying -p0 to -p5, seems to fix unipatch()!
#K_NOSETEXTRAVERSION=1
#K_NOUSENAME=1
K_NOUSEPR=1

K_EXTRAELOG="

Known broken options in ${PV}:

  CIX_CORE_CTL          (references missing function)
  DRM_NOUVEAU           (conflicts with drm_gpuvm.h)
  INV_ICM42600_I2C      (undefined reference to INV_ICM42600_REG_DRIVE_CONFIG)
  PM_EXCEPTION_PROTOCOL (undefined reference to scmi_protocol_(un)register)
  PM_EXCP_DSM_DRIVER    (undefined reference to get_pm_exception_data)
  TYPEC_DP_ALTMODE      (undefined reference to DP_CONF_SIGNALLING_SHIFT)
"

#K_EXP_GENPATCHES_NOUSE=1
K_DEBLOB_AVAILABLE=0

H_SUPPORTEDARCH="arm arm64"
#K_FROM_GIT=1

inherit kernel-2
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

EGIT_COMMIT="fd1a9d06cef85f16a4dcb16061a9128437e235f4"
# The base for the vendor patches may differ from the kernel we're trying to
# build...
EGIT_COMMIT_KV="6.6.89"

DESCRIPTION="CIX sources including the Gentoo patchset for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
HOMEPAGE="https://gitlab.com/cix-linux/cix_opensource/linux
	https://github.com/radxa/kernel/
	https://dev.gentoo.org/~mpagano/genpatches"
SRC_URI="
	https://github.com/radxa/kernel/commit/${EGIT_COMMIT}.patch -> ${PN}-${EGIT_COMMIT_KV}.patch
	${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}"

KEYWORDS="arm arm64"
IUSE="experimental git"

COMMON_DEPEND="
	sys-libs/binutils-libs
	|| (
		~sys-kernel/cix-headers-${KV_MAJOR}.${KV_MINOR}
		~sys-kernel/linux-headers-${KV_MAJOR}.${KV_MINOR}
	)
"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="${COMMON_DEPEND}
	git? ( dev-vcs/git )
"

# Potentially move the CIX patch from UNIPATCH_LIST to PATCHES so that we can
# take a git snapshot before and after it is applied...
#UNIPATCH_LIST=(
#	"${DISTDIR}/${PN}-${EGIT_COMMIT_KV}.patch"
#)

PATCHES=(
	"${FILESDIR}/${EGIT_COMMIT_KV}-Kconfig-mark-BROKEN.patch"

	"${FILESDIR}/${EGIT_COMMIT_KV}-blackbox.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-check_himntn.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-clk-sky1-audss.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-cppc_cpufreq.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-cros_ec.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-drm.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-dst_reboot_reason.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-mntn-headers.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-phy-cix-usbdp.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-pm_exception.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-printk.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-regulator.patch"
	#"${FILESDIR}/${EGIT_COMMIT_KV}-remove-gov_acpi_dp.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-sched_clock-isb.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-scmi.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-sky1_pcie-fixes.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-sky1_wdt.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-soc-cix-pm.patch"

	"${FILESDIR}/${EGIT_COMMIT_KV}-amba-pl011.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-cdnsp-plat.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-cix_cpu_ipa.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-cix-cpufreq-dt.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-cix_rproc.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-cix_scmi_em.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-dsu-pctrl-devfreq.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-get_current_last_irq.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-gov_acpi_dp.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-hf_manager.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-incompatible-pointer.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-processor_thermal.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-register_module_dump_mem_func.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-rfkill-wlan.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-rtc-rx8900.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-sky1-rng.c.patch"
	"${FILESDIR}/${EGIT_COMMIT_KV}-timer-sky1-gpt.c.patch"

	"${FILESDIR}/${EGIT_COMMIT_KV}-misc.patch"

	"${FILESDIR}/0001-DPTSW-16669-0-clocksource-timer-sky1-gpt-remove-rese.patch"
	"${FILESDIR}/0002-DPTSW-16669-1-pwm-remove-reset-operation.patch"
	"${FILESDIR}/0003-DPTSW-16669-2-arch-arm64-dts-cix-disable-uart1.patch"
	"${FILESDIR}/0004-DPTSW-17177-pwm-sky1-remove-pwm-clock-auto-enable-fe.patch"

	"${FILESDIR}/${EGIT_COMMIT_KV}-clang-warnings.patch"
)

#S="${WORKDIR}/kernel-${EGIT_COMMIT}"

pkg_setup() {
	ewarn ""
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the Radxa/CIX developers"
	ewarn "directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn ""

	if ! use git; then
		UNIPATCH_LIST=(
			"${DISTDIR}/${PN}-${EGIT_COMMIT_KV}.patch"
		)
	fi

	kernel-2_pkg_setup
}

#universal_unpack() {
#	cd "${WORKDIR}" || die "chdir() to '${WORKDIR}' failed: ${?}"
#	unpack "${P}.tar.gz"
#
#	if [[ -n "${EGIT_COMMIT}" ]]; then
#		mv "linux-${EGIT_COMMIT}" "linux-${KV_FULL}"
#	fi
#	cd "${S}" || die "chdir() to '${S}' failed: ${?}"
#
#	# remove all backup files
#	find . -iname "*~" -exec rm {} \; 2>/dev/null
#}

#src_unpack() {
#	# We expect unipatch to fail :(
#	$( kernel-2_src_unpack ) ||
#		ewarn "kernel-2_src_unpack failed during unipatch," \
#			"but this is anticipated"
#}

kernel-2_insert_prepatch() {
	if use git; then
		# Make the kernel source directory a new git repo, and tag changes as
		# we progress through the build, for ease of later debugging...
		rm -rf "${S}"/.git
		#tar -C "${S}" -cpf "${T}"/gitignore.tar $( find . -name .gitignore ) ||
		#	die
		#find . -name .gitignore -delete || die
		set -x
		git config --global init.defaultBranch main
		git config --global user.name "Gentoo Portage"
		git config --global user.email larry@gentoo.org

		git -C "${S}" init . >/dev/null || die

		git config --global --add safe.directory "${S}"

		git -C "${S}" add --all --force .
		git -C "${S}" commit --quiet --signoff --message \
			 "Linux ${KV_MAJOR}.${KV_MINOR}" || die
		git -C "${S}" tag "linux-${KV_MAJOR}.${KV_MINOR}" || die

		git -C "${S}" status
		set +x
	fi
}

kernel-2_insert_premake() {
	if use git; then
		set -x
		git -C "${S}" add --all --force . || die
		git -C "${S}" commit --quiet --signoff --message "Linux ${PV}" ||
			die
		git -C "${S}" tag "linux-${PV}" || die
		set +x
	fi
}

src_prepare() {
	if use git; then
		eapply "${DISTDIR}/${PN}-${EGIT_COMMIT_KV}.patch" || die

		# Revert random mode-changes the CIX patch introduces...
		chmod 0644 \
			drivers/i3c/master/i3c-master-cdns.c \
			drivers/iio/magnetometer/Kconfig \
			drivers/iio/magnetometer/Makefile \
			drivers/mtd/spi-nor/winbond.c \
			drivers/spi/spi-cadence-xspi.c \
			drivers/staging/Kconfig drivers/staging/Makefile \
			include/linux/dma-buf.h \
			drivers/tty/serial/amba-pl011.c

		set -x
		git -C "${S}" add --all --force . || die
		git -C "${S}" commit --quiet --signoff --message "Linux ${PV}-cix" ||
			die
		git -C "${S}" tag "linux-${PV}-cix" || die
		set +x
	fi

	default

	if use git && (( ${#PATCHES[@]} )); then
		set -x
		git -C "${S}" add --all --force . || die
		git -C "${S}" commit --quiet --signoff --message "Linux ${PV}-cix+" ||
			die
		git -C "${S}" tag "linux-${PV}-cix+" || die

		[[ -s "${T}"/gitignore.tar ]] &&
			tar -C "${S}" -xpf "${T}"/gitignore.tar
		set +x
	fi
}

src_install() {
	kernel-2_src_install

	# e.g. linux-6.1.75 -> linux-6.1.75-cix-r1
	dodir /usr/src
	if [[ "${PR}" != 'r0' ]]; then
		mv "${ED}/usr/src/linux-${CKV}-${PR}"  \
			"${ED}/usr/src/linux-${CKV}-cix-${PR}" || die
	else
		mv "${ED}/usr/src/linux-${CKV}" \
			"${ED}/usr/src/linux-${CKV}-cix" || die
	fi
}

pkg_postinst() {
	kernel-2_pkg_postinst

	if use symlink; then
		if [[ "${PR}" != 'r0' ]]; then
			ln -snf "linux-${PV%_p*}-cix${PR}" "${EROOT}"/usr/src/linux || die
		else
			ln -snf "linux-${PV%_p*}-cix" "${EROOT}"/usr/src/linux || die
		fi
	fi
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
