# Copyright 2019-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-group

IUSE="-compat"

ACCT_GROUP_ID=24  # Avoid clash with macOS 'staff' group
#ACCT_GROUP_ID=20  # Official GID

pkg_setup() {
	if use compat; then
		ACCT_USER_ID=24
	else
		ACCT_USER_ID=20
	fi
}
