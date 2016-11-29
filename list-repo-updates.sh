#! /usr/bin/env bash

set -u

# list-repo-updates.sh
#
# Show a list of packages which exist with identical versions in both the main
# Gentoo repo and also in this overlay where the upstream version is installed.
#

debug="${DEBUG:-}"
trace="${TRACE:-}"

[[ " ${*:-} " =~ \ -(h|-help)\  ]] && {
	echo "$( basename "${0}" ) [EROOT]"
	exit 0
}
[[ " ${*:-} " =~ \ -(v|-verbose)\  ]] && {
	debug=1
}

root="${1:-${EROOT:-${EPREFIX:-/}}}"
(( debug )) && echo >&2 "DEBUG: Using root '${root:-/}'"

repo='srcshelton'
overlay="$( portageq get_repo_path "${root:-/}" "${repo}" )/" || {
	echo >&2 "ERROR: Cannot find filesystem path for repo '${repo}'"
	exit 1
}
[[ -n "${overlay:-}" && -d "${overlay}" ]] || {
	echo >&2 "ERROR: Cannot access directory '${overlay:-}' for repo '${repo}'"
	exit 1
}
(( debug )) && echo >&2 "DEBUG: Using overlay directory '${overlay}'"

(( trace )) && set -o xtrace

declare -i rc=0
find "${overlay}" -mindepth 3 -maxdepth 3 -name \*.ebuild |
	sed "s|^${overlay}|| ; s/\.ebuild$//" |
	cut -d'/' -f 1,3 |
	while read -r d; do
		[[ -d /var/db/pkg/${d} ]] &&
			echo "${d}"
	done |
	sed 's/^/~/' |
	xargs emerge -vp |
	grep '::gentoo'
rc=${?}

(( trace )) && set +o xtrace

exit $(( ! rc ))

