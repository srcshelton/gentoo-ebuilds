# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="15"
#K_BASE_VER="${PV}"

K_SECURITY_UNSUPPORTED=1

##EXTRAVERSION="-${PN}/-*"
#K_NODRYRUN=1  # Fail early rather than trying -p0 to -p5, seems to fix unipatch()!
#K_NOSETEXTRAVERSION=1
#K_NOUSENAME=1
K_NOUSEPR=1

#K_EXP_GENPATCHES_NOUSE=1
K_DEBLOB_AVAILABLE=0

H_SUPPORTEDARCH="arm arm64"
#K_FROM_GIT=1

inherit kernel-2
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

EGIT_COMMIT="57e018a398248d7e5e4d798610df79a557c0629f"

DESCRIPTION="CIX sources including the Gentoo & Entropi patchsets for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
HOMEPAGE="https://github.com/Sky1-Linux/linux-sky1/
	https://dev.gentoo.org/~alicef/genpatches"
SRC_URI="https://github.com/Sky1-Linux/linux-sky1/archive/${EGIT_COMMIT}.tar.gz -> ${P}-${EGIT_COMMIT:0:7}.tar.gz
	${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}"
KEYWORDS="arm arm64"
IUSE="experimental"

COMMON_DEPEND="
	sys-libs/binutils-libs
	|| (
		~sys-kernel/cix-headers-${KV_MAJOR}.${KV_MINOR}
		~sys-kernel/linux-headers-${KV_MAJOR}.${KV_MINOR}
	)
"

pkg_setup() {
	ewarn
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the Radxa/CIX developers"
	ewarn "directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn

	kernel-2_pkg_setup
}

src_prepare() {
	local pf=''

	( cd "${WORKDIR}" && unpack "${P}-${EGIT_COMMIT:0:7}.tar.gz" ) || die

	while read -r pf; do
		eapply "${WORKDIR}/linux-sky1-${EGIT_COMMIT}/patches/${pf}" || die
	done < "${WORKDIR}/linux-sky1-${EGIT_COMMIT}/patches/series"

	rm -r "${WORKDIR}/linux-sky1-${EGIT_COMMIT}" || die

	eapply "${FILESDIR}"/0140-arm64-cix-fix-kconfig-deps-and-module-reachability.patch || die
	eapply "${FILESDIR}"/0141-cix-fix-deps-section-mismatch-and-clang-uninit-build-fail.patch || die
	eapply "${FILESDIR}"/0142-cix-sky1-fix-clang-build-warnings-in-config-dependent-paths.patch || die
	eapply "${FILESDIR}"/0143-drm-cix-linlon-dp-fix-symbol-clashes-and-clang-werror.patch || die
	eapply "${FILESDIR}"/0144-drm-cix-dptx-fix-clang-werror-in-component-bypass-builds.patch || die
	eapply "${FILESDIR}"/0145-armchina-npu-zhouyi-fix-missing-prototype-under-werror.patch || die
	eapply "${FILESDIR}"/0146-gpio-cadence-fix-pm-ops-when-pm-sleep-is-disabled.patch || die

	kernel-2_src_prepare
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
