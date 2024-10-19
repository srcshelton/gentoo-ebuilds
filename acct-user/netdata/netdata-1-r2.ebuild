# Copyright 2019-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for net-analyzer/netdata"
IUSE="podman ssl"

ACCT_USER_ID=290
ACCT_USER_GROUPS=( netdata )
ACCT_USER_HOME=/var/empty

RDEPEND="
	podman? ( acct-group/podman )
	ssl? ( acct-group/wheel )
"

acct-user_add_deps

pkg_setup() {
	if use podman; then
		ACCT_USER_GROUPS+=( podman )
	fi
	if use ssl; then
		ACCT_USER_GROUPS+=( wheel )
	fi
}
