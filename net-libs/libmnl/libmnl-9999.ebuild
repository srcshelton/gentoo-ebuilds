# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: c1eee63b971d93ae950f8d9ed8419667fa2e7f7f $

EAPI=6

inherit autotools eutils git-r3 toolchain-funcs

DESCRIPTION="Minimalistic netlink library"
HOMEPAGE="http://netfilter.org/projects/libmnl"
EGIT_REPO_URI="git://git.netfilter.org/${PN}.git"
EGIT_MASTER="master"

LICENSE="LGPL-2.1"
SLOT="0/0.2.0"
#KEYWORDS="alpha amd64 arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~amd64-linux"
KEYWORDS=""
IUSE="examples static-libs"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default

	gen_usr_ldscript -a mnl
	prune_libtool_files

	if use examples; then
		find examples/ -name 'Makefile*' -delete
		dodoc -r examples/
		docompress -x /usr/share/doc/${PF}/examples
	fi
}
