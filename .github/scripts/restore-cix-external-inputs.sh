#!/bin/bash

set -euo pipefail

if (($# != 2)); then
	echo "Usage: restore-cix-external-inputs.sh FALLBACK-DIR OUTPUT-DIR" >&2
	exit 2
fi

fallback_dir=$1
output_dir=$2
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ $fallback_dir == / || $output_dir == / || $fallback_dir == "$output_dir" ]]; then
	echo "Refusing unsafe retained-input directories" >&2
	exit 2
fi
if [[ ! -d $fallback_dir ]]; then
	echo "Fallback directory is absent: $fallback_dir" >&2
	exit 2
fi
if [[ -e $output_dir ]]; then
	echo "Output path already exists: $output_dir" >&2
	exit 2
fi

candidate="${output_dir}.candidate"
rm -rf -- "$candidate"
trap 'rm -rf -- "$candidate"' EXIT

restored=false
if [[ ${CIX_EXTERNAL_INPUTS_OFFLINE:-0} != 1 && -n ${GITHUB_REPOSITORY:-} ]] &&
	command -v gh >/dev/null; then
	run_id=$(gh run list \
		--repo "$GITHUB_REPOSITORY" \
		--workflow cix-external-inputs.yml \
		--branch master \
		--status success \
		--limit 1 \
		--json databaseId \
		--jq '.[0].databaseId' 2>/dev/null || :)
	if [[ -n $run_id ]] &&
		gh run download "$run_id" \
			--repo "$GITHUB_REPOSITORY" \
			--name cix-external-inputs \
			--dir "$candidate" 2>/dev/null &&
		"$script_dir/validate-cix-external-inputs.py" "$candidate"; then
		restored=true
		echo "Restored retained external inputs from workflow run $run_id"
	else
		echo "::warning::Unable to restore a retained external-input artifact; using the repository fallback"
		rm -rf -- "$candidate"
	fi
fi

if [[ $restored != true ]]; then
	mkdir -p "$candidate"
	cp -a "$fallback_dir/." "$candidate/"
	"$script_dir/validate-cix-external-inputs.py" "$candidate"
fi

mv "$candidate" "$output_dir"
trap - EXIT
