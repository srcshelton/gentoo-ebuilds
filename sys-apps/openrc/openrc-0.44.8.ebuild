# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic meson pam toolchain-funcs usr-ldscript

DESCRIPTION="OpenRC manages the services, startup and shutdown of a host"
HOMEPAGE="https://github.com/openrc/openrc/"

if [[ ${PV} =~ ^9{4,}$ ]]; then
	EGIT_REPO_URI="https://github.com/OpenRC/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/OpenRC/openrc/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
fi

LICENSE="BSD-2"
SLOT="0"
IUSE="audit bash compat debug ncurses +netifrc newnet pam prefix selinux sysv-utils +tmpfiles unicode -vanilla +varrun"

COMMON_DEPEND="
	ncurses? ( sys-libs/ncurses:0= )
	pam? ( sys-libs/pam )
	audit? ( sys-process/audit )
	sys-process/psmisc
	!<sys-process/procps-3.3.9-r2
	selinux? (
		sys-apps/policycoreutils
		>=sys-libs/libselinux-2.6
	)
	!<sys-apps/baselayout-2.1-r1
	!<sys-fs/udev-init-scripts-27"
DEPEND="${COMMON_DEPEND}
	virtual/os-headers
	ncurses? ( virtual/pkgconfig )"
RDEPEND="${COMMON_DEPEND}
	bash? ( app-shells/bash )
	!prefix? (
		sysv-utils? (
			!sys-apps/systemd[sysv-utils(-)]
			!sys-apps/sysvinit
		)
		!sysv-utils? ( >=sys-apps/sysvinit-2.86-r6[selinux?] )
		tmpfiles? (
			virtual/tmpfiles
		)
	)
	selinux? (
		>=sec-policy/selinux-base-policy-2.20170204-r4
		>=sec-policy/selinux-openrc-2.20170204-r4
	)
	!<app-shells/gentoo-bashcomp-20180302
	!<app-shells/gentoo-zsh-completions-20180228
"

PDEPEND="netifrc? ( net-misc/netifrc )"

REQUIRED_USE="compat? ( !vanilla )"

PATCHES=(
	"${FILESDIR}"/${PN}-0.42.1-agetty-initd.patch
	"${FILESDIR}"/${PN}-0.43.5-cgroups.patch
	"${FILESDIR}"/${PN}-0.44.7-whitespace.patch
)

src_prepare() {
	default

	if ! use vanilla; then
		if use varrun ; then
			eapply "${FILESDIR}/${PN}-0.43.5-norun.patch" || die "no-run eapply failed"
		else
			eapply -p0 -- "${FILESDIR}/${PN}-0.12.4-bootmisc.in.patch" || die "bootmisc.in eapply failed"
		fi
		eapply -p0 -- "${FILESDIR}/${PN}-0.38.2-init.patch" || die "init eapply failed"
		eapply -p0 -- "${FILESDIR}/${PN}-0.18.4-devfs.patch" || die "devfs eapply failed"
		eapply -p0 -- "${FILESDIR}/${PN}-0.19.1-functions.sh.in.patch" || die "functions.sh.in eapply failed"
		eapply -p0 -- "${FILESDIR}/${PN}-0.23.2-rc.conf.patch" || die "rc.conf.in eapply failed"
		eapply "${FILESDIR}/${PN}-0.43.5-init.d.patch" || die "init.d eapply failed"
	fi
	eapply "${FILESDIR}/${PN}-0.41.2-cgroup-race.patch" || die "cgroup eapply failed"
	eapply "${FILESDIR}/${PN}-0.43.5-checkpath-mkdir.patch" || die "checkpath eapply failed"
}

PATCHES=(
	# Backported from master
	"${FILESDIR}"/${P}-selinux-no-pam.patch
)

src_configure() {
	local emesonargs=(
		  $(meson_feature audit)
		"-Dbranding=\"Gentoo Linux\""
		  $(meson_use newnet)
		 -Dos=Linux
		  $(meson_use pam)
		  $(meson_feature selinux)
		 -Drootprefix="${EPREFIX}"
		 -Dshell=$(usex bash /bin/bash /bin/sh)
		  $(meson_use sysv-utils sysvinit)
		 -Dtermcap=$(usev ncurses)
	)
	# export DEBUG=$(usev debug)
	meson_src_configure
}

# set_config <file> <option name> <yes value> <no value> test
# a value of "#" will just comment out the option
set_config() {
	local file="${ED}/$1" var=$2 val com
	eval "${@:5}" && val=$3 || val=$4
	[[ ${val} == "#" ]] && com="#" && val='\2'
	sed -i -r -e "/^#?${var}=/{s:=([\"'])?([^ ]*)\1?:=\1${val}\1:;s:^#?:${com}:}" "${file}"
}

set_config_yes_no() {
	set_config "$1" "$2" YES NO "${@:3}"
}

src_install() {
	meson_install

	gen_usr_ldscript libeinfo.so
	gen_usr_ldscript librc.so

	if use varrun; then
		keepdir /lib/rc/init.d
	fi
	keepdir /lib/rc/tmp

	if ! use vanilla; then
		# Install updated /etc/init.d/root script, allowing /etc/fstab options to
		# determine mount options for the root filesystem
		newinitd "${FILESDIR}"/root-r3.initd root

		# Install updated /etc/init.d/localmount script, to run:
		#  `btrfs devices scan`
		# ... before attempting to mount local btrfs filesystems
		newinitd "${FILESDIR}"/localmount-r5.initd localmount

		# Make devtmpfs size explicitly customisable
		newinitd "${FILESDIR}"/devfs.initd devfs
		newconfd "${FILESDIR}"/devfs.confd devfs

		# Restore now-integrated script
		exeinto /lib/rc/sh
		newexe "${FILESDIR}"/${PN}-0.13.7-init-common-post.sh init-common-post.sh

		use compat && dosym rc-service /sbin/service
	fi

	# Setup unicode defaults for silly unicode users
	set_config_yes_no /etc/rc.conf unicode use unicode

	# Cater to the norm
	set_config_yes_no /etc/conf.d/keymaps windowkeys '(' use x86 '||' use amd64 ')'

	# On HPPA, do not run consolefont by default (bug #222889)
	if use hppa; then
		rm -f "${ED}"/etc/runlevels/boot/consolefont
	fi

	# Support for logfile rotation
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/openrc.logrotate openrc

	if use pam; then
		# install gentoo pam.d files
		newpamd "${FILESDIR}"/start-stop-daemon.pam start-stop-daemon
		newpamd "${FILESDIR}"/start-stop-daemon.pam supervise-daemon
	fi

	# install documentation
	dodoc ChangeLog *.md
	if use newnet; then
		dodoc README.newnet
	fi
}

pkg_preinst() {
	local cfgfile=''

	# avoid default thrashing in conf.d files when possible #295406
	for cfgfile in {"${EROOT}",}/etc/conf.d/hostname; do
		if [[ -e "${cfgfile}" ]] ; then
			(
			unset hostname HOSTNAME
			source "${cfgfile}"
			: ${hostname:=${HOSTNAME}}
			[[ -n ${hostname} ]] && set_config /etc/conf.d/hostname hostname "${hostname}"
			)
			break
		fi
	done

	# set default interactive shell to sulogin if it exists
	set_config /etc/rc.conf rc_shell "/sbin/sulogin" '#' test -e "${EROOT%/}/sbin/sulogin"
	return 0
}

pkg_postinst() {
	if use hppa; then
		elog "Setting the console font does not work on all HPPA consoles."
		elog "You can still enable it by running:"
		elog "# rc-update add consolefont boot"
	fi

	if ! use newnet && ! use netifrc; then
		ewarn "You have emerged OpenRC without network support. This"
		ewarn "means you need to SET UP a network manager such as"
		ewarn "	net-misc/netifrc, net-misc/dhcpcd, net-misc/connman,"
		ewarn " net-misc/NetworkManager, or net-vpn/badvpn."
		ewarn "Or, you have the option of emerging openrc with the newnet"
		ewarn "use flag and configuring /etc/conf.d/network and"
		ewarn "/etc/conf.d/staticroute if you only use static interfaces."
		ewarn
	fi

	if use newnet && [ ! -e "${EROOT}"/etc/runlevels/boot/network ]; then
		ewarn "Please add the network service to your boot runlevel"
		ewarn "as soon as possible. Not doing so could leave you with a system"
		ewarn "without networking."
		ewarn
	fi
}
