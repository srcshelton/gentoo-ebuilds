# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_COMMIT="1a17ed78d331062344e98abe94f7bebaf51cf34a"

DESCRIPTION="A userspace daemon for proactive free memory management"
HOMEPAGE="https://github.com/oracle/adaptivemm"
SRC_URI="https://github.com/oracle/adaptivemm/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"

DEPEND="
	dev-libs/glib:2
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/zoneinfo.patch
)

S="${WORKDIR}/adaptivemm-${EGIT_COMMIT}/adaptivemm"

src_compile() {
	emake -C src
}

src_install() {
	default

	dosbin src/adaptivemmd

	newconfd adaptivemmd.cfg adaptivemmd

	doman doc/adaptivemmd.8
}
