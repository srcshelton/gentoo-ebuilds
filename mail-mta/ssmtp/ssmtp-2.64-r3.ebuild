# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PATCHSET=4

WANT_AUTOMAKE=none

inherit autotools

DESCRIPTION="Extremely simple MTA to get mail off the system to a Mailhub"
HOMEPAGE="ftp://ftp.debian.org/debian/pool/main/s/ssmtp/"
SRC_URI="mirror://debian/pool/main/s/ssmtp/${P/-/_}.orig.tar.bz2
	https://dev.gentoo.org/~pinkbyte/distfiles/patches/${P}-patches-${PATCHSET}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ~mips ppc ppc64 ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="ipv6 libressl +ssl gnutls +mta"

DEPEND="ssl? (
		gnutls? ( net-libs/gnutls[openssl] )
		!gnutls? (
			!libressl? ( dev-libs/openssl:0= )
			libressl? ( dev-libs/libressl:0= )
		)
		!prefix? ( acct-group/ssmtp )
	)"
RDEPEND="${DEPEND}
	net-mail/mailbase
	mta? (
		!net-mail/mailwrapper
		!mail-mta/courier
		!mail-mta/esmtp
		!mail-mta/exim
		!mail-mta/mini-qmail
		!mail-mta/msmtp[mta]
		!mail-mta/nbsmtp
		!mail-mta/netqmail
		!mail-mta/nullmailer
		!mail-mta/postfix
		!mail-mta/qmail-ldap
		!mail-mta/sendmail
		!mail-mta/opensmtpd
	)"

REQUIRED_USE="gnutls? ( ssl )"

src_prepare() {
	# These patches are a mess with EAPI >6...
	for patch in "${WORKDIR}"/patches/*.patch; do
		name="$( basename "${patch}" )"
		sed -e '/^--- /			s|\.\(old\|new\|orig\)||' \
			-e '/^+++ /			s|\.\(old\|new\|orig\)||' \
			-e "/^--- /			s|${PN}-[0-9.]\+|${P}|" \
			-e "/^--- .*\//		s|^--- ${P}/|--- a/|" \
			-e '/^--- [^a][^/]/	s|^--- |--- a/|' \
			-e "/^+++ /			s|${PN}-[0-9.]\+|${P}|" \
			-e "/^+++ .*\//		s|^+++ ${P}/|+++ b/|" \
			-e '/^+++ [^b][^/]/	s|^+++ |+++ b/|' \
			"${patch}" > "${T}/${name}"
		eapply "${T}/${name}"
		rm "${T}/${name}"
	done

	eapply_user

	# let's start by not using configure.in anymore as future autoconf
	# versions will not support it.
	mv configure.in configure.ac || die

	eautoconf
}

src_configure() {
	econf \
		--sysconfdir="${EPREFIX}"/etc/ssmtp \
		$(use_enable ssl) \
		$(usex gnutls '--with-gnutls' '') \
		$(use_enable ipv6 inet6) \
		--enable-md5auth
}

src_compile() {
	emake etcdir="${EPREFIX}"/etc
}

src_install() {
	dosbin ssmtp

	doman ssmtp.8 ssmtp.conf.5
	dodoc ChangeLog CHANGELOG_OLD INSTALL README TLS
	newdoc ssmtp.lsm DESC

	insinto /etc/ssmtp
	doins ssmtp.conf revaliases

	local conffile="${ED%/}/etc/ssmtp/ssmtp.conf"

	# Sorry about the weird indentation, I couldn't figure out a cleverer way
	# to do this without having horribly >80 char lines.
	sed -i -e "s:^hostname=:\n# Gentoo bug #47562\\
# Commenting the following line will force ssmtp to figure\\
# out the hostname itself.\n\\
# hostname=:" \
		"${conffile}" || die "sed failed"

	# Comment rewriteDomain (bug #243364)
	sed -i -e "s:^rewriteDomain=:#rewriteDomain=:" "${conffile}"

	# Set restrictive perms on ssmtp.conf as per #187841, #239197
	# Protect the ssmtp configfile from being readable by regular users as it
	# may contain login/password data to auth against a the mailhub used.
	if ! use prefix; then
		fowners root:ssmtp /etc/ssmtp/ssmtp.conf
		fperms 640 /etc/ssmtp/ssmtp.conf
		fowners root:ssmtp /usr/sbin/ssmtp
		fperms 2711 /usr/sbin/ssmtp
	fi

	if use mta; then
		dosym ../sbin/ssmtp /usr/lib/sendmail
		dosym ../sbin/ssmtp /usr/bin/sendmail
		dosym ssmtp /usr/sbin/sendmail
		dosym ../sbin/ssmtp /usr/bin/mailq
		dosym ../sbin/ssmtp /usr/bin/newaliases
	fi
}
