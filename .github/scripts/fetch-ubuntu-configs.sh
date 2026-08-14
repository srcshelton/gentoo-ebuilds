#!/bin/bash

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: fetch-ubuntu-configs.sh --seed MAJOR.MINOR --output-dir DIR --work-dir DIR

Export frozen arm64 generic and generic-64k configurations from the official
Ubuntu kernel repository appropriate to the declared adjacent kernel seed.
EOF
}

seed=
output_dir=
work_dir=

while (($# > 0)); do
	case $1 in
		--seed)
			seed=${2-}
			shift 2
			;;
		--output-dir)
			output_dir=${2-}
			shift 2
			;;
		--work-dir)
			work_dir=${2-}
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

if [[ -z $seed || -z $output_dir || -z $work_dir ]]; then
	usage >&2
	exit 2
fi
if [[ $output_dir == / || $work_dir == / ]]; then
	echo "Refusing to use the filesystem root as an output or work directory" >&2
	exit 2
fi
if [[ -e $output_dir && ! -d $output_dir ]]; then
	echo "Output path is not a directory: $output_dir" >&2
	exit 2
fi
if [[ -d $output_dir ]]; then
	if [[ -n $(find "$output_dir" -mindepth 1 -print -quit) ]]; then
		echo "Output directory is not empty: $output_dir" >&2
		exit 2
	fi
fi

case $seed in
	6.17)
		compatibility_note="Ubuntu 6.17 seed for CIX Linux 6.18; this is not an Ubuntu 6.18 configuration"
		consumers_json='["6.18"]'
		candidates=(
			"Ubuntu Questing|https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/questing|master-next|questing"
			"Ubuntu Noble HWE 6.17|https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/noble|hwe-6.17-next|noble"
		)
		;;
	7.0)
		compatibility_note="Ubuntu 7.0 seed for CIX Linux 7.0 and 7.1; it is exact-series for 7.0 and adjacent-series for 7.1"
		consumers_json='["7.0", "7.1"]'
		candidates=(
			"Ubuntu Resolute|https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/resolute|master-next|resolute"
			"Ubuntu Noble HWE 7.0|https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/noble|hwe-7.0-next|noble"
		)
		;;
	*)
		echo "Unsupported Ubuntu configuration seed: $seed" >&2
		exit 2
		;;
esac

mkdir -p "$work_dir"
clone_dir="$work_dir/ubuntu-config-clone"
stage_dir="$work_dir/ubuntu-config-export"

cleanup() {
	rm -rf -- "$clone_dir" "$stage_dir"
}
trap cleanup EXIT

export GIT_TERMINAL_PROMPT=0
export LC_ALL=C

selected=0
for candidate in "${candidates[@]}"; do
	IFS='|' read -r source_name repository requested_ref expected_distribution <<<"$candidate"
	cleanup
	mkdir -p "$stage_dir"

	echo "Trying $source_name $requested_ref for Ubuntu kernel seed $seed"
	if ! timeout --foreground --kill-after=30s 10m \
		git clone \
			--depth=1 \
			--single-branch \
			--no-tags \
			--sparse \
			--branch "$requested_ref" \
			"$repository" \
			"$clone_dir"; then
		echo "Failed to clone $source_name $requested_ref; trying the next official source" >&2
		continue
	fi

	if ! resolved_commit=$(git -C "$clone_dir" rev-parse --verify 'HEAD^{commit}'); then
		echo "Failed to resolve the cloned $source_name commit" >&2
		continue
	fi
	if ! resolved_date=$(git -C "$clone_dir" show -s --format=%cI HEAD); then
		echo "Failed to resolve the cloned $source_name commit date" >&2
		continue
	fi
	if ! makefile=$(git -C "$clone_dir" show HEAD:Makefile); then
		echo "$source_name lacks the kernel Makefile needed for series validation" >&2
		continue
	fi

	kernel_major=$(sed -n 's/^VERSION[[:space:]]*=[[:space:]]*//p' <<<"$makefile")
	kernel_minor=$(sed -n 's/^PATCHLEVEL[[:space:]]*=[[:space:]]*//p' <<<"$makefile")
	kernel_sublevel=$(sed -n 's/^SUBLEVEL[[:space:]]*=[[:space:]]*//p' <<<"$makefile")
	resolved_seed="${kernel_major}.${kernel_minor}"
	if [[ ! $kernel_major =~ ^[0-9]+$ || ! $kernel_minor =~ ^[0-9]+$ ||
		! $kernel_sublevel =~ ^[0-9]+$ || $resolved_seed != "$seed" ]]; then
		echo "$source_name $requested_ref resolved kernel ${kernel_major}.${kernel_minor}.${kernel_sublevel}, expected seed $seed" >&2
		continue
	fi

	if ! git -C "$clone_dir" sparse-checkout set --no-cone /debian/debian.env; then
		echo "Failed to materialize $source_name debian/debian.env" >&2
		continue
	fi
	debian_env="$clone_dir/debian/debian.env"
	if [[ ! -f $debian_env ]]; then
		echo "$source_name does not provide debian/debian.env" >&2
		continue
	fi
	mapfile -t debian_values < <(sed -n 's/^DEBIAN=//p' "$debian_env")
	debian_nonempty=$(sed '/^[[:space:]]*$/d' "$debian_env")
	if ((${#debian_values[@]} != 1)) ||
		[[ $debian_nonempty != "DEBIAN=${debian_values[0]-}" ]]; then
		echo "$source_name has an unsupported debian/debian.env format" >&2
		continue
	fi
	debian_dir=${debian_values[0]}
	if [[ ! $debian_dir =~ ^debian\.[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
		echo "$source_name selected an unsafe Debian packaging directory: $debian_dir" >&2
		continue
	fi

	if ! changelog_head=$(git -C "$clone_dir" show "HEAD:${debian_dir}/changelog" | sed -n '1p'); then
		echo "$source_name lacks ${debian_dir}/changelog" >&2
		continue
	fi
	changelog_pattern="^[^[:space:]]+[[:space:]]+\\([^)]+\\)[[:space:]]+${expected_distribution};"
	if [[ ! $changelog_head =~ $changelog_pattern ]]; then
		echo "$source_name changelog does not identify the expected $expected_distribution distribution: $changelog_head" >&2
		continue
	fi

	sparse_paths=(
		"/${debian_dir}/config"
		/debian/scripts
		/debian/debian.env
	)
	if [[ $debian_dir != debian.master ]]; then
		sparse_paths+=(/debian.master/config)
	fi
	if ! git -C "$clone_dir" sparse-checkout set --no-cone "${sparse_paths[@]}"; then
		echo "Failed to materialize the complete $source_name annotations input" >&2
		continue
	fi
	annotations="$clone_dir/$debian_dir/config/annotations"
	annotations_tool="$clone_dir/debian/scripts/misc/annotations"
	if [[ ! -f $annotations || ! -f $annotations_tool ]]; then
		echo "$source_name does not provide the selected annotations file and exporter" >&2
		continue
	fi
	flavour_header=$(sed -n 's/^# FLAVOUR:[[:space:]]*//p' "$annotations" | sed -n '1p')
	for required_flavour in arm64-generic arm64-generic-64k; do
		if [[ " $flavour_header " != *" $required_flavour "* ]]; then
			echo "$source_name $debian_dir does not advertise $required_flavour" >&2
			continue 2
		fi
	done

	export_failed=0
	for flavour in generic generic-64k; do
		config="$stage_dir/arm64-${flavour}.config"
		if ! python3 "$annotations_tool" \
			-f "$annotations" \
			--arch arm64 \
			--flavour "$flavour" \
			--export >"${config}.tmp"; then
			echo "$source_name failed to export arm64/$flavour, including its annotation closure" >&2
			export_failed=1
			break
		fi
		mv "${config}.tmp" "$config"
		if [[ ! -s $config ]] || ! grep -q '^CONFIG_' "$config"; then
			echo "$source_name exported an empty or malformed arm64/$flavour configuration" >&2
			export_failed=1
			break
		fi
	done
	if ((export_failed)); then
		continue
	fi
	if ! grep -qx 'CONFIG_ARM64_4K_PAGES=y' "$stage_dir/arm64-generic.config" ||
		! grep -qx 'CONFIG_ARM64_64K_PAGES=y' "$stage_dir/arm64-generic-64k.config"; then
		echo "$source_name exports do not implement the requested 4K and 64K arm64 flavours" >&2
		continue
	fi

	generic_sha256=$(sha256sum "$stage_dir/arm64-generic.config" | awk '{print $1}')
	generic_64k_sha256=$(sha256sum "$stage_dir/arm64-generic-64k.config" | awk '{print $1}')
	annotations_sha256=$(sha256sum "$annotations" | awk '{print $1}')
	generic_lines=$(wc -l <"$stage_dir/arm64-generic.config")
	generic_64k_lines=$(wc -l <"$stage_dir/arm64-generic-64k.config")

	python3 - \
		"$stage_dir/metadata.json" \
		"$source_name" \
		"$repository" \
		"$requested_ref" \
		"$resolved_commit" \
		"$resolved_date" \
		"$seed" \
		"${kernel_major}.${kernel_minor}.${kernel_sublevel}" \
		"$expected_distribution" \
		"$debian_dir" \
		"${debian_dir}/config/annotations" \
		"$annotations_sha256" \
		"$generic_sha256" \
		"$generic_lines" \
		"$generic_64k_sha256" \
		"$generic_64k_lines" \
		"$consumers_json" \
		"$compatibility_note" <<'PY'
import json
import sys
from pathlib import Path

(
    output,
    source,
    repository,
    requested_ref,
    resolved_commit,
    resolved_date,
    seed,
    kernel_version,
    distribution,
    debian_directory,
    annotations_path,
    annotations_sha256,
    generic_sha256,
    generic_lines,
    generic_64k_sha256,
    generic_64k_lines,
    consumers_json,
    compatibility_note,
) = sys.argv[1:]

metadata = {
    "schema_version": 1,
    "source": source,
    "repository": repository,
    "requested_ref": requested_ref,
    "resolved_commit": resolved_commit,
    "resolved_commit_date": resolved_date,
    "declared_seed": seed,
    "source_kernel_series": ".".join(kernel_version.split(".")[:2]),
    "source_kernel_version": kernel_version,
    "distribution": distribution,
    "debian_directory": debian_directory,
    "annotations": {
        "path": annotations_path,
        "sha256": annotations_sha256,
    },
    "consumer_lines": json.loads(consumers_json),
    "compatibility_note": compatibility_note,
    "configs": {
        "arm64-generic.config": {
            "sha256": generic_sha256,
            "lines": int(generic_lines),
        },
        "arm64-generic-64k.config": {
            "sha256": generic_64k_sha256,
            "lines": int(generic_64k_lines),
        },
    },
}
Path(output).write_text(
    json.dumps(metadata, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY

	mkdir -p "$output_dir"
	install -m 0644 "$stage_dir/arm64-generic.config" "$output_dir/arm64-generic.config"
	install -m 0644 "$stage_dir/arm64-generic-64k.config" "$output_dir/arm64-generic-64k.config"
	install -m 0644 "$stage_dir/metadata.json" "$output_dir/metadata.json"
	selected=1
	echo "Selected $source_name $requested_ref at $resolved_commit ($resolved_date), kernel ${kernel_major}.${kernel_minor}.${kernel_sublevel}, $debian_dir"
	break
done

if ((!selected)); then
	echo "Failed to export Ubuntu arm64 configurations for kernel seed $seed" >&2
	exit 1
fi
