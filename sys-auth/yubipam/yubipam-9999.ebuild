# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

AUTOTOOLS_AUTORECONF=1
AUTOTOOLS_IN_SOURCE_BUILD=1
AUTOTOOLS_PRUNE_LIBTOOL_FILES="none"

inherit autotools-utils eutils git-r3 multilib user

DESCRIPTION="YubiPAM: PAM module for Yubikeys"
HOMEPAGE="http://www.securixlive.com/yubipam/"
EGIT_REPO_URI="git://github.com/firnsy/yubipam.git"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~mips ~x86"
IUSE=""

DEPEND="sys-libs/pam"
RDEPEND="${DEPEND}"

AUTHDB="/var/lib/${PN}/auth"
DOCS=( README ChangeLog )

pkg_setup() {
	enewgroup yubiauth
}

src_prepare() {
	find . -name "Makefile.am" -exec sed -ie '/rm .*\.l\?a/d' {} \;

	autotools-utils_src_prepare
	default_src_prepare
}

src_configure() {
	econf \
		--with-authdb="${AUTHDB}"
	# The following option is documented (although sometimes as --with-pam-lib)
	# but doesn't work correctly - the value specified is appended to '/lib' :(
	#	--with-pam-dir="$(get_libdir)"/security
}

src_install() {
	emake install DESTDIR="${ED}" PAMDIR="$(get_libdir)/security"

	find "${ED}" -type f -name \*.a -delete
	find "${ED}" -type f -name \*.la -delete

	touch "${T}"/"$( basename "${AUTHDB}" )"
	insopts -m0664 -g yubiauth
	insinto "$( dirname "${AUTHDB}" )"
	doins "${T}"/"$( basename "${AUTHDB}" )"

	fowners :yubiauth /usr/sbin/yk_chkpwd
	fperms g+s /usr/sbin/yk_chkpwd
	
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
