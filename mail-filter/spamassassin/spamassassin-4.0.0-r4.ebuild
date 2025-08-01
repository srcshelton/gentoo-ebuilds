# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools perl-functions systemd toolchain-funcs verify-sig

MY_P="Mail-SpamAssassin-${PV//_/-}"
DESCRIPTION="An extensible mail filter which can identify and tag spam"
HOMEPAGE="https://spamassassin.apache.org/"
SRC_URI="mirror://apache/spamassassin/source/${MY_P}.tar.bz2
	verify-sig? (
		https://downloads.apache.org/spamassassin/source/${MY_P}.tar.bz2.asc
	)
"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0 GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~hppa ~loong ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="+berkdb cron dkim dmarc extracttext geoip idn ipv6 largenet ldap mysql office pacct postgres qmail razor +sa-update spf sqlite ssl systemd test unicode"
RESTRICT="!test? ( test )"

# The Makefile.PL script checks for dependencies, but only fails if a
# required (i.e. not optional) dependency is missing. We therefore
# require most of the optional modules only at runtime.
PERL_BUILD_DEPEND="
	dev-perl/HTML-Parser
	dev-perl/Net-DNS
	dev-perl/NetAddr-IP
	virtual/perl-Digest-SHA
"

# SpamAssassin doesn't use libwww-perl except as a fallback for when
# curl/wget are missing, so we depend on one of those instead. Some
# mirrors use https, so we need those utilities to support SSL.
#
# re2c is needed to compile the rules (sa-compile).
#
# We still need the old Digest-SHA1 because razor2 has not been ported
# to Digest-SHA.
PERL_RUN_DEPEND="
	dev-perl/Email-Address-XS
	dev-perl/Net-CIDR-Lite
	dev-perl/Pod-Parser
	virtual/perl-MIME-Base64

	berkdb? (
		dev-perl/BerkeleyDB
		dev-perl/DBI
		virtual/perl-DB_File
	)
	dkim? ( dev-perl/Mail-DKIM )
	dmarc? ( dev-perl/Mail-DMARC )
	geoip? (
	|| ( dev-perl/GeoIP2 dev-perl/Geo-IP )
		dev-perl/IP-Country-DB_File
		|| ( dev-perl/MaxMind-DB-Reader-XS dev-perl/MaxMind-DB-Reader )
	)
	idn? ( dev-perl/Net-LibIDN2 )
	ipv6? ( dev-perl/IO-Socket-INET6 )
	largenet? ( dev-perl/Net-Patricia )
	ldap? ( dev-perl/perl-ldap )
	mysql? (
		dev-perl/DBI
		dev-perl/DBD-mysql
	)
	office? (
		dev-perl/Archive-Zip
		dev-perl/IO-String
	)
	pacct? ( dev-perl/BSD-Resource )
	postgres? (
		dev-perl/DBI
		dev-perl/DBD-Pg
	)
	razor? (
		mail-filter/razor
		dev-perl/Digest-SHA1
	)
	sa-update? (
		app-crypt/gnupg
		dev-perl/HTTP-Date
		dev-perl/libwww-perl
		dev-util/re2c
		www-client/fetch
		|| ( net-misc/wget[ssl] net-misc/curl[ssl] dev-perl/libwww-perl[ssl] )
	)
	spf? ( dev-perl/Mail-SPF )
	sqlite? (
		dev-perl/DBI
		dev-perl/DBD-SQLite
	)
	ssl? ( dev-perl/IO-Socket-SSL )
	unicode? ( dev-perl/Encode-Detect )
"

DEPEND="ssl? ( dev-libs/openssl:0= )"
EXTRACTTEXT_DEPEND="extracttext? ( app-text/poppler app-text/tesseract )"
BDEPEND="${PERL_BUILD_DEPEND}
	dev-lang/perl:=
	|| ( >dev-build/autoconf-2.71-r5 <sys-devel/gcc-13 )
	verify-sig? ( sec-keys/openpgp-keys-spamassassin )
	test? (
		${PERL_RUN_DEPEND}
		${EXTRACTTEXT_DEPEND}
		dev-perl/Devel-Cycle
		dev-perl/Test-Perl-Critic
		dev-perl/Test-Pod
		dev-perl/Text-Diff
		virtual/perl-Test-Harness
	)
"
RDEPEND="${PERL_BUILD_DEPEND}
	${PERL_RUN_DEPEND}
	${DEPEND}
	${EXTRACTTEXT_DEPEND}
	dev-lang/perl:=
	acct-group/spamd
	acct-user/spamd
"

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/spamassassin.apache.org.asc

PATCHES=(
	"${FILESDIR}/mention-geoip.cf-in-init.pre.patch"
	"${FILESDIR}/4.0.0-tests-dnsbl_subtests.t_001_load-URIDNSBL.patch"
	"${FILESDIR}/4.0.0-tests-dnsbl_subtests.t_002_no-net.patch"
	"${FILESDIR}/4.0.0-tests-strip2.t.patch"
	"${FILESDIR}/4.0.0-DnsResolver-udpsize.patch"
	"${FILESDIR}/4.0.0-sa-update-rdatastr.patch"
)

# There are a few renames and use-dependent ones in src_install as well.
DOCS=(
	NOTICE TRADEMARK CREDITS UPGRADE USAGE sql/README.bayes
	sql/README.awl procmailrc.example sample-nonspam.txt
	sample-spam.txt spamd/PROTOCOL spamd/README.vpopmail
	spamd-apache2/README.apache
)

src_prepare() {
	default

	# The sa_compile test does some weird stuff like hopping around in
	# the directory tree and calling "make" to create a dist tarball
	# from ${S}. It fails, and is more trouble than it's worth...
	perl_rm_files t/sa_compile.t || die 'failed to remove sa_compile test'

	# The spamc tests (which need the networked spamd daemon) fail for
	# irrelevant reasons. It's too hard to disable them (unlike the
	# spamd tests themselves -- see src_test), so use a crude
	# workaround.
	perl_rm_files t/spamc_*.t || die 'failed to remove spamc tests'

	# Some tests need extra dependencies
	# e.g. t/sql_based_whitelist.t needs DBD
	# This is kinder than REQUIRED_USE for tests which hurts automation
	if ! use mysql && ! use postgres && ! use sqlite ; then
		perl_rm_files t/sql_based_whitelist.t ||
			die 'failed to remove tests with extra dependencies'
	fi

	# Disable plugin by default
	sed -i -e 's/^loadplugin/\#loadplugin/g' \
		"rules/init.pre" \
		|| die "failed to disable plugins by default"
}

src_configure() {
	# This is how and where the perl-module eclass disables the
	# MakeMaker interactive prompt.
	export PERL_MM_USE_DEFAULT=1

	# Set SYSCONFDIR explicitly so we can't get bitten by bug 48205 again
	# (just to be sure, nobody knows how it could happen in the first place).
	#
	# We also set the path to the perl executable explictly. This will be
	# used to create the initial shebang line in the scripts (bug 62276).
	perl Makefile.PL \
		PREFIX="${EPREFIX}/usr" \
		INSTALLDIRS=vendor \
		SYSCONFDIR="${EPREFIX}/etc" \
		DATADIR="${EPREFIX}/usr/share/spamassassin" \
		PERL_BIN="${EPREFIX}/usr/bin/perl" \
		ENABLE_SSL="$(usex ssl)" \
		DESTDIR="${D}" \
		|| die 'failed to create a Makefile using Makefile.PL'
	# 'DATADIR' is not a known MakeMaker parameter name.
	# 'ENABLE_SSL' is not a known MakeMaker parameter name.
	# 'PERL_BIN' is not a known MakeMaker parameter name.
	# 'SYSCONFDIR' is not a known MakeMaker parameter name.

	# Now configure spamc.

	# Run autoreconf to avoid some issues caused by a standard test in the
	# current autoconf.  Expected to be fixed in next autoconf release, so
	# these next 3 lines might not be needed for long.  See bug #899782.
	pushd spamc >/dev/null
	eautoreconf
	popd >/dev/null
	emake CC="$(tc-getCC)" LDFLAGS="${LDFLAGS}" spamc/Makefile
}

src_compile() {
	emake
	use qmail && emake spamc/qmail-spamc
}

src_install() {
	default

	# Create the stub dir used by sa-update and friends
	keepdir /var/lib/spamassassin

	# Move spamd to sbin where it belongs.
	dodir /usr/sbin
	mv "${ED}"/usr/bin/spamd "${ED}"/usr/sbin/spamd  || die "move spamd failed"

	if use qmail; then
		dobin spamc/qmail-spamc
	fi

	dosym mail/spamassassin /etc/spamassassin

	# Add the init and config scripts.
	newinitd "${FILESDIR}/3.4.1-spamd.init-r3" spamd
	newconfd "${FILESDIR}/3.4.1-spamd.conf-r1" spamd

	if use systemd; then
		systemd_newunit "${FILESDIR}/${PN}.service-r4" "${PN}.service"
		systemd_install_serviced "${FILESDIR}/${PN}.service.conf-r2" \
			"${PN}.service"
	fi

	use postgres && dodoc sql/*_pg.sql
	use mysql && dodoc sql/*_mysql.sql
	use qmail && dodoc spamc/README.qmail

	# Rename some files so that they don't clash with others.
	newdoc spamd/README README.spamd
	newdoc sql/README README.sql
	newdoc ldap/README README.ldap

	insinto /etc/mail/spamassassin/
	newins "${FILESDIR}"/geoip-4.0.0.cf geoip.cf
	insopts -m0400
	newins "${FILESDIR}"/secrets.cf secrets.cf.example

	# Create the directory where sa-update stores its GPG key (if you
	# choose to import one). If this directory does not exist, the
	# import will fail. This is bug 396307. We expect that the import
	# will be performed as root, and making the directory accessible
	# only to root prevents a warning on the command-line.
	diropts -m0700
	dodir /etc/mail/spamassassin/sa-update-keys

	if use cron; then
		# Install the cron job if they want it.
		exeinto /etc/cron.daily
		newexe "${FILESDIR}/update-spamassassin-rules-r1.cron" \
			   update-spamassassin-rules
	fi

	# Remove perllocal.pod to avoid file collisions (bug #603338).
	perl_delete_localpod || die "failed to remove perllocal.pod"

	# The perl-module eclass calls three other functions to clean
	# up in src_install. The first fixes references to ${D} in the
	# packlist, and is useful to us, too. The other two functions,
	# perl_delete_emptybsdir and perl_remove_temppath, don't seem
	# to be needed: there are no empty directories, *.bs files, or
	# ${D} paths remaining in our installed image.
	perl_fix_packlist || die "failed to fix paths in packlist"
}

src_test() {
	# Trick the test suite into skipping the spamd tests. Setting
	# SPAMD_HOST to a non-localhost value causes SKIP_SPAMD_TESTS to be
	# set in SATest.pm.
	export SPAMD_HOST=disabled
	default
}

pkg_preinst() {
	if use mysql || use postgres ; then
		local _awlwarn=0
		local _v
		for _v in ${REPLACING_VERSIONS}; do
			if ver_test "${_v}" -lt "3.4.3"; then
				_awlwarn=1
				break
			fi
		done
		if [[ ${_awlwarn} == 1 ]] ; then
			ewarn 'If you used AWL before 3.4.3, the SQL schema has changed.'
			ewarn 'You will need to manually ALTER your tables for them to'
			ewarn 'continue working.  See the UPGRADE documentation for'
			ewarn 'details.'
			ewarn
		fi
	fi
}

pkg_postinst() {
	elog
	elog 'No rules are installed by default. You will need to run sa-update'
	elog 'at least once, and most likely configure SpamAssassin before it'
	elog 'will work.'

	if ! use cron; then
		elog
		elog 'You should consider a cron job for sa-update. One is provided'
		elog 'for daily updates if you enable the "cron" USE flag.'
	fi
	elog
	elog 'Configuration and update help can be found on the wiki:'
	elog
	elog '  https://wiki.gentoo.org/wiki/SpamAssassin'
	elog

	if use mysql || use postgres ; then
		local _v
		for _v in ${REPLACING_VERSIONS}; do
			if ver_test "${_v}" -lt "3.4.3"; then
				ewarn
				ewarn 'If you used AWL before 3.4.3, the SQL schema has changed.'
				ewarn 'You will need to manually ALTER your tables for them to'
				ewarn 'continue working.  See the UPGRADE documentation for'
				ewarn 'details.'
				ewarn

				# show this only once
				break
			fi
		done
	fi

	ewarn 'If this version of SpamAssassin causes permissions issues'
	ewarn 'with your user configurations or bayes databases, then you'
	ewarn 'may need to set SPAMD_RUN_AS_ROOT=true in your OpenRC service'
	ewarn 'configuration file, or remove the --username and --groupname'
	ewarn 'flags from the SPAMD_OPTS variable in your systemd service'
	ewarn 'configuration file.'

	if [[ ! ~spamd -ef "${ROOT}/var/lib/spamd" ]] ; then
		ewarn "The spamd user's home folder has been moved to a new location."
		elog
		elog "The acct-user/spamd package should have relocated it for you,"
		elog "but may have failed because your spamd daemon was running."
		elog
		elog "To fix this:"
		elog " - Stop your spamd daemon"
		elog " - emerge -1 acct-user/spamd"
		elog " - Restart your spamd daemon"
		elog " - Remove the old home folder if you want"
		elog "     rm -rf \"${ROOT}/home/spamd\""
	fi
	if [[ -e "${ROOT}/home/spamd" ]] ; then
		ewarn
		ewarn "The spamd user's home folder has been moved to a new location."
		elog
		elog "  Old Home: ${ROOT}/home/spamd"
		elog "  New Home: ${ROOT}/var/lib/spamd"
		elog
		elog "You may wish to migrate your data to the new location:"
		elog " - Stop your spamd daemon"
		elog " - Re-emerge acct-user/spamd to ensure the home folder has been"
		elog "   updated to the new location, now that the daemon isn't running:"
		elog "     # emerge -1 acct-user/spamd"
		elog "     # echo ~spamd"
		elog " - Migrate the contents from the old location to the new home"
		elog "   For example:"
		elog "     # cp -Rpi \"${ROOT}/home/spamd/\" \"${ROOT}/var/lib/\""
		elog " - Remove the old home folder"
		elog "     # rm -rf \"${ROOT}/home/spamd\""
		elog " - Restart your spamd daemon"
		elog
		elog "If you do not wish to migrate data, you should remove the old"
		elog "home folder from your system as it is not used."
	fi
}

# vi: set diffopt=iwhite,filler:
