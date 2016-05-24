# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 9d51a3fedcbb89ee9d89a8bb629120090e0509a5 $

EAPI=5
inherit prefix toolchain-funcs user

DESCRIPTION="Console-based network traffic monitor that keeps statistics of network usage"
HOMEPAGE="http://humdi.net/vnstat/"
SRC_URI="http://humdi.net/vnstat/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm hppa ~ppc ppc64 ~sparc ~x86"
IUSE="gd selinux test"

COMMON_DEPEND="
	gd? ( media-libs/gd[png] )
"
DEPEND="
	${COMMON_DEPEND}
	test? ( dev-libs/check )
"
RDEPEND="
	${COMMON_DEPEND}
	selinux? ( sec-policy/selinux-vnstatd )
"

pkg_setup() {
	enewgroup vnstat
	enewuser vnstat -1 -1 /dev/null vnstat
}

src_prepare() {
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
