# Copyright 2014-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

if [[ ${PV} == 9999* ]]; then
	inherit flag-o-matic toolchain-funcs
	EGIT_REPO_URI="https://anongit.gentoo.org/git/proj/gentoo-functions.git"
else
	SRC_URI="https://gitweb.gentoo.org/proj/gentoo-functions.git/snapshot/${P}.tar.gz"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
fi

inherit flag-o-matic toolchain-funcs

DESCRIPTION="Base functions required by all Gentoo systems"
HOMEPAGE="https://gitweb.gentoo.org/proj/gentoo-functions.git"

LICENSE="GPL-2"
SLOT="0"

PATCHES=(
	"${FILESDIR}/${P}-shellcheck.patch"
)

src_configure() {
	tc-export CC
	append-lfs-flags
	export ROOTPREFIX="${EPREFIX}"
	export PREFIX="${EPREFIX%/}/usr"
}
