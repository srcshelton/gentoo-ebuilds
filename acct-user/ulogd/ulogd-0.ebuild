# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for ulogd"
ACCT_USER_ID=23
ACCT_USER_GROUPS=( ulogd )

acct-user_add_deps
