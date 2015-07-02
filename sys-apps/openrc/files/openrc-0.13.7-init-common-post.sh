# Copyright (c) 2007-2009 Roy Marples <roy@marples.name>
# Released under the 2-clause BSD license.

: ${RC_LIBEXECDIR:=/lib/rc}
: ${RC_SVCDIR:=/lib/rc/init.d}

# This basically mounts $RC_SVCDIR as a ramdisk.
# The tricky part is finding something our kernel supports
# tmpfs and ramfs are easy, so force one or the other.
svcdir_restorecon()
{
	local rc=0

	if [ -x /usr/sbin/selinuxenabled -a -c /selinux/null ] &&
	  selinuxenabled; then
		restorecon $RC_SVCDIR
		rc=$?
	fi

	return $rc
}

mount_svcdir()
{
	# mount from fstab if we can
	fstabinfo --mount "$RC_SVCDIR" && return 0

	local fs= fsopts="-o rw,noexec,nodev,nosuid"
	local svcsize=${rc_svcsize:-1024}

	# Some buggy kernels report tmpfs even when not present :(
	if grep -Eq "[[:space:]]+tmpfs$" /proc/filesystems; then
		local tmpfsopts="${fsopts},mode=755,size=${svcsize}k"
		mount -n -t tmpfs $tmpfsopts rc-svcdir "$RC_SVCDIR"
		if [ $? -eq 0 ]; then
			svcdir_restorecon
			[ $? -eq 0 ] && return 0
		fi
	fi

	if grep -Eq "[[:space:]]+ramfs$" /proc/filesystems; then
		fs="ramfs"
		# ramfs has no special options
	elif [ -e /dev/ram0 ] &&
	  grep -Eq "[[:space:]]+ext2$" /proc/filesystems; then
		devdir="/dev/ram0"
		fs="ext2"
		dd if=/dev/zero of="$devdir" bs=1k count="$svcsize"
		mkfs -t "$fs" -i 1024 -vm0 "$devdir" "$svcsize"
	else
		echo
		eerror "OpenRC requires tmpfs, ramfs or a ramdisk + ext2"
		eerror "compiled into the kernel"
		echo
		return 1
	fi

	mount -n -t "$fs" $fsopts rc-svcdir "$RC_SVCDIR"
	if [ $? -eq 0 ]; then
		svcdir_restorecon
		[ $? -eq 0 ] && return 0
	fi
}

# mount $RC_SVCDIR as something we can write to if it's not rw
# On vservers, / is always rw at this point, so we need to clean out
# the old service state data
case "$(openrc --sys)" in
	OPENVZ|VSERVER)
		rm -rf "$RC_SVCDIR"/*
		;;
	*)
		if mountinfo --quiet "$RC_SVCDIR"; then
			rm -rf "$RC_SVCDIR"/*
		else
			mount_svcdir
		fi
		;;
esac
retval=$?

if [ -e "$RC_LIBEXECDIR"/cache/deptree ]; then
	cp -p "$RC_LIBEXECDIR"/cache/* "$RC_SVCDIR" 2>/dev/null
fi

echo sysinit >"$RC_SVCDIR"/softlevel
exit $retval
