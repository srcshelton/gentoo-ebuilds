
Various [Gentoo Linux](http://www.gentoo.org/) ebuilds, to provide out-of-tree packages and miscellaneous fixes.

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
* dev-ruby/lumberjack
* dev-ruby/pry
* dev-ruby/rake
* net-mail/davmail-bin
    * Java Microsoft Exchange <-> IMAP connector
* sys-auth/opie
    * OPIE One-time password system
* sys-auth/pam_mobile_otp
    * PAM component of mOTP
* www-apps/heatmiser
    * Data acquisition and web-interface for Heatmiser Wifi Thermostats
* www-apps/opennab
    * OpenNAB Nabaztag server software
* www-apps/siriproxy
    * Web interface for 'Three Little Pigs' fork of SiriProxy

# Modified ebuilds

* media-sound/teamspeak-server-bin
    * A more FHS/Gentoo-like installation structure
* sys-apps/busybox
    * Updates to make mdev more functional - see [here](http://blog.stuart.shelton.me/archives/891)...
* sys-power/apcupsd
    * Incorporate patch to allow apcupsd to be bulit against recent SNMP headers

# Fixes for x32 ABI

* sys-apps/baselayout
    * Don't error-out if using 'lib32' for x32 libraries

# Fixes to allow seperate '/usr' partition and/or operation without a '/run' directory

* sys-apps/openrc
    * Add optional 'varrun' USE-flag to allow 'run' to remain in '/var/run'
* sys-fs/cryptsetup
    * Make 'udev' and optional dependency, controlled by the 'udev' USE-flag
* sys-fs/lvm2
    * Make 'udev' and optional dependency, controlled by the 'udev' USE-flag
* sys-fs/mdadm
    * Restore previous boot-time functionality, add support for module-loading from '/etc/mdadm/mdmod.conf'

