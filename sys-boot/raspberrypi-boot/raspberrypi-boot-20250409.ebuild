# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_COMMIT="ecfb7222788735bd3b4714b0126f71025ae252da"
EGIT_SUBMODULE_COMMIT="914dd0f73f0d6b9d1bc6ee21f17cb2a705b57140"

RPI_MODELS=" rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3"
RPI4_MODELS=" rpi4 rpi400 rpi-cm4 rpi-cm4s"
RPI5_MODELS=" rpi5 rpi500 rpi-cm5"

DESCRIPTION="Raspberry Pi USB Device Boot Code"
HOMEPAGE="https://github.com/raspberrypi/usbboot"
SRC_URI="https://github.com/raspberrypi/usbboot/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz
	https://github.com/raspberrypi/rpi-eeprom/archive/${EGIT_SUBMODULE_COMMIT}.tar.gz -> rpi-eeprom-${EGIT_SUBMODULE_COMMIT}.tar.gz"
IUSE="+64bit examples deprecated pdf${RPI_MODELS}${RPI4_MODELS// / +}${RPI5_MODELS// / +} -secure-boot +tools"
REQUIRED_USE="
	64bit? ( || (${RPI4_MODELS}${RPI5_MODELS} ) )
	examples? ( secure-boot )
	pdf? ( secure-boot )
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64 arm x86"
RESTRICT="mirror"

DEPEND="
	virtual/libusb
	virtual/os-headers
"
RDEPEND="${DEPEND}"

S="${WORKDIR}/usbboot-${EGIT_COMMIT}"

src_prepare() {
	if [[ -e rpi-eeprom ]]; then
		if ! [[ -d rpi-eeprom && -f rpi-eeprom/rpi-eeprom-config ]]; then
			rm -rf rpi-eeprom
			mv "${WORKDIR}/rpi-eeprom-${EGIT_SUBMODULE_COMMIT}" rpi-eeprom
		fi
	fi

	sed -e '/^GIT_VER=/s/=/ ?= /' \
		-i Makefile

	export GIT_VER="${EGIT_COMMIT}"

	default
}

src_install() {
	local model='' link='' target=''
	local -i ins_rpi=0 ins_rpi4=0 ins_rpi5=0

	for model in ${RPI_MODELS}; do
		if use ${model}; then
			ins_rpi=1
		fi
	done
	for model in ${RPI4_MODELS}; do
		if use ${model}; then
			ins_rpi4=1
		fi
	done
	for model in ${RPI5_MODELS}; do
		if use ${model}; then
			ins_rpi5=1
		fi
	done

	newdoc Readme.md README.md
	if use pdf; then
		dodoc docs/*.pdf
	fi

	dobin rpiboot

	insinto "/usr/share/${PN/-//}"
	if (( ins_rpi )); then
		doins msd/bootcode.bin msd/start.elf
	fi
	if use deprecated && (( ins_rpi4 )); then
		cp "$( realpath -e msd/bootcode4.bin )" "${ED%/}/usr/share/${PN/-//}/"
		doins msd/start.elf
	fi
	if use tools; then
		doins -r rpi-imager-embedded # mass-storage-gadget
		doins -r mass-storage-gadget64
		dosym -r "/usr/share/${PN/-//}/mass-storage-gadget64" \
			"/usr/share/${PN/-//}/mass-storage-gadget"
		insinto "/usr/share/${PN/-//}/firmware"
		doins firmware/bootfiles.bin
	fi

	if (( ins_rpi4 || ins_rpi5 )); then
		# Since EAPI 4, symlinks are preserved rather than dereferenced, which
		# isn't what we want...
		find firmware -type l -print | while read -r link; do
			if ! target="$( realpath -e "${link}" )" || ! [[ -f "${target}" ]]
			then
				die "Failed to canonicalise path for symlink '${link}': ${?}"
			fi
			einfo "Replacing symlink '${link}' with file '${target}' ..."
			rm "${link}" || die
			cp -a "${target}" "${link}" || die
		done

		if (( ins_rpi4 )); then
			insinto "/usr/share/${PN/-//}/firmware/2711"
			doins firmware/2711/bootcode4.bin

			insinto "/var/lib/${PN/-//}/firmware/2711"
			doins firmware/2711/*.bin

			if [[ -f "${ED%/}/usr/share/${PN/-//}/firmware/2711/bootcode4.bin" ]] &&
					[[ -f "${ED%/}/var/lib/${PN/-//}/firmware/2711/bootcode4.bin" ]]
			then
				rm "${ED%/}/var/lib/${PN/-//}/firmware/2711/bootcode4.bin"
				dosym -r "/usr/share/${PN/-//}/firmware/2711/bootcode4.bin" \
					"/var/lib/${PN/-//}/firmware/2711/bootcode4.bin"
			fi
		fi

		if (( ins_rpi5 )); then
			insinto "/var/lib/${PN/-//}/firmware/2712"
			doins -r firmware/2712/*.bin
		fi
	fi

	insinto "/var/lib/${PN/-//}/firmware"
	doins firmware/*.bin

	insinto "/var/lib/${PN/-//}"
	if use tools; then
		doins -r eeprom-erase recovery
		if (( ins_rpi5 )); then
			doins -r recovery5
		fi
		exeinto "/var/lib/${PN/-//}/recovery"
		doexe recovery/update-pieeprom.sh
		exeinto "/var/lib/${PN/-//}/tools"
		doexe tools/*
	fi
	if use secure-boot; then
		doins -r secure-boot-{msd,recovery}
		if (( ins_rpi5 )); then
			doins -r secure-boot-recovery5
		fi
		if use examples; then
			doins -r secure-boot-example
		fi
	fi

	find "${ED}" -type f -name '.gitignore' -delete
}

pkg_postinst() {
	elog "To access a Raspberry Pi SBC as a USB device, run:"
	elog
	elog "    /usr/bin/rpiboot -d /usr/share/${PN/-//}"
	if use tools; then
		elog
		elog "Additional static firmware payloads can be found in"
		elog "/usr/share/${PN/-//} with configurable payloads"
		elog "in /var/lib/${PN/-//}"
	fi
	elog
	elog "'rpiboot' does not need elevated privileges to run, so long as the"
	elog "user executing the command has write access to /dev/bus/usb"
}
