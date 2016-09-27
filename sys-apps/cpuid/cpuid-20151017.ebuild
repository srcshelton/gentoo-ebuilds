# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: ae19cb5f037d0ee32e13716e68c487d519441f03 $

EAPI="5"

inherit eutils toolchain-funcs

DESCRIPTION="Utility to get detailed information about the CPU(s) using the
CPUID instruction"
HOMEPAGE="http://www.etallen.com/cpuid.html"
SRC_URI="http://www.etallen.com/${PN}/${P}.src.tar.gz"

KEYWORDS="amd64 ~x86"
SLOT="0"
LICENSE="GPL-2"
IUSE=""

src_prepare() {
	epatch "${FILESDIR}"/${PN}-20150606-Makefile.patch
	epatch "${FILESDIR}"/${PN}-20110305-fPIC.patch #376245
	epatch "${FILESDIR}"/${PN}-20140123-x32.patch
}

src_compile() {
	tc-export CC
	emake
}

src_install() {
	emake BUILDROOT="${D}" install
}
