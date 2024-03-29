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
IUSE="systemd"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

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

QA_PREBUILT="/lib/firmware/raspberrypi/bootloader/*/*.bin"

src_prepare() {
	default
	sed -i \
		-e 's:/etc/default/rpi-eeprom-update:/etc/conf.d/rpi-eeprom-update:' \
		"${MY_P}/rpi-eeprom-update" || die "Failed sed on rpi-eeprom-update"
	sed -i \
		-e 's:/usr/bin/rpi-eeprom-update:/usr/sbin/rpi-eeprom-update:' \
		"debian/rpi-eeprom.rpi-eeprom-update.service" || die "Failed sed on rpi-eeprom.rpi-eeprom-update.service"
}

src_install() {
	pushd "${MY_P}" 1>/dev/null || die "Cannot change into directory ${MY_P}"

	python_scriptinto /usr/sbin
	python_foreach_impl python_newscript rpi-eeprom-config rpi-eeprom-config

	dosbin rpi-eeprom-update rpi-eeprom-digest
	keepdir /var/lib/raspberrypi/bootloader/backup

	insinto /lib/firmware/raspberrypi/bootloader
	for dir in critical stable beta; do
		doins -r firmware/${dir}
	done
	dosym critical /lib/firmware/raspberrypi/bootloader/default
	dosym stable /lib/firmware/raspberrypi/bootloader/latest

	dodoc firmware/release-notes.md

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
