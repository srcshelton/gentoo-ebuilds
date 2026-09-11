# Copyright 2019-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=9

inherit acct-user

DESCRIPTION="user for ml-apps/ollama"

ACCT_USER_ID=796  # Pre-standardisation
#ACCT_USER_ID=562  # Official GID

ACCT_USER_HOME=/var/lib/ollama
ACCT_USER_HOME_PERMS=0750
ACCT_USER_GROUPS=( ollama )

IUSE="-compat cuda"

acct-user_add_deps

RDEPEND+="
	cuda? (
		acct-group/video
	)
"

pkg_setup() {
	# sci-ml/ollama[cuda]
	if use cuda; then
		ACCT_USER_GROUPS+=( video )
	fi

	if use compat; then
		ACCT_USER_ID=796
	else
		ACCT_USER_ID=562
	fi
}
