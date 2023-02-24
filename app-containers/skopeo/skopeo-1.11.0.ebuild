# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
COMMIT="968670116c56023d37e9e98b48346478599c6801"

inherit bash-completion-r1 go-module

DESCRIPTION="Command line utility foroperations on container images and image repositories"
HOMEPAGE="https://github.com/containers/skopeo"
SRC_URI="https://github.com/containers/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="btrfs"

COMMON_DEPEND=">=app-crypt/gpgme-1.5.5:=
	>=dev-libs/libassuan-2.4.3:=
	dev-libs/libgpg-error:=
	btrfs? ( >=sys-fs/btrfs-progs-4.0.1 )
	>=sys-fs/lvm2-2.02.145:="
DEPEND="${COMMON_DEPEND}
	dev-go/go-md2man"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="sys-apps/findutils
	sys-apps/grep
	sys-apps/sed"

RESTRICT="test"

src_prepare() {
	default

	# Fix run path...
	grep -Rl '[^r]/run/' . | xargs -r -- sed -ri -e 's|([ ":])/run|\1/var/run|g' || die
}

src_compile() {
	local BUILDTAGS
	BUILDTAGS="containers_image_ostree_stub $(usex btrfs "" exclude_graphdriver_btrfs)"
	set -- go build -mod=vendor -ldflags "-X main.gitCommit=${COMMIT}" \
		-gcflags "${GOGCFLAGS}" -tags "${BUILDTAGS}" \
		-o skopeo ./cmd/skopeo
	echo "$@"
	"$@" || die
	cd docs || die
	for f in *.1.md; do
		go-md2man -in ${f} -out ${f%%.md} || die
	done
}

src_install() {
	dobin skopeo
	doman docs/*.1
	insinto /etc/containers
	newins default-policy.json policy.json
	insinto /etc/containers/registries.d
	doins default.yaml
	keepdir /var/lib/atomic/sigstore
	einstalldocs
}
