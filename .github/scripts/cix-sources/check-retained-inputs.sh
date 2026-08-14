#!/usr/bin/env bash
set -euo pipefail

readonly fetch_unavailable=75

usage() {
	cat <<'USAGE'
Usage: check-retained-inputs.sh [--attempts N] <cix-sources.ebuild> <work-dir>

Use Portage's configured mirrors and SRC_URI fallbacks to fetch every input
needed by one retained cix-sources ebuild. The work directory must not exist.

The experimental USE flag is enabled for this check so every genpatches archive
declared by K_WANT_GENPATCHES is retrieved, even when it is optional in the
normal package configuration.

Exit status 75 means that clean Portage fetches failed repeatedly and the
retained kernel version needs an explicit maintainer decision. Other nonzero
statuses report invalid inputs or a test-environment failure.
USAGE
}

fail() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

manifest_has_distfile() {
	awk -v name="$1" '
		$1 == "DIST" && $2 == name {
			found = 1
			exit
		}
		END {
			exit !found
		}
	' "$manifest"
}

manifest_has_local_file() {
	awk -v kind="$1" -v name="$2" '
		$1 == kind && $2 == name {
			found = 1
			exit
		}
		END {
			exit !found
		}
	' "$manifest"
}

verify_manifest_local_file() {
	local kind=$1
	local name=$2
	local path=$3
	local actual_size
	local -a manifest_rows=()
	local expected_blake2b
	local expected_sha512
	local expected_size

	mapfile -t manifest_rows < <(
		awk -v kind="$kind" -v name="$name" '
			$1 == kind && $2 == name {
				print $3, $5, $7
			}
		' "$manifest"
	)
	((${#manifest_rows[@]} == 1)) ||
		fail "expected exactly one $kind row for $name"
	read -r expected_size expected_blake2b expected_sha512 \
		<<< "${manifest_rows[0]}"

	[[ -f $path ]] || fail "Manifest input is missing: $path"
	actual_size=$(stat -c %s -- "$path")
	[[ $actual_size == "$expected_size" ]] ||
		fail "$kind $name has size $actual_size, expected $expected_size"
	printf '%s  %s\n' "$expected_blake2b" "$path" | b2sum -c - >/dev/null ||
		fail "$kind $name failed BLAKE2B verification"
	printf '%s  %s\n' "$expected_sha512" "$path" |
		sha512sum -c - >/dev/null ||
		fail "$kind $name failed SHA512 verification"
}

attempts=2

while (($#)); do
	case $1 in
		--attempts)
			shift
			(($#)) || fail "--attempts requires a positive integer"
			attempts=$1
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			break
			;;
		-*)
			fail "unknown option: $1"
			;;
		*)
			break
			;;
	esac
	shift
done

(($# == 2)) || {
	usage >&2
	exit 1
}
[[ $attempts =~ ^[1-9][0-9]*$ ]] ||
	fail "--attempts must be a positive integer"
command -v emerge >/dev/null 2>&1 || fail "emerge is required"
command -v portageq >/dev/null 2>&1 || fail "portageq is required"
command -v b2sum >/dev/null 2>&1 || fail "b2sum is required"
command -v sha512sum >/dev/null 2>&1 || fail "sha512sum is required"

ebuild=$1
work_dir=$2
[[ -f $ebuild ]] || fail "missing ebuild: $ebuild"
[[ $ebuild == *.ebuild ]] || fail "not an ebuild: $ebuild"
[[ ! -e $work_dir ]] || fail "work directory already exists: $work_dir"

ebuild=$(cd -- "$(dirname -- "$ebuild")" && pwd -P)/$(basename -- "$ebuild")
package_dir=${ebuild%/*}
manifest="${package_dir}/Manifest"
[[ -f $manifest ]] || fail "missing Manifest: $manifest"

while read -r kind name _rest; do
	case $kind in
		AUX)
			verify_manifest_local_file "$kind" "$name" \
				"${package_dir}/files/${name}"
			;;
		EBUILD)
			verify_manifest_local_file "$kind" "$name" \
				"${package_dir}/${name}"
			;;
	esac
done < "$manifest"

while IFS= read -r -d '' path; do
	name=${path#"${package_dir}/files/"}
	[[ $name == .gitignore ]] && continue
	manifest_has_local_file AUX "$name" ||
		fail "unmanifested local AUX file: $name"
done < <(find "${package_dir}/files" -type f -print0)

while IFS= read -r -d '' path; do
	name=${path#"${package_dir}/"}
	manifest_has_local_file EBUILD "$name" ||
		fail "unmanifested ebuild: $name"
done < <(find "$package_dir" -maxdepth 1 -type f -name '*.ebuild' -print0)

ebuild_name=${ebuild##*/}
version=${ebuild_name#cix-sources-}
version=${version%.ebuild}
[[ $version != "$ebuild_name" && $version != *.ebuild ]] ||
	fail "unexpected cix-sources ebuild name: $ebuild_name"
[[ $version =~ ^([0-9]+)\.([0-9]+)\.[0-9]+(-r[0-9]+)?$ ]] ||
	fail "unsupported cix-sources version: $version"
kernel_line="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"

genpatches_version=$(
	sed -nE 's/^[[:space:]]*K_GENPATCHES_VER="([^"]+)"[[:space:]]*$/\1/p' \
		"$ebuild"
)
genpatches_kinds=$(
	sed -nE 's/^[[:space:]]*K_WANT_GENPATCHES="([^"]+)"[[:space:]]*$/\1/p' \
		"$ebuild"
)
[[ -n $genpatches_version && $genpatches_version != *$'\n'* ]] ||
	fail "expected exactly one K_GENPATCHES_VER in $ebuild"
[[ -n $genpatches_kinds && $genpatches_kinds != *$'\n'* ]] ||
	fail "expected exactly one K_WANT_GENPATCHES in $ebuild"

read -r -a kinds <<< "$genpatches_kinds"
((${#kinds[@]})) || fail "K_WANT_GENPATCHES is empty in $ebuild"

required_genpatches=()
enable_experimental=false
for kind in "${kinds[@]}"; do
	case $kind in
		base|extras)
			;;
		experimental)
			enable_experimental=true
			;;
		*)
			fail "unsupported genpatches kind '$kind' in $ebuild"
			;;
	esac
	name="genpatches-${kernel_line}-${genpatches_version}.${kind}.tar.xz"
	manifest_has_distfile "$name" ||
		fail "Manifest has no DIST row for $name"
	required_genpatches+=("$name")
done

use_value=${USE:-}
if $enable_experimental; then
	use_value="${use_value:+${use_value} }experimental"
fi

atom="=sys-kernel/cix-sources-${version}"
mkdir -p -- "$work_dir"

printf 'Checking %s with Portage %s\n' "$atom" "$(emerge --version | sed -n '1p')"
printf 'Configured GENTOO_MIRRORS: %s\n' "$(portageq envvar GENTOO_MIRRORS)"
printf 'Required genpatches: %s\n' "${required_genpatches[*]}"

for ((attempt = 1; attempt <= attempts; attempt++)); do
	distdir="${work_dir}/attempt-${attempt}/distfiles"
	mkdir -p -- "$distdir"
	printf 'Portage fetch attempt %d/%d with empty DISTDIR=%s\n' \
		"$attempt" "$attempts" "$distdir"

	if DISTDIR="$distdir" USE="$use_value" \
		emerge --fetchonly --nodeps --nospinner --color=n --quiet --oneshot \
			"$atom"; then
		missing=()
		for name in "${required_genpatches[@]}"; do
			[[ -s ${distdir}/${name} ]] || missing+=("$name")
		done
		if ((${#missing[@]} == 0)); then
			printf 'Portage fetched and verified every required genpatches archive\n'
			exit 0
		fi
		printf 'error: Portage returned success but omitted: %s\n' \
			"${missing[*]}" >&2
	fi

	rm -rf -- "${work_dir}/attempt-${attempt}"
done

printf 'error: %s failed %d clean Portage fetch attempts.\n' \
	"$atom" "$attempts" >&2
printf 'Maintainer decision required: should %s and files used only by that ebuild be removed?\n' \
	"$atom" >&2
exit "$fetch_unavailable"
