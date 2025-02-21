# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="A file system for mounting container images"
HOMEPAGE="https://github.com/containers/composefs"

if [ ${PV} == "9999" ] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/${PN}"
else
	SRC_URI="https://github.com/containers/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm64 ~arm ~x86"
fi

LICENSE="|| ( GPL-2+ Apache-2.0 ) LGPL-2+"
SLOT="0"
IUSE="fuse +man"

BDEPEND="
	virtual/pkgconfig
	fuse? ( >=sys-fs/fuse-3 )
	man? ( dev-go/go-md2man )
"
DEPEND="
	dev-libs/openssl
"

src_configure() {
	local -a emesonargs=(
		--default-library=shared
		-Dfuse=$(usex fuse 'enabled' 'disabled')
		-Dman=$(usex man 'enabled' 'disabled')
	)
	meson_src_configure
}

src_install() {
	meson_src_install
}
