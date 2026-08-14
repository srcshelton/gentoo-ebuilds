#!/usr/bin/env bash
# Compare each retained CIX userspace-header package with Gentoo's package.

set -euo pipefail

if (($# != 2)); then
	printf 'usage: %s OVERLAY_ROOT WORK_ROOT\n' "$0" >&2
	exit 2
fi

overlay_root=$1
work_root=$2
gentoo_repo=${GENTOO_REPO:-/var/db/repos/gentoo}
distdir=${DISTDIR:-${work_root}/distfiles}

[[ -d ${overlay_root}/sys-kernel/cix-headers ]] || {
	printf 'error: not a Gentoo overlay: %s\n' "${overlay_root}" >&2
	exit 1
}
[[ -d ${gentoo_repo}/sys-kernel/linux-headers ]] || {
	printf 'error: Gentoo repository is unavailable: %s\n' "${gentoo_repo}" >&2
	exit 1
}

mkdir -p -- "${work_root}" "${distdir}"

build_headers() {
	local ebuild=$1
	local package=$2
	local version=$3
	local output=$4
	local ebuild_pf=${ebuild##*/}
	local portage_tmp=${work_root}/portage-${package}-${version}
	local image

	ebuild_pf=${ebuild_pf%.ebuild}
	image=${portage_tmp}/portage/sys-kernel/${ebuild_pf}/image

	rm -rf -- "${portage_tmp}" "${output}"
	DISTDIR=${distdir} PORTAGE_TMPDIR=${portage_tmp} \
		ebuild "${ebuild}" clean fetch unpack prepare configure compile install
	[[ -d ${image}/usr/include ]] || {
		printf 'error: missing installed header tree: %s\n' "${image}/usr/include" >&2
		exit 1
	}
	mkdir -p -- "${output}"
	cp -a --no-preserve=ownership "${image}/usr/include" "${output}/"
	rm -rf -- "${portage_tmp}"
}

validate_tree() {
	local include_dir=$1
	local expected_perf_size=$2
	local expected_cix_sof_tokens=$3
	local consumer=${work_root}/header-consumer
	local forbidden

	if find "${include_dir}" \( -name '.install' -o -name '*.cmd' \) \
		-print -quit | grep -q .; then
		printf 'error: generated build metadata was installed under %s\n' \
			"${include_dir}" >&2
		exit 1
	fi

	for forbidden in arch drivers fs include kernel mm; do
		[[ ! -e ${include_dir}/${forbidden} ]] || {
			printf 'error: kernel-private directory installed: %s\n' \
				"${include_dir}/${forbidden}" >&2
			exit 1
		}
	done

	${CC:-cc} -std=c11 -Wall -Wextra -Werror \
		-I"${include_dir}" \
		-DEXPECTED_PERF_SIZE="${expected_perf_size}" \
		-DEXPECT_CIX_SOF_TOKENS="${expected_cix_sof_tokens}" \
		"${overlay_root}/.github/scripts/cix-headers/header-consumer.c" \
		-o "${consumer}"
	"${consumer}"
}

prepare_expected_tree() {
	local line=$1
	local gentoo_output=$2
	local expected_output=$3
	local patch_tree=${work_root}/expected-patch-${line}

	rm -rf -- "${expected_output}" "${patch_tree}"
	cp -a --no-preserve=ownership "${gentoo_output}" "${expected_output}"

	if [[ ${line} == 7.1 ]]; then
		mkdir -p -- "${patch_tree}/include/uapi/sound/sof"
		cp -- "${expected_output}/include/sound/sof/tokens.h" \
			"${patch_tree}/include/uapi/sound/sof/tokens.h"
		(
			cd -- "${patch_tree}"
			patch --batch --forward --fuzz=0 -p1 < \
				"${overlay_root}/sys-kernel/cix-headers/files/7.1-cix-sof-topology-tokens.patch"
		)
		cp -- "${patch_tree}/include/uapi/sound/sof/tokens.h" \
			"${expected_output}/include/sound/sof/tokens.h"
	fi

	rm -rf -- "${patch_tree}"
}

for specification in 6.18:136 7.0:144 7.1:144; do
	line=${specification%%:*}
	expected_perf_size=${specification##*:}
	cix_ebuild=${overlay_root}/sys-kernel/cix-headers/cix-headers-${line}.ebuild
	[[ ${line} != 7.1 ]] || \
		cix_ebuild=${overlay_root}/sys-kernel/cix-headers/cix-headers-7.1-r1.ebuild
	gentoo_ebuild=${gentoo_repo}/sys-kernel/linux-headers/linux-headers-${line}.ebuild
	cix_output=${work_root}/cix-headers-${line}
	gentoo_output=${work_root}/linux-headers-${line}
	expected_output=${work_root}/expected-headers-${line}

	[[ -f ${cix_ebuild} ]] || {
		printf 'error: missing retained CIX headers ebuild: %s\n' "${cix_ebuild}" >&2
		exit 1
	}
	[[ -f ${gentoo_ebuild} ]] || {
		printf 'error: matching Gentoo headers ebuild is unavailable: %s\n' \
			"${gentoo_ebuild}" >&2
		exit 1
	}

	build_headers "${cix_ebuild}" cix-headers "${line}" "${cix_output}"
	build_headers "${gentoo_ebuild}" linux-headers "${line}" "${gentoo_output}"
	prepare_expected_tree "${line}" "${gentoo_output}" "${expected_output}"
	diff -ruN -- "${expected_output}/include" "${cix_output}/include"
	if [[ ${line} == 7.1 ]]; then
		expected_cix_sof_tokens=1
	else
		expected_cix_sof_tokens=0
	fi
	validate_tree \
		"${cix_output}/include" \
		"${expected_perf_size}" \
		"${expected_cix_sof_tokens}"
	printf 'Linux %s: %s installed UAPI headers match the reviewed expected tree; consumer passed\n' \
		"${line}" "$(find "${cix_output}/include" -type f | wc -l)"

	rm -rf -- "${cix_output}" "${gentoo_output}" "${expected_output}"
done

rm -f -- "${work_root}/header-consumer"
printf 'CIX headers validation passed for all retained kernel lines\n'
