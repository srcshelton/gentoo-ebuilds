# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_COMMIT="34e8f3933242f2e566bbbbf343cf69b7d506c1cf"

inherit bash-completion-r1 flag-o-matic go-module linux-info tmpfiles

COMMON_VERSION='0.51.0'

DESCRIPTION="Library and podman tool for running OCI-based containers in Pods"
HOMEPAGE="https://github.com/containers/podman/"
SRC_URI="https://github.com/containers/podman/archive/v${PV/_/-}.tar.gz -> ${P}.tar.gz
	https://github.com/containers/common/archive/v${COMMON_VERSION}.tar.gz -> containers-common-${COMMON_VERSION}.tar.gz"
LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"

KEYWORDS="amd64 arm64 ~ppc64 ~riscv"
IUSE="apparmor +bash-completion btrfs -cgroup-hybrid fish-completion +fuse +init +rootless selinux systemd +tmpfiles zsh-completion"
#RESTRICT="mirror test network-sandbox"
RESTRICT="mirror test"

COMMON_DEPEND="
	app-crypt/gpgme:=
	>=app-containers/conmon-2.0.24
	cgroup-hybrid? ( >=app-containers/runc-1.0.0_rc6  )
	!cgroup-hybrid? ( app-containers/crun )
	dev-libs/libassuan:=
	dev-libs/libgpg-error:=
	|| ( app-containers/netavark >=app-containers/cni-plugins-0.8.6 )
	sys-apps/shadow:=
	sys-fs/lvm2
	sys-libs/libseccomp:=

	apparmor? ( sys-libs/libapparmor )
	btrfs? ( sys-fs/btrfs-progs )
	rootless? ( || ( app-containers/slirp4netns app-containers/passt ) )
	selinux? ( sys-libs/libselinux:= )
"
BDEPEND="
	dev-go/go-md2man
	dev-vcs/git
	sys-apps/findutils
	sys-apps/grep
	sys-apps/sed
	systemd? ( sys-apps/systemd )"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}
	fuse? ( sys-fs/fuse-overlayfs )
	init? ( app-containers/catatonit )
	selinux? ( sec-policy/selinux-podman )"

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

	~OVERLAY_FS ~!OVERLAY_FS_REDIRECT_DIR
	~EXT4_FS_SECURITY
	~EXT4_FS_POSIX_ACL
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

#PATCHES=(
#	"${FILESDIR}/${PN}-4.0.0-buildah-timeout.patch"
#	"${FILESDIR}/${PN}-4.0.0-dev-warning.patch"
#)

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
	fi

	CONFIG_CHECK+="
		~OVERLAY_FS ~EXT4_FS_SECURITY ~EXT4_FS_POSIX_ACL
	"

	linux-info_pkg_setup
}

src_prepare() {
	default

	# Disable installation of python modules here, since those are
	# installed by separate ebuilds.
	local makefile_sed_args=(
		-e '/^GIT_.*/d'
		-e 's/$(GO) build/$(GO) build -v -work -x/'
		-e 's/^\(install:.*\) install\.python$/\1/'
	)

	use systemd || makefile_sed_args+=(
		-e '/install.*SYSTEMDDIR/ s:^:#:'
		-e '/install.*TMPFILESDIR/ s:^:#:'
		-e 's/^\(install:.*\) install\.systemd$/\1/'
	)

	has_version -b '>=dev-lang/go-1.13.9' || makefile_sed_args+=(-e 's:GO111MODULE=off:GO111MODULE=on:')

	sed "${makefile_sed_args[@]}" -i Makefile || die

	# Fix run path...
	grep -Rl '[^r]/run/' . | xargs -r -- sed -re 's|([^r])/run/|\1/var/run/|g' -i || die
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
	filter-flags '-Wl,*'

	go-md2man -in "${WORKDIR}/common-${COMMON_VERSION}/docs/containers.conf.5.md" -out "${T}/containers.conf.5"

	[[ -f hack/apparmor_tag.sh ]] || die
	if use apparmor; then
		echo -e "#!/bin/sh\necho apparmor" > hack/apparmor_tag.sh || die
	else
		echo -e "#!/bin/sh\ntrue" > hack/apparmor_tag.sh || die
	fi

	[[ -f hack/btrfs_installed_tag.sh ]] || die
	if use btrfs; then
		echo -e "#!/bin/sh\ntrue" > hack/btrfs_installed_tag.sh || die
	else
		echo -e "#!/bin/sh\necho exclude_graphdriver_btrfs" > \
			hack/btrfs_installed_tag.sh || die
	fi

	[[ -f hack/selinux_tag.sh ]] || die
	if use selinux; then
		echo -e "#!/bin/sh\necho selinux" > hack/selinux_tag.sh || die
	else
		echo -e "#!/bin/sh\ntrue" > hack/selinux_tag.sh || die
	fi

	[[ -f hack/systemd_tag.sh ]] || die
	if use systemd; then
		echo -e "#!/bin/sh\necho systemd" > hack/systemd_tag.sh || die
	else
		echo -e "#!/bin/sh\ntrue" > hack/systemd_tag.sh || die
	fi

	export -n GOCACHE GOPATH XDG_CACHE_HOME
	GOBIN="${S}/bin" \
		emake all \
			GIT_BRANCH=master \
			GIT_BRANCH_CLEAN=master \
			COMMIT_NO="${EGIT_COMMIT}" \
			GIT_COMMIT="${EGIT_COMMIT}"
}

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install

	insinto /etc/containers
	newins test/registries.conf registries.conf.example
	newins test/policy.json policy.json.example

	# Migrated to containers/common ...
	insinto /usr/share/containers
	#doins vendor/github.com/containers/common/pkg/seccomp/seccomp.json
	newins "${WORKDIR}/common-${COMMON_VERSION}/pkg/seccomp/seccomp.json" seccomp.json

	insinto /etc/containers
	newins vendor/github.com/containers/storage/storage.conf storage.conf.example

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

	doman "${T}"/*.[15]

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
	use tmpfiles && tmpfiles_process podman.conf

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
