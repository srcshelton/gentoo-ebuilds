# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for memcached daemon"
ACCT_USER_ID=441
ACCT_USER_GROUPS=( memcached hugetlb )

acct-user_add_deps
