# Copyright 2023-2024 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_COMMIT="92900c5c733c8b91a67b1772d4f0a25104f2b05d"
EGIT_REPO="utils"
#CMAKE_MAKEFILE_GENERATOR="emake"

inherit bash-completion-r1 cmake

DESCRIPTION="Raspberry Pi tools"
HOMEPAGE="https://github.com/raspberrypi/utils"
SRC_URI="https://github.com/raspberrypi/${EGIT_REPO}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="-* arm64 arm"
IUSE="bash-completion devicetree -otp -tools"

BDEPEND="
	>=dev-build/cmake-3.10
	sys-apps/dtc
	sys-apps/sed
"
RDEPEND="
	!sys-apps/raspberrypi-utilities-armv6
	!media-libs/raspberrypi-userland
	tools? (
		app-admin/sudo
		dev-embedded/rpi-eeprom
		sys-apps/fbset
		sys-apps/raspberrypi-gpio
		sys-apps/usbutils
	)
"

PATCHES=(
	"${FILESDIR}/${PN}-sh.patch"
	"${FILESDIR}/${PN}-warnings.patch"
	"${FILESDIR}/${PN}-Werror.patch"
	"${FILESDIR}/${PN}-gcc14.patch"
)

S="${WORKDIR}/${EGIT_REPO}-${EGIT_COMMIT}"

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

	sed -n -e '1N;2N;3N;4N;5N;/\napt-cache .*$/{N;N;N;N;N;d};P;N;D' \
		-i raspinfo/raspinfo

	rm README.md

	cat > "${T}"/rpi-issue <<-EOF
		Raspberry Pi reference 2024-11-19
		Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, 891df1e21ed2b6099a2e6a13e26c91dea44b34d4, stage4
	EOF

	# See https://github.com/raspberrypi/rpi-eeprom/issues/647
	sed -e '/#define MAX_STRING/ s/1024/4096/' \
		-i vcgencmd/vcgencmd.c ||
			die "sed failed on 'vcgencmd/vcgencmd.c': ${?}"

	cmake_src_prepare
}

src_install() {
	local bc_src='' bc_dst=''

	cmake_src_install

	dodir /usr/sbin
	for sbin in vcmailbox vclog vcgencmd pinctrl eepflash.sh otpset; do
		[[ -e "${ED}/usr/bin/${sbin}" ]] &&
			mv "${ED}/usr/bin/${sbin}" "${ED}"/usr/sbin/
	done

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

	rm -r "${ED}"/usr/share/bash-completion/ || die
	if use bash-completion; then
		for bc_src in */*-completion.bash; do
			bc_dst=${bc_src%-completion.bash}
			newbashcomp "${bc_src}" "${bc_dst##*/}"
		done
	fi

	[[ -d "${ED}"/usr/lib ]] && rmdir "${ED}"/usr/lib
}

pkg_postinst() {
	elog "'vclog' (from this package) is the open-source equivalent to the"
	elog "32bit-only 'vcdbg' tool (from raspberrypi-utilities-armv6 for ARM"
	elog "architectures)"
}
