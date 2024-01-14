# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

MY_PN="pupnp"

DESCRIPTION="A Portable Open Source UPnP Development Kit" # forked in 2008 from upstream libupnp-1.6.6
HOMEPAGE="http://pupnp.sourceforge.net/"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/archive/release-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${MY_PN}-release-${PV}"

LICENSE="BSD"
SLOT="0/17"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~loong ~mips ppc ppc64 ~riscv sparc x86 ~amd64-linux"
IUSE="blocking-tcp +client debug examples +reuseaddr +server +ssl static-libs +tools +webserver"
REQUIRED_USE="!server? ( !webserver )"

RDEPEND="ssl? ( dev-libs/openssl:0= )"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

PATCHES=( "${FILESDIR}/${PN}-1.14.12-disable-network-tests.patch" )

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		$(use_enable blocking-tcp blocking-tcp-connections)
		$(use_enable client)
		$(use_enable debug)
		$(use_enable examples samples)
		--enable-ipv6
		$(use_enable reuseaddr)
		$(use_enable server device)
		$(use_enable ssl open_ssl)
		$(use_enable static-libs static)
		$(use_enable tools)
		$(use_enable webserver)
	)
	# Unspecified default-on options: ssdp, optssdp, soap, gena, scriptsupport
	# Unused default-off options: unspecified_server, open_ssl, postwrite

	econf ${myeconfargs[@]}
}

src_install() {
	default

	if use client && use server && use examples; then
		dobin upnp/sample/.libs/tv_{combo,ctrlpt,device}-$(ver_cut 1-2) || die
	fi

	find "${D}" -name '*.la' -delete || die
}
