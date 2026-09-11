# Copyright 2019-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=9

inherit acct-group

IUSE="-compat"

DESCRIPTION="group for ml-apps/ollama"

ACCT_GROUP_ID=796  # Pre-standardisation
#ACCT_GROUP_ID=562  # Official GID

pkg_setup() {
	if use compat; then
		ACCT_GROUP_ID=796
	else
		ACCT_GROUP_ID=562
	fi
}
