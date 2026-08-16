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
		compatibility_note="Ubuntu 7.0 seed for CIX Linux 7.1 and 7.2; this is an adjacent-series configuration"
		consumers_json='["7.1", "7.2"]'
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
source_dir="$work_dir/ubuntu-config-source"
stage_dir="$work_dir/ubuntu-config-export"

cleanup() {
	rm -rf -- "$source_dir" "$stage_dir"
}
trap cleanup EXIT

export LC_ALL=C

fetch_validated() {
	local url=$1
	local destination=$2
	local pattern=$3
	local description=$4
	local attempt
	local temporary="${destination}.tmp"

	mkdir -p "${destination%/*}"
	for ((attempt = 1; attempt <= 6; attempt++)); do
		rm -f -- "$temporary"
		if timeout --foreground --kill-after=10s 75s \
			curl \
				--connect-timeout 20 \
				--fail \
				--location \
				--max-time 60 \
				--retry 2 \
				--retry-all-errors \
				--retry-delay 1 \
				--show-error \
				--silent \
				--output "$temporary" \
				"$url" &&
			grep -Eq "$pattern" "$temporary"; then
			mv "$temporary" "$destination"
			return 0
		fi
		echo "Failed to fetch valid $description (attempt $attempt of 6)" >&2
		sleep "$attempt"
	done
	rm -f -- "$temporary"
	return 1
}

resolve_ref() {
	local repository=$1
	local requested_ref=$2
	local feed="$source_dir/ref.atom"

	if ! fetch_validated \
		"${repository}/atom/?h=${requested_ref}" \
		"$feed" \
		'^<feed xmlns=' \
		"$repository $requested_ref feed"; then
		return 1
	fi
	python3 - "$feed" "$requested_ref" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

feed = ET.fromstring(Path(sys.argv[1]).read_text(encoding="utf-8"))
namespace = {"atom": "http://www.w3.org/2005/Atom"}
title = feed.findtext("atom:title", namespaces=namespace)
if not title or not title.endswith(f", branch {sys.argv[2]}"):
    raise SystemExit(f"unexpected cgit feed title: {title!r}")
entry = feed.find("atom:entry", namespace)
commit = entry.findtext("atom:id", namespaces=namespace) if entry is not None else None
if not commit or not re.fullmatch(r"[0-9a-f]{40}", commit):
    raise SystemExit("the cgit feed lacks a valid tip commit")
print(commit)
PY
}

fetch_repository_file() {
	local repository_path=$1
	local destination=$2
	local pattern=$3
	local description=$4

	fetch_validated \
		"${repository}/plain/${repository_path}?id=${resolved_commit}" \
		"$destination" \
		"$pattern" \
		"$description"
}

declare -a fetched_annotations=()

fetch_annotations() {
	local repository_path=$1
	local destination="$source_dir/$repository_path"
	local include_list="${destination}.includes"
	local -a included_paths
	local fetched_path
	local included_path

	for fetched_path in "${fetched_annotations[@]}"; do
		[[ $fetched_path != "$repository_path" ]] || return 0
	done
	fetched_annotations+=("$repository_path")
	if ! fetch_repository_file \
		"$repository_path" \
		"$destination" \
		'^(# (FORMAT|ARCH|FLAVOUR):|CONFIG_|include[[:space:]])' \
		"$repository_path"; then
		return 1
	fi
	if ! python3 - "$repository_path" "$destination" >"$include_list" <<'PY'
import posixpath
import re
import sys
from pathlib import Path

repository_path = sys.argv[1]
annotations = Path(sys.argv[2])
for line in annotations.read_text(encoding="utf-8").splitlines():
    match = re.fullmatch(r'include\s+"?([^"\s]+)"?\s*', line)
    if not match:
        continue
    included = posixpath.normpath(
        posixpath.join(posixpath.dirname(repository_path), match.group(1))
    )
    if included == ".." or included.startswith("../") or included.startswith("/"):
        raise SystemExit(f"unsafe annotations include: {match.group(1)}")
    print(included)
PY
	then
		rm -f -- "$include_list"
		return 1
	fi
	mapfile -t included_paths <"$include_list"
	rm -f -- "$include_list"
	for included_path in "${included_paths[@]}"; do
		[[ -z $included_path ]] || fetch_annotations "$included_path" || {
			return 1
		}
	done
}

selected=0
for candidate in "${candidates[@]}"; do
	IFS='|' read -r source_name repository requested_ref expected_distribution <<<"$candidate"
	cleanup
	mkdir -p "$source_dir" "$stage_dir"
	fetched_annotations=()

	echo "Trying $source_name $requested_ref for Ubuntu kernel seed $seed"
	if ! resolved_commit=$(resolve_ref "$repository" "$requested_ref"); then
		echo "Failed to resolve $source_name $requested_ref; trying the next official source" >&2
		continue
	fi
	commit_info="$source_dir/commit.html"
	if ! fetch_validated \
		"${repository}/commit/?id=${resolved_commit}&dt=2" \
		"$commit_info" \
		'<tr><th>committer</th>.*<td class=.right.>[^<]+</td>' \
		"$source_name commit metadata"; then
		continue
	fi
	if ! resolved_date=$(python3 - "$commit_info" <<'PY'
import datetime
import html
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(
    r"<tr><th>committer</th>.*?<td class='right'>([^<]+)</td>",
    text,
    re.DOTALL,
)
if not match:
    raise SystemExit("committer date is absent from cgit metadata")
print(
    datetime.datetime.strptime(
        html.unescape(match.group(1)), "%Y-%m-%d %H:%M:%S %z"
    ).isoformat()
)
PY
	); then
		echo "Failed to parse the $source_name commit date" >&2
		continue
	fi
	makefile_path="$source_dir/Makefile"
	if ! fetch_repository_file \
		Makefile \
		"$makefile_path" \
		'^VERSION[[:space:]]*=[[:space:]]*[0-9]+$' \
		"$source_name kernel Makefile"; then
		echo "$source_name lacks the kernel Makefile needed for series validation" >&2
		continue
	fi
	makefile=$(<"$makefile_path")

	kernel_major=$(sed -n 's/^VERSION[[:space:]]*=[[:space:]]*//p' <<<"$makefile")
	kernel_minor=$(sed -n 's/^PATCHLEVEL[[:space:]]*=[[:space:]]*//p' <<<"$makefile")
	kernel_sublevel=$(sed -n 's/^SUBLEVEL[[:space:]]*=[[:space:]]*//p' <<<"$makefile")
	resolved_seed="${kernel_major}.${kernel_minor}"
	if [[ ! $kernel_major =~ ^[0-9]+$ || ! $kernel_minor =~ ^[0-9]+$ ||
		! $kernel_sublevel =~ ^[0-9]+$ || $resolved_seed != "$seed" ]]; then
		echo "$source_name $requested_ref resolved kernel ${kernel_major}.${kernel_minor}.${kernel_sublevel}, expected seed $seed" >&2
		continue
	fi

	debian_env="$source_dir/debian/debian.env"
	if ! fetch_repository_file \
		debian/debian.env \
		"$debian_env" \
		'^DEBIAN=debian\.[A-Za-z0-9][A-Za-z0-9.-]*$' \
		"$source_name debian/debian.env"; then
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

	changelog="$source_dir/$debian_dir/changelog"
	if ! fetch_repository_file \
		"${debian_dir}/changelog" \
		"$changelog" \
		"^[^[:space:]]+[[:space:]]+\\([^)]+\\)[[:space:]]+${expected_distribution};" \
		"$source_name ${debian_dir}/changelog"; then
		echo "$source_name lacks ${debian_dir}/changelog" >&2
		continue
	fi
	changelog_head=$(sed -n '1p' "$changelog")
	changelog_pattern="^[^[:space:]]+[[:space:]]+\\([^)]+\\)[[:space:]]+${expected_distribution};"
	if [[ ! $changelog_head =~ $changelog_pattern ]]; then
		echo "$source_name changelog does not identify the expected $expected_distribution distribution: $changelog_head" >&2
		continue
	fi

	annotations_path="${debian_dir}/config/annotations"
	if ! fetch_annotations "$annotations_path"; then
		echo "Failed to fetch the complete $source_name annotations input" >&2
		continue
	fi
	annotations="$source_dir/$annotations_path"
	annotations_tool="$source_dir/debian/scripts/misc/annotations"
	if ! fetch_repository_file \
		debian/scripts/misc/annotations \
		"$annotations_tool" \
		'^from kconfig import run' \
		"$source_name annotations exporter"; then
		continue
	fi
	exporter_files=(
		'annotations.py|^class Annotation'
		'run.py|^def main'
		'utils.py|^def arg_fail'
		'version.py|^VERSION[[:space:]]*='
	)
	exporter_failed=0
	for exporter in "${exporter_files[@]}"; do
		IFS='|' read -r exporter_file exporter_pattern <<<"$exporter"
		if ! fetch_repository_file \
			"debian/scripts/misc/kconfig/$exporter_file" \
			"$source_dir/debian/scripts/misc/kconfig/$exporter_file" \
			"$exporter_pattern" \
			"$source_name kconfig/$exporter_file"; then
			exporter_failed=1
			break
		fi
	done
	if ((exporter_failed)); then
		continue
	fi
	: >"$source_dir/debian/scripts/misc/kconfig/__init__.py"
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
