# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit toolchain-funcs pam

DESCRIPTION="Mobile-OTP: Strong, two-factor authentication with mobile phones"
HOMEPAGE="http://motp.sourceforge.net/"
SRC_URI="http://motp.sourceforge.net/pam_mobile_otp-0.6.1.tgz"
RESTICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
#IUSE=""

S="${WORKDIR}/${PN}"

src_prepare() {
	epatch "${FILESDIR}/${P}-motp-manager.patch" || die "Failed to patch motp-manager"
	epatch "${FILESDIR}/${P}-prompt.patch" || die "Failed to patch pam_mobile_otp.c"
	epatch "${FILESDIR}/${P}-Makefile.patch" || die "Failed to patch Makefile"
	epatch "${FILESDIR}/${P}-__stack_chk_fail_local.patch" || die "Failed to patch pam_mobile_otp.c"
}

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS}" \
		LD="$(tc-getLD)" \
		LDFLAGS="${LDFLAGS//-Wl,}" \
	|| die "emake failed"
}

src_install() {
	fperms 600 motp-manager || die "Cannot set permissions on 'motp-manager'"
	dosbin motp-manager || die "Cannot install 'motp-manager'"
	dodir /var/cache/motp
	dodir /etc/security
	cp "${FILESDIR}/${P}-motp.conf" "${ED}/etc/security/motp.conf"
	dopammod pam_mobile_otp.so || die "Cannot install pam_mobile_otp.so PAM module"
	dodoc README || die "Cannot install pam_mobile_otp README"
}

pkg_postinst() {
	elog "To enable pam_mobile_otp put something like"
	elog
	elog "		auth  sufficient /lib/security/pam_mobile_otp.so not_set_pass"
	elog "		password required /lib/security/pam_mobile_otp.so debug"
	elog "	and"
	elog "		account required /lib/security/pam_mobile_otp.so"
	elog
	elog "into /etc/pam.d/login"
}

