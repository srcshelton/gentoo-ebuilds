# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Symfony Polyfill Mbstring Component"
HOMEPAGE="https://github.com/symfony/polyfill-mbstring"
SRC_URI="https://github.com/symfony/polyfill-mbstring/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~hppa ~ia64 ppc ppc64 ~s390 sparc x86"
IUSE="test"
RESTRICT="test"

RDEPEND="
	dev-lang/php:*
	dev-php/fedora-autoloader
"
DEPEND="
	test? (
		${RDEPEND}
		dev-php/phpunit
	)
"

S="${WORKDIR}/polyfill-mbstring-${PV}"

src_prepare() {
	default

	if use test; then
		cp "${FILESDIR}"/autoload.php "${S}"/autoload-test.php || die
	fi
}

src_install() {
	insinto "/usr/share/php/Symfony/Polyfill/Mbstring"
	doins -r *.php Resources "${FILESDIR}"/autoload.php
	dodoc README.md
}

src_test() {
	phpunit --bootstrap "${S}"/autoload-test.php || die "test suite failed"
}
