
Various [Gentoo Linux](http://www.gentoo.org/) ebuilds, to provide out-of-tree
packages and miscellaneous fixes.

Also included is a script named `list-repo-updates.sh`, which will list any
packages which exist with identical versions in both this repository and the
main portage tree, but which still have the stock upstream package installed.

# Latest versions of podman container management tools

* app-emulation/buildah
* app-emulation/catatonit
* app-emulation/conmon
* app-emulation/containers-storage
* app-emulation/crun
* app-emulation/skopeo
* app-emulation/slirp4netns

# Fixes for ROOT != / installation

* dev-libs/cyrus-sasl
* dev-libs/glib
* mail-mta/postfix
* net-dns/bind
* net-libs/glib-networking

# Raspberry Pi tools and utilities

* dev-python/raspberrypi-gpio
    * RPi.GPIO ebuild
* media-libs/raspberrypi-userland
    * Replace non-functional Raspian init script with OpenRC equivalent, and update PID location
* sys-apps/raspberrypi-utilities-armv6
    * Some Raspberry Pi userland tools are closed-source, and so not available in media-libs/raspberrypi-userland.  There (armv6 only, currently) utilities are installed by this package
* sys-boot/raspberrypi-firmware
    * Raspberry Pi VideoCore firmware, Device Tree overlays, Kernel image, and kernel modules from a `smart-live-rebuild`-compatible ebuild
* ~~sys-boot/raspberrypi-mkimage~~
    * ~~Add latest signing tools to enable Device Tree support in self-built kernels~~
* sys-kernel/raspberrypi-image
    * Raspberry Pi latest kernel image
* sys-kernel/raspberrypi-sources
    * Raspberry Pi latest kernel sources, from a `smart-live-rebuild`-compatible ebuild
* www-apps/rpi-monitor
    * Raspberry Pi monitoring web-interface from [rpi-experiences.blogspot.fr](http://rpi-experiences.blogspot.fr/)

# Fixes for compiling prefix packages on macOS 10.13 (High Sierra) and later

For the High Sierra release, Apple have fixed a known vulnerability by causing
code which uses the '`%n`' `printf()` format in a string stored in writable
memory to crash with an `illegal instruction: 4` error.  Sadly, this is a
runtime error rather than a compiler error, making it difficult to detect.
Known failures currently exist in `vasnprintf()` implementations - these cases
are automatically detected and patched by deploying the Portage `bashrc`
override file from [local/etc/portage/bashrc](/local/etc/portage/bashrc)
to `${EPREFIX}/etc/portage/` and copying the accomdanying patch from
[local/etc/portage/patches/All/vasnprintf.patch](/local/etc/portage/patches/All/vasnprintf.patch)
to `${EPREFIX}/etc/portage/patches/All/`.

Two affected packages which use an older `vasnprintf()` implementation which is
incompatible with the supplied patch are as follows:

* dev-util/pkgconfig
* dev-vcs/cvs

... which are explicitly patched in an overlay package.

It is unlikely that this change affects only `vasnprintf()` code and no other,
so further patches will likely also be required...

# Fixes for compiling prefix packages under macOS using LLVM/clang

Some packages will fail with `illegal instruction: 4` if compiled with certain
compiler-optimisations enabled.  Indeed, the `-ftrapv` flag will cause `clang`
to intenionally insert `ud2` (Undefined Instruction) op-codes where integer
overflows could occur, and this catches-out a significant number of packages,
causing them to crash with `SIGILL` - illegal instruction.  To work around this
on a per-package basis where `-ftrapv` has not been used during compilation,
perform the following steps:

```
mkdir ${EPREFIX}/etc/portage/env

cat > ${EPREFIX}/etc/portage/env/debug <<EOF

# Assuming that clang is now default...

#CC="${EPREFIX}/usr/bin/clang"
#CXX="${EPREFIX}/usr/bin/clang++"

CFLAGS="-arch x86_64 -march=x86-64"
CFLAGS="${CFLAGS} -fcolor-diagnostics -O0 -g -pipe"
CFLAGS="${CFLAGS} -Wno-implicit-function-declaration"

CXXFLAGS="${CFLAGS}"
#CXXFLAGS="${CXXFLAGS} -stdlib=libstdc++"

#LDFLAGS="${LDFLAGS} -stdlib=libstdc++"

MAKEOPTS="-j1"

#PKGDIR="${PORTDIR}/packages/clang"

# vi: set syntax=conf:
EOF

cat >> ${EPREFIX}/etc/portage/package.env <<EOF
~sys-devel/binutils-apple-6.1 debug
EOF
```

... correcting for `CFLAGS` as appropriate in
`${EPREFIX}/etc/portage/env/debug`.

A similar configuration file could be added for all packages which fail to
compile with clang and require gcc.  An (unfortunately incomplete) list of
these packages consists of:

```
~dev-vcs/subversion-1.7.19
~sys-devel/binutils-config-3-r03.1
~sys-devel/gcc-apple-4.2.1_p5666
~sys-libs/db-5.2.42
```

(subversion presents an issue - it cannot be compiled with clang, but if
`USE="perl"` then the same compiler must be used to build subversion as was
used to build perl)

... with a slightly larger set of builds failing if `FEATURES="strict"` or
`FEATURES="stricter"`, or if `MAKEOPTS` is not set to "`-j1`".

* ~~app-arch/lz4~~
    * ~~Ensure that appropriate `PREFIX` directory is available to build system~~
* app-arch/unzip
    * Remove `cc` hard-coding
* ~~app-crypt/pinentry~~
    * ~~Add `-Wno-implicit-function-declaration` to work around ncurses-related failures, if supported by the compiler~~
* app-shells/bash
    * Include `<signal.h>` in relevant places to avoid `-Wimplicit-function-declaration` errors
* ~~dev-lang/python~~
    * ~~If `configure` is not removed after applying the prefix libffi patch, `@LIBFFI_LIB@` is never expanded to the correct value even after `autoconf` has completed~~
* ~~dev-libs/apr~~
    * ~~Support F\_FULLFSYNC on darwin~~
* dev-libs/gmp
    * Add patch to prevent `invalid reassignment of non-absolute variable 'L0m4_tmp'` error
* dev-libs/jemalloc
    * Correct library version used when calling `install_name_tool`
    * Don't use (64-bit) assembly when `__ILP32__` is defined
* dev-libs/libksba
    * Override `-Wall` CFLAG by adding clang `#pragma`s to problematic code
* dev-libs/liblinear
    * Update Makefile to build correctly on darwin
* ~~dev-libs/libxslt~~
    * ~~Fix for 'double prefix' QA error introduced in 1.1.28-r2~~
* dev-libs/openssl
    * Add `-Wno-error=unused-command-line-argument` to clang to prevent aborting with an `error` due to `-Wa,--noexecstack`, and fix util/domd to treat clang like gcc
* ~~dev-libs/udis86~~
    * ~~Add `${EPREFIX}` to `docdir` configure option~~
* ~~dev-python/backports-ssl-match-hostname~~
    * ~~Change `${ED}` to `${D}` to prevent double-prefix path usage QA error~~
* ~~dev-vcs/cvs~~
    * ~~Allow CVS to build and tests to run on darwin~~
* ~~dev-vcs/subversion~~
    * ~~Correct detection of compiler by `get-py-info.py` and ensure appropriate compiler is used~~
* ~~net-analyzer/nmap~~
    * ~~Restore `RT_MSGHDR_ALIGNMENT` definition for building on macOS~~
* net-analyzer/wireshark
    * Remove macOS '-isysroot' argument which broke macOS builds attempting to use SDK library stubs
* ~~sys-apps/baselayout-prefix~~
    * ~~Add missing `run_applets` prototype~~
* sys-apps/darwin-miscutils
    * Add missing `md.c` prototypes and `#include`s
* ~~sys-apps/gptfdisk~~
    * ~~Allow `gdisk` to build on darwin (there's a separate `Makefile` for this platform which doesn't use `libuuid`) and ensure appropriate compiler is used~~
* sys-apps/help2man
    * Ensure that `usr/lib/help2man/bindtextdomain.dylib` is correctly built and named
* ~~sys-apps/man~~
    * ~~Add missing `string.h` header to `makemsg.c`~~
* sys-apps/texinfo
    * Add missing `#include`
* ~~sys-devel/gdb~~
    * ~~Fixes for building with clang, building on Yosemite, and building with Python support~~
* sys-devel/gcc-apple
    * Fixes for building with clang and building on Yosemite
* sys-devel/llvm
    * Additional fixes for darwin
* sys-libs/db
    * Prevent clang builtins error due to `__atomic_compare_exchange` function
* sys-libs/gdbm
    * Ensure that all functions are defined before being called
* ~~sys-libs/readline~~
    * ~~Ensure that `<sys/ioctl.h>` header is included on darwin~~

# iOS7, 8, 9, and 10 -compatible tools &amp; macOS ebuilds

* app-admin/mas
    * Mac App Store command-line interface (requires `xcodebuild`)
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

# PHP 7.x compatible ebuilds
* dev-php/pecl-memcache
    * '`--php_targets_php7-0`' must currently be added to `/etc/portage/profile/use.mask`

# nftables ebuilds

* net-libs/libnftnl
    * Updated library version required by latest net-firewall/nftables
* net-firewall/iptables-nftables
    * git live ebuild for nftables' iptables compatibility libraries
* app-emulation/docker
    * Allow net-firewall/iptables-nftables as an alternative to net-firewall/iptables
* sys-apps/iproute2
    * Allow net-firewall/iptables-nftables as an alternative to net-firewall/iptables

# Out-of-tree ebuilds

* acct-group/cron
    * Consistent group for sys-process/cronbase
* acct-group/hugetlb
    * Consistent group for sys-libs/libhugetlbfs
* acct-group/milter
    * Consistent group for mail filters
* acct-group/socat
    * Privilege-separation account as recommended by net-misc/socat maintainers
* acct-group/ssmtp
    * Privilege-separation account
* acct-group/tcpdump
    * Privilege-separation account
* acct-user/cron
    * Consistent user for sys-process/cronbase
* acct-user/memcached
    * Add user to 'hugetlb' group
* acct-user/milter
    * Consistent user for mail filters
* acct-user/mysql
    * Add user to 'hugetlb' group
* acct-user/redis
    * Add user to 'hugetlb' group
* acct-user/tcpdump
    * Privilege-separation account
* app-accessibility/svox-pico
    * SVOX Pico TTS (aka 'pico2wave'), required by \>www-apps/nabaztaglives-2.2.0
* app-admin/checkrestart-ng
    * A pure-shell tool to check for updated binaries and libraries
* app-admin/openrc-restart-crashed
    * Check for services with status 'crashed', and optionally restart specified services
* ~~app-editors/vim-core~~
    * ~~Add v8.0.1094 which fixes arbitrary characters appearing in macOS Terminal.app and others~~
* ~~app-editors/vim~~
    * ~~Add v8.0.1094 which fixes arbitrary characters appearing in macOS Terminal.app and others~~
* app-emulation/wa-linux-agent
* app-shells/stdlib
    * stdlib.sh from https://github.com/srcshelton/stdlib.sh
* dev-embedded/rpi-eeprom
    * Follow raspbian releases more closely
* dev-perl/B-Lint
* dev-perl/CPANPLUS
* dev-perl/CPANPLUS-Dist-Gentoo
* dev-perl/Devel-Trace
* dev-perl/Email-Outlook-Message
* dev-perl/File-Touch
* ~~dev-perl/IO-Interface~~
* dev-perl/IO-Socket-Multicast
* dev-perl/IP-Country
* dev-perl/IP-Country-DB\_File
* dev-perl/Locale-Hebrew
* dev-perl/match-simple
    * Provides match::smart
* ~~dev-perl/Mojolicious~~
* dev-perl/Mojo-Server-FastCGI
* dev-perl/Net-Interface
* dev-perl/Net-MAC-Vendor
* dev-perl/Net-SDP
* dev-perl/Net-Subnet
* dev-perl/Net-Twitter-Lite
* dev-perl/POE-Component-Client-Ping
* dev-perl/Proc-PID-File
* dev-perl/Sub-Infix
* dev-php/Endroid-QrCode
    * To replace the bundled libraries which are supplied with mail-client/roundcube-1.4.x
* dev-php/Masterminds-HTML5
    * To replace the bundled libraries which are supplied with mail-client/roundcube-1.4.x
* dev-php/PEAR-Crypt\_GPG
    * To replace the bundled libraries which are supplied with mail-client/roundcube-1.0.x
* dev-php/PEAR-Net\_LDAP3
    * To replace the bundled libraries which are supplied with mail-client/roundcube-1.4.x
* dev-php/ZxcvbnPhp
    * To replace the bundled libraries which are supplied with mail-client/roundcube-1.4.x
* ~~dev-python/ansible-lint~~
* ~~dev-python/aspy\_yaml~~
* dev-python/identify
* ~~dev-python/nodeenv~~
* ~~dev-python/noxspellserver~~
* ~~dev-python/pathspec~~
* ~~dev-python/pre-commit~~ (see `dev-vcs/pre-commit`)
* dev-python/yamllint
* dev-ruby/CFPropertyList
* dev-util/ltrace
    * The ltrace project hasn't made a release in a long time, but we can pull-in more recent commits
* games-server/minecraft-bedrock-server-bin
* games-server/minecraft-server-bin
* mail-client/roundcube
    * Roundcube 1.0.0 and Roundcube 1.0.1 have been released, but are not yet in-tree...
* media-sound/logitechmediaserver-bin
    * Stuart Hickinbottom's Squeezebox Server ebuild, updated for Perl 5.22 and with minor optimisations
* net-libs/libhtp
    * Add more recent libhtp-0.5.21 release, to prevent net-analyzer/suricata-3.1 from complaining about libhtp being too old
* net-libs/libupnp
    * Add more recent libupnp-1.6.20 and forked libupnp-1.8.0 releases, both with [mjg59](https://twitter.com/mjg59/status/755062671418929152)'s [POST](http://seclists.org/oss-sec/2016/q3/118) patch applied
* net-libs/nDPI
    * Add further nDPI releases, to try to sync against ntopng (which is closely tied to nDPI but is fragile and doesn't declare version compatibility)
* net-mail/davmail-bin
    * Java Microsoft Exchange <-> IMAP connector
* net-mail/imapproxy
    * Retain old up-imapproxy ebuild, add imapproxy-1.2.8 with SSL fixes
* ~~net-misc/minissdpd~~
    * ~~Temporarily retain old ebuild, which doesn't require `USE="old-output"` for sys-apps/net-tools~~
* net-misc/pixelserv
* net-misc/unifi-controller-bin
    * Ubiquiti Networks' UniFi Controller software
* sys-apps/lsusb-apple
    * Jose L. Honorato's 'lsusb' for macOS
* sys-apps/tmpfs
    * Mirror segments of a filesystem to a memory-based backing store
* ~~sys-auth/opie~~
    * ~~OPIE One-time password system~~
* sys-auth/pam\_mobile\_otp
    * PAM component of mOTP
* ~~sys-auth/yubipam~~
    * ~~PAM authentication module for YubiKey hardware~~
    * See `sys-auth/pam_yubico`
* sys-boot/grub-legacy
    * Snapshot of grub-0.97 for systems where simplicity trumps technical correctness...
* sys-process/stalld
    * Red Hat thread-booster
* www-apps/heatmiser
    * Data acquisition and web-interface for Heatmiser Wifi Thermostats
* www-apps/nabaztaglives
    * Nabaztag Lives server software, re-factored into a webapp
* www-apps/opennab
    * OpenNAB Nabaztag server software
* www-apps/siriproxy
    * Web interface for 'Three Little Pigs' fork of SiriProxy
* www-servers/3dm2
    * 3ware 3DM2 RAID controller web interface for 3w-xxxx, 3w-9xxx and 3w-sas controllers
* www-servers/pound
    * Third-party Zevenet pound-2.8a, which builds against modern OpenSSL

# Modified ebuilds

* app-admin/cpulimit
    * Fix use of 'inline' (rather than 'static inline')
* app-admin/eselect
    * eselect requires app-shells/bash
* app-arch/xz-utils
    * Explicitly depend on 'grep that handles long lines and -e' (although the real issue could be that somehow GNU `grep` _was_ installed during bootsrapping, but `libpcre` wasn't?)
* ~~app-crypt/gnupg~~
    * ~~Fix clang compilation errors~~
* app-emulation/docker
    * Allow more fine-grained control over optional features
* app-emulation/lxc
    * Don't require an upgrade to Python 3.x unless building against Python
* app-misc/ca-certificates
    * Don't install files for creating .deb archives to `/usr/share/doc/${PF}/examples/`
* app-misc/colordiff
    * Install example configuration file to `/usr/share/doc/${PF}/` rather than `/etc/`
* app-portage/eix
    * Make `tmpfiles` installation optional
* dev-db/mongodb
    * Add firefox source to Allow building on ARM
* dev-db/mysql-init-scripts
    * Only install support for requested service-managers
* dev-java/commons-daemon
    * Add additional include path to allow building with Oracle JDK 8 and above
* ~~dev-lang/perl~~
    * ~~Fix HTTP::Tiny SSL CA path for prefix installations, prevent `darwin_time_mutex` errors on macOS~~
* dev-libs/geoip
    * Remove obselete update script and 'wget' dependency
* dev-libs/glib
    * Prevent binary merges from failing due to assumptions about build files being present
* dev-libs/libcgroup
    * Handle existing mountpoints and correct init scripts
* ~~dev-libs/yajl~~
    * ~~Bump to EAPI=7 for BDEPEND/RDEPEND build-dependency improvements~~
* ~~dev-perl/DBI-Shell~~
    * ~~Fix "Useless localization of scalar assignment" warning from DBI::Format~~
* dev-perl/Locale-gettext
    * Declare run-time dependency on dev-lang/perl
* dev-perl/LWP-Protocol-https
    * Fix SSL CA path for prefix installations
* dev-perl/Math-Pari
    * Hack to allow math-pari to build on x32 systems and systems running a 32-bit userland on a 64-bit kernel
* dev-perl/Net-DNS-SEC
    * Add optional dsa, ecdsa, gost, private-key dependencies
* dev-perl/libwww-perl
    * Add missing Mozilla::CA dependency for correct SSL operation
* mail-filter/libmilter
    * Add sys-devel/m4 dependency
* mail-filter/opendkim
    * Prevent the unqualified need for 'RequireSafeKeys' on Gentoo due to GID=0 standard system users
* mail-filter/opendmarc
    * Use `acct-*` dependencies rather than `user.eclass`
* mail-filter/postgrey
    * Make systemd service support optional
* mail-filter/spampd
    * Fix `status` reporting, revise installed documentation, add optional systemd service support
* mail-mta/nullmailer
    * Make systemd service support optional
* mail-mta/ssmtp
    * Use acct-group/ssmtp instead of `user` eclass
* media-sound/teamspeak-server-bin
    * A more FHS/Gentoo-like installation structure
* net-analyzer/munin
    * Re-factor munin to operate as a webapp, and remove configuration from `/etc`
* net-analyzer/netdata
    * With modifications to upstream ebuild and init script
* net-analyzer/ntopng
    * Remove some of the more onerous limitations from the community edition, use source from `3.0-stable` branch rather than `3.0` tag
* net-analyzer/suricata
    * Minor ebuild fixes, automatically fetch latest rules on build
* net-analyzer/tcpdump
    * Add consistent group and user dependencies
* net-dialup/ppp
    * Incorporate patches to allow interface discovery (rather than assuming that `eth0` is the primary interface, the appropriate interface with a prefix of `eth`, `em`, `ef`, or `eg` will be auto-detected), and to enable the use of Baby Jumbo Frames whereby the host interface is given an MTU of 1508 so that a PPPoE link can retain a full 1500-byte MTU
* net-dns/avahi
    * Prevent build from incorrectly creating `/run` directory
* net-dns/dnscrypt-proxy
    * Move binary to /sbin
* net-dns/dnstop
    * build correctly against >=libpcap-1.8.0 with (non-optional) IPv6 support
* net-firewall/ebtables
    * Update to latest git commit, which adds compatibility kernel headers more recent than v3.16
    * Allow `--among-src-file` and `--among-dst-file` options to accept files containing multiple lines, for ease of maintenance
    * Fix some crazy inconsistencies in output which were breaking `ebtables-save` and `ebtables-restore`
    * Set appropriate maximum buffer sizes to prevent `ebtables-restore` from segfaulting when loading more than 2kbytes of data from a single statement
    * Add Debian patch to correct the use of `RETURN` as a module target
* net-libs/neon
    * Patch trivial typo which prevents `writev` from being defined
* net-misc/dhcp
    * Enhance chroot support in init script
* net-misc/socat
    * Use privilege-separation group for security, make HTML documentation and additional tools optional installs
* net-misc/tor
    * Prevent GCC infinite loop, rather than simply warning about it
* net-misc/usbip
    * Prevent build failure due to harmless warning
* net-misc/wget
    * Filter `-funsafe-math-optimizations`, which prevents wget from building on ARM
* net-nds/openldap
    * If /etc/init.d/tmpfiles.setup isn't active, `/var/run/openldap` is never created yet the ebuild still attempts to set permissions upon it...
* net-vpn/tor
    * Remove hard dependency on asciidoc
* sys-apps/baselayout-java
    * Fix UID logic
* sys-apps/busybox
    * Updates to make mdev more functional - see [here](http://blog.stuart.shelton.me/archives/891)...
* sys-apps/gentoo-functions
    * Fix inclusion when unbound variable checking is enabled
* sys-apps/groff
    * Fix for building on ARM
* ~~sys-apps/portage~~
    * ~~Prevent `ebuild ... digest` from aborting if the owner of the category directory differs from that of the package directory~~
    * ~~Prevent binary merges from failing due to assumptions about build files being present~~
* ~~sys-apps/usbutils~~
    * ~~Revert changes which make usbutils dependent on udev~~
* sys-apps/util-linux
    * Add static libary dependencies, use `/var/run` in place of `/run`
* sys-apps/sysvinit
    * Don't force `initctl` into a (auto-created) `/run` directory if not on FreeBSD
* sys-auth/pam\_mktemp
    * Create user temporary directories under '/var/tmp/' rather than under '/tmp/', to guard against running out of space on the root filesystem
* sys-kernel/linux-firmware
    * Be much more verbose about which firmware is being installed and skipped with `USE=savedconfig`, and don't try to strip firmware blobs :o
* sys-libs/libblockdev
    * Add undeclared libudev dependency
* sys-libs/libhugetlbfs
    * Fix build on systems where userspace and kernel conform to different ABIs, and fix installation of broken manpage symlinks
* sys-power/apcupsd
    * Incorporate patch to allow apcupsd to be bulit against recent SNMP headers;
    * Correct SNMP patch failure of version 3.14.12, make exposed configuration options more flexible;
    * Provide more flexibility with finer-grained USE flags
* sys-power/iasl
    * Fix paths in ebuild and make build documentation optional
* sys-process/cronbase
    * Add consistent group and user dependencies
* virtual/bitcoin-leveldb
    * Be more flexible about necessary dependencies
* virtual/mta
    * Add optional USE flags to control which MTA will be installed
* virtual/tmpfiles
    * Provide an option _not_ to use systemd's tmpfiles system (directly or via `sys-apps/opentmpfiles`)
* ~~x11-drivers/nvidia-drivers~~
    * ~~Only start nVidia System Management Interface if valid for the host system~~

# Fixes for ebuilds using `/run`
(... rather than `/var/run`)

Included as `install-qa-check.d/95run-directory` in the repo `metadata`
directory is an additional QA check which reports an error if files deployed to
`/etc/init.d` or `/etc/conf.d` contain references to `/run`.

* app-admin/eselect-php
* app-admin/metalog
* app-admin/sudo
* app-admin/syslog-ng
* app-admin/ulogd
* app-emulation/containerd
* app-misc/screen
* dev-db/redis
* dev-libs/cyrus-sasl
    * Prevent binary merges from failing due to assumptions about build files being present
* mail-filter/spamassassin
* net-analyzer/arpwatch
* net-analyzer/darkstat
* net-analyzer/iptraf-ng
* net-analyzer/nagios-core
* ~~net-analyzer/ntop~~
* net-analyzer/rrdtool
* net-analyzer/vnstat
* net-analyzer/zabbix
* net-dialup/freeradius
* net-dns/bind
* net-dns/unbound
* net-firewall/conntrack-tools
* net-fs/netatalk
* net-fs/samba
* net-im/bitlbee
* net-mail/dovecot
* net-misc/cni-plugins
* net-misc/dhcpcd
* net-misc/memcached
* net-misc/minidlna
* net-misc/ndisc6
* net-misc/ntp
* net-misc/openntpd
* net-misc/radvd
* net-misc/rsyncd
* net-p2p/deluge
* net-print/cups
* net-vpn/openvpn
* sys-apps/dbus
* sys-apps/haveged
* sys-apps/kmod
* sys-apps/lm\_sensors
* sys-apps/smartmontools
* sys-auth/elogind
* sys-devel/distcc
* sys-fs/cachefilesd
* sys-fs/udev-init-scripts
* sys-libs/ncurses
    * Fix list of libraries relocated to the root filesystem
* sys-libs/pam
* sys-power/acpid
* www-servers/lighttpd
* www-servers/spawn-fcgi

# Fixes to allow `/var/state` to be used in place of `/var/lib`

`/var/state` was referenced in the [Filesystem Hierarchy Standard 2.0](http://www.ibiblio.org/pub/Linux/docs/fsstnd/fhs-2.0.tar.gz)
as superseding `/var/lib`, although versions 2.1 and later no longer mention
this particular configuration.  Regardless, supporting `/var/state` (with a
symlink from `/var/lib` for compatibility) takes very little effort, and the
name `state` feels like a much better fit with respect to the intended
contents.

* dev-lang/php
* dev-php/PEAR-PEAR
* media-libs/libpvx

# Fixes for MIPS n32 and x86\_64 x32 ABIs

Included is a modified `eclass/multilib.eclass` that no longer overrides any
amd64 `LIBDIR_*` environment variables, which may now usefully be set in
`/etc/portage/make.conf`.  For this to work universally, you may need to edit
`/etc/portage/repos.conf` and add:

```
[DEFAULT]
eclass-overrides = srcshelton
```

... to ensure that main-repo ebuilds benefit from the change.  The `LIBDIR`
variables, and their default values, are:

```
LIBDIR_amd64="lib64"
LIBDIR_x32="libx32"
LIBDIR_x86="lib"
SYMLINK_LIB="yes"
```

... noting that `SYMLINK_LIB` defaults to `"no"` (e.g. do not try to symlink
`/lib` and `/usr/lib` to the library directory which the ABI actually uses) for
x32 profiles, and that these variables only affect multilib systems.

* app-admin/monit
    * Add required `--with-ssl-lib-dir` option
* app-crypt/mit-krb5
    * Ensure that AES assembly is built for x32 rather than amd64
* app-antivirus/clamav
    * Don't use (64-bit) assembly when `__ILP32__` is defined
* dev-db/libdbi-drivers
    * Add required `--with-dbi-libdir` option
* dev-db/mariadb
    * Prevent x32 builds from failing because of warnings generated by int to long-int conversions in LZO code
* ~~dev-lang/ruby~~
    * ~~Avoid inline assembly with x32 ABI~~
* dev-util/cmake
    * Add (x)32 library paths in addition to 64-bit variants
* ~~media-libs/flac~~
    * ~~Avoid link failures due to 32 bit downgrade with x32 ABI~~
* net-analyzer/arp-sk
    * Look for libnet in the appropriate "libdir" rather than `lib`
* net-dns/bind-tools
    * Correct many instances of hard-coded references to `lib`
* net-misc/miniupnpd
    * Prevent use of `sysctl` syscall (which specifically errors on x32, but is deprecated for all ABIs)
* net-misc/openssh
    * Add experimental `libseccomp` patch, and on x32 either use this or fallback to `rlimit` sandbox.  Without one of these changes, `sshd` is non-functional on x32
* sys-apps/baselayout
    * Don't error-out if using `lib32` for x32 libraries
* ~~sys-apps/cpuid~~
    * ~~Don't use 64-bit assembly when `__ILP32__` is defined~~
* sys-apps/kexec-tools
    * Add x32 patch from [OpenEmbedded](http://cgit.openembedded.org/meta-openembedded/tree/meta-initramfs/recipes-kernel/kexec/kexec-tools-klibc/kexec-x32.patch?h=thud)
* sys-devel/binutils
    * Allow `LIBDIR_*` variables to override hard-coded default directory locations
* sys-devel/gcc
    * Allow `LIBDIR_*` variables to override hard-coded default directory locations
* sys-libs/glibc
    * Allow `LIBDIR_*` variables to override hard-coded default directory locations (for x86 only)
    * Prevent binary merges from failing due to assumptions about build files being present
* ~sys-libs/libunwind~
    * ~Add x32 patch from [sjnewbury's repo](https://github.com/sjnewbury/x32/blob/master/sys-libs/libunwind/files/libunwind-1.1-x32.patch)~

# Fixes for `udev` and to allow separate `/usr`
(... and/or operation without a `/run` directory)

* app-eselect/eselect-awk
    * Support for (g)awk installed in `/bin`
* net-wireless/bluez
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-apps/coreutils
    * Add `uniq` to the list of binaries moved to `/bin`, as some init scripts (such as `device-mapper`) rely on it being present during early-boot
* sys-apps/gawk
    * Install to `/bin` rather than `/usr/bin`, for init scripts which invoke `awk`
* sys-apps/openrc
    * Add optional `USE="varrun"` flag to allow 'run' directory to remain as '/var/run'
* sys-fs/cryptsetup
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-fs/e2fsprogs
    * Avoid installing udev rules unless `USE="udev"` is specified
* sys-fs/fuse
    * Avoid installing udev rules unless `USE="udev"` is specified
* sys-fs/fuse-common
    * Avoid installing udev rules unless `USE="udev"` is specified
* sys-fs/lvm2
    * Make 'udev' an optional dependency, controlled by `USE="udev"`
* sys-fs/mdadm
    * Restore previous boot-time functionality, add support for module-loading from `/etc/mdadm/mdmod.conf`
* net-misc/netifrc
    * Avoid installing udev rules unless `USE="udev"` is specified
* sys-libs/libeudev
    * Provide `libudev` only without (e)udev daemon, for builds which require only the library component of udev
* sys-process/procps
    * Maintain compatibility with releases prior to 3.3.11 by keeping `sysctl` in `/sbin`
* virtual/libudev
    * Allow sys-libs/libeudev to satisfy `virtual/libudev` dependency

# Fixes for binaries and libraries which are installed to the root filesystem, but link to libraries originally installed to `/usr`
(... previously controlled by the `sep-usr` USE-flag, now using standardised `split-usr`)

* app-arch/zstd
* app-crypt/argon2
* app-crypt/mit-krb5
* dev-libs/elfutils
* dev-libs/gmp
* dev-libs/inih
    * Required by mkfs.xfs - perhaps this should be moved to /usr/sbin/ instead?
* dev-libs/jansson
* dev-libs/json-c
* dev-libs/libbsd
* dev-libs/libgcrypt
* dev-libs/libgpg-error
* dev-libs/libnl
* dev-libs/libpcre2
* dev-libs/libunistring
* dev-libs/mini-xml
* dev-libs/mpfr
* dev-libs/openssl
* dev-libs/popt
* net-dns/libidn
* net-dns/libidn2
* net-fs/nfs-utils
    * Move 'nfsdcltrack', with many non-root library dependencies, to `/usr/sbin`
* net-libs/libnfnetlink
* net-libs/libpcap
* sys-apps/file
    * Move `libmagic.so` to the root filesystem, for app-editors/nano
* sys-apps/util-linux
    * Add `libfdisk.so` to the list of libraries relocated to root
* sys-block/thin-provisioning-tools
    * Move 'pdata\_tools', with many non-root library dependencies, to `/usr/sbin`
* sys-fs/cryptsetup
* sys-libs/libcap-ng
* sys-libs/slang
* sys-process/audit
    * Add `zos` USE-flag to prevent building of z/OS-specific `zos-remote` plugin and tools, with many non-root library dependencies

# Make systemd unit installation optional

* sys-apps/rng-tools
* sys-block/zram-init

