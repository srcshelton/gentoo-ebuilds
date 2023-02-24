# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COMMIT="ace074c"
MY_Y="${PV%????}"
MY_M="${PV#????}"
MY_M="${MY_M%??}"
MY_D="${PV#??????}"

DESCRIPTION="Plug A Simple Socket Transport"
HOMEPAGE="https://passt.top/passt/"
SRC_URI="https://passt.top/passt/snapshot/passt-${MY_Y}_${MY_M}_${MY_D}.${COMMIT}.tar.gz"

LICENSE="AGPL-3+ BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

IUSE="cpu_flags_x86_avx2 qemu"

#DEPEND=""
#RDEPEND=""
#BDEPEND=""

#PATCHES=()

S="${WORKDIR}/passt-${MY_Y}_${MY_M}_${MY_D}.${COMMIT}"

src_install() {
	if use cpu_flags_x86_avx2; then
		newbin "${PN}.avx2" "${PN}"
		newbin pasta.avx2 pasta
	else
		dobin "${PN}" pasta
	fi
	if use qemu; then
		dobin qrap
	fi

	newdoc README.plain.md README.md
	doman "${PN}.1" pasta.1
	if use qemu; then
		doman qrap.1
	fi
}
