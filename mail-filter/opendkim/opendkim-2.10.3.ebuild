# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: f0d9a69a613ef20e34a8beab9386eca8ae2a7ac6 $

EAPI=5
inherit autotools db-use eutils systemd user

# for betas
#MY_P=${P/_b/.B}
#S=${WORKDIR}/${PN}-2.8.0
#SRC_URI="mirror://sourceforge/opendkim/${MY_P}.tar.gz"

DESCRIPTION="A milter-based application to provide DKIM signing and verification"
HOMEPAGE="http://opendkim.org"
SRC_URI="mirror://sourceforge/opendkim/${P}.tar.gz"

LICENSE="Sendmail-Open-Source BSD"
SLOT="0"
KEYWORDS="amd64 ~arm x86"
IUSE="+berkdb diffheaders erlang experimental gnutls ldap libevent lmdb lua -memcached opendbx poll sasl selinux static-libs unbound"

DEPEND="|| ( mail-filter/libmilter mail-mta/sendmail )
	dev-libs/libbsd
	berkdb? ( >=sys-libs/db-3.2:* )
	diffheaders? ( dev-libs/tre )
	erlang? ( dev-lang/erlang )
	experimental? ( dev-libs/jansson net-analyzer/rrdtool net-misc/curl )
	gnutls? ( >=net-libs/gnutls-2.11.7 )
	!gnutls? ( >=dev-libs/openssl-0.9.8:* )
	ldap? ( net-nds/openldap )
	lmdb? ( dev-db/lmdb )
	lua? ( dev-lang/lua:* )
	memcached? ( dev-libs/libmemcached )
	opendbx? ( >=dev-db/opendbx-1.4.0 )
	sasl? ( dev-libs/cyrus-sasl )
	unbound? ( >=net-dns/unbound-1.4.1 net-dns/dnssec-root libevent? ( dev-libs/libevent ) )
	!unbound? ( net-libs/ldns )"

RDEPEND="${DEPEND}
	sys-process/psmisc
	selinux? ( sec-policy/selinux-dkim )
"

REQUIRED_USE="sasl? ( ldap )"

pkg_setup() {
	enewgroup milter
	# mail-milter/spamass-milter creates milter user with this home directory
	# For consistency reasons, milter user must be created here with this home directory
	# even though this package doesn't need a home directory for this user (#280571)
	enewuser milter -1 -1 /var/lib/milter milter

	if use libevent && ! use unbound; then
		ewarn "USE='libevent' requires USE='unbound' - libevent support will not be built"
	fi
	if use memcached; then
		ewarn "memcached support in ${PN} is thought to be unstable"
	fi
}

src_prepare() {
	sed -i -e 's:/var/db/dkim:/etc/opendkim:g' \
	       -e 's:/var/db/opendkim:/var/lib/opendkim:g' \
	       -e 's:/etc/mail:/etc/opendkim:g' \
	       -e 's:mailnull:milter:g' \
	       -e 's:^#[[:space:]]*PidFile.*:PidFile /var/run/opendkim/opendkim.pid:' \
		   opendkim/opendkim.conf.sample opendkim/opendkim.conf.simple.in \
		   stats/opendkim-reportstats{,.in} || die

	sed -i -e 's:dist_doc_DATA:dist_html_DATA:' libopendkim/docs/Makefile.am \
		|| die

	sed -i -e '/sock.*mt.getcwd/s:mt.getcwd():"/tmp":' opendkim/tests/*.lua
	sed -i -e '/sock.*mt.getcwd/s:mt.getcwd():"/proc/self/cwd":' opendkim/tests/*.lua

	epatch "${FILESDIR}"/"${PN}"-2.9.2-safekeys.patch || die

	einfo "Using libdir '$(get_libdir)' ..."
	sed -i -r \
	       -e "/\/lib/s#/lib([: \"/]|$)#/$(get_libdir)\1#" \
		   configure.ac || die

	eautoreconf
}

src_configure() {
	local myconf

	# Not featured:
	# --enable-socketdb						arbitrary socket data sets
	# --enable-postgresql_reconnect_hack	hack to overcome PostgreSQL connection error detection bug

	if use berkdb; then
		# Not a bug, myconf is redefined based on its own contents...
		myconf="$(db_includedir)"
		myconf="--with-db-incdir=${myconf#-I}"

		myconf+=" --enable-popauth"
		myconf+=" --enable-query_cache"
		myconf+=" --enable-stats"
		myconf+=" $(use_enable lua statsext)"
	fi
	if use experimental; then
		#myconf+=" --enable-atps" # Despite being experimental, included as standard below...
		myconf+=" $(use_enable opendbx db_handle_pools)"

		myconf+=" --with-librrd"
		myconf+=" --enable-reprrd"

		myconf+=" --with-curl"
		myconf+=" --with-jansson"
		myconf+=" --enable-reputation"
	fi
	if use ldap; then
		#myconf+=" --enable-ldap_caching" # - Prevents LDAP changes from being immediately seen
		myconf+=" $(use_with sasl)"
	fi
	if use unbound; then
		myconf+=" --with-unbound"
		if use libevent; then
			myconf+=" --with-libevent"
		fi
	else
		myconf+=" --with-ldns"
	fi
	econf \
		${myconf} \
		--docdir=/usr/share/doc/${PF} \
		--htmldir=/usr/share/doc/${PF}/html \
		--libdir=/usr/$(get_libdir) \
		--enable-atps \
		--enable-default_sender \
		$(use_enable diffheaders) \
		--enable-filter \
		--enable-identity_header \
		$(use_enable poll) \
		--enable-rate_limit \
		$(use_enable lua rbl) \
		--enable-replace_rules \
		--enable-resign \
		--enable-sender_macro \
		$(use_enable static-libs static) \
		--enable-vbr \
		--disable-live-testing \
		$(use_with berkdb db) \
		$(use_with erlang) \
		$(use_with gnutls) \
		$(use_with memcached libmemcached) \
		$(use_with lmdb) \
		$(use_with lua) \
		$(use_with opendbx odbx) \
		$(use_with ldap openldap) \
		$(use_with diffheaders tre)
		#--with-test-socket=/tmp/opendkim-$(echo ${RANDOM})-S
		#--disable-rpath
}

src_install() {
	emake DESTDIR="${D}" install

	dosbin stats/opendkim-reportstats

	newinitd "${FILESDIR}/opendkim.init.r3" opendkim
	systemd_dounit "${FILESDIR}/opendkim.service"

	dodir /etc/opendkim /var/lib/opendkim
	fowners milter:milter /var/lib/opendkim

	# default configuration
	if [ ! -f "${ROOT}"/etc/opendkim/opendkim.conf ]; then
		grep ^[^#] "${S}"/opendkim/opendkim.conf.simple \
			> "${D}"/etc/opendkim/opendkim.conf
		if use unbound; then
			echo TrustAnchorFile /etc/dnssec/root-anchors.txt >> "${D}"/etc/opendkim/opendkim.conf
		fi
		echo UserID milter >> "${D}"/etc/opendkim/opendkim.conf
		if use berkdb; then
			echo Statistics /var/lib/opendkim/stats.dat >> \
				"${D}"/etc/opendkim/opendkim.conf
		fi
	fi

	use static-libs || find "${D}" -name "*.la" -delete
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSION} ]]; then
		elog "If you want to sign your mail messages and need some help"
		elog "please run:"
		elog "  emerge --config ${CATEGORY}/${PN}"
		elog "It will help you create your key and give you hints on how"
		elog "to configure your DNS and MTA."

		ewarn "Make sure your MTA has r/w access to the socket file."
		ewarn "This can be done either by setting UMask to 002 and adding MTA's user"
		ewarn "to milter group or you can simply set UMask to 000."
	fi
}

pkg_config() {
	local selector keysize pubkey

	read -p "Enter the selector name (default ${HOSTNAME}): " selector
	[[ -n "${selector}" ]] || selector=${HOSTNAME}
	if [[ -z "${selector}" ]]; then
		eerror "Oddly enough, you don't have a HOSTNAME."
		return 1
	fi
	if [[ -f "${ROOT}"etc/opendkim/${selector}.private ]]; then
		ewarn "The private key for this selector already exists."
	else
		keysize=1024
		# generate the private and public keys
		opendkim-genkey -b ${keysize} -D "${ROOT}"etc/opendkim/ \
			-s ${selector} -d '(your domain)' && \
			chown milter:milter \
			"${ROOT}"etc/opendkim/"${selector}".private || \
				{ eerror "Failed to create private and public keys." ; return 1; }
		chmod go-r "${ROOT}"etc/opendkim/"${selector}".private
	fi

	# opendkim selector configuration
	echo
	einfo "Make sure you have the following settings in your /etc/opendkim/opendkim.conf:"
	einfo "  Keyfile /etc/opendkim/${selector}.private"
	einfo "  Selector ${selector}"

	# MTA configuration
	echo
	einfo "If you are using Postfix, add following lines to your main.cf:"
	einfo "  smtpd_milters     = unix:/var/run/opendkim/opendkim.sock"
	einfo "  non_smtpd_milters = unix:/var/run/opendkim/opendkim.sock"
	einfo "  and read http://www.postfix.org/MILTER_README.html"

	# DNS configuration
	einfo "After you configured your MTA, publish your key by adding this TXT record to your domain:"
	cat "${ROOT}"etc/opendkim/${selector}.txt
	einfo "t=y signifies you only test the DKIM on your domain. See following page for the complete list of tags:"
	einfo "  http://www.dkim.org/specs/rfc4871-dkimbase.html#key-text"
}
