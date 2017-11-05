# Specify interface(s) to record traffic from:
NTOPNG_OPTS="-i eth0"

# Specify local network, to ensure that remote hosts don't cause the amount of
# data ntopng records to grow in an uncontrolled fashion:
NTOPNG_OPTS="${NTOPNG_OPTS} -m 192.168.0.0/16"

# Specify the directory ntopng should write data to - noting that it will fall-
# back to using /usr/tmp/ntopng if this directory is considered inaccessible
# for any reason...
NTOPNG_OPTS="${NTOPNG_OPTS} -d /var/lib/ntopng"
