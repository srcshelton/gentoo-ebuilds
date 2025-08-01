# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/netfilter.org.asc
inherit linux-info usr-ldscript verify-sig

DESCRIPTION="Netlink API to the in-kernel nf_tables subsystem"
HOMEPAGE="https://netfilter.org/projects/nftables/"

if [[ ${PV} =~ ^[9]{4,}$ ]]; then
	inherit autotools git-r3
	EGIT_REPO_URI="https://git.netfilter.org/${PN}"
else
	inherit libtool
	SRC_URI="
		https://netfilter.org/projects/${PN}/files/${P}.tar.xz
		verify-sig? ( https://netfilter.org/projects/${PN}/files/${P}.tar.xz.sig )
	"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86"

	BDEPEND+="verify-sig? ( >=sec-keys/openpgp-keys-netfilter-20240415 )"
fi

LICENSE="GPL-2"
SLOT="0/11" # libnftnl.so version
IUSE="examples static-libs test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=net-libs/libmnl-1.0.4:=
"
BDEPEND="${BDEPEND}
	virtual/pkgconfig
"
DEPEND="${RDEPEND}"

pkg_setup() {
	if kernel_is ge 3 13; then
		CONFIG_CHECK="~NF_TABLES"
		linux-info_pkg_setup
	else
		eerror "This package requires kernel version 3.13 or newer to work properly."
	fi
}

src_prepare() {
	default

	if [[ ${PV} =~ ^[9]{4,}$ ]] ; then
		eautoreconf
	else
		elibtoolize
	fi
}

src_configure() {
	local myeconfargs=(
		$(use_enable static-libs static)
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	gen_usr_ldscript -a nftnl

	find "${ED}" -type f -name '*.la' -delete || die

	if use examples; then
		find examples/ -name 'Makefile*' -delete || die "Could not rm examples"
		dodoc -r examples
		docompress -x /usr/share/doc/${PF}/examples
	fi
}
