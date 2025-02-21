#! /usr/bin/env bash

set -eu  # x
set -o pipefail

TEMPLATE='os-headers-0-r2.ebuild'

die() {
	echo >&2 "FATAL: ${*:-"Unknown error"}"
	exit 1
}

cd "$( dirname "$( readlink -e "${0}" )" )/.." ||
	die "Cannot locate script directory"

[[ -s "${TEMPLATE}" ]] ||
	die "Cannot locate base/template file '${TEMPLATE}'"

# os-headers-0_p20639.ebuild
for f in *_p*.ebuild; do
	: $(( major = 0 ))
	: $(( minor = 0 ))
	: $(( revision = 0 ))
	: $(( version = 0 ))

	f="${f%".ebuild"}"
	f="${f#*"-0_p"}"

	: $(( number = f ))

	major="${number:0:1}"
	minor="${number:1:2}"
	revision="${number:3:2}"

	f="os-headers-0_p${major}${minor}${revision}.ebuild"

	if ! [[ -s "${f}" ]]; then
		echo >&2 "ERROR: Generated filename '${f}' does not exist"
		exit 1
	fi
	if [[ "${f}" == "${TEMPLATE}" ]]; then
		die "Attempting to overwrite base/template file '${f}'"
	fi

	minor="$( sed 's/^0\+//' <<<"${minor}" )"
	revision="$( sed 's/^0\+//' <<<"${revision}" )"

	version="${major:-0}.${minor:-0}$( (( revision <= 0 )) || echo ".${revision}" )"
	echo "DEBUG: '${f}' -> ${version}"

	sed \
			-e "s#sys-kernel/\([^-]\+\)-headers:0#>=sys-kernel/\1-headers-${version}:0#" \
			-e "/SLOT=/s#\"0\"#\"${number}\"#" \
				< "${TEMPLATE}" > "${f}" ||
		die "sed failed: ${?}"
done
