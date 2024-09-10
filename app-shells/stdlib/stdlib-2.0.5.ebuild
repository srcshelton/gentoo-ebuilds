# Copyright 1999-2017 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Standard functions library for bash"
HOMEPAGE="https://github.com/srcshelton/stdlib.sh"
SRC_URI="https://github.com/srcshelton/stdlib.sh/archive/v2.0.5.tar.gz -> stdlib.sh-2.0.5.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k mips ppc ppc64 s390 sh sparc x86 amd64-fbsd sparc-fbsd x86-fbsd"
KEYWORDS+="~x64-macos ~x86-macos"
IUSE="colour"

RDEPEND=">=app-shells/bash-2.02"

S="${WORKDIR}"/stdlib.sh-"${PV}"

src_install() {
	dodoc README.md

	# Use insinto/doins rather than into/dolib as we don't want to use an
	# architecture-specific library directory
	insinto /usr/local/lib
	doins stdlib.sh

	if use colour; then
		insinto /etc/stdlib
		newins stdlib-colour.map colour.map
	fi
}
