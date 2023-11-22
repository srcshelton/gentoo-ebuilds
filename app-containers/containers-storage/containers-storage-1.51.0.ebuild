# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Default config and docs related to Containers' storage"
HOMEPAGE="https://github.com/containers/storage"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/storage.git"
else
	SRC_URI="https://github.com/containers/storage/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${P#containers-}"
	KEYWORDS="amd64 arm64 ~riscv"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="btrfs +device-mapper test"
RDEPEND="
	btrfs? ( sys-fs/btrfs-progs )
	device-mapper? ( sys-fs/lvm2:= )"
DEPEND="${RDEPEND}
	test? (
		sys-fs/btrfs-progs
		sys-fs/lvm2
		sys-apps/util-linux
	)"
BDEPEND="
	dev-go/go-md2man
	dev-lang/go
"
RESTRICT="test"

PATCHES=(
	"${FILESDIR}"/system-md2man-path.patch
)

src_prepare() {
	default

	sed -e 's|: install\.tools|:|' -i Makefile || die

	[[ -f hack/btrfs_tag.sh ]] || die
	if ! use btrfs ; then
		echo -e "#!/bin/sh\necho exclude_graphdriver_btrfs" > \
			"hack/btrfs_tag.sh" || die
	fi

	[[ -f hack/libdm_tag.sh ]] || die
	if ! use device-mapper ; then
		echo -e "#!/bin/sh\necho btrfs_noversion exclude_graphdriver_devicemapper" > \
			"hack/libdm_tag.sh" || die
	fi
}

src_compile() {
	export -n GOCACHE GOPATH XDG_CACHE_HOME #678856
	emake GOMD2MAN=go-md2man FFJSON= containers-storage docs
}

src_test() {
	env -u GOFLAGS unshare -m emake local-test-unit || die
}

src_install() {
	emake DESTDIR="${D}" -C docs install
	dobin "${PN}"

	while read -r -d ''; do
		mv "${REPLY}" "${REPLY%.1}" || die
	done < <(find "${S}/docs" -name '*.[[:digit:]].1' -print0)
	find "${S}/docs" -name '*.[[:digit:]]' -exec doman '{}' + || die

	insinto /etc/containers
	doins storage.conf
}
