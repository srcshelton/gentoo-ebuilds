# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit autotools git-r3 toolchain-funcs user

DESCRIPTION="Network traffic analyzer with web interface"
HOMEPAGE="https://www.ntop.org/"
# Use (updated) stable branch rather than release tag...
#SRC_URI="https://github.com/ntop/${PN}/archive/${PV}-stable.zip -> ${P}.zip"
#RESTRICT="mirror"
EGIT_REPO_URI="https://github.com/ntop/${PN}.git"
EGIT_BRANCH='dev'

LICENSE="GPL-3"
SLOT="0"
KEYWORDS='-*'

DEPEND="dev-db/sqlite:3
	dev-python/pyzmq
	dev-lang/luajit:2
	dev-libs/json-c:=
	dev-libs/geoip
	dev-libs/glib:2
	dev-libs/hiredis
	dev-libs/libmaxminddb
	dev-libs/libsodium:=
	dev-libs/libxml2
	net-analyzer/rrdtool
	net-libs/libpcap
	=net-libs/nDPI-9999
	net-misc/curl
	sys-libs/binutils-libs
	virtual/libmysqlclient"
RDEPEND="${DEPEND}
	dev-db/redis"

PATCHES=(
	#"${FILESDIR}"/${PN}-3.8-gentoo.patch
	#"${FILESDIR}"/${PN}-3.2-mysqltool.patch
	#"${FILESDIR}"/${P}-pointer-cmp.patch
	"${FILESDIR}"/${PN}-3.8-remove-pool-limits.patch
	"${FILESDIR}"/${PN}-3.8-ndpi.patch
)

src_prepare() {
	if [ "${PV}" != 9999 ]; then
		sed -e "s/@VERSION@/${PV}/g;s/@SHORT_VERSION@/${PV}/g" < "${S}/configure.seed" > "${S}/configure.ac" || die
	else
		sed -e "s/@VERSION@/$( date -u +'%Y%m%d' )/g" \
		    -e "s/@SHORT_VERSION@/$( date -u +'%Y%m%d' )/g" \
			-e '/^(REVISION|GIT_(RELEASE|DATE|BRANCH)|PRO_GIT_(RELEASE|DATE))=/d' \
		< "${S}/configure.seed" > "${S}/configure.tmp" || die
		awk -v output=1 -f <( cat - <<-END
			/^dnl start: nDPI handling$/	{ output = 0 }
			( 1 == output )					{ print \$0 }
			/^dnl finish: nDPI handling$/	{ output = 1 }
		END
		) -- "${S}/configure.tmp" > "${S}/configure.ac" || die
		rm "${S}/configure.tmp"
	fi

	default

	eautoreconf
}

src_configure() {
	econf --with-ndpi-includes="${EPREFIX%/}/usr/include/ndpi"
}

src_install() {
	SHARE_NTOPNG_DIR="${EPREFIX}/usr/share/${PN}"
	dodir ${SHARE_NTOPNG_DIR}
	insinto ${SHARE_NTOPNG_DIR}
	doins -r httpdocs
	doins -r scripts

	dodir ${SHARE_NTOPNG_DIR}/third-party
	insinto ${SHARE_NTOPNG_DIR}/third-party
	doins -r third-party/i18n.lua-master
	doins -r third-party/lua-resty-template-master

	exeinto /usr/sbin
	doexe ${PN}

	doman ${PN}.8

	newinitd "${FILESDIR}/ntopng.init.d" ntopng
	newconfd "${FILESDIR}/ntopng.conf.d" ntopng

	dodir "/var/lib/ntopng"
	fowners ntopng "${EPREFIX}/var/lib/ntopng"
}

pkg_setup() {
	enewuser ntopng
}

pkg_postinst() {
	elog "ntopng default credentials are user='admin' password='admin'"
}
