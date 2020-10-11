#!/bin/bash
# $Id: ip6tables_removeall.sh,v 1.1 2012/04/24 22:13:41 nanard Exp $

set -o pipefail

IPTABLES="$( which ip6tables )" || exit 1
IP="$( which ip )" || exit 1

# Change these parameters:
EXTIF_default="eth0"

EXTIF="$( LC_ALL=C $IP -6 route | grep 'default' | sed -e 's/.*dev[[:space:]]*//' -e 's/[[:space:]].*//' )"
[[ -n "${EXTIF}" ]] || EXTIF="${EXTIF_default}"
EXTIP="$( LC_ALL=C $IP -6 addr show $EXTIF | awk '/inet/ { print $2 }' | cut -d "/" -f 1 )"

CHAIN="MINIUPNPD"
BRIDGED=0
BRIF="br0"

DEBUG="${DEBUG:-0}"

debug() {
	local opt="${1}"
	local message="${*}"
	local spaces="   "

	case "${opt:-}" in
		-n)
			shift
			message="${*}"
			;;
		-f)
			shift
			message="${*}"
			unset opt
			unset spaces
			;;
		*)
			unset opt
			;;
	esac

	(( DEBUG )) && echo ${opt:-} "${spaces:-}${message:-}"

	return $(( ! DEBUG ))
}

doiptables() {
	local -a rule=( "${@}" )

	(( ${#rule[@]} )) || return 1

	(( DEBUG )) && echo "     ${IPTABLES:-ip6tables} -w ${rule[*]}"
	"${IPTABLES:-ip6tables}" -w "${rule[@]}" || {
		echo "Failed: ${IPTABLES:-ip6tables} -w ${rule[*]}"
		false
	}

	return ${?}
}

debug "Detected IPv6 external interface '${EXTIF}' with IP address '${EXTIP}'"

debug "Flushing IPv6 FILTER chain '${CHAIN}'"
doiptables -t filter -F "${CHAIN}"

debug "Deleting IPv6 FILTER FORWARD rules"
if (( BRIDGED )) && [[ -n "${BRIF}" ]]; then
	doiptables -t filter -D FORWARD -i "${BRIF}" -m physdev --physdev-in "${EXTIF}" ! --physdev-out "${EXTIF}" --physdev-is-bridged -j "${CHAIN}"
else
	doiptables -t filter -D FORWARD -i "${EXTIF}" ! -o "${EXTIF}" -j "${CHAIN}"
fi

debug -n "Deleting IPv6 FILTER chain '${CHAIN}'"
doiptables -t filter -X "${CHAIN}" >/dev/null 2>&1 && debug -f " okay" || debug -f " failed"
