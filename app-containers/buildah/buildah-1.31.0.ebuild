# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 go-module linux-info
GIT_COMMIT="d0de60bbf34d7e97d08f8652abf794c3b66e47a1"

DESCRIPTION="A tool that facilitates building OCI images"
HOMEPAGE="https://github.com/containers/buildah"
SRC_URI="https://github.com/containers/buildah/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="btrfs selinux"
RESTRICT="mirror test"

DEPEND="
	app-crypt/gpgme:=
	app-containers/skopeo
	dev-libs/libgpg-error:=
	dev-libs/libassuan:=
	sys-apps/shadow:=
	sys-fs/lvm2:=
	sys-libs/libseccomp:=
	btrfs? ( sys-fs/btrfs-progs )
	selinux? ( sys-libs/libselinux:= )
"
RDEPEND="${DEPEND}"

# Inherited from docker-20.10.22 ...
CONFIG_CHECK="
	~OVERLAY_FS ~!OVERLAY_FS_REDIRECT_DIR
	~EXT4_FS_SECURITY
	~EXT4_FS_POSIX_ACL
"

pkg_setup() {
	if use btrfs; then
		CONFIG_CHECK+="
			~BTRFS_FS
			~BTRFS_FS_POSIX_ACL
		"
	fi

	linux-info_pkg_setup
}

src_prepare() {
	default

	[[ -f selinux_tag.sh ]] || die
	use selinux || { echo -e "#!/bin/sh\\ntrue" > \
		selinux_tag.sh || die; }
	sed -i -e 's/make -C/$(MAKE) -C/' Makefile || die 'sed failed'

	[[ -f btrfs_installed_tag.sh ]] || die
	if use btrfs; then
		echo -e "#!/bin/sh\\ntrue" > \
			btrfs_installed_tag.sh || die
	else
		echo -e "#!/bin/sh\\necho exclude_graphdriver_btrfs" > \
			btrfs_installed_tag.sh || die
	fi

	# Fix run path...
	grep -Rl '[^r]/run/' . |
		xargs -r -- sed -re 's|([^r])/run/|\1/var/run/|g' -i || die
}

src_compile() {
	emake GIT_COMMIT=${GIT_COMMIT} all
}

src_install() {
	dodoc CHANGELOG.md CONTRIBUTING.md README.md install.md troubleshooting.md
	doman docs/*.1
	dodoc -r docs/tutorials
	dobin bin/{${PN},imgtype}
	dobashcomp contrib/completions/bash/buildah
}

src_test() {
	emake test-unit
}
