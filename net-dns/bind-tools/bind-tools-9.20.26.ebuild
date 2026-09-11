# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="bind tools: dig, nslookup, host, nsupdate, dnssec-keygen"
HOMEPAGE="https://www.isc.org/bind/"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ~ppc ppc64 ~riscv ~s390 ~sparc x86"
IUSE="doc gssapi idn xml"

RDEPEND="=net-dns/bind-9.20*[tools,doc?,gssapi?,idn?,xml?]"
BDEPEND="${RDEPEND}"
