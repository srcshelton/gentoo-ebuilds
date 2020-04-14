# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit php-pear-r2

DESCRIPTION="Advanced functionality for accessing LDAP directories"
HOMEPAGE="https://gitlab.com/roundcube/net_ldap3"
SRC_URI="https://gitlab.com/roundcube/net_ldap3/-/archive/pear-Net-LDAP3-${PV}/net_ldap3-pear-Net-LDAP3-${PV}.tar.bz2"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"
RDEPEND="
	>=dev-lang/php-5.3.3:*[ldap]
	>=dev-php/PEAR-Net_LDAP2-2.0.12
"

S="${WORKDIR}/net_ldap3-pear-Net-LDAP3-${PV}"
