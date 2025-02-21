# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

SLOT="0"

DESCRIPTION="user for dev-db/mysql & dev-db/mariadb"

ACCT_USER_ID=60
ACCT_USER_GROUPS=( mysql hugetlb )

acct-user_add_deps
