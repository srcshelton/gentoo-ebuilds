# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for app-admin/ulogd"
IUSE="-compat"

ACCT_USER_ID=23  # Pre-standardisation
#ACCT_USER_ID=311  # Official GID
ACCT_USER_GROUPS=( ulogd )

pkg_setup() {
	if use compat; then
		ACCT_USER_ID=23
	else
		ACCT_USER_ID=311
	fi
}

acct-user_add_deps
