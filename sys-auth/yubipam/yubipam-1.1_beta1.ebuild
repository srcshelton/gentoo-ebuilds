# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

MY_PV="${PV/_/-}"

inherit eutils multilib user

DESCRIPTION="YubiPAM: PAM module for Yubikeys"
HOMEPAGE="http://www.securixlive.com/yubipam/"
SRC_URI="http://www.securixlive.com/download/yubipam/YubiPAM-${MY_PV}.tar.gz"
RESTRICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~mips ~x86"
IUSE=""

DEPEND="sys-libs/pam"
RDEPEND="${DEPEND}"

DOCS=( README INSTALL RELEASE.NOTES )
S="${WORKDIR}/YubiPAM-${MY_PV}"

pkg_setup() {
	enewgroup yubiauth
}

src_prepare() {
	cd "${S}"

	epatch "${FILESDIR}/${P}-concat-twofactor.patch" || die "epatch failed"
	epatch "${FILESDIR}/${P}-resource.h.patch" || die "epatch failed"
}

src_install() {
	emake install DESTDIR="${ED}" PAMDIR="$(get_libdir)/security"
	find "${ED}" -type f -name \*.a -delete
	find "${ED}" -type f -name \*.la -delete

	#diropts -m0660 -g yubiauth
	#dodir /etc/yubikey || die "creation of state directory failed"
	touch "${T}"/yubikey
	insinto /etc
	doins "${T}"/yubikey

	fowners :yubiauth /etc/yubikey /sbin/yk_chkpwd
	fperms g+rw /etc/yubikey
	fperms g+s /sbin/yk_chkpwd
	
	dodoc "${DOCS[@]}"
}

pkg_postinst() {
	einfo "To enable YubiPAM for system authentication"
	einfo "edit your /etc/pam.d/system-auth to include:"
	einfo
	einfo "	 auth sufficient pam_yubikey.so"
	einfo
	einfo "... just before pam_unix.so"
	echo
	einfo "See included README for module parameters"
}
