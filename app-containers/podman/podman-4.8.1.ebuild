# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic go-module linux-info tmpfiles

DESCRIPTION="A tool for managing OCI containers and pods with Docker-compatible CLI"
HOMEPAGE="https://github.com/containers/podman/ https://podman.io/"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/podman.git"
else
	SRC_URI="https://github.com/containers/podman/archive/v${PV/_rc/-rc}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${P/_rc/-rc}"
	KEYWORDS="~amd64 ~arm64 ~riscv"
fi

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"
IUSE="apparmor +bash-completion btrfs -cgroup-hybrid experimental fish-completion +fuse +init +rootless +seccomp selinux systemd +tmpfiles wrapper zsh-completion"
RESTRICT="mirror test"

COMMON_DEPEND="
	app-crypt/gpgme:=
	>=app-containers/conmon-2.0.24
	>=app-containers/containers-common-0.56.0
	dev-libs/libassuan:=
	dev-libs/libgpg-error:=
	|| (
		>=app-containers/netavark-1.6.0[dns]
		>=app-containers/cni-plugins-0.8.6
	)
	sys-apps/shadow:=

	apparmor? ( sys-libs/libapparmor )
	btrfs? ( sys-fs/btrfs-progs )
	cgroup-hybrid? ( >=app-containers/runc-1.0.0_rc6  )
	!cgroup-hybrid? ( app-containers/crun )
	rootless? ( || ( app-containers/slirp4netns net-misc/passt ) )
	seccomp? ( sys-libs/libseccomp:= )
	selinux? ( sec-policy/selinux-podman sys-libs/libselinux:= )
"
BDEPEND="
	dev-go/go-md2man
	dev-vcs/git
	sys-apps/findutils
	sys-apps/grep
	sys-apps/sed
	systemd? ( sys-apps/systemd )
"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}
	fuse? ( sys-fs/fuse-overlayfs )
	init? ( app-containers/catatonit )
	selinux? ( sec-policy/selinux-podman )
	systemd? ( sys-apps/systemd:= )
	wrapper? ( !app-containers/docker-cli )
"

PATCHES=(
	"${FILESDIR}/seccomp-toggle-4.7.0.patch"
)

pkg_setup() {
	# Inherited from docker-20.10.22 ...
	local CONFIG_CHECK="
		~NAMESPACES ~NET_NS ~PID_NS ~IPC_NS ~UTS_NS
		~CGROUPS ~CGROUP_CPUACCT ~CGROUP_DEVICE ~CGROUP_FREEZER ~CGROUP_SCHED ~CPUSETS ~MEMCG
		~CGROUP_NET_PRIO
		~KEYS
		~VETH ~BRIDGE ~BRIDGE_NETFILTER
		~IP_NF_FILTER ~IP_NF_TARGET_MASQUERADE ~NETFILTER_XT_MARK
		~NETFILTER_NETLINK ~NETFILTER_XT_MATCH_ADDRTYPE ~NETFILTER_XT_MATCH_CONNTRACK ~NETFILTER_XT_MATCH_IPVS
		~IP_NF_NAT ~NF_NAT
		~POSIX_MQUEUE

		~USER_NS
		~SECCOMP
		~CGROUP_PIDS

		~BLK_CGROUP ~BLK_DEV_THROTTLING
		~CGROUP_PERF
		~CGROUP_HUGETLB
		~NET_CLS_CGROUP
		~CFS_BANDWIDTH ~FAIR_GROUP_SCHED
		~IP_VS ~IP_VS_PROTO_TCP ~IP_VS_PROTO_UDP ~IP_VS_NFCT ~IP_VS_RR

		~VXLAN
		~CRYPTO ~CRYPTO_AEAD ~CRYPTO_GCM ~CRYPTO_SEQIV ~CRYPTO_GHASH ~XFRM_ALGO ~XFRM_USER
		~IPVLAN
		~MACVLAN ~DUMMY
	"

	local ERROR_KEYS="CONFIG_KEYS: is mandatory"
	local ERROR_MEMCG_SWAP="CONFIG_MEMCG_SWAP: is required if you wish to limit swap usage of containers"
	local ERROR_RESOURCE_COUNTERS="CONFIG_RESOURCE_COUNTERS: is optional for container statistics gathering"

	local ERROR_BLK_CGROUP="CONFIG_BLK_CGROUP: is optional for container statistics gathering"
	local ERROR_IOSCHED_CFQ="CONFIG_IOSCHED_CFQ: is optional for container statistics gathering"
	local ERROR_CGROUP_PERF="CONFIG_CGROUP_PERF: is optional for container statistics gathering"
	local ERROR_CFS_BANDWIDTH="CONFIG_CFS_BANDWIDTH: is optional for container statistics gathering"
	local ERROR_XFRM_ALGO="CONFIG_XFRM_ALGO: is optional for secure networks"
	local ERROR_XFRM_USER="CONFIG_XFRM_USER: is optional for secure networks"

	if kernel_is lt 3 10; then
		ewarn ""
		ewarn "Using podman with kernels older than 3.10 is unstable and unsupported."
		ewarn " - http://docs.docker.com/engine/installation/binaries/#check-kernel-dependencies"
	fi

	if kernel_is le 3 18; then
		CONFIG_CHECK+="
			~RESOURCE_COUNTERS
		"
	fi

	if kernel_is le 3 13; then
		CONFIG_CHECK+="
			~NETPRIO_CGROUP
		"
	else
		CONFIG_CHECK+="
			~CGROUP_NET_PRIO
		"
	fi

	if kernel_is lt 4 5; then
		CONFIG_CHECK+="
			~MEMCG_KMEM
		"
		ERROR_MEMCG_KMEM="CONFIG_MEMCG_KMEM: is optional"
	fi

	if kernel_is lt 4 7; then
		CONFIG_CHECK+="
			~DEVPTS_MULTIPLE_INSTANCES
		"
	fi

	if kernel_is lt 5 1; then
		CONFIG_CHECK+="
			~NF_NAT_IPV4
			~IOSCHED_CFQ
			~CFQ_GROUP_IOSCHED
		"
	fi

	if kernel_is lt 5 2; then
		CONFIG_CHECK+="
			~NF_NAT_NEEDED
		"
	fi

	if kernel_is lt 5 8; then
		CONFIG_CHECK+="
			~MEMCG_SWAP_ENABLED
		"
	fi

	if kernel_is lt 6 1; then
		CONFIG_CHECK+="
			~MEMCG_SWAP
		"
	fi

	if use btrfs; then
		CONFIG_CHECK+="
			~BTRFS_FS
			~BTRFS_FS_POSIX_ACL
		"
	else
		CONFIG_CHECK+="
			~OVERLAY_FS ~!OVERLAY_FS_REDIRECT_DIR
			~EXT4_FS_SECURITY
			~EXT4_FS_POSIX_ACL
		"
	fi

	linux-info_pkg_setup
}

src_prepare() {
	local -a makefile_sed_args=()
	local file='' feature=''

	# test/e2e/build/containerignore-symlink/.dockerignore
	touch "${T}"/private_file
	rm test/e2e/build/containerignore-symlink/.dockerignore &&
		ln -s "${T}"/private_file \
			test/e2e/build/containerignore-symlink/.dockerignore

	default

	# assure necessary files are present
	local file
	for file in apparmor btrfs_installed btrfs systemd; do
		[[ -f "hack/${file}_tag.sh" ]] ||
			die "File '${file}_tag.sh' missing"
	done

	local feature
	for feature in apparmor systemd; do
		cat <<-EOF > "hack/${feature}_tag.sh" || die
			#!/bin/sh
			$(usex "${feature}" "echo ${feature}" 'true')
		EOF
	done

	cat <<-EOF > hack/btrfs_installed_tag.sh || die
		#!/bin/sh
		$(usex 'btrfs' 'true' 'echo exclude_graphdriver_btrfs')
	EOF
	cat <<-EOF > hack/btrfs_tag.sh || die
		#!/bin/sh
		$(usex 'btrfs' 'true' 'echo exclude_graphdriver_btrfs btrfs_noversion')
	EOF

	# Fix run path...
	grep -Rl '[^r]/run/' . |
		xargs -r -- sed -ri \
			-e 's|([^r])/run/|\1/var/run/|g ; s|^/run/|/var/run/|g' || die
}

src_compile() {
	# For non-live versions, prevent git operations which causes sandbox violations
	# https://github.com/gentoo/gentoo/pull/33531#issuecomment-1786107493
	[[ ${PV} != 9999* ]] && export COMMIT_NO="" GIT_COMMIT=""

	# BUILD_SECCOMP is used in the patch to toggle seccomp
	emake \
			PREFIX="${EPREFIX}/usr" \
			BUILDFLAGS="-v -work -x" \
			GOMD2MAN="go-md2man" \
			BUILD_SECCOMP="$(usex seccomp)" \
		all $(usev wrapper docker-docs)
}

src_install() {
	emake \
			PREFIX="${EPREFIX}/usr" \
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

	newconfd "${FILESDIR}"/podman.confd podman
	newinitd "${FILESDIR}"/podman.initd podman

	insinto /etc/logrotate.d
	newins "${FILESDIR}/podman.logrotated" podman

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
	use tmpfiles && tmpfiles_process podman.conf $(usev wrapper podman-docker.conf)

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
