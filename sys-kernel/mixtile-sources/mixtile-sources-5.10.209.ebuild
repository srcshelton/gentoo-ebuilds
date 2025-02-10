# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ETYPE="sources"
K_WANT_GENPATCHES="extras experimental"
K_GENPATCHES_VER="220"
K_BASE_VER="${PV}"

K_DEFCONFIG="rockchip_linux_defconfig"
K_SECURITY_UNSUPPORTED=1

#EXTRAVERSION="-${PN}/-*"
K_NODRYRUN=1  # Fail early rather than trying -p0 to -p5, seems to fix unipatch()!
K_NOSETEXTRAVERSION=1
K_NOUSENAME=1
K_NOUSEPR=1

K_EXP_GENPATCHES_NOUSE=1
K_DEBLOB_AVAILABLE=0

H_SUPPORTEDARCH="arm arm64"
K_FROM_GIT=1

inherit kernel-2
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

EGIT_COMMIT="85259f5e679a07c2d24c463692c56ef75a3094da"

DESCRIPTION="Third-party Rockchip kernel sources"
HOMEPAGE="https://github.com/mixtile-rockchip/linux-rockchip/"
SRC_URI="
	https://github.com/mixtile-rockchip/linux-rockchip/archive/${EGIT_COMMIT}.tar.gz -> mixtile-rockchip-${PV}.tar.gz
	${GENPATCHES_URI}
	${ARCH_URI}
"
RESTRICT="mirror"

KEYWORDS="arm arm64"

UNIPATCH_LIST=(
	"${FILESDIR}/${PN}-5.15.32-gentoo-Kconfig.patch"
	"${FILESDIR}"/orange-pi-5-max.patch
	"${FILESDIR}"/orange-pi-cm5.patch
	"${FILESDIR}"/firefly-aio-3588l.patch
	"${FILESDIR}"/armsom-aim7.patch
	"${FILESDIR}"/ubuntu-rockchip-5.10.0-1011.11.patch
	"${FILESDIR}"/ubuntu-bpf.patch
	"${FILESDIR}"/ubuntu-u-boot-menu.patch
	"${FILESDIR}"/ubuntu-rockchip-5.10.0-1012.12.patch
	
)

S="${WORKDIR}/linux-${CKV}"

pkg_setup() {
	ewarn ""
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the Mixtile/Rockchip developers"
	ewarn "directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn ""

	kernel-2_pkg_setup
}

universal_unpack() {
	cd "${WORKDIR}" || die "chdir() to '${WORKDIR}' failed: ${?}"
	unpack "${P}.tar.gz"

	if [[ -n "${EGIT_COMMIT}" ]]; then
		mv "linux-rockchip-${EGIT_COMMIT}" "linux-${KV_FULL}"
	fi
	cd "${S}" || die "chdir() to '${S}' failed: ${?}"

	# remove all backup files
	find . -iname "*~" -exec rm {} \; 2>/dev/null
}

src_unpack() {
	# We expect unipatch to fail :(
	$( kernel-2_src_unpack ) ||
		ewarn "kernel-2_src_unpack failed during unipatch," \
			"but this is anticipated"
}

src_install() {
	default

	kernel-2_src_install
}

src_install() {
	# e.g. linux-5.10.209 -> linux-5.10.209-mixtile-r1
	dodir /usr/src
	if [[ "${PR}" != 'r0' ]]; then
		mv "${S}" "${ED}/usr/src/linux-${CKV}-mixtile${PR}"
	else
		mv "${S}" "${ED}/usr/src/linux-${CKV}-mixtile"
	fi
}

pkg_postinst() {
	kernel-2_pkg_postinst

	if use symlink; then
		if [[ "${PR}" != 'r0' ]]; then
			ln -snf "linux-${PV%_p*}-mixtile${PR}" "${EROOT}"/usr/src/linux || die
		else
			ln -snf "linux-${PV%_p*}-mixtile" "${EROOT}"/usr/src/linux || die
		fi
	fi
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
