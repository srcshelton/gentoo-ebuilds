# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Most up-to-date uCode for the Broadcom wifi chips on Raspberry Pi SBCs"
HOMEPAGE="
	https://github.com/RPi-Distro/firmware-nonfree
	https://archive.raspberrypi.org/debian/pool/main/f/firmware-nonfree"
MY_PN=firmware-nonfree
SRC_URI="https://archive.raspberrypi.org/debian/pool/main/f/${MY_PN}/${MY_PN}_$(ver_cut 1)-$(ver_cut 2)~bpo12+1+rpt$(ver_cut 4).debian.tar.xz"
S="${WORKDIR}"

LICENSE="Broadcom"
SLOT="0"
KEYWORDS="arm arm64"

RDEPEND="
	net-wireless/wireless-regdb
	!sys-kernel/linux-firmware[-savedconfig]
"

pkg_pretend() {
	local -a BADFILES=()
	local txt file

	# /lib/firmware/brcm/brcmfmac434{30,36,55,56}-sdio.*.txt
	#
	# The above pattern works because the files we want to hit
	# have names of the form:
	#
	# * /lib/firmware/brcm/brcmfmac43430-sdio.AP6212.txt
	# * /lib/firmware/brcm/brcmfmac43430-sdio.Hampoo-D2D3_Vi8A1.txt
	# * /lib/firmware/brcm/brcmfmac43430-sdio.MUR1DX.txt
	# * /lib/firmware/brcm/brcmfmac43430-sdio.ilife-S806.txt
	# * /lib/firmware/brcm/brcmfmac43430-sdio.raspberrypi,3-model-b.txt
	# * /lib/firmware/brcm/brcmfmac43430a0-sdio.ONDA-V80 PLUS.txt
	# * /lib/firmware/brcm/brcmfmac43430a0-sdio.ilife-S806.txt
	# * /lib/firmware/brcm/brcmfmac43430a0-sdio.jumper-ezpad-mini3.txt
	# * /lib/firmware/brcm/brcmfmac43455-sdio.AW-CM256SM.txt
	# * /lib/firmware/brcm/brcmfmac43455-sdio.MINIX-NEO Z83-4.txt
	# * /lib/firmware/brcm/brcmfmac43455-sdio.Radxa-ROCK Pi X.txt
	# * /lib/firmware/brcm/brcmfmac43455-sdio.acepc-t8.txt
	# * /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,3-model-b-plus.txt
	# * /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt
	#
	# ... whilst the files installed by raspberrypi-wifi-ucode have names of
	# the form:
	#
	# * /lib/firmware/brcm/brcmfmac43430-sdio.txt
	# * /lib/firmware/brcm/brcmfmac43436-sdio.txt
	# * /lib/firmware/brcm/brcmfmac43436s-sdio.txt
	# * /lib/firmware/brcm/brcmfmac43439-sdio.txt (symlink to ../cypress/cyfmac43439-sdio.txt)
	# * /lib/firmware/brcm/brcmfmac43455-sdio.txt
	# * /lib/firmware/brcm/brcmfmac43456-sdio.txt
	#
	# ... so no overlap should be assured.
	#
	for txt in "${EPREFIX}"/lib/firmware/brcm/brcmfmac434{30,55}-sdio.*.txt; do
		[[ -e "${txt}" ]] && BADFILES+=( "${txt}" )
	done

	if [[ "${#BADFILES[@]}" -gt 0 ]]; then
		eerror "The following files should be excluded from the savedconfig of"
		eerror "linux-firmware and linux-firmware should be re-emerged. Even"
		eerror "though they do not collide with files from ${PN},"
		eerror "they may be loaded preferentially to the files included in"
		eerror "${PN}, leading to undefined behaviour."
		eerror
		eerror "List of files:"
		for file in "${BADFILES[@]}"; do
			eerror "  ${file}"
		done
	fi
}

src_configure() {
	local model

	ln -frs \
		"${S}"/debian/config/brcm80211/cypress/cyfmac43455-sdio-standard.bin \
		"${S}"/debian/config/brcm80211/brcm/brcmfmac43455-sdio.bin || die

	# Fix broken symlinks
	for model in \
			'raspberrypi,3-model-a-plus' 'raspberrypi,3-model-b-plus' \
			'raspberrypi,4-compute-module' 'raspberrypi,4-model-b' \
			'raspberrypi,500' 'raspberrypi,5-compute-module' \
			'raspberrypi,5-model-b'
	do
		ln -frs \
			"${S}"/debian/config/brcm80211/cypress/cyfmac43455-sdio-standard.bin \
			"${S}"/debian/config/brcm80211/brcm/brcmfmac43455-sdio.${model}.bin
	done
}

src_install() {
	insinto /lib/firmware/brcm
	doins debian/config/brcm80211/brcm/*

	insinto /lib/firmware/cypress
	doins debian/config/brcm80211/cypress/*

	#dodoc debian/changelog
}
