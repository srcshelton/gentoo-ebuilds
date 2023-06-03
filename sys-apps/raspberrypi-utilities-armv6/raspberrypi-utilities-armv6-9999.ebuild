# Copyright 2015 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

DESCRIPTION="Raspberry Pi closed-source userspace tools"
HOMEPAGE="https://github.com/raspberrypi/firmware"
SRC_URI=""

LICENSE="Broadcom"
SLOT="0/0"
KEYWORDS="-*"

RDEPEND="
	media-libs/raspberrypi-userland
	!sys-apps/raspberrypi-tools
"

EGIT_REPO_URI="https://github.com/raspberrypi/firmware"
# The current repo is ~4GB in size, but contains only ~200MB of data - the rest
# is (literally) history :(
EGIT_CLONE_TYPE="shallow"

RESTRICT="strip"
QA_PREBUILT=""

src_install() {
	local bin name

	for bin in hardfp/opt/vc/bin/*; do
		name="$( basename "${bin}" )"
		[[ "${name}" =~ ^containers_ ]] && continue

		if grep -q " /usr/bin/${name} " /var/db/pkg/media-libs/raspberrypi-userland-*/CONTENTS; then
			einfo "Skipping existing binary '${name}' ..."
		else
			dobin "${bin}"
			QA_PREBUILT+="${QA_PREBUILT:+ }usr/bin/${name}"
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
