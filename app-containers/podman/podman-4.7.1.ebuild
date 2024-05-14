# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
#EGIT_COMMIT="ef83eeb9c7482826672f3efa12db3d61c88df6c4"

inherit bash-completion-r1 flag-o-matic go-module linux-info tmpfiles

#COMMON_VERSION='0.56.0'

DESCRIPTION="A tool for managing OCI containers and pods with Docker-compatible CLI"
HOMEPAGE="https://github.com/containers/podman/ https://podman.io/"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/podman.git"
else
	SRC_URI="https://github.com/containers/podman/archive/v${PV/_/-}.tar.gz -> ${P}.tar.gz"
	#	https://github.com/containers/common/archive/v${COMMON_VERSION}.tar.gz -> containers-common-${COMMON_VERSION}.tar.gz"
	KEYWORDS="~amd64 ~arm64 ~riscv"
fi

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"
IUSE="apparmor +bash-completion btrfs -cgroup-hybrid experimental fish-completion +fuse +init +rootless +seccomp selinux +sqlite systemd +tmpfiles wrapper zsh-completion"
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
	sys-fs/lvm2

	apparmor? ( sys-libs/libapparmor )
	btrfs? ( sys-fs/btrfs-progs )
	cgroup-hybrid? ( >=app-containers/runc-1.0.0_rc6  )
	!cgroup-hybrid? ( app-containers/crun )
	rootless? ( || ( app-containers/slirp4netns net-misc/passt ) )
	seccomp? ( sys-libs/libseccomp:= )
	selinux? ( sec-policy/selinux-podman sys-libs/libselinux:= )
	sqlite? ( dev-db/sqlite:= )
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

S="${WORKDIR}/${P/_/-}"

# Inherited from docker-20.10.22 ...
CONFIG_CHECK="
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

ERROR_KEYS="CONFIG_KEYS: is mandatory"
ERROR_MEMCG_SWAP="CONFIG_MEMCG_SWAP: is required if you wish to limit swap usage of containers"
ERROR_RESOURCE_COUNTERS="CONFIG_RESOURCE_COUNTERS: is optional for container statistics gathering"

ERROR_BLK_CGROUP="CONFIG_BLK_CGROUP: is optional for container statistics gathering"
ERROR_IOSCHED_CFQ="CONFIG_IOSCHED_CFQ: is optional for container statistics gathering"
ERROR_CGROUP_PERF="CONFIG_CGROUP_PERF: is optional for container statistics gathering"
ERROR_CFS_BANDWIDTH="CONFIG_CFS_BANDWIDTH: is optional for container statistics gathering"
ERROR_XFRM_ALGO="CONFIG_XFRM_ALGO: is optional for secure networks"
ERROR_XFRM_USER="CONFIG_XFRM_USER: is optional for secure networks"

pkg_setup() {
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

	# Disable installation of python modules here, since those are
	# installed by separate ebuilds.
	#makefile_sed_args=(
	#	-e '/^GIT_.*/d'
	#	-e 's/$(GO) build/$(GO) build -v -work -x/'
	#	-e 's/^\(install:.*\) install\.python$/\1/'
	#)

	#use systemd || makefile_sed_args+=(
	#	-e '/install.*SYSTEMDDIR/ s:^:#:'
	#	-e 's/^\(install:.*\) install\.systemd$/\1/'
	#)
	#use tmpfiles || makefile_sed_args+=(
	#	-e '/install.*TMPFILESDIR/ s:^:#:'
	#)

	#has_version -b '>=dev-lang/go-1.13.9' ||
	#	makefile_sed_args+=(-e 's:GO111MODULE=off:GO111MODULE=on:')

	#sed "${makefile_sed_args[@]}" -i Makefile || die

	for file in apparmor btrfs_installed btrfs selinux systemd; do
		[[ -f "hack/${file}_tag.sh" ]] || die
	done

	for feature in apparmor selinux systemd; do
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
	#local git_commit='' file=''
	#git_commit=$(grep '^[[:space:]]*gitCommit[[:space:]]' vendor/k8s.io/client-go/pkg/version/base.go)
	#git_commit=${git_commit#*\"}
	#git_commit=${git_commit%\"*}
	#if [[ "${git_commit:-}" != "${EGIT_COMMIT}" ]]; then
	#	ewarn "ebuild commit '${EGIT_COMMIT}' does not match source" \
	#		"commit '${git_commit:-}' (from file" \
	#		"'vendor/k8s.io/client-go/pkg/version/base.go')"
	#fi

	# Filter unsupported linker flags
	#filter-flags '-Wl,*'

	#go-md2man -in "${WORKDIR}/common-${COMMON_VERSION}/docs/containers.conf.5.md" -out "${T}/containers.conf.5"

	#export -n GOCACHE GOPATH XDG_CACHE_HOME
	#GOBIN="${S}/bin" \
	emake \
			PREFIX="${EPREFIX}/usr" \
			BUILDFLAGS="-v -work -x" \
			GOMD2MAN="go-md2man" \
			BUILD_SECCOMP="$(usex seccomp)" \
		all $(usev wrapper docker-docs)

			#GIT_BRANCH=master \
			#GIT_BRANCH_CLEAN=master \
			#COMMIT_NO="${EGIT_COMMIT}" \
			#GIT_COMMIT="${EGIT_COMMIT}"
}

src_install() {
	emake \
			PREFIX="${EPREFIX}/usr" \
			DESTDIR="${D}" \
		install $(usev wrapper install.docker-full)

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

	use bash-completion && dobashcomp completions/bash/*

	if use zsh-completion; then
		insinto /usr/share/zsh/site-functions
		doins completions/zsh/*
	fi

	if use fish-completion; then
		insinto /usr/share/fish/vendor_completions.d
		doins completions/fish/*
	fi

	#doman "${T}"/*.[15]

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
	if [[ ! ( -e ${EROOT%/*}/etc/containers/policy.json && -e ${EROOT%/*}/etc/containers/registries.conf ) ]]; then
		elog "You need to create the following config files:"
		elog "/etc/containers/registries.conf"
		elog "/etc/containers/policy.json"
		elog "To copy over default examples, use:"
		elog "cp /etc/containers/registries.conf{.example,}"
		elog "cp /etc/containers/policy.json{.example,}"
		want_newline=true
	fi
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
