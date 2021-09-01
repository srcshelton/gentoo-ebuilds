# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools bash-completion-r1 flag-o-matic linux-info optfeature pam readme.gentoo-r1 systemd verify-sig

DESCRIPTION="A userspace interface for the Linux kernel containment features"
HOMEPAGE="https://linuxcontainers.org/ https://github.com/lxc/lxc"
SRC_URI="https://linuxcontainers.org/downloads/lxc/${P}.tar.gz
	verify-sig? ( https://linuxcontainers.org/downloads/lxc/${P}.tar.gz.asc )"

KEYWORDS="amd64 ~arm ~arm64 ~ppc64 ~riscv x86"

LICENSE="LGPL-3"
SLOT="0"
IUSE="apparmor +caps checkpoint doc examples man pam seccomp selinux +ssl systemd +templates +tools verify-sig"

RDEPEND="acct-group/lxc
	acct-user/lxc
	app-misc/pax-utils
	sys-apps/util-linux
	sys-libs/libcap
	virtual/awk
	caps? ( sys-libs/libcap )
	checkpoint? ( sys-process/criu )
	pam? ( sys-libs/pam )
	seccomp? ( sys-libs/libseccomp )
	selinux? ( sys-libs/libselinux )
	ssl? (
		dev-libs/openssl:0=
	)"
DEPEND="${RDEPEND}
	>=sys-kernel/linux-headers-4
	apparmor? ( sys-apps/apparmor )"
BDEPEND="doc? ( app-doc/doxygen )
	man? ( app-text/docbook-sgml-utils )
	verify-sig? ( app-crypt/openpgp-keys-linuxcontainers )"
PDEPEND="templates? ( app-emulation/lxc-templates )"

CONFIG_CHECK="~!NETPRIO_CGROUP
	~CGROUPS
	~CGROUP_CPUACCT
	~CGROUP_DEVICE
	~CGROUP_FREEZER

	~CGROUP_SCHED
	~CPUSETS
	~IPC_NS
	~MACVLAN

	~MEMCG
	~NAMESPACES
	~NET_NS
	~PID_NS

	~POSIX_MQUEUE
	~USER_NS
	~UTS_NS
	~VETH

	~CHECKPOINT_RESTORE
	~INET_TCP_DIAG
	~INET_UDP_DIAG
	~NETLINK_DIAG
	~PACKET_DIAG
	~UNIX_DIAG
"

ERROR_CGROUP_FREEZER="CONFIG_CGROUP_FREEZER: needed to freeze containers"
ERROR_MACVLAN="CONFIG_MACVLAN: needed for internal (inter-container) networking"
ERROR_MEMCG="CONFIG_MEMCG: needed for memory resource control in containers"
ERROR_NET_NS="CONFIG_NET_NS: needed for unshared network"
ERROR_POSIX_MQUEUE="CONFIG_POSIX_MQUEUE: needed for lxc-execute command"
ERROR_UTS_NS="CONFIG_UTS_NS: needed to unshare hostnames and uname info"
ERROR_VETH="CONFIG_VETH: needed for internal (host-to-container) networking"

ERROR_CHECKPOINT_RESTORE="CONFIG_CHECKPOINT_RESTORE:  needed for lxc-checkpoint"
ERROR_INET_TCP_DIAG="CONFIG_INET_TCP_DIAG:  needed for lxc-checkpoint"
ERROR_INET_UDP_DIAG="CONFIG_INET_UDP_DIAG:  needed for lxc-checkpoint"
ERROR_NETLINK_DIAG="CONFIG_NETLINK_DIAG:  needed for lxc-checkpoint"
ERROR_PACKET_DIAG="CONFIG_PACKET_DIAG:  needed for lxc-checkpoint"
ERROR_UNIX_DIAG="CONFIG_UNIX_DIAG:  needed for lxc-checkpoint"

DOCS=( AUTHORS CONTRIBUTING MAINTAINERS NEWS README doc/FAQ.txt )

pkg_setup() {
	linux-info_pkg_setup
}

PATCHES=(
	"${FILESDIR}"/${PN}-3.0.0-bash-completion.patch
	"${FILESDIR}"/${PN}-2.0.5-omit-sysconfig.patch # bug 558854
)

VERIFY_SIG_OPENPGP_KEY_PATH=${BROOT}/usr/share/openpgp-keys/linuxcontainers.asc

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	append-flags -fno-strict-aliasing

	local myeconfargs=(
		--bindir=/usr/bin
		--localstatedir=/var
		--sbindir=/usr/bin

		--with-config-path=/etc/lxc
		--with-distro=gentoo
		--with-init-script=$(usex systemd systemd distro )
		--with-rootfs-path=/var/lib/lxc/rootfs
		--with-runtime-path=/var/run
		--with-systemdsystemunitdir=$(systemd_get_systemunitdir)

		--disable-coverity-build
		--disable-dlog
		--disable-fuzzers
		--disable-mutex-debugging
		--disable-no-undefined
		--disable-rpath
		--disable-sanitizers
		--disable-tests
		--disable-werror

		--enable-bash
		--enable-commands
		--enable-memfd-rexec
		--enable-thread-safety

		$(use_enable apparmor)
		$(use_enable caps capabilities)
		$(use_enable doc api-docs)
		$(use_enable examples)
		$(use_enable man doc)
		$(use_enable pam)
		$(use_enable seccomp)
		$(use_enable selinux)
		$(use_enable ssl openssl)
		$(use_enable tools)

		$(use_with pam pamdir $(getpam_mod_dir))
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	mv "${ED}"/usr/share/bash-completion/completions/${PN} "${ED}"/$(get_bashcompdir)/${PN}-start || die
	bashcomp_alias ${PN}-start \
		${PN}-{attach,cgroup,copy,console,create,destroy,device,execute,freeze,info,monitor,snapshot,stop,unfreeze,wait}

	keepdir /etc/lxc /var/lib/lxc/rootfs /var/log/lxc
	rmdir "${D}"/var/cache/lxc "${D}"/var/cache || die "rmdir failed"

	find "${D}" -name '*.la' -delete -o -name '*.a' -delete || die

	# Gentoo-specific additions!
	newinitd "${FILESDIR}/${PN}.initd.8" ${PN}

	# Remember to compare our systemd unit file with the upstream one
	# config/init/systemd/lxc.service.in
	use systemd && systemd_newunit "${FILESDIR}"/${PN}_at.service.4.0.0 "lxc@.service"

	DOC_CONTENTS="
		For openrc, there is an init script provided with the package.
		You should only need to symlink /etc/init.d/lxc to
		/etc/init.d/lxc.configname to start the container defined in
		/etc/lxc/configname.conf."

	use systemd && DOC_CONTENTS+="

		Correspondingly, for systemd a service file lxc@.service is installed.
		Enable and start lxc@configname in order to start the container defined
		in /etc/lxc/configname.conf."

	DOC_CONTENTS+="

	If you want checkpoint/restore functionality, please install criu
	(sys-process/criu)."
	DISABLE_AUTOFORMATTING=true
	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog

	elog "Please run 'lxc-checkconfig' to see optional kernel features."
	elog
	optfeature "automatic template scripts" app-emulation/lxc-templates
	optfeature "Debian-based distribution container image support" dev-util/debootstrap
	optfeature "snapshot & restore functionality" sys-process/criu
}
