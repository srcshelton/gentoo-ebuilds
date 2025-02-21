# Copyright 2019-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-group

DESCRIPTION="group for crontab"
IUSE="-compat"

ACCT_GROUP_ID=116  # Pre-standardisation
#ACCT_GROUP_ID=460  # Official GID

pkg_setup() {
	if use compat; then
		ACCT_USER_ID=116
	else
		ACCT_USER_ID=460
	fi
}
