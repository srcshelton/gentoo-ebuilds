# Copyright 2015-2021 Gentoo Authors, Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Raspberry Pi closed-source userspace tools"
HOMEPAGE="https://github.com/raspberrypi/firmware"
# Share with sys-boot/raspberrypi-firmware
#SRC_URI="https://github.com/raspberrypi/firmware/archive/${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://github.com/raspberrypi/firmware/archive/${PV}.tar.gz -> raspberrypi-firmware-${PV}.tar.gz"

LICENSE="Broadcom"
SLOT="0/0"
KEYWORDS="~aarch64 arm -*"
IUSE=""

BDEPEND="media-libs/raspberrypi-userland"
DEPEND="${BDEPEND}"
# vcdbg is linked against libelftoolchain.so, which is is the firmware repo :(
RDEPEND="sys-boot/raspberrypi-firmware"

RESTRICT="binchecks mirror strip"
QA_PREBUILT=""

S="${WORKDIR}/firmware-${PV}"

src_install() {
	local bin name

	for bin in hardfp/opt/vc/bin/*; do
		name="$( basename "${bin}" )"
		[[ "${name}" =~ ^containers_ ]] && continue

		if grep -q " /usr/bin/${name} " /var/db/pkg/media-libs/raspberrypi-userland-*/CONTENTS; then
			einfo "Skipping existing binary '${name}' ..."
		else
			dobin "${bin}"
			QA_PREBUILT+="${QA_PREBUILT:+ }/usr/bin/${name}"
		fi
	done
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
