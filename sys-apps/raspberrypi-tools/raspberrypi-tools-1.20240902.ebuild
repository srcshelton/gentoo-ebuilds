# Copyright 2023-2024 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_COMMIT="6dc6f5f3d129a6c9423316ac1a53efb19a5c40d1"
EGIT_REPO="utils"

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
	tools? (
		app-admin/sudo
		dev-embedded/rpi-eeprom
		sys-apps/fbset
		sys-apps/raspberrypi-gpio
		sys-apps/usbutils
	)
"
#	tools? ( media-libs/raspberrypi-userland )
# FIXME: media-libs/raspberrypi-userland is deprecated - what here depends on it?

S="${WORKDIR}/${EGIT_REPO}-${EGIT_COMMIT}"
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

	sed -n -e '1N;2N;3N;4N;5N;/\napt-cache .*$/{N;N;N;N;N;d};P;N;D' \
		-i raspinfo/raspinfo

	rm README.md

	cat > "${T}"/rpi-issue <<-EOF
		Raspberry Pi reference 2023-02-21
		Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, 25e2319effa91eb95edd9d9209eb9f8a584d67be, stage4
	EOF

	cmake_src_prepare
}

#src_configure() {
#	cmake_src_configure
#}

#src_compile() {
#	cmake_src_compile
#}

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
