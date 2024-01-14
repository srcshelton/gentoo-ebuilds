# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} )

inherit python-r1 systemd

MY_P="${PN}-$(ver_cut 1-2)"
MY_BASE_URL="https://archive.raspberrypi.org/debian/pool/main/r/${PN}/${PN}_$(ver_cut 1-2)"
DESCRIPTION="Updater for Raspberry Pi 4 bootloader and the VL805 USB controller"
HOMEPAGE="https://github.com/raspberrypi/rpi-eeprom/"
SRC_URI="${MY_BASE_URL}-$(ver_cut 4).debian.tar.xz
	${MY_BASE_URL}.orig.tar.gz"
RESTRICT="mirror"
S="${WORKDIR}"

LICENSE="BSD rpi-eeprom"
SLOT="0"
KEYWORDS="arm arm64"
IUSE="-old-firmware rpi5 systemd tools"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	old-firmware? ( !rpi5 )"

BDEPEND="sys-apps/help2man"
DEPEND="${PYTHON_DEPS}"
RDEPEND="${PYTHON_DEPS}
	sys-apps/flashrom[linux-spi]
	sys-apps/pciutils
	sys-devel/binutils
	|| (
		>=media-libs/raspberrypi-userland-0_pre20201022
		>=media-libs/raspberrypi-userland-bin-1.20201022
	)"

QA_PREBUILT="lib/firmware/raspberrypi/bootloader/*/*.bin usr/sbin/vl805"

src_prepare() {
	default
	sed \
			-i "${MY_P}/rpi-eeprom-update" \
			-e 's:/etc/default/rpi-eeprom-update:/etc/conf.d/rpi-eeprom-update:' ||
		die "Failed sed on rpi-eeprom-update"
	sed \
			-i "debian/rpi-eeprom.rpi-eeprom-update.service" \
			-e 's:/usr/bin/rpi-eeprom-update:/usr/sbin/rpi-eeprom-update:' ||
		die "Failed sed on rpi-eeprom.rpi-eeprom-update.service"
}

src_install() {
	pushd "${MY_P}" 1>/dev/null ||
		die "Cannot change into directory ${MY_P}"

	python_scriptinto /usr/sbin
	python_foreach_impl python_newscript rpi-eeprom-config rpi-eeprom-config
	use tools && python_foreach_impl python_newscript tools/rpi-bootloader-key-convert rpi-bootloader-key-convert

	dosbin rpi-eeprom-update rpi-eeprom-digest
	use tools && dosbin tools/rpi-otp-private-key
	use tools && [[ "${ARCH}" == 'arm' ]] && dosbin tools/vl805

	keepdir /var/lib/raspberrypi/bootloader/backup

	insinto /lib/firmware/raspberrypi/bootloader
	if use rpi5; then
		for dir in default latest; do
			doins -r firmware-2712/${dir}
		done

		dodoc firmware-2712/release-notes.md
	else
		for dir in default latest $(usex old-firmware old ''); do
			doins -r firmware-2711/${dir}
		done

		dodoc firmware-2711/release-notes.md
	fi
	# This is failing with:
	#  dosym: dosym target omits basename: '/lib/firmware/raspberrypi/bootloader/latest'
	#
	# ... for no reason I can tell?
	#
	# (It doesn't help that the dosym documentation labels the arguments
	# 'filename' and 'linkname")
	#
	#dosym -r beta /lib/firmware/raspberrypi/bootloader/latest
	#dosym -r stable /lib/firmware/raspberrypi/bootloader/latest
	#dosym -r critical /lib/firmware/raspberrypi/bootloader/default
	#dosym -r /lib/firmware/raspberrypi/bootloader/beta latest
	#dosym -r /lib/firmware/raspberrypi/bootloader/stable latest
	#dosym -r /lib/firmware/raspberrypi/bootloader/critical default
	#dosym -r /lib/firmware/raspberrypi/bootloader/beta /lib/firmware/raspberrypi/bootloader/latest
	#dosym -r /lib/firmware/raspberrypi/bootloader/stable /lib/firmware/raspberrypi/bootloader/latest
	#dosym -r /lib/firmware/raspberrypi/bootloader/critical /lib/firmware/raspberrypi/bootloader/default
	ln -s latest "${ED}"/lib/firmware/raspberrypi/bootloader/beta
	ln -s latest "${ED}"/lib/firmware/raspberrypi/bootloader/stable
	ln -s default "${ED}"/lib/firmware/raspberrypi/bootloader/critical

	help2man -N \
		--version-string="${PV}" --help-option="-h" \
		--name="Bootloader EEPROM configuration tool for the Raspberry Pi 4B" \
		--output=rpi-eeprom-config.1 ./rpi-eeprom-config || die "Failed to create manpage for rpi-eeprom-config"

	help2man -N \
		--version-string="${PV}" --help-option="-h" \
		--name="Checks whether the Raspberry Pi bootloader EEPROM is \
			up-to-date and updates the EEPROM" \
		--output=rpi-eeprom-update.1 ./rpi-eeprom-update || die "Failed to create manpage for rpi-eeprom-update"

	doman rpi-eeprom-update.1 rpi-eeprom-config.1

	newconfd rpi-eeprom-update-default rpi-eeprom-update

	popd 1>/dev/null || die

	pushd debian 1>/dev/null || die "Cannot change into directory debian"

	use systemd && systemd_newunit rpi-eeprom.rpi-eeprom-update.service rpi-eeprom-update.service
	newdoc changelog changelog.Debian

	popd 1>/dev/null || die

	newinitd "${FILESDIR}/init.d_rpi-eeprom-update-1" "rpi-eeprom-update"
}

pkg_postinst() {
	elog 'To have rpi-eeprom-update run at each startup, enable and start'
	if ! use systemd; then
		elog '    /etc/init.d/rpi-eeprom-update'
	else
		elog '    rpi-eeprom-update.service'
	fi
	elog '/etc/conf.d/rpi-eeprom-update contains the configuration.'
	elog 'FIRMWARE_RELEASE_STATUS="critical|stable|beta" determines'
	elog 'which release track you get. "critical" is recommended and the default.'
}
