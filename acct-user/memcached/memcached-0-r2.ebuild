# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="User for net-misc/memcached"
ACCT_USER_ID=441
ACCT_USER_GROUPS=( memcached hugetlb )

acct-user_add_deps
