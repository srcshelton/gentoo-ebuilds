# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for dev-db/redis"
ACCT_USER_ID=75
ACCT_USER_GROUPS=( redis hugetlb )
acct-user_add_deps
