# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-group

DESCRIPTION="group for mail-mta/ssmtp"
IUSE="-compat"

ACCT_GROUP_ID=125  # Pre-standardisation
#ACCT_GROUP_ID="299"  # Official GID

pkg_setup() {
	if use compat; then
		ACCT_USER_ID=125
	else
		ACCT_USER_ID=299
	fi
}
