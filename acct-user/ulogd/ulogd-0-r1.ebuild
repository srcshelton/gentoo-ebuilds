# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="User for app-admin/ulogd"
ACCT_USER_ID=23  # Pre-standardisation
#ACCT_USER_ID=311  # Official GID
ACCT_USER_GROUPS=( ulogd )

acct-user_add_deps
