# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )

inherit cmake optfeature python-single-r1

EGIT_COMMIT="6609ecb54f233d372d76b00caa12b292a6a9dba1"
EGIT_REPO="utils"

DESCRIPTION="Raspberry Pi scripts, diagnostic tools and support libraries"
HOMEPAGE="https://github.com/raspberrypi/utils"
SRC_URI="https://github.com/raspberrypi/${EGIT_REPO}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${EGIT_REPO}-${EGIT_COMMIT}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="-* arm arm64"
IUSE="+bash-completion +devicetree"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	${PYTHON_DEPS}
	>=dev-build/cmake-3.10
	virtual/pkgconfig
"
DEPEND="
	net-libs/gnutls:=
	sys-libs/ncurses:=
	devicetree? ( sys-apps/dtc )
"
RDEPEND="
	${PYTHON_DEPS}
	${DEPEND}
	!sys-apps/raspberrypi-utilities-armv6
	app-admin/sudo
	app-arch/tar
	app-arch/zstd
	bash-completion? ( app-shells/bash-completion )
	devicetree? ( dev-lang/perl )
	sys-apps/ethtool
	sys-apps/net-tools
	sys-apps/usbutils
"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	local -a python_scripts=(
		otamaker/otamaker
		otpset/otpset
		splashasm/splash_assembler.py
	)

	if use devicetree; then
		python_scripts+=(
			dtapply/dtapply
			overlaycheck/overlaycheck
			ovmerge/ovmerge
		)

		sed -e '1s:^#!/bin/env perl$:#!/usr/bin/perl:' \
			-i kdtc/kdtc || die "Failed to fix the kdtc shebang"
	else
		sed -e '/^add_subdirectory(dtapply)$/d' \
			-e '/^add_subdirectory(dtmerge)$/d' \
			-e '/^add_subdirectory(kdtc)$/d' \
			-e '/^add_subdirectory(overlaycheck)$/d' \
			-e '/^add_subdirectory(ovmerge)$/d' \
			-i CMakeLists.txt || die "Failed to disable device-tree tools"
	fi

	# raspinfo's package query is specific to Raspberry Pi OS, and /etc/rpi-issue
	# is optional outside images produced by pi-gen.
	sed -e '/^echo "Package version information"$/,/^apt-cache policy rpd-plym-splash | head -2$/d' \
		-e 's:^cat /etc/rpi-issue$:[ ! -f /etc/rpi-issue ] || cat /etc/rpi-issue:' \
		-e 's:^      if test -e \$F;$:      if command -v fbset >/dev/null \&\& test -e $F;:' \
		-i raspinfo/raspinfo || die "Failed to adapt raspinfo for Gentoo"

	python_fix_shebang "${python_scripts[@]}"
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=ON
		-DENABLE_WERROR=OFF
	)

	cmake_src_configure
}

src_install() {
	local docdir

	cmake_src_install

	# Retain the established Gentoo paths for commands that directly access
	# hardware or firmware.  rpi-eeprom-update locates rpi-eeprom-ab via PATH.
	dodir /usr/sbin
	for command in \
		eepflash.sh otpset pinctrl rpi-eeprom-ab \
		vcgencmd vclog vcmailbox
	do
		if [[ -e "${ED}/usr/bin/${command}" ]]; then
			mv "${ED}/usr/bin/${command}" "${ED}/usr/sbin/${command}" || die
		fi
	done

	if ! use devicetree; then
		# eepmake and eepdump are independent of the dtoverlay-based flasher.
		rm "${ED}/usr/sbin/eepflash.sh" || die
	fi

	if ! use bash-completion; then
		rm -r "${ED}/usr/share/bash-completion" || die
	fi

	dodoc README.md
	for docdir in \
		eeptools otamaker otpset pinctrl piolib raspinfo \
		rpi-gpu-usage rpieepromab rpifwcrypto splashasm vclog
	do
		newdoc "${docdir}/README.md" "${docdir}.md"
	done
	if use devicetree; then
		for docdir in dtapply dtmerge kdtc overlaycheck ovmerge; do
			newdoc "${docdir}/README.md" "${docdir}.md"
		done
	fi
}

pkg_postinst() {
	elog "rpi-eeprom-ab is installed for the BCM2712 A/B EEPROM service."
	elog "It will report unsupported hardware when that firmware service is absent."
	elog
	elog "'vclog' is the open-source equivalent of the 32-bit-only 'vcdbg'."

	optfeature "legacy framebuffer details in raspinfo" sys-apps/fbset
}
