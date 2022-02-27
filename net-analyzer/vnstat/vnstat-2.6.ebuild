# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit systemd tmpfiles user

DESCRIPTION="Console-based network traffic monitor that keeps statistics of network usage"
HOMEPAGE="https://humdi.net/vnstat/"

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/vergoh/vnstat"
	inherit git-r3
else
	VERIFY_SIG_OPENPGP_KEY_PATH="/usr/share/openpgp-keys/teemutoivola.asc"
	inherit verify-sig

	SRC_URI="https://humdi.net/vnstat/${P}.tar.gz
		verify-sig? ( https://humdi.net/vnstat/${P}.tar.gz.asc )"

	KEYWORDS="amd64 arm arm64 ~hppa ~mips ppc ppc64 sparc x86"

	BDEPEND="verify-sig? ( app-crypt/openpgp-keys-teemutoivola )"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="gd selinux systemd test"
RESTRICT="!test? ( test )"

COMMON_DEPEND="
	dev-db/sqlite
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

PATCHES=(
	"${FILESDIR}"/${PN}-2.2-drop-root.patch
)

pkg_setup() {
	enewgroup vnstat
	enewuser vnstat -1 -1 /var/lib/vnstat vnstat
}

src_compile() {
	emake ${PN} ${PN}d $(usex gd ${PN}i '')
}

src_install() {
	use gd && dobin vnstati
	dobin vnstat vnstatd

	exeinto /usr/share/${PN}
	newexe "${FILESDIR}"/vnstat.cron-r1 vnstat.cron

	insinto /etc
	doins cfg/vnstat.conf
	fowners root:vnstat /etc/vnstat.conf

	keepdir /var/lib/vnstat
	fowners vnstat:vnstat /var/lib/vnstat

	newconfd "${FILESDIR}"/vnstatd.confd-r1 vnstatd
	newinitd "${FILESDIR}"/vnstatd.initd-r2 vnstatd

	if use systemd; then
		systemd_newunit "${FILESDIR}"/vnstatd.systemd vnstatd.service
		newtmpfiles "${FILESDIR}"/vnstatd.tmpfile vnstatd.conf
	fi

	if use prefix; then
		sed -i -r \
			-e "s,(\W)/(etc|bin|sbin|usr|var),\1${EPREFIX}/\2,g" \
			"${EPREFIX}"/etc/conf.d/vnstatd \
			"${EPREFIX}"/etc/init.d/vnstatd \
			"${EPREFIX}"/etc/vnstat.conf \
			"${EPREFIX}"/etc/cron.hourly/vnstat
	fi

	use gd && doman man/vnstati.1
	doman man/vnstat.1 man/vnstatd.8

	newdoc INSTALL README.setup
	dodoc CHANGES README UPGRADE FAQ examples/vnstat.cgi
}

# vi: set diffopt=iwhite,filler:
