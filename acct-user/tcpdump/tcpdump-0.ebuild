# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for tcpdump"
ACCT_USER_ID=473
ACCT_USER_GROUPS=( tcpdump )

acct-user_add_deps
