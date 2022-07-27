# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_COMMIT="4c729407e9ef3cf9b5d03d0c103eeffa601cf276"

inherit bash-completion-r1 flag-o-matic go-module

DESCRIPTION="Library and podman tool for running OCI-based containers in Pods"
HOMEPAGE="https://github.com/containers/libpod/"
SRC_URI="https://github.com/containers/libpod/archive/v${PV/_/-}.tar.gz -> ${P}.tar.gz"
LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"

KEYWORDS="~amd64"
IUSE="apparmor btrfs +fuse +rootless selinux systemd"
RESTRICT="mirror test"

COMMON_DEPEND="
	app-crypt/gpgme:=
	>=app-containers/conmon-2.0.0
	|| ( >=app-containers/runc-1.0.0_rc6 app-containers/crun )
	dev-libs/libassuan:=
	dev-libs/libgpg-error:=
	app-containers/cni-plugins
	sys-fs/lvm2
	sys-libs/libseccomp:=

	apparmor? ( sys-libs/libapparmor )
	btrfs? ( sys-fs/btrfs-progs )
	rootless? ( app-containers/slirp4netns )
	selinux? ( sys-libs/libselinux:= )
"
BDEPEND="
	systemd? ( sys-apps/systemd )"
DEPEND="
	${COMMON_DEPEND}
	dev-go/go-md2man"
RDEPEND="${COMMON_DEPEND}
	fuse? ( sys-fs/fuse-overlayfs )"

PATCHES=(
	"${FILESDIR}"/libpod-2.0.0_rc4-varlink.patch 
)

S="${WORKDIR}/${P/_/-}"

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

	sed -e 's|OUTPUT="${CIRRUS_TAG:.*|OUTPUT='v${PV}'|' \
		-i hack/get_release_info.sh || die
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

	insinto /usr/share/containers
	doins seccomp.json

	newinitd "${FILESDIR}"/podman.initd podman

	insinto /etc/logrotate.d
	newins "${FILESDIR}/podman.logrotated" podman

	dobashcomp completions/bash/*

	keepdir /var/lib/containers
}

pkg_preinst() {
	LIBPOD_ROOTLESS_UPGRADE=false
	if use rootless; then
		has_version 'app-containers/libpod[rootless]' || LIBPOD_ROOTLESS_UPGRADE=true
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
