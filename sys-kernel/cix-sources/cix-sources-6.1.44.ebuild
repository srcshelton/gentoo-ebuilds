# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ETYPE="sources"
K_WANT_GENPATCHES="extras experimental"
K_GENPATCHES_VER="50"
K_BASE_VER="${PV}"

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

inherit kernel-2 linux-info
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

EGIT_COMMIT="f23e892a27cbb83f6a34a3cc3fe10743fde9d8c6"

DESCRIPTION="CIX kernel sources"
HOMEPAGE="https://gitlab.com/cix-linux/cix_opensource/linux"
SRC_URI="
	https://gitlab.com/cix-linux/cix_opensource/linux/-/archive/${EGIT_COMMIT}/linux-${EGIT_COMMIT}.tar.bz2 -> ${P}.tar.bz2
	${GENPATCHES_URI}
	${ARCH_URI}
"
RESTRICT="mirror"

KEYWORDS="arm arm64"

#UNIPATCH_LIST=(
#	"${FILESDIR}/${PN}-6.1.21-gentoo-Kconfig.patch"
#)

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
	unpack "${P}.tar.bz2"

	if [[ -n "${EGIT_COMMIT}" ]]; then
		mv "linux-${EGIT_COMMIT}" "linux-${KV_FULL}"
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
	# e.g. linux-6.1.75 -> linux-6.1.75-cix-r1
	dodir /usr/src
	if [[ "${PR}" != 'r0' ]]; then
		mv "${S}" "${ED}/usr/src/linux-${CKV}-cix${PR}"
	else
		mv "${S}" "${ED}/usr/src/linux-${CKV}-cix"
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
