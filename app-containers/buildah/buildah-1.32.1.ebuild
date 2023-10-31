# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 go-module linux-info
GIT_COMMIT="bfd436d159059b45d770a0fc62386c9e0b9bdbb1"

DESCRIPTION="A tool that facilitates building OCI images"
HOMEPAGE="https://github.com/containers/buildah"
SRC_URI="https://github.com/containers/buildah/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="btrfs doc selinux systemd test"
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
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}"

pkg_setup() {
	local CONFIG_CHECK=""

	# Inherited from docker-20.10.22 ...
	CONFIG_CHECK="
		~OVERLAY_FS ~!OVERLAY_FS_REDIRECT_DIR
		~EXT4_FS_SECURITY
		~EXT4_FS_POSIX_ACL
	"

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

	[[ -f hack/systemd_tag.sh ]] || die
	if use systemd; then
		echo -e '#!/bin/sh\necho systemd' > \
			hack/systemd_tag.sh || die
	else
		echo -e '#!/bin/sh\necho' > \
			hack/systemd_tag.sh || die
	fi

	[[ -f btrfs_installed_tag.sh ]] || die
	[[ -f btrfs_tag.sh ]] || die
	if use btrfs; then
		echo -e '#!/bin/sh\necho btrfs_noversion' > \
			btrfs_tag.sh || die
		#echo -e "#!/bin/sh\\ntrue" > \
		#	btrfs_installed_tag.sh || die
	else
		echo -e "#!/bin/sh\\necho exclude_graphdriver_btrfs" > \
			btrfs_installed_tag.sh || die
	fi

	# Fix run path...
	grep -Rl '[^r]/run/' . |
		xargs -r -- sed -re 's|([^r])/run/|\1/var/run/|g' -i || die

	if ! use test; then
		cat <<-'EOF' > "${T}/Makefile.patch"
			--- Makefile
			+++ Makefile
			@@ -54 +54 @@
			-all: bin/buildah bin/imgtype bin/copy bin/tutorial docs
			+all: bin/buildah docs
		EOF
		eapply -p0 "${T}/Makefile.patch"
	fi
}

src_compile() {
	emake GIT_COMMIT=${GIT_COMMIT} all
}

src_test() {
	emake test-unit
}

src_install() {
	use doc && dodoc CHANGELOG.md CONTRIBUTING.md README.md install.md troubleshooting.md
	use doc && dodoc -r docs/tutorials
	doman docs/*.1
	dobin bin/${PN}
	dobashcomp contrib/completions/bash/buildah
}
