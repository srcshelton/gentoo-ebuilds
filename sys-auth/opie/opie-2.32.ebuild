# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils

DEBIAN_VERSION=".dfsg.1"
DEBIAN_EXTRA="-0.2+squeeze1"
DESCRIPTION="One-time Passwords In Everything"
HOMEPAGE="http://www.inner.net/opie"
SRC_URI="http://ftp.debian.org/debian/pool/main/${PN:0:1}/${PN}/${PN}_${PV}${DEBIAN_VERSION}.orig.tar.gz
	http://ftp.debian.org/debian/pool/main/${PN:0:1}/${PN}/${PN}_${PV}${DEBIAN_VERSION}${DEBIAN_EXTRA}.diff.gz"
RESTICT="nomirror"

LICENSE="inner-net"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="+client server"


S="${WORKDIR}"/"${P}${DEBIAN_VERSION}"

pkg_pretend() {
	if ! use server && ! use client; then
		die "At least one of USE=\"client\" or USE=\"server\" must be specified"
	fi
}

src_prepare() {
	epatch "${WORKDIR}"/"${PN}_${PV}${DEBIAN_VERSION}${DEBIAN_EXTRA}.diff" || \
		die "Applying Debian patch failed: $?"
	epatch "${FILESDIR}"/${P}-includes.patch || \
		die "Applying includes patch failed: $?"
	epatch "${FILESDIR}"/${P}-min_length.patch || \
		die "Applying password length patch failed: $?"
}

src_configure() {
	econf \
		--enable-su-star-check \
		--enable-insecure-override \
	|| die "Configuration failed: $?"
#		--enable-retype \

	sed -i 's/^DEBUG=.*$/DEBUG=/' Makefile || \
		die "Failed correcting DEBUG flags"
	sed -ri "s/^(CFLAGS=.*)$/\1 ${CFLAGS}/" Makefile || \
		die "Failed correcting CFLAGS"
	sed -ri "s/^(LFLAGS=.*)$/\1 ${LDFLAGS}/" Makefile || \
		die "Failed correcting CFLAGS"
}

src_install() {
	dodoc README
	doman opie.4
	doman opieaccess.5

	if use client; then
		fperms 511 opiekey
		dobin opiekey
		#dosym opiekey /usr/bin/otp-md4
		#dosym opiekey /usr/bin/otp-md5

		doman opiekey.1
		#dosym opiekey.1.bz2 /usr/share/man/man1/otp-md4.1.bz2
		#dosym opiekey.1.bz2 /usr/share/man/man1/otp-md5.1.bz2
		doman opiekeys.5
	fi

	if use server; then
		fperms 555 opieinfo
		fperms 4511 opiepasswd
		dobin opiepasswd opieinfo

		touch opiekeys
		fperms 644 opiekeys
		insinto /etc
		doins opiekeys

		dodir /etc/opielocks
		fperms 700 /etc/opielocks

		doman opieinfo.1
		doman opiepasswd.1

		doheader opie.h
		dolib.a libopie/libopie.a
	fi
}
