# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DIST_AUTHOR=NLNETLABS
DIST_VERSION=1.16
inherit perl-module

DESCRIPTION="DNSSEC extensions to Net::DNS"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm arm64 ~hppa ~ia64 ~mips ~ppc ppc64 ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="+dsa +ecdsa gost +private-key test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-perl/Crypt-OpenSSL-Bignum-0.50.0
	>=dev-perl/Crypt-OpenSSL-RSA-0.280.0
	>=virtual/perl-File-Spec-0.860.0
	>=virtual/perl-MIME-Base64-2.110.0
	>=dev-perl/Net-DNS-1.10.0
	>=virtual/perl-Digest-SHA-5.230.0
	dsa? ( >=dev-perl/Crypt-OpenSSL-DSA-0.150.0 )
	ecdsa? (
		>=dev-perl/Crypt-OpenSSL-EC-1.10.0
		>=dev-perl/Crypt-OpenSSL-ECDSA-0.60.0
	)
	gost? (
		>=dev-perl/Crypt-OpenSSL-EC-1.10.0
		>=dev-perl/Crypt-OpenSSL-ECDSA-0.60.0
		>=dev-perl/Digest-GOST-0.60.0
	)
	private-key? ( >=dev-perl/Crypt-OpenSSL-Random-0.100.0 )
"
DEPEND="${RDEPEND}
	virtual/perl-ExtUtils-MakeMaker
	test? (
		>=virtual/perl-Test-Simple-0.470.0
	)
"

optdep_installed() {
	local chr=" "
	has_version "${1}" && chr="I"
	printf '[%s] %s\n' "${chr}" "${1}";
}

optdep_notice() {
	local i

	use dsa && use ecdsa && use gost && use private-key && return

	elog "This package has several modules which may require additional dependencies"
	elog "to use. However, it is up to you to install them separately if you need this"
	elog "optional functionality:"

	if ! use dsa; then
		elog " - Support for DSA signature algorithm via Net::DNS::SEC::DSA"
		elog "   $(optdep_installed ">=dev-perl/Crypt-OpenSSL-DSA-0.150.0")"
		elog
	fi
	if ! use ecdsa; then
		elog " - Support for ECDSA signatures via Net::DNS::SEC::ECDSA"
		elog "   $(optdep_installed ">=dev-perl/Crypt-OpenSSL-EC-1.10.0")"
		elog "   $(optdep_installed ">=dev-perl/Crypt-OpenSSL-ECDSA-0.60.0")"
		elog
	fi
	if ! use private-key; then
		elog " - Support for reading Private Keys in creation of Net::DNS::RR::RRSIG"
		elog "   objects"
		elog "   $(optdep_installed ">=dev-perl/Crypt-OpenSSL-Random-0.100.0")"
		elog
	fi
	if ! use gost; then
		elog " - Support for ECC-GOST signatures via Net::DNS::SEC::ECCGOST"
		elog "   $(optdep_installed ">=dev-perl/Crypt-OpenSSL-EC-1.10.0")"
		elog "   $(optdep_installed ">=dev-perl/Crypt-OpenSSL-ECDSA-0.60.0")"
		elog "   $(optdep_installed ">=dev-perl/Digest-GOST-0.60.0")"
	fi
}

src_test() {
	optdep_notice
	elog
	elog "This module will perform additional tests if these dependencies are"
	elog "pre-installed"
	perl-module_src_test
}
