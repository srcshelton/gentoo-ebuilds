# Copyright 2019-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="user for ml-apps/ollama"

ACCT_USER_ID=796
ACCT_USER_GROUPS=( ollama )
ACCT_USER_HOME=/var/lib/ollama
ACCT_USER_HOME_PERMS=0700

acct-user_add_deps
