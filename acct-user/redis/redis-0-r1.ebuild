# Copyright 2019-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="user for redis daemon"
ACCT_USER_ID=75
ACCT_USER_GROUPS=( redis hugetlb )
acct-user_add_deps
