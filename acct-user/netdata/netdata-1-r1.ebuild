# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="User for net-analyzer/netdata"
IUSE="podman"

ACCT_USER_ID=290
ACCT_USER_GROUPS=( netdata )
ACCT_USER_HOME=/var/empty

RDEPEND="podman? ( acct-group/podman )"

acct-user_add_deps

pkg_setup() {
	if use podman; then
		ACCT_USER_GROUPS+=( podman )
	fi
}
