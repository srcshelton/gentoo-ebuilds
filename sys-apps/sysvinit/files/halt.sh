#!/bin/sh
if [ "${INIT_HALT}" = HALT ]; then
	exec /sbin/halt -dh
else
	exec /sbin/poweroff -dh
fi
