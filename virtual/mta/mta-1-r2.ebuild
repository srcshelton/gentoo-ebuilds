# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for Message Transfer Agents"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="courier esmtp exim msmtp netqmail -no-mta notqmail nullmailer opensmtpd postfix sendmail ssmtp"

RDEPEND="
	no-mta? (
		prefix? ( sys-apps/baselayout-prefix )
		!prefix? ( sys-apps/baselayout )
	)
	nullmailer? ( mail-mta/nullmailer )
	msmtp? ( mail-mta/msmtp[mta] )
	ssmtp? ( mail-mta/ssmtp[mta] )
	courier? ( mail-mta/courier )
	esmtp? ( mail-mta/esmtp )
	exim? ( mail-mta/exim )
	netqmail? ( mail-mta/netqmail )
	notqmail? ( mail-mta/notqmail )
	postfix? ( mail-mta/postfix )
	sendmail? ( mail-mta/sendmail )
	opensmtpd? ( mail-mta/opensmtpd[mta] )
	!no-mta? ( !nullmailer? ( !msmtp? ( !ssmtp? ( !courier? ( !esmtp? ( !exim? ( !netqmail? ( !notqmail? ( !postfix? ( !sendmail? ( !opensmtpd? (
		|| (	mail-mta/nullmailer
				mail-mta/msmtp[mta]
				mail-mta/ssmtp[mta]
				mail-mta/courier
				mail-mta/esmtp
				mail-mta/exim
				mail-mta/netqmail
				mail-mta/notqmail
				mail-mta/postfix
				mail-mta/sendmail
				mail-mta/opensmtpd[mta] )
	) ) ) ) ) ) ) ) ) ) ) )"
REQUIRED_USE="?? ( no-mta nullmailer msmtp ssmtp courier esmtp exim netqmail notqmail postfix sendmail opensmtpd )"
