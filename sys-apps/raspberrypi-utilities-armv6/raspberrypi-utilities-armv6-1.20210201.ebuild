# Copyright 2015-2021 Gentoo Authors, Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Raspberry Pi closed-source userspace tools"
HOMEPAGE="https://github.com/raspberrypi/firmware"
# Share with sys-boot/raspberrypi-firmware
#SRC_URI="https://github.com/raspberrypi/firmware/archive/${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://github.com/raspberrypi/firmware/archive/${PV}.tar.gz -> raspberrypi-firmware-${PV}.tar.gz"

LICENSE="Broadcom"
SLOT="0/0"
KEYWORDS="~aarch64 arm -*"
IUSE="-containers devicetree tools"

BDEPEND="media-libs/raspberrypi-userland"
DEPEND="${BDEPEND}"
# vcdbg is linked against libelftoolchain.so, which is is the firmware repo :(
RDEPEND="sys-boot/raspberrypi-firmware"

RESTRICT="mirror strip"

S="${WORKDIR}/firmware-${PV}"

src_install() {
	local bin name

	if ! [[ -s "${EROOT}/var/db/pkg/$(best_version -r media-libs/raspberrypi-userland)/CONTENTS" ]]; then
		die "Cannot read list of installed files for package 'media-libs/raspberrypi-userland'"
	fi

	for bin in hardfp/opt/vc/bin/*; do
		name="$( basename "${bin}" )"
		use !containers && [[ "${name}" =~ ^containers_ ]] && continue

		if grep -q "bin/${name} " "${EROOT}/var/db/pkg/$(best_version -r media-libs/raspberrypi-userland)/CONTENTS"; then
			einfo "Skipping existing binary '${name}' ..."
		else
			if ! use devicetree; then
				# Keep this list sync'd with media-libs/raspberrypi-userland...
				if [[ "${name}" =~ ^(dtmerge|dtoverlay|dtoverlay-post|dtoverlay-pre|dtparam)$ ]]; then
					einfo "Skipping binary '${name}' due to USE='-devicetree'"
					continue
				fi
			fi
			if ! use tools; then
				# Keep this list sync'd with media-libs/raspberrypi-userland...
				if [[ "${name}" =~ ^(mmal_vc_diag|vchiq_test|vcmailbox|vcsmem)$ ]]; then
					einfo "Skipping binary '${name}' due to USE='-tools'"
					continue
				fi
			fi
			case "${name}" in
				# Keep this list sync'd with media-libs/raspberrypi-userland...
				mmal_vc_diag|vcgencmd|vchiq_test|vcmailbox|vcsmem)
					dosbin "${bin}"
					QA_PREBUILT+="${QA_PREBUILT:+ }/usr/sbin/${name}"
					;;
				*)
					dobin "${bin}"
					QA_PREBUILT+="${QA_PREBUILT:+ }/usr/bin/${name}"
					;;
			esac
		fi
	done

	export QA_PREBUILT
}

pkg_postinst() {
	ewarn "Is is possible that Broadcom may decide to open-source more of the"
	ewarn "Raspberry Pi firmware binaries, in which case updating"
	ewarn "media-libs/raspberrypi-userland may fail with merge conflicts."
	ewarn
	ewarn "If this occurs, simply remove ${CATEGORY}/${PN},"
	ewarn "reinstall media-libs/raspberrypi-userland, and finally emerge"
	ewarn "${CATEGORY}/${PN} again if closed-source binaries still exist."
}
