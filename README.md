
Various [Gentoo Linux](http://www.gentoo.org/) ebuilds, to provide out-of-tree packages and miscellaneous fixes.

# Fixes for compiling prefix packages under Mac OS using LLVM/clang

Some packages will fail with `illegal instruction: 4` if compiled with compiler-optimisations enabled.  To work around this on a per-package basis:

```
mkdir ${EPREFIX}/etc/portage/env

cat > ${EPREFIX}/etc/portage/env/fragile <<EOF
CC="clang"

CFLAGS="-arch x86_64 -march=core-avx-i -mmacosx-version-min=10.9"
CFLAGS="${CFLAGS} -O0 -g -pipe"

CXX="clang++"
CXXFLAGS="${CFLAGS}"
EOF

cat >> ${EPREFIX}/etc/portage/package.env <<EOF
~dev-lang/perl-5.18.2  debug
~dev-lang/python-2.7.5 debug
~dev-libs/icu-51.2     debug
EOF
```

... correcting for `CFLAGS` as appropriate in `${EPREFIX}/etc/portage/env/fragile`.

* app-arch/unzip
    * Remove `cc` hard-coding
* dev-lang/python
    * If `configure` is not removed after applying the prefix libffi patch, `@LIBFFI_LIB@` is never expanded to the correct value even after `autoconf` has completed
* dev-libs/openssl
    * Add `-Qunused-arguments` to clang to prevent aborting with an `error` due to `-Wa,--noexecstack`, and fix util/domd to treat clang like gcc
* dev-vcs/subversion
    * Correct detection of compiler by `get-py-info.py` and ensure appropriate compiler is used
* sys-devel/binutils-apple
    * Build to current Mac OS version and fix missing Libc header
* sys-devel/llvm
    * Additional fixes for Darwin

# iOS7-compatible ebuilds

* app-pda/ipheth-pair
    * Tether an Apple iOS device to provide a network-link
* app-pda/libimobiledevice
    * git live ebuild for updated libimobiledevice tools
* app-pda/libplist
    * git live ebuild for updated plist library
* app-pda/libusbmuxd
    * git live ebuild for split libusbmuxd/usbmuxd library
* app-pda/usbmuxd
    * git live ebuild for usbmuxd binaries

# nftables ebuilds

* net-firewall/iptables-nftables
    * git live ebuild for nftables' iptables compatibility libraries
* net-firewall/nftables
    * git live ebuild for nftables `nft` binary (obsolete due to in-tree nftables build)
* sys-apps/iproute2
    * Updated dependencies to accept iptables or iptables-nftables packages

# Out-of-tree ebuilds

* dev-perl/Email-Outlook-Message
* dev-perl/Locale-Hebrew
* dev-perl/Net-Subnet
* dev-perl/Net-Twitter-Lite
* dev-perl/POE-Component-Client-Ping
* dev-perl/Proc-PID-File
* dev-python/noxspellserver
* dev-ruby/CFPropertyList
* dev-ruby/cora
* dev-ruby/geocoder
* dev-ruby/guard
* dev-ruby/guard-rspec
* dev-ruby/pry
* dev-ruby/rake
* net-mail/davmail-bin
    * Java Microsoft Exchange <-> IMAP connector
* net-misc/minissdpd
    * Temporarily retain old build, which doesn't require `USE="old-output"` for sys-apps/net-tools
* sys-apps/tmpfs
    * Mirror segments of a filesystem to a memory-based backing store
* sys-auth/opie
    * OPIE One-time password system
* sys-auth/pam_mobile_otp
    * PAM component of mOTP
* www-apps/heatmiser
    * Data acquisition and web-interface for Heatmiser Wifi Thermostats
* www-apps/opennab
    * OpenNAB Nabaztag server software
* www-apps/rpi-monitor
    * Raspberry Pi monitoring web-interface from [rpi-experiences.blogspot.fr](http://rpi-experiences.blogspot.fr/)
* www-apps/siriproxy
    * Web interface for 'Three Little Pigs' fork of SiriProxy
* www-misc/observium
    * Observium is an autodiscovering SNMP based network monitoring platform

# Modified ebuilds

* app-misc/ca-certificates
    * Don't install files for creating .deb archives to `/usr/share/doc/${PF}/examples/`
* app-misc/colordiff
    * Install example configuration file to `/usr/share/doc/${PF}/` rather than `/etc/`
* dev-libs/libcgroup
    * Improve output with `USE="DEBUG"`
* media-sound/teamspeak-server-bin
    * A more FHS/Gentoo-like installation structure
* net-dialup/ppp
    * Incorporate patches to allow interface discovery (rather than assuming the `eth0` is the primary interface -the appropriate interface with a prefix of `eth`, `em`, `ef`, or `eg` will be auto-discovered), and to enable the use of Baby Jumbo Frames whereby the host interface is given an MTU of 1508 so that the PPPoE link can retain a full 1500-byte MTU.
* sys-apps/busybox
    * Updates to make mdev more functional - see [here](http://blog.stuart.shelton.me/archives/891)...
* sys-power/apcupsd
    * Incorporate patch to allow apcupsd to be bulit against recent SNMP headers

# Fixes for ebuilds using /run
(... rather than /var/run)

* app-admin/eselect-php
* app-admin/ulogd
* app-antivirus/clamav
* app-misc/screen
* dev-libs/cyrus-sasl
* mail-filter/spamassassin
* net-analyzer/iptraf-ng
* net-analyzer/ntop
* net-analyzer/rrdtool
* net-analyzer/wireshark
* net-firewall/conntrack-tools
* net-misc/dhcpcd
* net-misc/memcached
* net-misc/minidlna
* net-misc/openntpd
* net-p2p/bitcoind
* sys-apps/kmod
* sys-apps/lm_sensors
* sys-libs/pam
* sys-power/acpid
* www-servers/lighttpd

# Fixes for MIPS n32 and x86_64 x32 ABIs

* app-admin/monit
    * Add required `--with-ssl-lib-dir` option
* dev-db/libdbi-drivers
    * Add required `--with-dbi-libdir` option
* dev-lang/ruby
    * Avoid inline assembly with x32 ABI
* net-analyzer/arp-sk
    * Look for libnet in the appropriate "libdir" rather than `lib`
* net-dns/bind-tools
    * Correct many instances of hard-coded references to `lib`
* sys-apps/baselayout
    * Don't error-out if using `lib32` for x32 libraries

# Fixes for `udev` and to allow separate `/usr`
(... and/or operation without a `/run` directory)

* net-wireless/bluez
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-apps/openrc
    * Add optional `USE="varrun"` flag to allow 'run' directory to remain as '/var/run'
* sys-fs/cryptsetup
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-fs/fuse
    * Avoid installing udev rules unless `USE="udev"` is specified
* sys-fs/lvm2
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-fs/mdadm
    * Restore previous boot-time functionality, add support for module-loading from `/etc/mdadm/mdmod.conf`

