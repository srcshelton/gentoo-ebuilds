# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

MY_P="${P#PEAR-}"
MY_P="${MY_P//_/-}"

DESCRIPTION="PEAR:Net_LDAP2 successor, provides functionality for accessing LDAP"
HOMEPAGE="https://gitlab.com/roundcube/net_ldap3"
SRC_URI="https://gitlab.com/roundcube/net_ldap3/-/archive/pear-${MY_P}/net_ldap3-pear-${MY_P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm ~hppa ppc ppc64 sparc x86"

RDEPEND="
	dev-lang/php:*[ldap]
	dev-php/PEAR-Net_LDAP2
"

S="${WORKDIR}"

src_install() {
	insinto "/usr/share/php"
	doins -r lib/*
}
