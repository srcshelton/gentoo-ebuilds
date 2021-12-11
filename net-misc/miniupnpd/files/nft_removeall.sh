#!/bin/sh
#
# Undo the things nft_init.sh did
#
# Do not disturb other existing structures in nftables, e.g. those created by firewalld
#

command -v nft >/dev/null 2>&1 || exit 1

if nft --check list table nat >/dev/null 2>&1; then
	# nat table exists, so first remove the chains we added
	nft --check list chain nat MINIUPNPD > /dev/null 2>&1
	if [ $? -eq "0" ]; then
		echo "  * Removing miniupnpd chain from 'nat' table"
		nft delete chain nat MINIUPNPD
	fi

	nft --check list chain nat MINIUPNPD-POSTROUTING > /dev/null 2>&1
	if [ $? -eq "0" ]; then
		echo "  * Removing miniupnpd pcp peer chain from 'nat' table"
		nft delete chain nat MINIUPNPD-POSTROUTING
	fi

	# Do *not* delete the entire NAT table, this removes all nft-backed
	# xtables rules!
	#
	#echo "  * Removing 'nat' table"
	#nft delete table nat
fi

if nft --check list table inet filter >/dev/null 2>&1; then
	# filter table exists, so first remove the chain we added
	nft --check list chain inet filter MINIUPNPD > /dev/null 2>&1
	if [ $? -eq "0" ]; then
		echo "  * Removing miniupnpd chain from 'filter' table"
		nft delete chain inet filter MINIUPNPD
	fi

	# Do *not* delete the entire FILTER table, this removes all nft-backed
	# xtables rules!
	#
	#echo "  * Removing 'filter' table"
	#nft delete table inet filter
fi
