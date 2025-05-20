# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Tool for incremental and recursive IMAP transfers between mailboxes"
HOMEPAGE="https://ks.lamiral.info/imapsync/ https://github.com/imapsync/imapsync"
SRC_URI="https://github.com/${PN}/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://imapsync.lamiral.info/dist/${P}.tgz"

LICENSE="WTFPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 ppc x86"
#IUSE="test" # not fully supported yet

# Authen::NTLM         1.09
# CGI                  4.67
# Compress::Zlib       2.212
# Crypt::OpenSSL::RSA  0.33
# Digest::HMAC_MD5     1.05
# Digest::HMAC_SHA1    1.05
# Digest::MD5          2.58_01
# Digest::SHA          6.04
# Encode               3.21
# Encode::IMAPUTF7     1.05
# File::Copy::Recursive 0.45
# File::Spec           3.90
# Getopt::Long         2.58
# HTML::Entities       3.83
# IO::Socket           1.55
# IO::Socket::INET     1.55
# IO::Socket::INET6    2.73
# IO::Socket::IP       0.42
# IO::Socket::SSL      2.089
# IO::Tee              0.65
# JSON                 4.10
# JSON::WebToken       0.10
# LWP                  6.78
# MIME::Base64         3.16_01
# Mail::IMAPClient     3.43
# Net::Ping            2.76
# Net::SSLeay          1.94
# Term::ReadKey        2.38
# Test::MockObject     1.20200122
# Time::HiRes          1.9777
# Unicode::String      2.10
RDEPEND="
	dev-perl/Authen-NTLM
	dev-perl/CGI
	virtual/perl-Compress-Raw-Zlib
	dev-perl/Crypt-OpenSSL-RSA
	virtual/perl-Digest
	dev-perl/Digest-HMAC
	virtual/perl-Digest-MD5
	virtual/perl-Digest-SHA
	virtual/perl-Encode
	dev-perl/Encode-IMAPUTF7
	dev-perl/File-Copy-Recursive
	dev-perl/IO-Socket-INET6
	dev-perl/IO-Socket-SSL
	dev-perl/IO-Tee
	dev-perl/JSON
	dev-perl/libwww-perl
	dev-perl/Mail-IMAPClient
	dev-perl/Net-SSLeay
	dev-perl/TermReadKey
	dev-perl/Unicode-String

	dev-perl/App-cpanminus
	dev-perl/Data-Uniqid
	dev-perl/Dist-CheckConflicts
	dev-perl/File-Tail
	dev-perl/Module-Implementation
	dev-perl/Module-Runtime
	dev-perl/Module-ScanDeps
	dev-perl/Package-Stash
	dev-perl/Package-Stash-XS
	dev-perl/PAR
	dev-perl/Parse-RecDescent
	dev-perl/Readonly
	dev-perl/Readonly-XS
	dev-perl/Regexp-Common
	dev-perl/Sys-MemInfo
	dev-perl/Try-Tiny
	dev-perl/URI
	virtual/perl-Data-Dumper
	virtual/perl-MIME-Base64
	"
	# Not yet in tree:
	# HTML::Entities
	# JSON::WebToken
	# JSON::WebToken::Crypt::RSA
DEPEND="${RDEPEND}"
BDEPEND="sys-apps/lsb-release"
	#test? (
	#	virtual/perl-Test
	#	dev-perl/Test-Deep
	#	dev-perl/Test-Fatal
	#	dev-perl/Test-MockObject
	#	dev-perl/Test-Pod
	#	dev-perl/Test-Requires
	#	dev-perl/Test-Warn
	#	dev-perl/Test-NoWarnings
	#)"
	# Not yet in tree:
	# test? ( Test::Mock::Guard )

RESTRICT="test"

src_prepare() {
	sed -e "s/^install: testp/install:/" \
		-e "/^DO_IT/,/^$/d" \
		-i "${S}"/Makefile || die

	default
}

src_compile() { :; }

src_install() {
	default

	docinto FAQ.d
	dodoc FAQ.d/FAQ.General.txt || die
}
