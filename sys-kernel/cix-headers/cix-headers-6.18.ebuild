# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ETYPE="headers"
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version

EGIT_COMMIT="57e018a398248d7e5e4d798610df79a557c0629f"
KV_MINOR=14

PATCH_PV=${PV} # to ease testing new versions against not existing patches
PATCH_VER="1"
PATCH_DEV="sam"
SRC_URI="
	${KERNEL_URI}
	https://github.com/Sky1-Linux/linux-sky1/archive/${EGIT_COMMIT}.tar.gz -> cix-sources-${PV}.${KV_MINOR}-${EGIT_COMMIT:0:7}.tar.gz
	${PATCH_VER:+https://dev.gentoo.org/~${PATCH_DEV}/distfiles/sys-kernel/linux-headers/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
"
S="${WORKDIR}/linux-${PV}"

KEYWORDS="arm arm64"

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl
	net-misc/rsync
"
DEPEND="
	!sys-kernel/linux-headers
"
RDEPEND="${DEPEND}"

src_unpack() {
	# Avoid kernel-2_src_unpack
	default
}

src_prepare() {
	local pf=''
	local -a PATCHES=()

	( cd "${WORKDIR}" && unpack "cix-sources-${PV}.${KV_MINOR}-${EGIT_COMMIT:0:7}.tar.gz" ) || die

	while read -r pf; do
		case "${pf}" in
			0117-*)
				continue ;;
		esac
		PATCHES+=( "${WORKDIR}/linux-sky1-${EGIT_COMMIT}/patches/${pf}" )
	done < "${WORKDIR}/linux-sky1-${EGIT_COMMIT}/patches/series"

	PATCHES+=(
		"${FILESDIR}/0140-arm64-cix-fix-kconfig-deps-and-module-reachability.patch"
		"${FILESDIR}/0141-cix-fix-deps-section-mismatch-and-clang-uninit-build-fail.patch"
		"${FILESDIR}/0142-cix-sky1-fix-clang-build-warnings-in-config-dependent-paths.patch"
		"${FILESDIR}/0143-drm-cix-linlon-dp-fix-symbol-clashes-and-clang-werror.patch"
		"${FILESDIR}/0144-drm-cix-dptx-fix-clang-werror-in-component-bypass-builds.patch"
		"${FILESDIR}/0145-armchina-npu-zhouyi-fix-missing-prototype-under-werror.patch"
		"${FILESDIR}/0146-gpio-cadence-fix-pm-ops-when-pm-sleep-is-disabled.patch"
	)

	[[ -n ${PATCH_VER} ]] && PATCHES+=( "${WORKDIR}/${PATCH_PV}" )

	# TODO: May need forward porting to newer versions
	use elibc_musl && PATCHES+=(
		"${FILESDIR}/${PN}-5.15-remove-inclusion-sysinfo.h.patch"
	)

	# Avoid kernel-2_src_prepare
	default
}

src_install() {
	kernel-2_src_install

	find "${ED}" \( -name '.install' -o -name '*.cmd' \) -delete || die
	# Delete empty directories
	find "${ED}" -empty -type d -delete || die
}
