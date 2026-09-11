# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=9

inherit readme.gentoo-r1

DESCRIPTION="Several utilities from the containers project"
HOMEPAGE="https://github.com/podman-container-tools/container-libs"
SRC_URI="https://github.com/podman-container-tools/container-libs/archive/common/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-common-v${PV}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~loong ~riscv"
IUSE="btrfs +extra +fuse +rootless systemd tool"
REQUIRED_USE="
	btrfs? ( tool )
"
RESTRICT="test"

COMMON_DEPEND="
	btrfs? ( sys-fs/btrfs-progs )
"
RDEPEND="${COMMON_DEPEND}
	app-containers/containers-shortnames
	extra? (
		>=app-containers/crun-1.25.1
		>=app-containers/netavark-2.0.0[dns(+)]
		rootless? ( >=net-misc/passt-2026.05.26 )
	)
	fuse? ( >=sys-fs/fuse-overlayfs-1.16 )
	!app-containers/containers-image
	!app-containers/containers-common
	!app-containers/containers-storage
	!<app-containers/buildah-1.44.0
	!<app-containers/podman-6.0.0
	!<app-containers/skopeo-1.23
"
DEPEND="${COMMON_DEPEND}
	tool? ( sys-apps/shadow:= )
"
BDEPEND="
	>=dev-go/go-md2man-2.0.7
	tool? ( dev-lang/go )
"

PATCHES=(
	"${FILESDIR}/c-libs-${PV}-remove-go-cc.patch"
	"${FILESDIR}"/c-libs-pr989-correct-CONTAINERSCONFDIR.patch
)

DOC_CONTENTS="\\n
For rootless operations, one needs to configure subuid(5) and subgid(5).\\n
See /etc/sub{uid,gid} to check whether rootless user is already configured.\\n
If not, quickly configure it with:\\n
usermod --add-subuids 1065536-1131071 <rootless user>\\n
usermod --add-subgids 1065536-1131071 <rootless user>\\n
"

src_prepare() {
	local file=''

	if use tool; then
		sed -e 's|: install\.tools|:|' -i Makefile || die

		for file in \
			storage/hack/btrfs_tag.sh \
			storage/hack/libsubid_tag.sh
		do
			[[ -f "${file}" ]] || die "Required file '${file}' missing"
		done
		if use btrfs ; then
			printf '#!/bin/sh\ntrue\n' \
				> storage/hack/btrfs_tag.sh || die
		else
			printf '#!/bin/sh\necho exclude_graphdriver_btrfs\n' \
				> storage/hack/btrfs_tag.sh || die
		fi
		printf '#!/bin/sh\necho libsubid\n' > storage/hack/libsubid_tag.sh || die
	fi

	default
}

src_compile() {
	if [[ "${GOFLAGS:-}" =~ -tags ]]; then
		GOFLAGS="$( sed "s/ '-tags\s\+[^']*' / /g" <<<" ${GOFLAGS} " )"
	fi

	if use tool; then
		export -n GOCACHE GOPATH XDG_CACHE_HOME #678856
		emake -C storage GOMD2MAN=go-md2man FFJSON='' containers-storage docs
	else
		emake -C storage/docs GOMD2MAN=go-md2man containers-storage.conf.5
	fi

	emake -C common PREFIX="${EPREFIX}/usr" docs
	emake -C image docs
	emake -C storage docs
	#touch {images,layers}.lock || die
}

src_install() {
	emake -C common DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
	emake -C image PREFIX="${ED}/usr" install
	emake -C storage DESTDIR="${ED}" install
	readme.gentoo_create_doc

	insinto /usr/share/containers
	doins common/pkg/{seccomp/seccomp.json,subscriptions/mounts.conf} storage/storage.conf image/registries.conf

	keepdir /etc/containers/{certs.d,oci/hooks.d,networks}
	use systemd && keepdir /etc/containers/systemd
	#keepdir /var/lib/containers/{sigstore,storage}

	if use tool; then
		dobin storage/containers-storage

		while read -r -d ''; do
			mv "${REPLY}" "${REPLY%.1}" || die
		done < <(find "${S}/storage/docs" -name '*.[[:digit:]].1' -print0)
		find "${S}/storage/docs" -name '*.[[:digit:]]' -exec doman '{}' + || die
	fi

	#diropts -m0700
	#dodir /usr/lib/containers/storage/overlay-{images,layers}
	#local i
	#for i in images layers; do
	#	insinto /usr/lib/containers/storage/overlay-"${i}"
	#	doins "${i}".lock
	#done
	insinto /usr/share/containers/registries.conf.d
	newins "${FILESDIR}/c-libs-${PV}-registries.conf" 00-gentoo.conf
}

pkg_postinst() {
	readme.gentoo_print_elog
}

# vi: set diffopt=filler,iwhite:
