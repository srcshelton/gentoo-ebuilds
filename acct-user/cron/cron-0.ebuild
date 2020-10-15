# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="user for cron daemon"
ACCT_USER_ID=16
ACCT_USER_ENFORCE_ID=1
ACCT_USER_HOME='/var/spool/cron'
ACCT_USER_HOME_OWNER='root:cron'
ACCT_USER_HOME_PERMS='0750'
ACCT_USER_GROUPS=( cron )

acct-user_add_deps
