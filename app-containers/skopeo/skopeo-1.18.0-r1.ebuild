# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module linux-info

DESCRIPTION="Work with remote container images registries"
HOMEPAGE="https://github.com/containers/skopeo"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/skopeo.git"
else
	SRC_URI="https://github.com/containers/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm64"
fi

# main
LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT"
SLOT="0"
IUSE="bash-completion btrfs device-mapper fish-completion rootless zsh-completion"
RESTRICT="test"

COMMON_DEPEND="
	>=app-crypt/gpgme-1.5.5:=
	>=dev-libs/libassuan-2.4.3:=
	btrfs? ( >=sys-fs/btrfs-progs-4.0.1 )
	device-mapper? ( >=sys-fs/lvm2-2.02.145:= )
	rootless? ( sys-apps/shadow:= )
"

# TODO: Is this really needed? cause upstream doesnt mention it
# https://github.com/containers/skopeo/blob/main/install.md#building-from-source
# 	dev-libs/libgpg-error:=
DEPEND="${COMMON_DEPEND}"
RDEPEND="
	${COMMON_DEPEND}
	app-containers/containers-common
"
BDEPEND="dev-go/go-md2man
	sys-apps/findutils
	sys-apps/grep
	sys-apps/sed"

pkg_setup() {
	use btrfs && CONFIG_CHECK+=" ~BTRFS_FS"
	use device-mapper && CONFIG_CHECK+=" ~MD"
	linux-info_pkg_setup
}

src_prepare() {
	default

	# Fix run path...
	grep -Rl '[^r]/run/' . | xargs -r -- sed -ri -e 's|([ ":])/run|\1/var/run|g' || die
}

run_make() {
	local -a emakeflags=(
		BTRFS_BUILD_TAG="$(usex btrfs '' 'btrfs_noversion exclude_graphdriver_btrfs')"
		CONTAINERSCONFDIR="${EPREFIX}/etc/containers"
		LIBDM_BUILD_TAG="$(usex device-mapper '' 'libdm_no_deferred_remove exclude_graphdriver_devicemapper')"
		LIBSUBID_BUILD_TAG="$(usex rootless 'libsubid' '')"
		PREFIX="${EPREFIX}/usr"
		EXTRA_LDFLAGS="-bindnow -s -w"
		GOFLAGS="-trimpath"
	)
	emake "${emakeflags[@]}" "$@"
}

src_compile() {
	local completions=''

	if use bash-completion || use fish-completion || use zsh-completion; then
		completions='completions'
	fi
	run_make all ${completions:-}
}

src_install() {
	# The install target in the Makefile tries to rebuild the binary and
	# installs things that are already installed by containers-common.
	dobin bin/skopeo
	einstalldocs
	doman docs/*.1
	if use bash-completion || use fish-completion || use zsh-completion; then
		run_make "DESTDIR=${D}" install-completions
		if ! use bash-completion; then
			rm -r "${ED}"/usr/share/bash-completion/completions
		fi
		if ! use fish-completion; then
			rm -r "${ED}"/share/fish/vendor_completions.d
		fi
		if ! use zsh-completion; then
			rm -r "${ED}"/share/zsh/site-functions
		fi
	fi
}
