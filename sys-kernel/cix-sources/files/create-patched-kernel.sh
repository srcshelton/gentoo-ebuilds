#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage: create-patched-kernel.sh [options] <cix-sources.ebuild> <target-dir>

Create a Linux source tree prepared from a sys-kernel/cix-sources ebuild.

Options:
  --force                 Replace an existing target directory.
  --work-dir DIR          Use DIR for scratch work; it must not already exist.
  --distdir DIR           Reuse or keep downloaded distfiles in DIR.
  --use FLAGS             Enable additional USE flags, comma or space separated.
  --disable-use FLAGS     Disable USE flags that are enabled by default.
  --compile-acpi-tables   Compile ACPI table-upgrade AML artifacts.
  --acpi-table-profile P  ACPI table-upgrade profile: ssdt or dsdt (default: dsdt).
  --board-profile P       Report ACPI initramfs list for o6-acpi or o6n-acpi.
  --firmware VERSION      Select firmware profile 1.2 or 1.3 (default: 1.2).
  --keep-work             Keep the scratch directory after completion.
  -h, --help              Show this help.
USAGE
}

fail() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

manifest_field() {
	awk -v name="$1" -v field="$2" '
		$1 == "DIST" && $2 == name {
			for (i = 1; i <= NF; i++) {
				if ($i == field) {
					print $(i + 1)
					exit
				}
			}
		}
	' "$manifest"
}

verify_distfile() {
	if [[ -n $(manifest_field "$1" SHA512) ]]; then
		printf '%s  %s\n' "$(manifest_field "$1" SHA512)" "${DISTDIR}/$1" | sha512sum -c -
	fi
	if [[ -n $(manifest_field "$1" BLAKE2B) ]]; then
		if command -v b2sum >/dev/null 2>&1; then
			printf '%s  %s\n' "$(manifest_field "$1" BLAKE2B)" "${DISTDIR}/$1" | b2sum -c -
		else
			printf 'warning: b2sum not found; skipped BLAKE2B verification for %s\n' "$1" >&2
		fi
	fi
}

fetch_url() {
	local name=$1
	local tmp="${DISTDIR}/$1.tmp.$$"
	shift

	if [[ -s ${DISTDIR}/${name} ]]; then
		verify_distfile "$name"
		return
	fi

	for url in "$@"; do
		printf 'Fetching %s from %s\n' "$name" "$url"
		if curl -fL --retry 5 --retry-connrefused --connect-timeout 30 -o "$tmp" "$url"; then
			mv -- "$tmp" "${DISTDIR}/${name}"
			verify_distfile "$name"
			return
		fi
		rm -f -- "$tmp"
	done

	fail "unable to fetch ${name}"
}

fetch_gentoo_distfile() {
	local mirror_prefix=''
	local urls=(
		"https://dev.gentoo.org/~mpagano/dist/genpatches/$1"
		"https://dev.gentoo.org/~alicef/dist/genpatches/$1"
	)

	# Gentoo's distfiles layout hashes the filename, not the archive content
	# recorded in Manifest.  Developer-hosted copies are pruned sooner than
	# mirrors, so this fallback must use the repository layout hash.
	if command -v b2sum >/dev/null 2>&1; then
		mirror_prefix=$(printf '%s' "$1" | b2sum | cut -c 1-2)
	elif command -v python3 >/dev/null 2>&1; then
		mirror_prefix=$(python3 -c \
			'import hashlib, sys; print(hashlib.blake2b(sys.argv[1].encode()).hexdigest()[:2])' \
			"$1")
	fi

	if [[ -n $mirror_prefix ]]; then
		urls+=(
			"https://distfiles.gentoo.org/distfiles/${mirror_prefix}/$1"
			"https://ftp.osuosl.org/pub/gentoo/distfiles/${mirror_prefix}/$1"
			"https://ftp.gwdg.de/pub/linux/gentoo/distfiles/${mirror_prefix}/$1"
			"https://ftp.jaist.ac.jp/pub/Linux/Gentoo/distfiles/${mirror_prefix}/$1"
		)
	fi

	fetch_url "$1" "${urls[@]}"
}

apply_patch_file() {
	printf 'Applying %s\n' "$1"
	patch --batch --forward --no-backup-if-mismatch -p1 -i "$1"
}

apply_patch_archive() {
	mkdir -p -- "${T}/patches"
	tar -xf "$1" -C "${T}/patches"
	while IFS= read -r patch_file; do
		apply_patch_file "$patch_file"
	done < <(find "${T}/patches" -type f \( -name '*.patch' -o -name '*.diff' \) | LC_ALL=C sort)
	rm -rf -- "${T}/patches"
}

write_initramfs_list() {
	local profile_dir=$1
	local list_file=$2
	local final_profile_dir=$3
	local file
	local found=no

	[[ -d $profile_dir ]] || return 0

	{
		echo 'dir /dev 0755 0 0'
		echo 'nod /dev/console 0600 0 0 c 5 1'
		echo 'dir /root 0700 0 0'
		echo 'dir /kernel 0755 0 0'
		echo 'dir /kernel/firmware 0755 0 0'
		echo 'dir /kernel/firmware/acpi 0755 0 0'

		for file in "${profile_dir}"/*.aml; do
			[[ -e $file ]] || continue
			found=yes
			printf 'file /kernel/firmware/acpi/%s %s/%s 0644 0 0\n' \
				"$(basename -- "$file")" \
				"$final_profile_dir" \
				"$(basename -- "$file")"
		done
	} > "$list_file"

	if [[ $found != yes ]]; then
		rm -f -- "$list_file"
		printf 'warning: no AML files found in %s; skipped %s\n' "$profile_dir" "$list_file" >&2
	fi
}

die() {
	fail "die: $*"
}

eapply() {
	local patch_file
	for patch_file in "$@"; do
		apply_patch_file "$patch_file"
	done
}

eapply_user() { :; }
kernel-2_pkg_setup() { :; }
kernel-2_src_prepare() { eapply_user; }
kernel-2_src_install() { :; }
kernel-2_pkg_postinst() { :; }
kernel-2_pkg_postrm() { :; }
inherit() { :; }
detect_version() { :; }
detect_arch() { :; }
ewarn() { printf 'warning: %s\n' "$*" >&2; }
elog() { printf 'info: %s\n' "$*"; }
einfo() { printf 'info: %s\n' "$*"; }
use() {
	[[ " ${enabled_use} " == *" $1 "* && " ${disabled_use} " != *" $1 "* ]]
}
unpack() {
	local archive
	for archive in "$@"; do
		[[ -f $archive ]] || archive="${DISTDIR}/${archive}"
		[[ -f $archive ]] || die "missing archive ${archive}"
		tar -xf "$archive" -C "$PWD"
	done
}
default() {
	eapply "${PATCHES[@]}"
	eapply_user
}

force=no
keep_work=no
compile_acpi_tables=no
acpi_table_profile=dsdt
board_profile=
firmware_profile=1.2
acpi_table_upgrade_initramfs_source=
iasl_min_version=20241212
work_root=
DISTDIR=
enabled_use=
disabled_use=
args=()
declare -a PATCHES=() UNIPATCH_LIST=()

while (($#)); do
	case $1 in
		--force)
			force=yes
			;;
		--keep-work)
			keep_work=yes
			;;
		--work-dir)
			shift
			(($#)) || fail "--work-dir requires a directory"
			work_root=$1
			;;
		--distdir)
			shift
			(($#)) || fail "--distdir requires a directory"
			DISTDIR=$1
			;;
		--use)
			shift
			(($#)) || fail "--use requires one or more flags"
			enabled_use+=" ${1//,/ }"
			;;
		--disable-use)
			shift
			(($#)) || fail "--disable-use requires one or more flags"
			disabled_use+=" ${1//,/ }"
			;;
		--compile-acpi-tables)
			compile_acpi_tables=yes
			;;
		--acpi-table-profile)
			shift
			(($#)) || fail "--acpi-table-profile requires ssdt or dsdt"
			case $1 in
				ssdt|dsdt) acpi_table_profile=$1 ;;
				*) fail "--acpi-table-profile must be ssdt or dsdt" ;;
			esac
			;;
		--board-profile)
			shift
			(($#)) || fail "--board-profile requires o6-acpi or o6n-acpi"
			case $1 in
				o6-acpi|o6n-acpi) board_profile=$1 ;;
				*) fail "--board-profile must be o6-acpi or o6n-acpi" ;;
			esac
			;;
		--firmware)
			shift
			(($#)) || fail "--firmware requires 1.2 or 1.3"
			case $1 in
				1.2|1.3) firmware_profile=$1 ;;
				*) fail "--firmware must be 1.2 or 1.3" ;;
			esac
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			args+=("$@")
			break
			;;
		-*)
			fail "unknown option $1"
			;;
		*)
			args+=("$1")
			;;
	esac
	shift
done

((${#args[@]} == 2)) || {
	usage >&2
	exit 2
}

for cmd in awk curl patch sha512sum tar; do
	command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: ${cmd}"
done

if [[ -n $board_profile && $compile_acpi_tables != yes ]]; then
	printf 'warning: --board-profile has no effect without --compile-acpi-tables\n' >&2
fi
if [[ $firmware_profile != 1.2 && $compile_acpi_tables != yes ]]; then
	printf 'warning: --firmware has no effect without --compile-acpi-tables\n' >&2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(cd -- "${script_dir}/../../.." && pwd -P)
manifest="${repo_root}/sys-kernel/cix-sources/Manifest"
FILESDIR="${repo_root}/sys-kernel/cix-sources/files"

case ${args[0]} in
	/*) ebuild=${args[0]} ;;
	*) ebuild="${PWD}/${args[0]}" ;;
esac
ebuild=$(cd -- "$(dirname -- "$ebuild")" && pwd -P)/$(basename -- "$ebuild")
[[ -f $ebuild ]] || fail "ebuild not found: ${args[0]}"

if [[ $(basename -- "$ebuild") =~ ^(.+)-([0-9][^-]*)(-r([0-9]+))?\.ebuild$ ]]; then
	PN=${BASH_REMATCH[1]}
	PV=${BASH_REMATCH[2]}
	PR=${BASH_REMATCH[4]:+r${BASH_REMATCH[4]}}
	PR=${PR:-r0}
else
	fail "could not parse package/version from $(basename -- "$ebuild")"
fi

[[ $PN == cix-sources ]] || fail "this helper only supports cix-sources ebuilds"

mkdir -p -- "$(dirname -- "${args[1]}")"
target_dir=$(cd -- "$(dirname -- "${args[1]}")" && pwd -P)/$(basename -- "${args[1]}")
if [[ -e $target_dir && ! -d $target_dir ]]; then
	fail "target exists and is not a directory: ${target_dir}"
fi
if [[ -d $target_dir && $force != yes && -n $(find "$target_dir" -mindepth 1 -maxdepth 1 -print -quit) ]]; then
	fail "target directory is not empty; pass --force to replace it"
fi

if [[ -z $work_root ]]; then
	work_root="${target_dir}.work/create-patched-kernel-${PN}-${PV}-${PR}-$$"
else
	mkdir -p -- "$(dirname -- "$work_root")"
	work_root=$(cd -- "$(dirname -- "$work_root")" && pwd -P)/$(basename -- "$work_root")
fi
[[ ! -e $work_root ]] || fail "work directory already exists: ${work_root}"
mkdir -p -- "$work_root"

cleanup() {
	if [[ $keep_work != yes && -n ${work_root:-} && -d $work_root ]]; then
		rm -rf -- "$work_root"
	fi
}
trap cleanup EXIT

if [[ -z $DISTDIR ]]; then
	DISTDIR="${work_root}/distfiles"
else
	mkdir -p -- "$(dirname -- "$DISTDIR")"
	DISTDIR=$(cd -- "$(dirname -- "$DISTDIR")" && pwd -P)/$(basename -- "$DISTDIR")
fi
source_parent="${work_root}/source"
WORKDIR="${work_root}/work"
T="${work_root}/tmp"
S="${source_parent}/linux-${PV%.*}"
P="${PN}-${PV}"
CATEGORY=sys-kernel
KV_MAJOR=${PV%%.*}
KV_MINOR=${PV#*.}
KV_MINOR=${KV_MINOR%%.*}
KV_PATCH=${PV#"$KV_MAJOR.$KV_MINOR."}
CKV=$PV
OKV="${KV_MAJOR}.${KV_MINOR}"
KV_FULL=$PV
KERNEL_URI=
GENPATCHES_URI=
ARCH_URI=

export ARCH_URI CATEGORY CKV DISTDIR FILESDIR GENPATCHES_URI KERNEL_URI KV_FULL KV_MAJOR KV_MINOR KV_PATCH OKV P PN PR PV S T WORKDIR
mkdir -p -- "$DISTDIR" "$source_parent" "$WORKDIR" "$T"

# shellcheck source=/dev/null
source "$ebuild"

[[ -z ${K_FROM_GIT:-} ]] || fail "K_FROM_GIT ebuilds are not supported by this standalone helper"

for flag in ${USE:-} ${IUSE:-}; do
	case $flag in
		+*) enabled_use+=" ${flag#+}" ;;
		-*) disabled_use+=" ${flag#-}" ;;
		*) ;;
	esac
done
if [[ $compile_acpi_tables == yes ]]; then
	if [[ " ${disabled_use} " == *" acpi-table-upgrade "* ]]; then
		fail "--compile-acpi-tables conflicts with --disable-use acpi-table-upgrade"
	fi
	if [[ $acpi_table_profile == dsdt && " ${disabled_use} " == *" acpi-table-upgrade-dsdt "* ]]; then
		fail "--compile-acpi-tables --acpi-table-profile dsdt conflicts with --disable-use acpi-table-upgrade-dsdt"
	fi
	if [[ $acpi_table_profile == dsdt && $board_profile == o6n-acpi && $firmware_profile == 1.3 ]]; then
		fail "firmware 1.3 has no O6N DSDT profile; use --acpi-table-profile ssdt"
	fi
	if ! command -v iasl >/dev/null 2>&1; then
		fail "--compile-acpi-tables requires ACPICA iasl >= ${iasl_min_version}; install the current ACPICA release when possible"
	fi
	iasl_version=$(iasl -v 2>&1 | awk '{
		for (i = 1; i <= NF; i++) {
			if ($i ~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/) {
				print $i
				exit
			}
		}
	}')
	[[ -n $iasl_version ]] || fail "could not determine iasl version; need ACPICA iasl >= ${iasl_min_version}"
	if ((10#$iasl_version < iasl_min_version)); then
		fail "iasl ${iasl_version} is too old; need >= ${iasl_min_version}; install the current ACPICA release when possible"
	fi
	command -v python3 >/dev/null 2>&1 || fail "--compile-acpi-tables requires python3"
	declare -F src_compile >/dev/null || fail "selected ebuild does not define src_compile for ACPI table compilation"

	enabled_use+=" acpi-table-upgrade"
	if [[ $acpi_table_profile == dsdt ]]; then
		enabled_use+=" acpi-table-upgrade-dsdt acpi-table-upgrade-iort-httu acpi-table-upgrade-iort-msi"
	else
		disabled_use+=" acpi-table-upgrade-dsdt acpi-table-upgrade-iort-httu acpi-table-upgrade-iort-msi"
	fi
fi

if declare -F pkg_setup >/dev/null; then
	pkg_setup
fi

fetch_url "linux-${OKV}.tar.xz" \
	"https://cdn.kernel.org/pub/linux/kernel/v${KV_MAJOR}.x/linux-${OKV}.tar.xz" \
	"https://www.kernel.org/pub/linux/kernel/v${KV_MAJOR}.x/linux-${OKV}.tar.xz"

for kind in ${K_WANT_GENPATCHES:-}; do
	if [[ $kind == experimental && -z ${K_EXP_GENPATCHES_PULL:-} && -z ${K_EXP_GENPATCHES_NOUSE:-} ]] && ! use experimental; then
		continue
	fi
	fetch_gentoo_distfile "genpatches-${OKV}-${K_GENPATCHES_VER}.${kind}.tar.xz"
done

if [[ -n ${EGIT_CIX_COMMIT:-} ]]; then
	fetch_url "${PN}-cix-${EGIT_CIX_COMMIT:0:7}.tar.gz" \
		"https://github.com/cixtech/cix-linux-main/archive/${EGIT_CIX_COMMIT}.tar.gz"
fi
if [[ -n ${EGIT_SKY1_COMMIT:-} ]]; then
	fetch_url "${PN}-sky1-${EGIT_SKY1_COMMIT:0:7}.tar.gz" \
		"https://github.com/Sky1-Linux/linux-sky1/archive/${EGIT_SKY1_COMMIT}.tar.gz"
	for alias in "${PN}-${EGIT_SKY1_COMMIT:0:7}.tar.gz" "${P}-${EGIT_SKY1_COMMIT:0:7}.tar.gz" "${P}-sky1-${EGIT_SKY1_COMMIT:0:7}.tar.gz"; do
		[[ -e ${DISTDIR}/${alias} ]] || cp -- "${DISTDIR}/${PN}-sky1-${EGIT_SKY1_COMMIT:0:7}.tar.gz" "${DISTDIR}/${alias}"
	done
fi
if [[ -n ${EGIT_COMMIT:-} && -n ${EGIT_COMMIT_KV:-} ]]; then
	fetch_url "${PN}-${EGIT_COMMIT_KV}.patch" \
		"https://github.com/radxa/kernel/commit/${EGIT_COMMIT}.patch"
fi

tar -xf "${DISTDIR}/linux-${OKV}.tar.xz" -C "$source_parent"
cd "$S"

for kind in ${K_WANT_GENPATCHES:-}; do
	if [[ $kind == experimental && -z ${K_EXP_GENPATCHES_PULL:-} && -z ${K_EXP_GENPATCHES_NOUSE:-} ]] && ! use experimental; then
		continue
	fi
	apply_patch_archive "${DISTDIR}/genpatches-${OKV}-${K_GENPATCHES_VER}.${kind}.tar.xz"
done

for patch_file in "${UNIPATCH_LIST[@]}"; do
	case $patch_file in
		*.tar|*.tar.*|*.tgz|*.tbz)
			apply_patch_archive "$patch_file"
			;;
		*)
			apply_patch_file "$patch_file"
			;;
	esac
done

src_prepare

if [[ $compile_acpi_tables == yes ]]; then
	if ! ( src_compile ); then
		fail "ACPI table compilation failed"
	fi
	[[ -d ${T}/cix-acpi-table-upgrade ]] || fail "ACPI table compilation produced no cix-acpi-table-upgrade directory"

	mkdir -p -- "${S}/cix-acpi-table-upgrade"
	cp -a -- "${T}/cix-acpi-table-upgrade"/. "${S}/cix-acpi-table-upgrade/"

	for board in o6 o6n; do
		for firmware in 1.2 1.3; do
			for profile in initramfs initramfs-dsdt; do
				write_initramfs_list \
					"${S}/cix-acpi-table-upgrade/${board}/${firmware}/${profile}/kernel/firmware/acpi" \
					"${S}/cix-acpi-table-upgrade/${board}/${firmware}/${profile}.list" \
					"${target_dir}/cix-acpi-table-upgrade/${board}/${firmware}/${profile}/kernel/firmware/acpi"
			done
		done
	done

	for board in o6 o6n ''; do
		for profile in initramfs initramfs-dsdt; do
			if [[ -n $board ]]; then
				write_initramfs_list \
					"${S}/cix-acpi-table-upgrade/${board}/${profile}/kernel/firmware/acpi" \
					"${S}/cix-acpi-table-upgrade/${board}/${profile}.list" \
					"${target_dir}/cix-acpi-table-upgrade/${board}/${profile}/kernel/firmware/acpi"
			else
				write_initramfs_list \
					"${S}/cix-acpi-table-upgrade/${profile}/kernel/firmware/acpi" \
					"${S}/cix-acpi-table-upgrade/${profile}.list" \
					"${target_dir}/cix-acpi-table-upgrade/${profile}/kernel/firmware/acpi"
			fi
		done
	done

	[[ -n $(find "${S}/cix-acpi-table-upgrade" -type f -name '*.aml' -print -quit) ]] || fail "ACPI table compilation produced no AML artifacts"

	if [[ -n $board_profile ]]; then
		acpi_table_upgrade_initramfs_source="${target_dir}/cix-acpi-table-upgrade/${board_profile%%-*}/${firmware_profile}/initramfs"
		[[ $acpi_table_profile == dsdt ]] && acpi_table_upgrade_initramfs_source+="-dsdt"
		acpi_table_upgrade_initramfs_source+=".list"
		[[ -s ${S}/cix-acpi-table-upgrade/${board_profile%%-*}/${firmware_profile}/$(basename -- "$acpi_table_upgrade_initramfs_source") ]] || \
			fail "expected ACPI initramfs list was not produced: ${acpi_table_upgrade_initramfs_source}"
	fi
fi

rm -rf -- "$target_dir"
mv -- "$S" "$target_dir"

printf 'Prepared kernel source: %s\n' "$target_dir"
if [[ -n $acpi_table_upgrade_initramfs_source ]]; then
	printf 'ACPI table-upgrade initramfs source: %s\n' "$acpi_table_upgrade_initramfs_source"
elif [[ -d ${target_dir}/cix-acpi-table-upgrade ]]; then
	printf 'ACPI table-upgrade artifacts: %s\n' "${target_dir}/cix-acpi-table-upgrade"
fi
