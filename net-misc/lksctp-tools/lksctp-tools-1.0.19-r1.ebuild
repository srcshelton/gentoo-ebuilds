# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic linux-info

DESCRIPTION="Tools for Linux Kernel Stream Control Transmission Protocol implementation"
HOMEPAGE="https://github.com/sctp/lksctp-tools/wiki"
SRC_URI="https://github.com/sctp/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="|| ( GPL-2+ LGPL-2.1 )"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="static-libs"

# This is only supposed to work with Linux to begin with.
DEPEND="virtual/os-headers:20600"

REQUIRED_USE="kernel_linux"

CONFIG_CHECK="~IP_SCTP"
WARNING_IP_SCTP="CONFIG_IP_SCTP:\tis not set when it should be."

DOCS=( AUTHORS ChangeLog INSTALL NEWS README ROADMAP )

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	append-flags -fno-strict-aliasing

	local myeconfargs=(
		--enable-shared
		$(use_enable static-libs static)
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	default

	dodoc doc/*txt
	newdoc src/withsctp/README README.withsctp

	find "${ED}" -name '*.la' -delete || die

	if ! use static-libs ; then
		find "${ED}" -name "*.a" -delete || die
	fi
}
