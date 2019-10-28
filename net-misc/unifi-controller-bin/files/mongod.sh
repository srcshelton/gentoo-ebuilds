#! /bin/bash

declare -r MONGOD='/usr/bin/mongod'
declare args=''

if ! [[ -x "${MONGOD}" ]]; then
	echo >&2 "FATAL: '${MONGOD}' does not exist or is not executable"
	exit 1
fi

if [[ -n "${*:-}" ]]; then
	args=" ${*} "
	args="${args// --nohttpinterface }"
fi

exec "${MONGOD}" ${args:-}

# vi: sey syntax=sh:
