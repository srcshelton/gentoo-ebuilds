# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_COMMIT='cbdb4d54bd3dddb8b4452adbfc29ca7702b8e387'
SECCOMP_VERSION='v0.30.0'
CATATONIT_VERSION='0.1.5'

inherit bash-completion-r1 flag-o-matic go-module linux-info

DESCRIPTION="Library and podman tool for running OCI-based containers in Pods"
HOMEPAGE="https://github.com/containers/podman/"
SRC_URI="https://github.com/containers/podman/archive/v${PV/_/-}.tar.gz -> ${P}.tar.gz
	https://github.com/openSUSE/catatonit/archive/v${CATATONIT_VERSION}.tar.gz -> catatonit-${CATATONIT_VERSION}.tar.gz
	https://github.com/containers/common/raw/${SECCOMP_VERSION}/pkg/seccomp/seccomp.json -> seccomp-${SECCOMP_VERSION}.json"
LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 GPL-3+ ISC MIT MPL-2.0" # GPL-3+ for catatonit
SLOT="0"

KEYWORDS="~amd64 ~arm64"
IUSE="apparmor btrfs +fuse +rootless selinux systemd"
RESTRICT="mirror test network-sandbox"

COMMON_DEPEND="
	app-crypt/gpgme:=
	>=app-containers/conmon-2.0.0
	|| ( >=app-containers/runc-1.0.0_rc6 app-containers/crun )
	dev-libs/libassuan:=
	dev-libs/libgpg-error:=
	>=net-misc/cni-plugins-0.8.6
	sys-fs/lvm2
	sys-libs/libseccomp:=

	apparmor? ( sys-libs/libapparmor )
	btrfs? ( sys-fs/btrfs-progs )
	rootless? ( app-containers/slirp4netns )
	selinux? ( sys-libs/libselinux:= )
"
BDEPEND="
	dev-vcs/git
	systemd? ( sys-apps/systemd )"
DEPEND="${COMMON_DEPEND}
	dev-go/go-md2man"
RDEPEND="${COMMON_DEPEND}
	fuse? ( sys-fs/fuse-overlayfs )"

PATCHES=(
	"${FILESDIR}"/libpod-2.0.0_rc4-varlink.patch 
)

S="${WORKDIR}/${P/_/-}"

# Inherited from docker-19.03.8 ...
CONFIG_CHECK="
	~NAMESPACES ~NET_NS ~PID_NS ~IPC_NS ~UTS_NS
	~CGROUPS ~CGROUP_CPUACCT ~CGROUP_DEVICE ~CGROUP_FREEZER ~CGROUP_SCHED ~CPUSETS ~MEMCG
	~KEYS
	~VETH ~BRIDGE ~BRIDGE_NETFILTER
	~IP_NF_FILTER ~IP_NF_TARGET_MASQUERADE
	~NETFILTER_XT_MATCH_ADDRTYPE ~NETFILTER_XT_MATCH_CONNTRACK ~NETFILTER_XT_MATCH_IPVS
	~IP_NF_NAT ~NF_NAT
	~POSIX_MQUEUE

	~USER_NS
	~SECCOMP
	~CGROUP_PIDS
	~MEMCG_SWAP

	~BLK_CGROUP ~BLK_DEV_THROTTLING
	~CGROUP_PERF
	~CGROUP_HUGETLB
	~NET_CLS_CGROUP
	~CFS_BANDWIDTH ~FAIR_GROUP_SCHED ~RT_GROUP_SCHED
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

src_unpack() {
	# Don't try to unpack the .json file
	MY_A=( ${A[@]/seccomp-${SECCOMP_VERSION}.json} )
	unpack ${MY_A[@]}
}

src_prepare() {
	default

	eapply -Rp1 "${FILESDIR}"/podman-2.2.0_rc2-unbreak-network.patch || die

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

	sed -e 's|OUTPUT="${CIRRUS_TAG:.*|OUTPUT='v${PV}'|' \
		-i hack/get_release_info.sh || die

	# Fix run path...
	local f
	find "${S}" -type f -exec grep -H '/run/podman/podman.sock' {} + | cut -d':' -f 1 | while read -r f; do
		einfo "Correcting run-path in file '${f}' ..."
		sed -i -e 's|/run/podman/podman.sock|/var/run/podman/podman.sock|g' "${f}" || die
	done
}

src_compile() {
	# Filter unsupported linker flags
	filter-flags '-Wl,*'

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

	[[ -f hack/install_catatonit.sh ]] || die
	cat > hack/install_catatonit.sh <<-EOF
		#!/bin/bash -ux
		BASE_PATH="/usr/libexec/podman"
		CATATONIT_PATH="\${BASE_PATH}/catatonit"
		CATATONIT_VERSION="v${CATATONIT_VERSION}"

		if [ -f \$CATATONIT_PATH ]; then
				echo "skipping ... catatonit is already installed"
		else
				echo "installing catatonit to \$CATATONIT_PATH"
				#buildDir=\$(mktemp -d)
				#git clone https://github.com/openSUSE/catatonit.git \$buildDir
				buildDir="${WORKDIR}/catatonit-${CATATONIT_VERSION}"

				pushd \$buildDir
				echo \$( pwd )
				#git reset --hard \${CATATONIT_VERSION}
				autoreconf -fiv
				./configure
				make
				install \${SELINUXOPT} -d -m 755 "${D%/}"/\$BASE_PATH
				install \${SELINUXOPT} -m 755 catatonit "${D%/}"/\$CATATONIT_PATH
				popd

				#rm -rf \$buildDir
		fi
	EOF
	sed -e '/\.\/hack\/install_catatonit\.sh$/ s|\.|SELINUXOPT="${SELINUXOPT}" .|' -i Makefile || die

	export -n GOCACHE GOPATH XDG_CACHE_HOME
	GOBIN="${S}/bin" \
		emake all install.catatonit \
			GIT_BRANCH=master \
			GIT_BRANCH_CLEAN=master \
			COMMIT_NO="${EGIT_COMMIT}" \
			GIT_COMMIT="${EGIT_COMMIT}"
}

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install install.catatonit

	insinto /etc/containers
	newins test/registries.conf registries.conf.example
	newins test/policy.json policy.json.example

	# Migrated to containers/common ...
	insinto /usr/share/containers
	newins "${DISTDIR}/seccomp-${SECCOMP_VERSION}.json" seccomp.json

	newinitd "${FILESDIR}"/podman.initd podman

	insinto /etc/logrotate.d
	newins "${FILESDIR}/podman.logrotated" podman

	dobashcomp completions/bash/*

	keepdir /var/lib/containers
}

pkg_preinst() {
	LIBPOD_ROOTLESS_UPGRADE=false
	if use rootless; then
		has_version 'app-containers/libpod[rootless]' ||
		has_version 'app-containers/podman[rootless]' ||
			LIBPOD_ROOTLESS_UPGRADE=true
	fi
}

pkg_postinst() {
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
	if [[ ${LIBPOD_ROOTLESS_UPGRADE} == true ]] ; then
		${want_newline} && elog ""
		elog "For rootless operation, you need to configure subuid/subgid"
		elog "for user running podman. In case subuid/subgid has only been"
		elog "configured for root, run:"
		elog "usermod --add-subuids 1065536-1131071 <user>"
		elog "usermod --add-subgids 1065536-1131071 <user>"
		want_newline=true
	fi
}
