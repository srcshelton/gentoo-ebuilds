# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit php-pear-r2

DESCRIPTION="Encrypt/decrypt PGP messages with PHP"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="posix"
DEPEND="
	>=dev-lang/php-5.2.1[posix?,unicode]
	dev-php/pear
	dev-php/PEAR-Console_CommandLine
	dev-php/PEAR-Exception"
RDEPEND="${DEPEND}
	app-crypt/gnupg"
