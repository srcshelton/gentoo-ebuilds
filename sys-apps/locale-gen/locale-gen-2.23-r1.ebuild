# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit prefix

DESCRIPTION="Generate locales based upon the config file /etc/locale.gen"
HOMEPAGE="https://gitweb.gentoo.org/proj/locale-gen.git/"
SRC_URI="https://gitweb.gentoo.org/proj/locale-gen.git/snapshot/${P}.tar.bz2"

# Totally unclear what the license is. Following here the statement
# in the Debian file that the tools accompanying glibc are GPL-2+
LICENSE="GPL-2+"

SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"

RDEPEND="
	app-alternatives/awk
	app-alternatives/gzip
	>=app-shells/bash-4
	sys-apps/gentoo-functions
	sys-apps/grep
	!<sys-libs/glibc-2.37-r3
"

src_prepare() {
	default
	eprefixify locale-gen

	sed -e '/--library-path/s|\./ld-\*\.so|./ld-linux-*.so*|' \
			-i locale-gen ||
		die "In-place library name correction failed: ${?}"
}

src_install() {
	dosbin locale-gen
	doman *.[0-8]
	insinto /etc
	doins locale.gen
	keepdir /usr/lib/locale
}
