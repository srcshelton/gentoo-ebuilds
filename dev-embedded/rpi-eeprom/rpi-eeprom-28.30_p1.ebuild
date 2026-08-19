# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )

inherit python-single-r1 systemd

MY_P="${PN}-$(ver_cut 1-2)"
MY_BASE_URL="https://archive.raspberrypi.org/debian/pool/main/r/${PN}/${PN}_$(ver_cut 1-2)"

DESCRIPTION="Bootloader EEPROM firmware and updater for Raspberry Pi 4 and 5"
HOMEPAGE="https://github.com/raspberrypi/rpi-eeprom/"
SRC_URI="${MY_BASE_URL}-$(ver_cut 4).debian.tar.xz
	${MY_BASE_URL}.orig.tar.gz"
S="${WORKDIR}"

LICENSE="BSD rpi-eeprom"
SLOT="0"
KEYWORDS="-* arm arm64"
IUSE="deprecated old-firmware rpi5 rpi500 rpi500plus rpi-cm5 systemd"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	old-firmware? ( deprecated )"

BDEPEND="
	${PYTHON_DEPS}
	sys-apps/help2man
"
RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep 'dev-python/pycryptodome[${PYTHON_USEDEP}]')
	>=sys-apps/raspberrypi-tools-1.20260811
	sys-apps/flashrom[linux-spi]
	sys-apps/pciutils
	sys-devel/binutils
"

RESTRICT="mirror"
QA_PREBUILT="lib/firmware/raspberrypi/bootloader/*/*.bin usr/sbin/vl805"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	default

	sed -e 's:/etc/default/rpi-eeprom-update:/etc/conf.d/rpi-eeprom-update:' \
		-i "${MY_P}/rpi-eeprom-update" ||
		die "Failed to set the updater configuration path"
	sed -e 's:/usr/bin/rpi-eeprom-update:/usr/sbin/rpi-eeprom-update:' \
		-i debian/rpi-eeprom.rpi-eeprom-update.service ||
		die "Failed to set the updater service path"
	sed -e '/FIRMWARE_ROOT/s:/usr/lib/firmware/:/lib/firmware/:' \
		-i "${MY_P}/rpi-eeprom-update-default" ||
		die "Failed to set the firmware path"

	# Gentoo's pycryptodome exposes the Crypto namespace.  The upstream
	# scripts use the alternative pycryptodomex namespace.
	sed -e 's/^from Cryptodome/from Crypto/' \
		-i "${MY_P}"/tools/{rpi-bootloader-key-convert,rpi-sign-bootcode} ||
		die "Failed to select the installed PyCryptodome namespace"

	python_fix_shebang \
		"${MY_P}/rpi-eeprom-config" \
		"${MY_P}/tools/rpi-bootloader-key-convert" \
		"${MY_P}/tools/rpi-sign-bootcode"
}

src_install() {
	local firmware_family=2711
	local firmware_root=/lib/firmware/raspberrypi/bootloader

	if use rpi5 || use rpi500 || use rpi500plus || use rpi-cm5; then
		firmware_family=2712
	fi

	pushd "${MY_P}" >/dev/null || die "Cannot enter ${MY_P}"

	dosbin \
		rpi-eeprom-config \
		rpi-eeprom-update \
		rpi-eeprom-digest \
		tools/rpi-bootloader-key-convert \
		tools/rpi-sign-bootcode
	dobin rpi-bootloader-version
	if use deprecated; then
		dosbin tools/rpi-otp-private-key
		if [[ ${ARCH} == arm ]]; then
			dosbin tools/vl805
		fi
	fi

	keepdir /var/lib/raspberrypi/bootloader/backup

	insinto "${firmware_root}"
	doins -r "firmware-${firmware_family}/default"
	doins -r "firmware-${firmware_family}/latest"
	if use old-firmware; then
		doins -r "firmware-${firmware_family}/old"
	fi
	doins "firmware-${firmware_family}/versions.txt"

	dosym latest "${firmware_root}/beta"
	dosym latest "${firmware_root}/stable"
	dosym default "${firmware_root}/critical"

	dodoc README.md releases.md
	newdoc "firmware-${firmware_family}/release-notes.md" release-notes.md

	help2man -N \
		--version-string="${PV}" --help-option="-h" \
		--name="Bootloader EEPROM configuration tool for Raspberry Pi" \
		--output=rpi-eeprom-config.1 ./rpi-eeprom-config ||
		die "Failed to create the rpi-eeprom-config man page"
	help2man -N \
		--version-string="${PV}" --help-option="-h" \
		--name="Check and update the Raspberry Pi bootloader EEPROM" \
		--output=rpi-eeprom-update.1 ./rpi-eeprom-update ||
		die "Failed to create the rpi-eeprom-update man page"
	doman rpi-eeprom-config.1 rpi-eeprom-update.1

	newconfd rpi-eeprom-update-default rpi-eeprom-update
	popd >/dev/null || die

	use systemd && systemd_newunit \
		debian/rpi-eeprom.rpi-eeprom-update.service \
		rpi-eeprom-update.service
	newdoc debian/changelog changelog.Debian
	newinitd "${FILESDIR}/init.d_rpi-eeprom-update-1" rpi-eeprom-update
}

pkg_postinst() {
	elog "To check for EEPROM updates at each startup, enable:"
	if use systemd; then
		elog "    rpi-eeprom-update.service"
	else
		elog "    /etc/init.d/rpi-eeprom-update"
	fi
	elog
	elog "/etc/conf.d/rpi-eeprom-update contains the updater configuration."
	elog "FIRMWARE_RELEASE_STATUS accepts 'default' or 'latest'; the legacy"
	elog "'critical', 'stable' and 'beta' names remain as compatibility aliases."

	if use rpi5 || use rpi500 || use rpi500plus || use rpi-cm5; then
		elog
		elog "On BCM2712, rpi-eeprom-update uses rpi-eeprom-ab automatically when"
		elog "the firmware A/B service is available. AB_EEPROM_FORCE_COMMIT defaults"
		elog "to 1; set it to 0 if you want to test-boot before committing manually."
	fi
}
