# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )

inherit go-module linux-info python-any-r1 tmpfiles toolchain-funcs

DESCRIPTION="A tool for managing OCI containers and pods with Docker-compatible CLI"
HOMEPAGE="https://github.com/containers/podman/ https://podman.io/"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/podman.git"
else
	SRC_URI="https://github.com/containers/podman/archive/v${PV/_rc/-rc}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${P/_rc/-rc}"
	[[ ${PV} != *rc* ]] &&
		KEYWORDS="~amd64 ~arm64 ~loong ~riscv"
fi

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"
IUSE="apparmor +bash-completion btrfs experimental fish-completion +fuse +rootless +seccomp selinux systemd +tmpfiles wrapper zsh-completion"
RESTRICT="mirror test"

COMMON_DEPEND="
	>=app-containers/conmon-2.1.10
	>=app-containers/containers-common-0.58.0-r1
	app-containers/crun
	>=app-containers/netavark-1.6.0[dns]
	app-crypt/gpgme:=
	dev-libs/libassuan:=
	dev-libs/libgpg-error:=
	sys-apps/shadow:=

	apparmor? ( sys-libs/libapparmor )
	btrfs? ( sys-fs/btrfs-progs )
	rootless? ( net-misc/passt )
	seccomp? ( sys-libs/libseccomp:= )
	selinux? ( sec-policy/selinux-podman sys-libs/libselinux:= )
"
BDEPEND="
	${PYTHON_DEPS}
	dev-go/go-md2man
	dev-vcs/git
	sys-apps/findutils
	sys-apps/grep
	sys-apps/sed
	systemd? ( sys-apps/systemd )
"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}
	app-containers/catatonit
	fuse? ( sys-fs/fuse-overlayfs )
	selinux? ( sec-policy/selinux-podman )
	systemd? ( sys-apps/systemd:= )
	wrapper? ( !app-containers/docker-cli )
"

PATCHES=(
	"${FILESDIR}/${PN}-5.1.1-togglable-seccomp.patch"
)

pkg_setup() {
	# Inherited from app-containers/docker-27.0.3...
	#
	# This is based on "contrib/check-config.sh" from upstream's sources
	# required features
	#
	# N.B. The docker ebuild specifies checks over multiple blocks :(
	local CONFIG_CHECK="
		~NAMESPACES ~NET_NS ~PID_NS ~IPC_NS ~UTS_NS
		~CGROUPS ~CGROUP_CPUACCT ~CGROUP_DEVICE ~CGROUP_FREEZER ~CGROUP_SCHED ~CPUSETS ~MEMCG
		~KEYS
		~VETH ~BRIDGE ~BRIDGE_NETFILTER
		~IP_NF_FILTER ~IP_NF_TARGET_MASQUERADE
		~NETFILTER_XT_MATCH_ADDRTYPE
		~NETFILTER_XT_MATCH_CONNTRACK
		~NETFILTER_XT_MATCH_IPVS
		~NETFILTER_XT_MARK
		~IP_NF_NAT ~NF_NAT
		~POSIX_MQUEUE

		~USER_NS
		~CGROUP_PIDS

		~!LEGACY_VSYSCALL_NATIVE
		~!LEGACY_VSYSCALL_NONE

		~BLK_CGROUP ~BLK_DEV_THROTTLING
		~CGROUP_PERF
		~CGROUP_HUGETLB
		~NET_CLS_CGROUP ~CGROUP_NET_PRIO
		~CFS_BANDWIDTH ~FAIR_GROUP_SCHED
		~IP_NF_TARGET_REDIRECT
		~IP_VS
		~IP_VS_NFCT
		~IP_VS_PROTO_TCP
		~IP_VS_PROTO_UDP
		~IP_VS_RR

		~OVERLAY_FS ~!OVERLAY_FS_REDIRECT_DIR
		~EXT4_FS ~EXT4_FS_SECURITY ~EXT4_FS_POSIX_ACL

		~VXLAN ~BRIDGE_VLAN_FILTERING
		~CRYPTO ~CRYPTO_AEAD ~CRYPTO_GCM ~CRYPTO_SEQIV ~CRYPTO_GHASH
		~XFRM ~XFRM_ALGO ~XFRM_USER ~INET_ESP

		~IPVLAN
		~MACVLAN ~DUMMY

		~NF_NAT_FTP ~NF_CONNTRACK_FTP ~NF_NAT_TFTP ~NF_CONNTRACK_TFTP

		~OVERLAY_FS
	"
	# Additional checks, not performed by app-containers/docker...
	CONFIG_CHECK+="
		~NETFILTER_NETLINK
	"

	local ERROR_KEYS="CONFIG_KEYS: is mandatory"

	local WARNING_LEGACY_VSYSCALL_NONE="CONFIG_LEGACY_VSYSCALL_NONE enabled: Containers with <=glibc-2.13 will not work"
	local WARNING_BLK_CGROUP="CONFIG_BLK_CGROUP: is optional for container statistics gathering"
	local WARNING_CFS_BANDWIDTH="CONFIG_CFS_BANDWIDTH: is optional for container statistics gathering"
	local WARNING_CGROUP_PERF="CONFIG_CGROUP_PERF: is optional for container statistics gathering"
	local WARNING_IOSCHED_CFQ="CONFIG_IOSCHED_CFQ: is optional for container statistics gathering"
	local WARNING_MEMCG_SWAP="CONFIG_MEMCG_SWAP: is required if you wish to limit swap usage of containers"
	local WARNING_POSIX_MQUEUE="CONFIG_POSIX_MQUEUE: is required for bind-mounting /dev/mqueue into containers"
	local WARNING_RESOURCE_COUNTERS="CONFIG_RESOURCE_COUNTERS: is optional for container statistics gathering"
	local WARNING_XFRM_ALGO="CONFIG_XFRM_ALGO: is optional for secure networks"
	local WARNING_XFRM_USER="CONFIG_XFRM_USER: is optional for secure networks"

	if kernel_is lt 5 2; then
		ewarn
		ewarn "podman 5.2.0 and above now require the kernel mount API, which"
		ewarn "was introduced in linux-5.2"
	fi

	if kernel_is le 5 3; then
		CONFIG_CHECK+="
			~INET_XFRM_MODE_TRANSPORT
		"
	fi

	if kernel_is lt 5 8; then
		CONFIG_CHECK+="
			~MEMCG_SWAP_ENABLED
		"
		local ERROR_MEMCG_SWAP="CONFIG_MEMCG_SWAP: is required if you wish to limit swap usage of containers"
	fi

	if kernel_is lt 5 19; then
		CONFIG_CHECK+="
			~LEGACY_VSYSCALL_EMULATE
		"
	fi

	if kernel_is lt 6 1; then
		CONFIG_CHECK+="
			~MEMCG_SWAP
		"
		local ERROR_MEMCG_SWAP="CONFIG_MEMCG_SWAP: is required if you wish to limit swap usage of containers"
	fi

	# N.B. 'ge'
	if kernel_is ge 4 15; then
		CONFIG_CHECK+="
			~CGROUP_BPF
		"
	fi

	if use apparmor; then
		CONFIG_CHECK+="
			~SECURITY_APPARMOR
		"
	fi

	if use btrfs; then
		CONFIG_CHECK+="
			~BTRFS_FS
			~BTRFS_FS_POSIX_ACL
		"
	fi

	if use seccomp; then
		CONFIG_CHECK+="
			~SECCOMP ~SECCOMP_FILTER
		"
	fi

	if use selinux; then
		CONFIG_CHECK+="
			~SECURITY_SELINUX
		"
	fi

	linux-info_pkg_setup
	python-any-r1_pkg_setup
}

src_prepare() {
	local -a makefile_sed_args=()
	local file='' feature=''

	if ! use seccomp; then
		ewarn "Disabling 'seccomp' support may prevent podman from" \
			"starting if"
		ewarn "any seccomp-related settings exist beneath" \
			"/etc/containers/"
	fi

	default

	# Ensure necessary files are present...
	local file
	for file in apparmor btrfs_installed btrfs systemd; do
		[[ -f "hack/${file}_tag.sh" ]] ||
			die "File '${file}_tag.sh' missing"
	done

	local feature
	for feature in apparmor systemd; do
		cat <<-EOF > "hack/${feature}_tag.sh" || die
			#! /bin/sh
			$(usex "${feature}" "echo ${feature}" 'true')
		EOF
	done

	cat <<-EOF > hack/btrfs_installed_tag.sh || die
		#! /bin/sh
		$(usex 'btrfs' 'true' 'echo exclude_graphdriver_btrfs')
	EOF
	cat <<-EOF > hack/btrfs_tag.sh || die
		#! /bin/sh
		$(usex 'btrfs' 'true' 'echo exclude_graphdriver_btrfs btrfs_noversion')
	EOF

	# Fix run path...
	grep -Rl '/run/lock' . |
		xargs -r -- sed -ri \
			-e 's|/run/lock|/var/lock|g' || die
	grep -Rl '[^r]/run/' . |
		xargs -r -- sed -ri \
			-e 's|([^r])/run/|\1/var/run/|g ; s|^/run/|/var/run/|g' || die
}

src_compile() {
	export PREFIX="${EPREFIX}/usr"

	# For non-live versions, prevent git operations which causes sandbox violations
	# https://github.com/gentoo/gentoo/pull/33531#issuecomment-1786107493
	[[ ${PV} != 9999* ]] &&
		export COMMIT_NO="" GIT_COMMIT="" EPOCH_TEST_COMMIT=""

	# Use proper pkg-config to get gpgme cflags and ldflags when
	# cross-compiling, bug 930982.
	if tc-is-cross-compiler; then
		tc-export PKG_CONFIG
	fi

	emake \
			BUILDFLAGS="-v -work -x" \
			GOMD2MAN="go-md2man" \
			EXTRA_BUILDTAGS="$(usev seccomp)" \
		all $(usex wrapper 'docker-docs' '')
}

src_install() {
	emake \
			DESTDIR="${D}" \
		install install.completions \
			$(usex wrapper 'install.docker-full' '')

	if ! use experimental; then
		rm \
			"${ED}"/usr/bin/podmansh \
			"${ED}"/usr/share/man/man1/podmansh.1
	fi
	if ! use systemd; then
		rm \
			"${ED}"/usr/libexec/podman/quadlet \
			"${ED}"/usr/share/man/man5/quadlet.5 \
			"${ED}"/usr/share/man/man5/podman-systemd.unit.5
	fi
	if ! use rootless; then
		rm "${ED}"/usr/libexec/podman/rootlessport
	fi

	if has_version -r '>=app-containers/cni-plugins-0.8.6'; then
		insinto /etc/cni/net.d
		doins cni/87-podman-bridge.conflist
	fi

	if use !systemd; then
		newconfd "${FILESDIR}"/podman-5.0.0_rc4.confd podman
		newinitd "${FILESDIR}"/podman-5.0.0_rc4.initd podman

		newinitd "${FILESDIR}"/podman-restart-5.0.0_rc4.initd podman-restart
		newconfd "${FILESDIR}"/podman-restart-5.0.0_rc4.confd podman-restart

		newinitd "${FILESDIR}"/podman-clean-transient-5.0.0_rc6.initd podman-clean-transient
		newconfd "${FILESDIR}"/podman-clean-transient-5.0.0_rc6.confd podman-clean-transient

		exeinto /etc/cron.daily
		newexe "${FILESDIR}"/podman-auto-update-5.0.0.cron podman-auto-update

		insinto /etc/logrotate.d
		newins "${FILESDIR}/podman.logrotated" podman
	fi

	if ! use bash-completion; then
		rm -r "${ED}"/usr/share/bash-completion/completions
	fi
	if ! use zsh-completion; then
		rm -r "${ED}"/usr/share/zsh/site-functions
	fi
	if ! use fish-completion; then
		rm -r "${ED}"/usr/share/fish/vendor_completions.d
	fi

	keepdir /var/lib/containers
}

pkg_preinst() {
	PODMAN_ROOTLESS_UPGRADE=false
	if use rootless; then
		has_version 'app-containers/libpod[rootless]' ||
		has_version 'app-containers/podman[rootless]' ||
			PODMAN_ROOTLESS_UPGRADE=true
	fi
}

pkg_postinst() {
	use tmpfiles &&
		tmpfiles_process podman.conf \
			$(usex wrapper 'podman-docker.conf' '')

	local want_newline=false
	if [[ ${PODMAN_ROOTLESS_UPGRADE} == true ]] ; then
		${want_newline} && elog ""
		elog "For rootless operation, you need to configure subuid/subgid"
		elog "for user running podman. In case subuid/subgid has only been"
		elog "configured for root, run:"
		elog "usermod --add-subuids 1065536-1131071 <user>"
		elog "usermod --add-subgids 1065536-1131071 <user>"
		want_newline=true
	fi
}

# vi: set diffopt=iwhite,filler:
