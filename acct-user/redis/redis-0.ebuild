# Copyright 2019-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for dev-db/redis"

ACCT_USER_ID=75
ACCT_USER_GROUPS=( redis hugetlb )

acct-user_add_deps
