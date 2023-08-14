#!/bin/sh
# Copyright (c) 2007-2015 The OpenRC Authors.
# See the Authors file at the top-level directory of this distribution and
# https://github.com/OpenRC/openrc/blob/HEAD/AUTHORS
#
# This file is part of OpenRC. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/OpenRC/openrc/blob/HEAD/LICENSE
# This file may not be copied, modified, propagated, or distributed
#    except according to the terms contained in the LICENSE file.

: "${RC_LIBEXECDIR:="/lib/rc"}"
: "${RC_SVCDIR:="${RC_LIBEXECDIR}/init.d"}"

svcdir_restorecon()
{
	rc=0

	if [ -x /usr/sbin/selinuxenabled ] && [ -c /selinux/null ] &&
	  selinuxenabled; then
		restorecon "${RC_SVCDIR}" ||
			rc=$?
	fi

	return $rc
}

# This basically mounts $RC_SVCDIR as a ramdisk, but preserving its content
# which allows us to run depscan.sh
#
# (This is only necessary if RC_SVCDIR isn't beneath (/var)/run, which is
# assumed to already be a tmpfs mount before we get this far...
#
mount_svcdir()
{
	# mount from fstab if we can
	"${RC_LIBEXECDIR}"/bin/fstabinfo --mount "${RC_SVCDIR}" &&
		return 0

	fs='' fsopts='-o rw,noexec,nodev,nosuid'
	svcsize="${rc_svcsize:-1024}"
	rc=-1

	# Some buggy kernels report tmpfs even when not present :(
	if grep -q -- "\s\+tmpfs$" /proc/filesystems; then
		tmpfsopts="${fsopts},mode=755,size=${svcsize}k"
		if eval "mount -n -t tmpfs ${tmpfsopts} rc-svcdir ${RC_SVCDIR}"
		then
			svcdir_restorecon
			rc=${?}
		fi
		unset tmpfsopts
	fi

	if [ $(( rc )) -eq -1 ]; then
		if grep -q -- "\s\+ramfs$" /proc/filesystems; then
			fs='ramfs'
			# ramfs has no special options
		elif [ -e /dev/ram0 ] &&
				grep -q -- "\s\+ext2$" /proc/filesystems
		then
			devdir='/dev/ram0'
			fs='ext2'
			dd if=/dev/zero of="${devdir}" bs=1k count="${svcsize}"
			mkfs -t "${fs}" -i 1024 -vm0 "${devdir}" "${svcsize}"
			unset devdir
		else
			echo
			"${RC_LIBEXECDIR}"/bin/eerror "OpenRC requires" \
				"tmpfs, ramfs or a ramdisk + ext2"
			"${RC_LIBEXECDIR}"/bin/eerror "compiled into the" \
				"kernel"
			echo
			rc=1
		fi

		if [ $(( rc )) -ne 1 ]; then
			if eval "mount -n -t ${fs} ${fsopts} rc-svcdir ${RC_SVCDIR}"
			then
				svcdir_restorecon
				rc=${?}
			fi
		fi
	fi

	unset svcsize fsopts fs
	return ${rc}
}

# mount $RC_SVCDIR as something we can write to if it's not rw
#
# On vservers, / is always rw at this point, so we need to clean out
# the old service state data
#
case "$(openrc --sys)" in
	OPENVZ|VSERVER)
		rm -rf "${RC_SVCDIR:?}"/*
		;;
	*)
		if "${RC_LIBEXECDIR}"/bin/mountinfo --quiet "${RC_SVCDIR}"; then
			rm -rf "${RC_SVCDIR:?}"/*
		else
			mount_svcdir
		fi
		;;
esac
if [ $(( $? )) -ne 0 ]; then
	exit 1
fi
