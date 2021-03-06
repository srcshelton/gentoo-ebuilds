# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils linux-info systemd toolchain-funcs user

DESCRIPTION="The ReadyMedia DLNA/UPnP-AV compliant media server"
HOMEPAGE="http://minidlna.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${PV}/${P}.tar.gz
	https://dev.gentoo.org/~xmw/${PN}-gentoo-artwork.patch.xz"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="digikam netgear readynas systemd tivo"

RDEPEND="dev-db/sqlite:3
	media-libs/flac
	media-libs/libexif
	media-libs/libid3tag
	media-libs/libogg
	media-libs/libvorbis
	virtual/ffmpeg
	virtual/jpeg:0"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

CONFIG_CHECK="~INOTIFY_USER"

PATCHES=(
	"${WORKDIR}"/${PN}-gentoo-artwork.patch
	"${FILESDIR}"/${P}-logging.patch 
	"${FILESDIR}"/${P}-samsung.patch
)
	#"${FILESDIR}"/${P}-clients-samsung.patch
	#"${FILESDIR}"/${P}-upnpsoap-samsung.patch

pkg_setup() {
	local my_is_new="yes"

	[[ -d "${EPREFIX}"/var/lib/${PN} ]] && my_is_new="no"
	enewgroup ${PN}
	enewuser ${PN} -1 -1 /var/lib/${PN} ${PN}
	if [[ -d "${EPREFIX}"/var/lib/${PN} && "${my_is_new}" == "yes" ]] ; then
		# created by above enewuser command w/ wrong group and permissions
		chown ${PN}:${PN} "${EPREFIX}"/var/lib/${PN} || die
		chmod 0750 "${EPREFIX}"/var/lib/${PN} || die
		# if user already exists, but /var/lib/minidlna is missing
		# rely on ${D}/var/lib/minidlna created in src_install
	fi

	linux-info_pkg_setup
}

src_prepare() {
	sed -e "/log_dir/s:/var/log:/var/log/${PN}:" \
		-e "/db_dir/s:/var/cache/:/var/lib/:" \
		-i ${PN}.conf || die

	default
}

src_configure() {
	econf \
		--disable-silent-rules \
		--with-db-path=/var/lib/${PN} \
		--with-log-path=/var/log/${PN} \
		$(use_enable netgear) \
		$(use_enable readynas) \
		$(use_enable tivo)
}

src_install() {
	default

	#bug 536532
	use digikam && dosym /usr/sbin/${PN}d /usr/bin/${PN}

	insinto /etc
	doins ${PN}.conf

	newconfd "${FILESDIR}"/${PN}-1.0.25.confd ${PN}
	newinitd "${FILESDIR}"/${PN}-1.1.5.initd ${PN}

	if use systemd; then
		systemd_newunit "${FILESDIR}"/${PN}-1.1.2.service ${PN}.service
		echo "d /var/run/${PN} 0755 ${PN} ${PN} -" > "${T}"/${PN}.conf
		systemd_dotmpfilesd "${T}"/${PN}.conf
	fi

	dodir /var/{lib,log}/${PN}
	fowners ${PN}:${PN} /var/{lib,log}/${PN}
	fperms 0750 /var/{lib,log}/${PN}

	dodoc AUTHORS NEWS README TODO
	doman ${PN}d.8 ${PN}.conf.5
}

pkg_postinst() {
	ewarn "For legal reasons, the MiniDLNA projet is now known as ReadyMedia"
	elog "minidlna now runs as minidlna:minidlna (bug 426726),"
	elog "logfile is moved to /var/log/minidlna/minidlna.log,"
	elog "cache is moved to /var/lib/minidlna."
	elog "Please edit /etc/conf.d/${PN} and file ownerships to suit your needs."
}

# vi: set diffopt=iwhite,filler:
