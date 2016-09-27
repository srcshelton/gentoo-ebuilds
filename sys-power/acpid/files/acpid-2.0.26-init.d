#!/sbin/openrc-run
# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 7f3ff3c72ab8b72cbffd0c943f233d220c3c7e8b $

extra_started_commands="reload"
command="/usr/sbin/acpid"
command_args="${ACPID_ARGS}"
#start_stop_daemon_args="--quiet"
description="Daemon for Advanced Configuration and Power Interface"

depend() {
	need localmount
	use logger
}

reload() {
	ebegin "Reloading acpid configuration"
	start-stop-daemon --exec $command --signal HUP
	eend $?
}
