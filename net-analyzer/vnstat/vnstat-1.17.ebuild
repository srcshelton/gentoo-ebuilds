# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/teemutoivola.asc
inherit toolchain-funcs user verify-sig

DESCRIPTION="Console-based network traffic monitor that keeps statistics of network usage"
HOMEPAGE="https://humdi.net/vnstat/"
SRC_URI="https://humdi.net/vnstat/${P}.tar.gz
	verify-sig? ( https://humdi.net/vnstat/${P}.tar.gz.asc )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~hppa ppc ppc64 sparc x86"
IUSE="gd selinux test"
RESTRICT="!test? ( test )"

COMMON_DEPEND="gd? ( media-libs/gd[png] )"
DEPEND="
	${COMMON_DEPEND}
	test? ( dev-libs/check )
"
RDEPEND="
	${COMMON_DEPEND}
	selinux? ( sec-policy/selinux-vnstatd )
"
BDEPEND="verify-sig? ( app-crypt/openpgp-keys-teemutoivola )"

pkg_setup() {
	enewgroup vnstat
	enewuser vnstat -1 -1 /dev/null vnstat
}

src_prepare() {
	default

	tc-export CC

	sed -i \
		-e 's|vnstat[.]log|vnstatd.log|' \
		-e 's|vnstat/vnstat[.]pid|vnstatd/vnstatd.pid|' \
		cfg/${PN}.conf || die
}

src_compile() {
	emake ${PN} ${PN}d $(usex gd ${PN}i '')
}

src_install() {
	use gd && dobin vnstati
	dobin vnstat vnstatd

	exeinto /etc/cron.hourly
	newexe "${FILESDIR}"/vnstat.cron vnstat

	insinto /etc
	doins cfg/vnstat.conf
	fowners root:vnstat /etc/vnstat.conf

	newconfd "${FILESDIR}"/vnstatd.confd vnstatd
	newinitd "${FILESDIR}"/vnstatd.initd-r1 vnstatd

	if use prefix; then
		sed -i -r \
			-e "s,(\W)/(etc|bin|sbin|usr|var),\1${EPREFIX}/\2,g" \
			"${EPREFIX}"/etc/conf.d/vnstatd \
			"${EPREFIX}"/etc/init.d/vnstatd \
			"${EPREFIX}"/etc/vnstat.conf \
			"${EPREFIX}"/etc/cron.hourly/vnstat
	fi

	use gd && doman man/vnstati.1
	doman man/vnstat.1 man/vnstatd.1

	newdoc INSTALL README.setup
	dodoc CHANGES README UPGRADE FAQ examples/vnstat.cgi
}
