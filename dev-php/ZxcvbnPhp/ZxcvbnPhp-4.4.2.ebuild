# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="Realistic PHP password strength estimate library based on Zxcvbn JS"
HOMEPAGE="https://github.com/mkopinsky/zxcvbn-php"
SRC_URI="https://github.com/mkopinsky/zxcvbn-php/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="unicode"

RDEPEND="|| ( dev-lang/php:5.6= =dev-lang/php-7* )"

S="${WORKDIR}/zxcvbn-php-${PV}"

src_install() {
	insinto "/usr/share/php/ZxcvbnPhp"
	doins -r src/Matchers/ src/*.php
	dodoc README.md
}
