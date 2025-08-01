# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson-multilib usr-ldscript

DESCRIPTION="inih (INI not invented here) simple .INI file parser"
HOMEPAGE="https://github.com/benhoyt/inih"
SRC_URI="https://github.com/benhoyt/inih/archive/r${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}"/inih-r${PV}

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86"

DOCS=( README.md )

src_configure() {
	local emesonargs=(
		-Ddefault_library=shared
		-Ddistro_install=true
		-Dwith_INIReader=true
	)

	meson-multilib_src_configure
}

src_install() {
	meson-multilib_src_install

	if use split-usr; then
		# need the libs in /
		gen_usr_ldscript -a inih
	fi
}
