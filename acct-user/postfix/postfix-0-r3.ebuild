# Copyright 2019-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for mail-mta/postfix"
IUSE="+milter opendkim"

ACCT_USER_ID=207
ACCT_USER_GROUPS=( postfix mail )

RDEPEND="
	milter? ( acct-group/milter )
	opendkim? ( acct-group/opendkim )
"

acct-user_add_deps

pkg_setup() {
	if use milter; then
		ACCT_USER_GROUPS+=( milter )
	fi
	if use opendkim; then
		ACCT_USER_GROUPS+=( opendkim )
	fi
}
