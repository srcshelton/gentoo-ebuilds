#!/bin/sh
#
# establish the chains that miniupnpd will update dynamically
#
# 'add' doesn't raise an error if the object already exists. 'create' does.
#

#opts="--echo"

command -v nft >/dev/null 2>&1 || exit 1

echo "  * Creating 'nat' table"
nft ${opts} add table nat

echo "  * Creating miniupnpd chain in 'nat' table"
nft ${opts} add chain nat MINIUPNPD

echo "  * Creating miniupnpd Port Control Protocol peer chain in 'nat' table"
nft ${opts} add chain nat MINIUPNPD-POSTROUTING

echo "  * Creating 'filter' table"
nft ${opts} add table inet filter

echo "  * Creating miniupnpd chain in 'filter' table"
nft ${opts} add chain inet filter MINIUPNPD
