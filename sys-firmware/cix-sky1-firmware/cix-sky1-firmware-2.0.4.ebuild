# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info unpacker

CIX_AUDIO_DSP_PV="2.0.0"
CIX_SOF_PV="2.0.0"
CIX_VPU_PV="1.0.1-3"
SOF_TOPOLOGY_PV="2.11.2"

DESCRIPTION="Supplemental firmware for CIX Sky1 DSP, SOF, and VPU drivers"
HOMEPAGE="
	https://archive.cixtech.com/debian/pool/main/c/cix-audio-dsp/
	https://archive.cixtech.com/debian/pool/main/c/cix-audio-sof/
	https://archive.cixtech.com/debian/pool/main/c/cix-vpu-driver/
"
SRC_URI="
	https://archive.cixtech.com/debian/pool/main/c/cix-audio-dsp/cix-audio-dsp_${CIX_AUDIO_DSP_PV}_arm64.deb -> ${P}-audio-dsp-${CIX_AUDIO_DSP_PV}.deb
	https://archive.cixtech.com/debian/pool/main/c/cix-vpu-driver/cix-vpu-firmware_${CIX_VPU_PV}_all.deb -> ${P}-vpu-${CIX_VPU_PV}.deb
	sof? (
		https://archive.cixtech.com/debian/pool/main/c/cix-audio-sof/cix-audio-sof_${CIX_SOF_PV}_arm64.deb -> ${P}-sof-${CIX_SOF_PV}.deb
		https://github.com/thesofproject/sof/archive/refs/tags/v${SOF_TOPOLOGY_PV}.tar.gz -> ${P}-sof-topology-${SOF_TOPOLOGY_PV}.tar.gz
	)
"
S="${WORKDIR}"

# The native DSP and VPU Debian packages declare MIT and GPL-2+ respectively.
# The SOF package contains no licence or copyright file, so normal copyright
# applies and redistribution must not be assumed.
LICENSE="MIT GPL-2+ sof? ( all-rights-reserved BSD )"
SLOT="0"
KEYWORDS="arm arm64"
IUSE="compress-xz compress-zstd sof"
REQUIRED_USE="?? ( compress-xz compress-zstd )"
RESTRICT="sof? ( bindist mirror )"

BDEPEND="
	app-arch/zstd
	compress-xz? ( app-arch/xz-utils )
	compress-zstd? ( app-arch/zstd )
	sof? (
		media-sound/alsa-utils
		sys-devel/m4
	)
"
RDEPEND="
	>=sys-kernel/linux-firmware-20260110[firmware_realtek(+),redistributable(+)]
"

QA_PREBUILT="*"

src_unpack() {
	local distfile

	for distfile in ${A}; do
		case ${distfile} in
		*-sof-topology-*.tar.gz)
			unpack "${distfile}" || die
			;;
		*)
			unpack_deb "${distfile}" || die
			;;
		esac
	done
}

pkg_setup() {
	if use compress-xz || use compress-zstd ; then
		local CONFIG_CHECK

		if kernel_is -ge 5 19; then
			use compress-xz && CONFIG_CHECK="~FW_LOADER_COMPRESS_XZ"
			use compress-zstd && CONFIG_CHECK="~FW_LOADER_COMPRESS_ZSTD"
		else
			use compress-xz && CONFIG_CHECK="~FW_LOADER_COMPRESS"
			if use compress-zstd; then
				eerror "Kernels <5.19 do not support ZSTD-compressed firmware files"
			fi
		fi
		linux-info_pkg_setup
	fi
}

pkg_pretend() {
	if use sof; then
		ewarn "CIX's cix-audio-sof package does not contain a licence file."
		ewarn "It is therefore treated as all-rights-reserved and must not be"
		ewarn "redistributed without separate permission from CIX."
	fi
}

src_compile() {
	if use sof; then
		local topology_dir="${S}/lib/firmware/cix/sof-tplg"
		local topology_source="${topology_dir}/sof-sky1-passthrough-alc5682-alc1019.tplg"
		local topology_upstream="${WORKDIR}/sof-${SOF_TOPOLOGY_PV}/tools/topology/topology1"
		local topology_vendor="${T}/sof-sky1-vendor.conf"
		local topology_named="${T}/sof-sky1-nocodec-named.conf"
		local topology_config="${T}/sof-sky1-nocodec.conf"
		local topology_process="${T}/sof-sky1-host-process.conf"
		local topology_validated="${T}/sof-sky1-nocodec-validated.conf"

		if [[ ! -e ${topology_dir}/sof-sky1-nocodec.tplg ]]; then
			[[ -f ${topology_source} ]] || die "missing CIX passthrough SOF topology"
			alsatplg -d "${topology_source}" -o "${topology_vendor}" || die
			sed \
				-e 's/pa_alc1019/NoCodec-3/g' \
				-e 's/codec_alc5682/NoCodec-0/g' \
				-e 's/ALC1019/HiFi5-PCM0/g' \
				-e 's/ALC5682/HiFi5-PCM1/g' \
				"${topology_vendor}" > "${topology_named}" || die
			awk -f "${FILESDIR}/cix-sof-nocodec-topology.awk" \
				"${topology_named}" > "${topology_config}" || die
			m4 \
				-I "${FILESDIR}" \
				-I "${topology_upstream}/m4" \
				-I "${topology_upstream}/common" \
				-I "${topology_upstream}/platform/common" \
				-I "${topology_upstream}" \
				"${FILESDIR}/cix-sky1-host-process.m4" \
				> "${topology_process}" || die
			cat "${topology_process}" >> "${topology_config}" || die
			alsatplg -c "${topology_config}" \
				-o "${topology_dir}/sof-sky1-nocodec.tplg" || die
			alsatplg -d "${topology_dir}/sof-sky1-nocodec.tplg" \
				-o "${topology_validated}" || die
			grep -Fq "'manifest:data0'.bytes '03:1e:01'" \
				"${topology_validated}" || die "SOF topology lost CIX ABI 3.30.1"
			[[ $(grep -Fc "'HiFi5 Loopback' {" "${topology_validated}") -eq 1 ]] ||
				die "SOF topology does not contain one processing PCM"
			[[ $(grep -Fc "'PCM2C, , BUF4.1'" "${topology_validated}") -eq 1 ]] ||
				die "SOF topology does not contain one component-to-buffer return route"
			for widget in \
				PCM2P PGA4.0 BUF4.0 BUF4.1 PIPELINE.4.BUF4.1 \
				PCM2C PIPELINE.5.PCM2C; do
				[[ $(grep -Fc "data '${widget}:tuple0'" "${topology_validated}") -eq 1 ]] ||
					die "SOF topology does not contain one ${widget} widget"
			done
			[[ $(grep -Fc "'4 Playback Volume' {" "${topology_validated}") -eq 1 ]] ||
				die "SOF topology does not contain one processing-volume control"
		fi
	fi
}

src_install() {
	insinto /lib/firmware
	doins usr/lib/firmware/dsp_fw.bin
	doins usr/lib/firmware/*.fwb

	if use sof; then
		insinto /lib/firmware/cix/sof
		doins lib/firmware/cix/sof/*

		insinto /lib/firmware/cix/sof-tplg
		doins lib/firmware/cix/sof-tplg/*
	fi

	docinto licences
	newdoc usr/share/doc/cix-audio-dsp/copyright cix-audio-dsp
	newdoc usr/share/doc/cix-vpu-firmware/copyright cix-vpu-firmware

	dostrip -x /lib/firmware

	if use compress-xz; then
		find "${ED}"/lib/firmware -type f -exec xz --check=crc32 {} +
	elif use compress-zstd; then
		find "${ED}"/lib/firmware -type f -exec zstd --quiet --rm {} +
	fi
}
