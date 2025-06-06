# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Default config and docs related to Containers' storage"
HOMEPAGE="https://github.com/containers/storage"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/storage.git"
else
	SRC_URI="https://github.com/containers/storage/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${P#containers-}"
	KEYWORDS="amd64 arm64 ~loong ~riscv"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="btrfs test tool"
REQUIRED_USE="
	btrfs? ( tool )
	test? ( tool )
"

RDEPEND="
	btrfs? ( sys-fs/btrfs-progs )"
DEPEND="${RDEPEND}
	tool? ( sys-apps/shadow:= )
	test? (
		sys-fs/btrfs-progs
		sys-fs/lvm2
		sys-apps/util-linux
	)"
BDEPEND="
	>=dev-go/go-md2man-2.0.2
	tool? ( dev-lang/go )
"
RESTRICT="test"

PATCHES=(
	"${FILESDIR}"/system-md2man-path.patch
)

src_prepare() {
	local file=''

	default

	if use tool; then
		sed -e 's|: install\.tools|:|' -i Makefile || die

		for file in \
			hack/btrfs_tag.sh \
			hack/libsubid_tag.sh
		do
			[[ -f "${file}" ]] || die "Required file '${file}' missing"
		done
		if ! use btrfs ; then
			printf '#!/bin/sh\necho exclude_graphdriver_btrfs' > \
				hack/btrfs_tag.sh || die
		fi
		printf '#!/bin/sh\necho libsubid' > hack/libsubid_tag.sh || die
	fi
}

src_compile() {
	if [[ "${GOFLAGS:-}" =~ -tags ]]; then
		GOFLAGS="$( sed "s/ '-tags\s\+[^']*' / /g" <<<" ${GOFLAGS} " )"
	fi

	if use tool; then
		export -n GOCACHE GOPATH XDG_CACHE_HOME #678856
		emake GOMD2MAN=go-md2man FFJSON= containers-storage docs
	else
		emake -C docs GOMD2MAN=go-md2man containers-storage.conf.5
	fi
}

src_test() {
	env -u GOFLAGS unshare -m emake local-test-unit || die
}

src_install() {
	emake DESTDIR="${ED}" -C docs install

	if use tool; then
		dobin "${PN}"

		while read -r -d ''; do
			mv "${REPLY}" "${REPLY%.1}" || die
		done < <(find "${S}/docs" -name '*.[[:digit:]].1' -print0)
		find "${S}/docs" -name '*.[[:digit:]]' -exec doman '{}' + || die
	fi

	insinto /usr/share/containers
	doins storage.conf
}

# vi: set diffopt=filler,iwhite:
