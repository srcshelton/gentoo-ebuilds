# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_COMMIT="dce7f60c78e16794c8a03ba1f0089fec1d23a873"

DESCRIPTION="Raspberry Pi USB Device Boot Code"
HOMEPAGE="https://github.com/raspberrypi/usbboot"
SRC_URI="https://github.com/raspberrypi/usbboot/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
IUSE="examples pdf -secure-boot +tools"
REQUIRED_USE="
	examples? ( secure-boot )
	pdf? ( secure-boot )
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64 arm x86"
RESTRICT="mirror"

DEPEND="virtual/libusb"
RDEPEND="${DEPEND}"

S="${WORKDIR}/usbboot-${EGIT_COMMIT}"

PATCHES=( #
	"${FILESDIR}"/rpiboot-custom-flags.patch
)

src_install() {
	newdoc Readme.md README.md
	if use pdf; then
		dodoc docs/*.pdf
	fi

	dobin rpiboot

	insinto "/usr/share/${PN/-//}"
	doins bootcode4.bin msd/bootcode.bin msd/*.elf
	if use tools; then
		doins -r mass-storage-gadget rpi-imager-embedded
	fi

	insinto "/var/lib/${PN/-//}"
	doins recovery.bin
	if use tools; then
		doins -r eeprom-erase recovery
		exeinto "/var/lib/${PN/-//}/recovery"
		doexe recovery/update-pieeprom.sh
		exeinto "/var/lib/${PN/-//}/tools"
		doexe tools/*
	fi
	if use secure-boot; then
		doins -r secure-boot-{msd,recovery}
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
