# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-group

DESCRIPTION="group for app-containers/podman socket"

ACCT_GROUP_ID=49  # After docker(48)
