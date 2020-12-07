# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for mail filter daemons"
ACCT_USER_ID=440
ACCT_USER_GROUPS=( milter )

acct-user_add_deps
