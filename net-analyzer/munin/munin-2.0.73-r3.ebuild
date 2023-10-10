# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit java-pkg-opt-2 systemd tmpfiles webapp

MY_P=${P/_/-}

DESCRIPTION="Munin Server Monitoring Tool"
HOMEPAGE="https://munin-monitoring.org/"
SRC_URI="
	https://github.com/munin-monitoring/munin/archive/${PV}.tar.gz -> ${P}.tar.gz
	"

LICENSE="GPL-2"
#SLOT="0"
KEYWORDS="amd64 arm arm64 ~ppc ~ppc64 x86"
IUSE="apache2 asterisk cgi dhcpd doc http ipmi ipv6 irc java ldap memcached minimal mysql postgres selinux ssl syslog systemd test +tmpfiles"
REQUIRED_USE="cgi? ( !minimal ) apache2? ( cgi )"
RESTRICT="!test? ( test )"

# Upstream's listing of required modules is NOT correct!
# Some of the postgres plugins use DBD::Pg, while others call psql directly.
# Some of the mysql plugins use DBD::mysql, while others call mysqladmin directly.
# We replace the original ipmi plugins with the freeipmi_ plugin which at least works.
DEPEND_COM="
	acct-user/munin
	acct-user/munin-async
	acct-group/munin
	dev-lang/perl:=[berkdb]
	dev-perl/DBI
	dev-perl/Date-Manip
	dev-perl/File-Copy-Recursive
	dev-perl/List-MoreUtils
	dev-perl/Log-Log4perl
	dev-perl/Net-CIDR
	dev-perl/Net-DNS
	dev-perl/Net-Netmask
	dev-perl/Net-SNMP
	dev-perl/Net-Server[ipv6(-)?]
	dev-perl/TimeDate
	virtual/perl-Digest-MD5
	virtual/perl-Getopt-Long
	virtual/perl-MIME-Base64
	virtual/perl-Storable
	virtual/perl-Text-Balanced
	virtual/perl-Time-HiRes
	apache2? ( www-servers/apache[apache2_modules_cgi,apache2_modules_cgid,apache2_modules_rewrite] )
	asterisk? ( dev-perl/Net-Telnet )
	cgi? (
		dev-perl/FCGI
		dev-perl/CGI-Fast
		)
	dhcpd? (
		>=net-misc/dhcp-3[server]
		dev-perl/Net-IP
		dev-perl/HTTP-Date
		)
	doc? ( dev-python/sphinx )
	http? ( dev-perl/libwww-perl )
	irc? ( dev-perl/Net-IRC )
	ldap? ( dev-perl/perl-ldap )
	kernel_linux? ( sys-process/procps )
	memcached? ( dev-perl/Cache-Memcached )
	mysql? (
		virtual/mysql
		dev-perl/Cache-Cache
		dev-perl/DBD-mysql
		)
	postgres? ( dev-perl/DBD-Pg dev-db/postgresql:* )
	ssl? ( dev-perl/Net-SSLeay )
	syslog? ( virtual/perl-Sys-Syslog )
	!minimal? (
		dev-perl/HTML-Template
		dev-perl/IO-Socket-INET6
		dev-perl/URI
		>=net-analyzer/rrdtool-1.3[graph,perl]
		virtual/ssh
		)
	"

# Keep this seperate, as previous versions have had other deps here
DEPEND="${DEPEND_COM}
	dev-perl/Module-Build
	cgi? ( || ( virtual/httpd-cgi virtual/httpd-fastcgi ) )
	java? ( >=virtual/jdk-1.8 )
	test? (
		dev-perl/Test-Deep
		dev-perl/Test-Exception
		dev-perl/Test-LongString
		dev-perl/Test-Differences
		dev-perl/Test-MockModule
		dev-perl/Test-MockObject
		dev-perl/File-Slurp
		dev-perl/IO-stringy
		dev-perl/IO-Socket-INET6
	)"
RDEPEND="${DEPEND_COM}
		app-alternatives/awk
		ipmi? ( >=sys-libs/freeipmi-1.1.6-r1 )
		java? (
			>=virtual/jre-1.8:*
			|| ( net-analyzer/netcat net-analyzer/openbsd-netcat )
		)
		!minimal? (
			virtual/cron
			media-fonts/dejavu
		)
		selinux? ( sec-policy/selinux-munin )"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	webapp_pkg_setup

	java-pkg-opt-2_pkg_setup
}

src_prepare() {
	echo "${PV}" > RELEASE || die

	eapply "${FILESDIR}"/patches/*.patch

	eapply_user

	java-pkg-opt-2_src_prepare
}

src_configure() {
	local cgidir='$(DESTDIR)/usr/libexec/munin/cgi'
	use cgi || cgidir="${T}/useless/cgi-bin"

	local cgiuser=$(usex apache2 apache munin)

	cat >> "${S}"/Makefile.config <<- EOF || die
	PREFIX=\$(DESTDIR)/usr
	CONFDIR=\$(DESTDIR)/etc/munin
	DOCDIR=${T}/useless/doc
	MANDIR=\$(PREFIX)/share/man
	LIBDIR=\$(PREFIX)/libexec/munin
	HTMLDIR=\$(DESTDIR)/var/www/localhost/htdocs/munin
	CGIDIR=${cgidir}
	CGITMPDIR=\$(DESTDIR)/var/cache/munin-cgi
	CGIUSER=${cgiuser}
	DBDIR=\$(DESTDIR)/var/lib/munin
	DBDIRNODE=\$(DESTDIR)/var/lib/munin-node
	SPOOLDIR=\$(DESTDIR)/var/spool/munin-async
	LOGDIR=\$(DESTDIR)/var/log/munin
	PERLLIB=\$(DESTDIR)$(perl -V:vendorlib | cut -d"'" -f2)
	JCVALID=$(usex java yes no)
	STATEDIR=\$(DESTDIR)/var/run/munin
	EOF
}

# parallel make and install need to be fixed before, and I haven't
# gotten around to do so yet.
src_compile() {
	emake -j1
	use doc && emake -C doc html
}

src_test() {
	if [[ ${EUID} == 0 ]]; then
		eerror "You cannot run tests as root."
		eerror "Please enable FEATURES=userpriv before proceeding."
		return 1
	fi

	local testtargets="test-common test-node test-plugins"
	use minimal || testtargets+=" test-master"

	LC_ALL=C emake -j1 ${testtargets}
}

src_install() {
	local cgiuser=$(usex apache2 apache munin)

	local dirs="
		/var/log/munin
		/var/lib/munin/plugin-state
		/etc/munin/plugin-conf.d
	"
	use minimal || dirs+=" /etc/munin/munin-conf.d/"

	webapp_src_preinst

	keepdir ${dirs}
	fowners munin:munin ${dirs}

	# parallel install doesn't work and it's also pointless to have this
	# run in parallel for now (because it uses internal loops).
	emake -j1 CHOWN=true DESTDIR="${D}" $(usex minimal "install-minimal install-man" install)

	# we remove /run and /var/cache from the install, as it's not the
	# package's to deal with.
	rm -rf "${ED}"/run "${ED}"/var/cache || die

	# remove the plugins for non-Gentoo package managers; use -f so that
	# it doesn't fail when installing on non-Linux platforms.
	rm -f "${ED}"/usr/libexec/munin/plugins/{apt{,_all},yum} ||
		die "Failed to remove non-Gentoo package-manager plugins"

	if ! use minimal; then
		dodir "${MY_HTDOCSDIR}"/{config,static,templates}
		dodir "${MY_HTDOCSDIR}"/templates/partial
		find "${ED}"/etc/munin/static/ -type f -exec mv -v {} "${ED}"/"${MY_HTDOCSDIR}"/static/ \;
		find "${ED}"/etc/munin/templates/ -type f -not -name munin-\* -exec mv -v {} "${ED}"/"${MY_HTDOCSDIR}"/templates/partial/ \;
		find "${ED}"/etc/munin/templates/ -type f -name munin-\* -exec mv -v {} "${ED}"/"${MY_HTDOCSDIR}"/templates/ \;
		dodir "${MY_HTDOCSDIR}"/config/plugins
		rmdir "${ED}"/etc/munin/templates/partial
		rmdir "${ED}"/etc/munin/{plugins,static,templates} || die "Cannot remove directories from '${ED}/etc/'"

		# remove .htaccess files
		find "${ED}" -type f -name .htaccess -delete || die "Failed to remove .htaccess files from destination '${ED}'"
		rmdir "${ED}"/var/www/localhost/htdocs/munin || die "Cannot remove '${ED}/var/www/localhost/htdocs/munin' directory"

		if use cgi; then
			dodir "${MY_CGIBINDIR}"/munin
			mv "${ED}"/usr/libexec/munin/cgi/munin-cgi-graph "${ED}"/"${MY_CGIBINDIR}"/munin/
			mv "${ED}"/usr/libexec/munin/cgi/munin-cgi-html "${ED}"/"${MY_CGIBINDIR}"/munin/
			rmdir "${ED}"/usr/libexec/munin/cgi || die "Cannot remove '${ED}/usr/libexec/munin/cgi' directory"

			keepdir /var/cache/munin-cgi
			touch "${ED}"/var/log/munin/munin-cgi-{graph,html}.log

			webapp_serverowned /var/cache/munin-cgi
			webapp_serverowned /var/log/munin/munin-cgi-{graph,html}.log
		else
			keepdir /var/cache/munin-cgi
			touch "${ED}"/var/log/munin/munin-cgi-{graph,html}.log

			fowners $(usex apache apache munin) \
				/var/cache/munin-cgi \
				/var/log/munin/munin-cgi-{graph,html}.log

		fi
	fi

	# The webapp application folder needs to be writable by the 'munin' user,
	# as *all* HTML content is auto-generated by cron.  Unfortunately,
	# webapp-config does not seem to propagate permissions on this top-level
	# directory, so the following statement appears in the hope that this will
	# change at some point in the future...
	webapp_serverowned "${MY_HTDOCSDIR}"

	# ... so we'll ensure that the correct permissions are set in a hook
	# instead!
	webapp_hook_script "${FILESDIR}"/webapp-hook-1.0.0

	webapp_src_install

	dodoc "${FILESDIR}"/lighttpd.sample

	insinto /etc/munin/plugin-conf.d/
	newins "${FILESDIR}"/${PN}-1.3.2-plugins.conf munin-node

	newinitd "${FILESDIR}"/munin-node_init.d_2.0.73 munin-node
	newconfd "${FILESDIR}"/munin-node_conf.d_1.4.6-r2 munin-node

	newinitd "${FILESDIR}"/munin-asyncd.init.2 munin-asyncd

	if use tmpfiles; then
		newtmpfiles - ${CATEGORY}:${PN}:${SLOT}.conf <<-EOF || die
			d /var/run/munin 0700 munin munin - -
			d /var/cache/munin-cgi 0755 ${cgiuser} munin - -
		EOF
	fi

	if use systemd; then
		systemd_dounit "${FILESDIR}"/munin-async.service
		systemd_dounit "${FILESDIR}"/munin-graph.{service,socket}
		systemd_dounit "${FILESDIR}"/munin-html.{service,socket}
		systemd_dounit "${FILESDIR}"/munin-node.service
	fi

	cat >> "${T}"/munin.env <<- EOF
	CONFIG_PROTECT=/var/spool/munin-async/.ssh
	EOF
	newenvd "${T}"/munin.env 50munin

	dodoc README ChangeLog INSTALL
	if use doc; then
		cd "${S}"/doc/_build/html || die
		docinto html
		dodoc -r *
		cd "${S}" || die
	fi

	dodir /etc/logrotate.d/
	sed -e "s:@CGIUSER@:$(usex apache2 apache munin):g" \
		"${FILESDIR}"/logrotate.d-munin.3 > "${ED}"/etc/logrotate.d/munin

	dosym ipmi_ /usr/libexec/munin/plugins/ipmi_sensor_

	if use syslog; then
		sed -i -e '/log_file/s| .*| Sys::Syslog|' \
			"${ED}"/etc/munin/munin-node.conf ||
				die "Adding syslog support to '/etc/munin/munin-node.conf' failed"
	fi

	# Use a simpler pid file to avoid trouble with run in tmpfs. The
	# munin-node service is run as user root, and only later drops
	# privileges.
	#sed -i -e 's:/run/munin/munin-node.pid:/run/munin-node.pid:' \
	#	"${ED}"/etc/munin/munin-node.conf ||
	#		die "Flattening PID path in '/etc/munin/munin-node.conf' failed"

	keepdir /var/spool/munin-async/.ssh
	touch "${ED}"/var/spool/munin-async/.ssh/authorized_keys
	fowners munin-async:munin /var/spool/munin-async{,/.ssh/{,authorized_keys}}
	fperms 0750 /var/spool/munin-async{,/.ssh}
	fperms 0600 /var/spool/munin-async/.ssh/authorized_keys

	if use minimal; then
		# This requires the presence of munin-update, which is part of
		# the non-minimal install...
		rm "${ED}"/usr/libexec/munin/plugins/munin_stats
	else
		# remove font files so that we don't have to keep them around
		rm "${ED}"/usr/libexec/${PN}/*.ttf ||
			die "Removing font files failed"

		if use cgi; then
			sed -i -e '/#graph_strategy cgi/s:^#::' \
				"${ED}"/etc/munin/munin.conf ||
					die "Updating graph_strategy to 'cgi' in '/etc/munin/munin-node.conf' failed"

			#touch "${D}"/var/log/munin/munin-cgi-{graph,html}.log
			#fowners ${cgiuser} \
			#	/var/log/munin/munin-cgi-{graph,html}.log

			if use apache2; then
				insinto /etc/apache2/vhosts.d
				newins "${FILESDIR}"/munin.apache.include-2.4-r1 munin-2.4.include
			fi
		else
			sed \
				-e '/#graph_strategy cgi/s:#graph_strategy cgi:graph_strategy cron:' \
				-i "${ED}"/etc/munin/munin.conf ||
					die "Updating graph_strategy to 'cron' in '/etc/munin/munin-node.conf' failed"
		fi

		keepdir /var/lib/munin/.ssh
		cat >> "${ED}"/var/lib/munin/.ssh/config <<- EOF
		IdentityFile /var/lib/munin/.ssh/id_ecdsa
		IdentityFile /var/lib/munin/.ssh/id_rsa
		EOF

		fowners munin:munin /var/lib/munin/.ssh/{,config}
		fperms go-rwx /var/lib/munin/.ssh/{,config}

		insinto "/usr/share/${PN}"
		doins "${FILESDIR}"/"${PN}-crontab"
		doins "${FILESDIR}"/"${PN}-fcrontab"

		# remove .htaccess file
		#find "${D}" -name .htaccess -delete || die
	fi
}

pkg_config() {
	if use minimal; then
		einfo "Nothing to do."
		return 0
	fi

	einfo "Press enter to install the default crontab for the munin master"
	einfo "installation from /usr/share/${PN}/f?crontab"
	einfo "If you have a large site, you may wish to customize it."
	read

	ebegin "Setting up cron ..."
	if has_version sys-process/fcron; then
		fcrontab - -u munin < /usr/share/${PN}/fcrontab
	else
		# dcron is very fussy about syntax
		# the following is the only form that works in BOTH dcron and vixie-cron
		crontab - -u munin < /usr/share/${PN}/crontab
	fi
	eend $?

	einfo "Press enter to set up the SSH keys used for SSH transport"
	read

	# generate one rsa (for legacy) and one ecdsa (for new systems)
	ssh-keygen -t rsa \
		-f /var/lib/munin/.ssh/id_rsa -N '' \
		-C "created by portage for ${CATEGORY}/${PN}" || die
	ssh-keygen -t ecdsa \
		-f /var/lib/munin/.ssh/id_ecdsa -N '' \
		-C "created by portage for ${CATEGORY}/${PN}" || die
	chown -R munin:munin /var/lib/munin/.ssh || die
	chmod 0600 /var/lib/munin/.ssh/id_{rsa,ecdsa} || die

	einfo "Your public keys are available in "
	einfo "  /var/lib/munin/.ssh/id_rsa.pub"
	einfo "  /var/lib/munin/.ssh/id_ecdsa.pub"
	einfo "and follows for convenience"
	echo
	cat /var/lib/munin/.ssh/id_*.pub
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process "${CATEGORY}:${PN}:${SLOT}.conf"

	elog "Please follow the munin documentation to set up the plugins you"
	elog "need, afterwards start munin-node."
	elog ""
	elog "To make use of munin-async, make sure to set up the corresponding"
	elog "SSH key in /var/lib/munin-async/.ssh/authorized_keys"
	elog ""
	if ! use minimal; then
		elog "Please run"
		elog "  emerge --config net-analyzer/munin"
		elog "to automatically configure munin's cronjobs as well as generate"
		elog "passwordless SSH keys to be used with munin-async."
	fi
	elog ""
	elog "Further information about setting up Munin in Gentoo can be found"
	elog "in the Gentoo Wiki: https://wiki.gentoo.org/wiki/Munin"

	if use cgi; then
		#chown $(usex apache2 apache munin) \
		#	"${ROOT}"/var/log/munin/munin-cgi-{graph,html}.log

		if use apache2; then
			elog "To use Munin with CGI you should include"
			elog "/etc/apache2/vhosts.d/munin-2.4.include from the virtual"
			elog "host you want it to be served."
			elog "If you want to enable CGI-based HTML as well, you have to add to"
			elog "/etc/conf.d/apache2 the option -D MUNIN_HTML_CGI."
		else
			elog "Effective CGI support has just been added in 2.0.7-r6."
			elog "Documentation on how to use it is still sparse."
		fi
	fi

	# we create this here as we don't want Portage to check /run
	# symlinks but we still need this to be present before the reboot.
	if ! use minimal; then
		if [[ -d "${ROOT}"/run ]]; then
			if ! [[ -d "${ROOT}"/run/munin ]]; then
				mkdir "${ROOT}"/run/munin
				chown munin:munin "${ROOT}"/run/munin
				chmod 0700 "${ROOT}"/run/munin
			fi
		elif [[ -d "${ROOT}"/var/run ]]; then
			if ! [[ -d "${ROOT}"/var/run/munin ]]; then
				mkdir "${ROOT}"/var/run/munin
				chown munin:munin "${ROOT}"/var/run/munin
				chmod 0700 "${ROOT}"/var/run/munin
			fi
		fi
	fi
}

# vi: set diffopt=iwhite,filler:
