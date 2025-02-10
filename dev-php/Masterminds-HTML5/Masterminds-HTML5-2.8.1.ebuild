# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="An HTML5 parser and serializer for PHP"
HOMEPAGE="https://github.com/Masterminds/html5-php"
SRC_URI="https://github.com/Masterminds/html5-php/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="HTML5-PHP"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND=">=dev-lang/php-5.3.0[ctype,xml]"

S="${WORKDIR}/html5-php-${PV}"

src_install() {
	insinto "/usr/share/php/Masterminds"
	doins -r src/HTML5 src/HTML5.php
	dodoc README.md
}
