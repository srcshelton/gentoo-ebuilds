#!/bin/bash
# $Id: iptables_removeall.sh,v 1.8 2014/04/15 13:45:08 nanard Exp $

set -o pipefail

IPTABLES="$( which iptables )" || exit 1
IP="$( which ip )" || exit 1

# Change these parameters:
EXTIF_default="eth0"

EXTIF="$( LC_ALL=C $IP -4 route | grep 'default' | sed -e 's/.*dev[[:space:]]*//' -e 's/[[:space:]].*//' )"
[[ -n "${EXTIF}" ]] || EXTIF="${EXTIF_default}"
EXTIP="$( LC_ALL=C $IP -4 addr show $EXTIF | awk '/inet/ { print $2 }' | cut -d "/" -f 1 )"

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

	(( DEBUG )) && echo "     ${IPTABLES:-iptables} -w ${rule[*]}"
	"${IPTABLES:-iptables}" -w "${rule[@]}" || {
		echo >&2 "Failed: ${IPTABLES:-iptables} -w ${rule[*]}"
		false
	}

	return ${?}
}

debug "Detected external interface '${EXTIF}' with IP address '${EXTIP}'"

debug "Flushing NAT chain '${CHAIN}'"
doiptables -t nat -F "${CHAIN}"

debug "Deleting NAT PREROUTING rules"
if (( BRIDGED )) && [[ -n "${BRIF}" ]]; then
	doiptables -t nat -D PREROUTING -i "${BRIF}" -m physdev --physdev-in "${EXTIF}" --physdev-is-bridged -j "${CHAIN}"
else
	doiptables -t nat -D PREROUTING -i "${EXTIF}" -d "${EXTIP}" -j "${CHAIN}"
	doiptables -t nat -D PREROUTING -i "${EXTIF}" -j "${CHAIN}"
fi

debug -n "Deleting NAT chain '${CHAIN}' ..."
doiptables -t nat -X "${CHAIN}" >/dev/null 2>&1 && debug -f " okay" || debug -f " failed"

debug "Flushing MANGLE chain '${CHAIN}'"
doiptables -t mangle -F "${CHAIN}"

debug "Deleting MANGLE PREROUTING rules"
if (( BRIDGED )) && [[ -n "${BRIF}" ]]; then
	doiptables -t mangle -D PREROUTING -i "${BRIF}" -m physdev --physdev-in "${EXTIF}" --physdev-is-bridged -j "${CHAIN}"
else
	doiptables -t mangle -D PREROUTING -i "${EXTIF}" -j "${CHAIN}"
fi

debug -n "Deleting MANGLE chain '${CHAIN}'"
doiptables -t mangle -X "${CHAIN}" >/dev/null 2>&1 && debug -f " okay" || debug -f " failed"

debug "Flushing FILTER chain '${CHAIN}'"
doiptables -t filter -F "${CHAIN}"

debug "Deleting FILTER FORWARD rules"
if (( BRIDGED )) && [[ -n "${BRIF}" ]]; then
	doiptables -t filter -D FORWARD -i "${BRIF}" -m physdev --physdev-in "${EXTIF}" ! --physdev-out "${EXTIF}" --physdev-is-bridged -j "${CHAIN}"
else
	doiptables -t filter -D FORWARD -i "${EXTIF}" ! -o "${EXTIF}" -j "${CHAIN}"
fi

debug -n "Deleting FILTER chain '${CHAIN}'"
doiptables -t filter -X "${CHAIN}" >/dev/null 2>&1 && debug -f " okay" || debug -f " failed"

debug "Flushing NAT chain '${CHAIN}-PCP-PEER'"
doiptables -t nat -F "${CHAIN}-PCP-PEER"

debug "Deleting NAT POSTROUTING rules"
if (( BRIDGED )) && [[ -n "${BRIF}" ]]; then
	doiptables -t nat -D POSTROUTING -i "${BRIF}" -m physdev --physdev-in "${EXTIF}" --physdev-is-bridged -j "${CHAIN}"
else
	doiptables -t nat -D POSTROUTING -o "${EXTIF}" -j "${CHAIN}-PCP-PEER"
fi

debug -n "Deleting NAT chain '${CHAIN}-PCP-PEER' ..."
doiptables -t nat -X "${CHAIN}-PCP-PEER" >/dev/null 2>&1 && debug -f " okay" || debug -f " failed"
