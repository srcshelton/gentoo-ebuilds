# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="Realistic PHP password strength estimate library based on Zxcvbn JS"
HOMEPAGE="https://github.com/bjeavons/zxcvbn-php"
SRC_URI="https://github.com/bjeavons/zxcvbn-php/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
#IUSE="test"
#RESTRICT="test"

RDEPEND="
	|| ( dev-lang/php:8.1= dev-lang/php:8.0= dev-lang/php:7.2= )
	dev-php/symfony-mbstring
"
#DEPEND="
#	test? (
#		${RDEPEND}
#		dev-php/phpunit
#		dev-php/PHP_CodeSniffer
#	)
#"
# 'test' needs php-coveralls/php-coveralls

S="${WORKDIR}/zxcvbn-php-${PV}"

src_prepare() {
	default

	rm -r .github
}

src_install() {
	insinto "/usr/share/php/ZxcvbnPhp"
	doins -r src/Matchers src/Math src/*.php
	dodoc README.md
}

# The test-suite requires the contents of a 'vendor' directory which is
# specifically excluded from the GitHub repo :(
#
#src_test() {
#	phpunit --bootstrap test/config/bootstrap.php || die "test suite failed"
#}
