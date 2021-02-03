# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# $Header: app-pda/libimobiledevice/libimobiledevice-9999.ebuild,v 1.0 2013/10/31 16:38:49 srcs Exp $

EAPI=6
PYTHON_COMPAT=( python3_{7..9} )
inherit autotools eutils git-r3 multilib python-r1

DESCRIPTION="Support library to communicate with Apple iPhone/iPod Touch devices"
HOMEPAGE="http://www.libimobiledevice.org/"
EGIT_REPO_URI="https://github.com/libimobiledevice/libimobiledevice.git"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0/6"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"
IUSE="gnutls python"

RDEPEND=">=app-pda/libplist-1.10[python?,${PYTHON_USEDEP}]
	>=app-pda/libusbmuxd-1.0.9
	gnutls? (
		dev-libs/libgcrypt
		>=dev-libs/libtasn1-1.1
		>=net-libs/gnutls-2.2.0
	)
	!gnutls? ( dev-libs/openssl:0 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	python? (
		${PYTHON_DEPS}
		>=dev-python/cython-0.17[${PYTHON_USEDEP}]
	)"

DOCS=( AUTHORS NEWS README.md )

pkg_setup() {
	# Prevent linking to the installed copy
	if has_version "<${CATEGORY}/${P}"; then
		rm -f "${EROOT}"/usr/$(get_libdir)/${PN}$(get_libname)
	fi
}

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	#use python && python_export_best

	local myconf
	use gnutls && myconf='--disable-openssl'
	use python || myconf+=' --without-cython'

	econf --disable-static ${myconf}
}

src_install() {
	default

	#prune_libtool_files --all
	find "${ED}" -type f -name "*.la" -delete
}
