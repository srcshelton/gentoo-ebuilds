# Copyright 2020-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for net-misc/memcached"
ACCT_USER_ID=441
ACCT_USER_GROUPS=( memcached hugetlb )

acct-user_add_deps
