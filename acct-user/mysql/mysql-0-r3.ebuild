# Copyright 2019-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for dev-db/mysql & dev-db/mariadb"
ACCT_USER_ID=60
ACCT_USER_GROUPS=( mysql hugetlb )
acct-user_add_deps
SLOT="0"
