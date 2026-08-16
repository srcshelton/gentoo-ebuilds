#!/usr/bin/env bash
# Compare generated arm and arm64 userspace headers before and after CIX patches.

set -euo pipefail

if (($# < 3 || $# > 4)); then
	printf 'usage: %s PRE_CIX_TREE FINAL_CIX_TREE WORK_DIR [EXPECTED_UAPI_PATCH]\n' "$0" >&2
	exit 2
fi

pre_cix_tree=$1
final_cix_tree=$2
work_dir=$3
expected_uapi_patch=${4:-}

for tree in "${pre_cix_tree}" "${final_cix_tree}"; do
	[[ -f ${tree}/Makefile ]] || {
		printf 'error: not a kernel source tree: %s\n' "${tree}" >&2
		exit 1
	}
done

if [[ -n ${expected_uapi_patch} && ! -f ${expected_uapi_patch} ]]; then
	printf 'error: expected UAPI patch is unavailable: %s\n' \
		"${expected_uapi_patch}" >&2
	exit 1
fi
[[ -z ${expected_uapi_patch} ]] || expected_uapi_patch=$(realpath -- "${expected_uapi_patch}")

case ${work_dir} in
	''|/)
		printf 'error: unsafe work directory: %s\n' "${work_dir}" >&2
		exit 2
		;;
esac

rm -rf -- "${work_dir}"
mkdir -p -- "${work_dir}"

generate_headers() {
	local label=$1
	local tree=$2
	local arch

	for arch in arm arm64; do
		make -s -C "${tree}" \
			O="${work_dir}/${label}-build-${arch}" \
			ARCH="${arch}" \
			headers_install \
			INSTALL_HDR_PATH="${work_dir}/${label}-headers-${arch}"
		find "${work_dir}/${label}-headers-${arch}" \
			-type f \( -name .install -o -name .check \) -delete
	done
}

generate_headers before "${pre_cix_tree}"
generate_headers after "${final_cix_tree}"

prepare_expected_headers() {
	local arch=$1
	local before=${work_dir}/before-headers-${arch}
	local expected=${work_dir}/expected-headers-${arch}
	local patch_tree=${work_dir}/expected-patch-${arch}
	local path
	local paths=()

	cp -a -- "${before}" "${expected}"
	mapfile -t paths < <(
		sed -n 's|^+++ b/include/uapi/||p' "${expected_uapi_patch}"
	)
	((${#paths[@]} > 0)) || {
		printf 'error: expected patch changes no include/uapi files: %s\n' \
			"${expected_uapi_patch}" >&2
		exit 1
	}

	mkdir -p -- "${patch_tree}"
	for path in "${paths[@]}"; do
		[[ -f ${before}/include/${path} ]] || {
			printf 'error: expected UAPI preimage is missing: %s\n' \
				"${before}/include/${path}" >&2
			exit 1
		}
		mkdir -p -- "${patch_tree}/include/uapi/$(dirname -- "${path}")"
		cp -- "${before}/include/${path}" \
			"${patch_tree}/include/uapi/${path}"
	done

	(
		cd -- "${patch_tree}"
		patch --batch --forward --fuzz=0 -p1 < "${expected_uapi_patch}"
	)
	for path in "${paths[@]}"; do
		cp -- "${patch_tree}/include/uapi/${path}" \
			"${expected}/include/${path}"
	done
	rm -rf -- "${patch_tree}"
}

for arch in arm arm64; do
	before=${work_dir}/before-headers-${arch}
	after=${work_dir}/after-headers-${arch}
	expected=${before}
	if [[ -n ${expected_uapi_patch} ]]; then
		prepare_expected_headers "${arch}"
		expected=${work_dir}/expected-headers-${arch}
	fi
	if [[ ! -d ${before}/include || ! -d ${after}/include ]]; then
		printf 'error: generated %s UAPI include tree is missing\n' \
			"${arch}" >&2
		exit 1
	fi
	before_count=$(find "${before}/include" -type f | wc -l | tr -d ' ')
	after_count=$(find "${after}/include" -type f | wc -l | tr -d ' ')

	if ((before_count == 0 || after_count == 0)); then
		printf 'error: generated %s UAPI tree is empty (%s before, %s after)\n' \
			"${arch}" "${before_count}" "${after_count}" >&2
		exit 1
	fi

	if ! diff -ruN -- "${expected}" "${after}" \
		> "${work_dir}/uapi-${arch}.diff"; then
		printf 'error: CIX patches differ from expected %s userspace headers; see %s\n' \
			"${arch}" "${work_dir}/uapi-${arch}.diff" >&2
		exit 1
	fi
	rm -f -- "${work_dir}/uapi-${arch}.diff"
	printf '%s generated UAPI matches the reviewed expectation (%s headers)\n' \
		"${arch}" "${after_count}"
done

printf 'CIX source-stack generated UAPI comparison passed\n'
