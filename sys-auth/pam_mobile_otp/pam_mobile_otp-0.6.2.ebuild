# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs pam

DESCRIPTION="Mobile-OTP: Strong, two-factor authentication with mobile phones"
HOMEPAGE="http://motp.sourceforge.net/"
SRC_URI="http://motp.sourceforge.net/pam_mobile_otp-0.6.2.tgz"
RESTICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="-android manager"

DEPEND="sys-libs/pam"

S="${WORKDIR}/${PN}"

src_prepare() {
	eapply "${FILESDIR}/${P}-Makefile.patch" || die "Failed to patch Makefile"
	eapply "${FILESDIR}/${P}-md5.patch" || die "Failed to patch md5 library code"
	eapply "${FILESDIR}/${PN}-0.6.1-prompt.patch" || die "Failed to patch pam_mobile_otp.c"
	eapply "${FILESDIR}/${PN}-0.6.1-__stack_chk_fail_local.patch" || die "Failed to patch pam_mobile_otp.c"

	if use android; then
		sed -i '/^#define LEN_PIN/s/4$/7/' pam_mobile_otp.c || die "Failed to update PIN length for Android devices"
	fi

	default
}

src_install() {
	if use manager; then
		dosbin motp-manager || die "Cannot install 'motp-manager'"
		fperms 0700 /usr/sbin/motp-manager || die "Cannot set permissions on 'motp-manager'"
	fi

	insinto /etc/security
	newins "${FILESDIR}/${PN}-0.6.1-motp.conf" "motp.conf"

	dopammod pam_mobile_otp.so || die "Cannot install pam_mobile_otp.so PAM module"

	dodoc README || die "Cannot install pam_mobile_otp README"
}

pkg_postinst() {
	# Create cache directory for motp
	mkdir -p -m 0755 "${EROOT%/}"/var/cache
	mkdir -p -m 0700 "${EROOT%/}"/var/cache/motp

	elog "To enable pam_mobile_otp put something similar to:"
	elog
	elog "		auth  sufficient /lib/security/pam_mobile_otp.so not_set_pass"
	if ! use android; then
	elog "		password required /lib/security/pam_mobile_otp.so debug"
	fi
	elog "	and"
	elog "		account required /lib/security/pam_mobile_otp.so"
	elog
	elog "... into /etc/pam.d/login"
}

