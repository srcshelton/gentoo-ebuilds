# Copyright 2023 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Raspberry Pi tools"
HOMEPAGE="https://github.com/raspberrypi/utils"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS="-* ~arm64 ~arm"
IUSE="devicetree -otp -tools"

BDEPEND="
	>=dev-util/cmake-3.10
	sys-apps/dtc
	sys-apps/sed
"
RDEPEND="
	!sys-apps/raspberrypi-utilities-armv6
	tools? (
		app-admin/sudo
		dev-embedded/rpi-eeprom
		media-libs/raspberrypi-userland
		sys-apps/fbset
		sys-apps/raspberrypi-gpio
		sys-apps/usbutils
	)
"

EGIT_REPO_URI="https://github.com/raspberrypi/utils"
EGIT_CLONE_TYPE="shallow"

DOCS=()

src_prepare() {
	local -a sed_cmds=()

	sed_cmds+=( '-e "/^add_subdirectory(overlaycheck)$/d"' )
	if ! use devicetree; then
		sed_cmds+=( # <- Syntax
			'-e "/^add_subdirectory(dtmerge)$/d"'
			'-e "/^add_subdirectory(ovmerge)$/d"'
		)
	fi
	if ! use otp; then
		sed_cmds+=( '-e "/^add_subdirectory(otpset)$/d"' )
	fi
	if ! use tools; then
		sed_cmds+=( '-e "/^add_subdirectory(raspinfo)$/d"' )
	fi
	eval sed \
		"${sed_cmds[@]}" \
		-i CMakeLists.txt

	sed -n -e '1N;2N;3N;4N;5N;/\napt-cache .*$/{N;N;N;N;N;d};P;N;D'
		-i raspinfo/raspinfo

	rm README.md

	cat > "${T}"/rpi-issue <<-EOF
		Raspberry Pi reference 2023-02-21
		Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, 25e2319effa91eb95edd9d9209eb9f8a584d67be, stage4
	EOF

	cmake_src_prepare
}

src_configure() {
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
}

src_install() {
	cmake_src_install

	insinto /etc
	doins "${T}"/rpi-issue

	newdoc vclog/README.md vclog.md
	if use devicetree; then
		newdoc dtmerge/README.md dtmerge.md
		newdoc ovmerge/README.md ovmerge.md
	fi
	if use otp; then
		newdoc otpset/README.md otpset.md
	fi
}

pkg_postinst() {
	elog "'vclog' (from this package) is the open-source equivalent to the"
	elog "32bit-only 'vcdbg' tool (from raspberrypi-utilities-armv6 for ARM"
	elog "architectures)"
}
