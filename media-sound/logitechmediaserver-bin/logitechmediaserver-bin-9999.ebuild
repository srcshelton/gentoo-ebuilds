# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

MY_PN="${PN/-bin}"

if [[ ${PV} == *_pre* ]] ; then
	GIT_COMMIT="c17601c5892eaac40a359d1392e454ad5c69db9d"
	SRC_URI="https://github.com/Logitech/slimserver/archive/${GIT_COMMIT}.zip"
	HOMEPAGE="http://github.com/Logitech/slimserver"
	S="${WORKDIR}/slimserver-${GIT_COMMIT}"
	INHERIT_VCS=""
	KEYWORDS="~amd64 ~x86"
elif [[ ${PV} == "9999" ]] ; then
	EGIT_BRANCH="public/7.9"
	EGIT_REPO_URI="https://github.com/Logitech/slimserver.git"
	HOMEPAGE="http://github.com/Logitech/slimserver"
	S="${WORKDIR}/slimserver"
	INHERIT_VCS="git-r3"
	KEYWORDS="~amd64 ~x86"
else
	SRC_DIR="LogitechMediaServer_v${PV}"
	SRC_URI="http://downloads.slimdevices.com/${SRC_DIR}/${MY_P}.tgz"
	HOMEPAGE="http://www.mysqueezebox.com/download"
	BUILD_NUM="1375965195"
	MY_PV="${PV/_*}"
	MY_P_BUILD_NUM="${MY_PN}-${MY_PV}-${BUILD_NUM}"
	MY_P="${MY_PN}-${MY_PV}"
	S="${WORKDIR}/${MY_P_BUILD_NUM}"
	INHERIT_VCS=""
	KEYWORDS="~amd64 ~x86"
fi

inherit ${INHERIT_VCS} eutils user systemd

DESCRIPTION="Server for Logitech Squeezebox players"
LICENSE="${PN}"
RESTRICT="mirror"
SLOT="0"
IUSE="doc html systemd"

LANGS="de en es fr he it nl"
for lang in ${LANGS}; do
    IUSE+=" l10n_${lang}"
done
unset lang

# Installation dependencies.
DEPEND="
	!media-sound/squeezecenter
	!media-sound/squeezeboxserver
	app-arch/unzip
	"

# Runtime dependencies.
RDEPEND="
	!prefix? ( >=sys-apps/baselayout-2.0.0 )
	!prefix? ( virtual/logger )
	>=dev-lang/perl-5.10.0[ithreads]
	x86? ( <dev-lang/perl-5.23[ithreads] )
	amd64? ( <dev-lang/perl-5.23[ithreads] )
	>=dev-perl/Data-UUID-1.202
	"

# This is a binary package and contains prebuilt executable and library
# files. We need to identify those to suppress the QA warnings during
# installation.
QA_PREBUILT="
*
"

RUN_UID=logitechmediaserver
RUN_GID=logitechmediaserver

# Installation locations
OPTDIR="/opt/${MY_PN}"
VARDIR="/var/lib/${MY_PN}"
CACHEDIR="${VARDIR}/cache"
USRPLUGINSDIR="${VARDIR}/Plugins"
SVRPLUGINSDIR="${CACHEDIR}/InstalledPlugins"
CLIENTPLAYLISTSDIR="${VARDIR}/ClientPlaylists"
PREFSDIR="/etc/${MY_PN}"
LOGDIR="/var/log/${MY_PN}"
SVRPREFS="${PREFSDIR}/server.prefs"

# Old Squeezebox Server file locations
SBS_PREFSDIR='/etc/squeezeboxserver/prefs'
SBS_SVRPREFS="${SBS_PREFSDIR}/server.prefs"
SBS_VARLIBDIR='/var/lib/squeezeboxserver'
SBS_SVRPLUGINSDIR="${SBS_VARLIBDIR}/cache/InstalledPlugins"
SBS_USRPLUGINSDIR="${SBS_VARLIBDIR}/Plugins"

pkg_setup() {
	# Create the user and group if not already present
	enewgroup ${RUN_GID}
	enewuser ${RUN_UID} -1 -1 "/dev/null" ${RUN_GID}
}

src_prepare() {
	# Apply patches to make LMS work on Gentoo.
	epatch "${FILESDIR}/${P}-uuid-gentoo.patch"
	epatch "${FILESDIR}/${P}-client-playlists-gentoo.patch"
}

src_install() {
	local pv lang

	# The custom OS module for Gentoo - provides OS-specific path details
	cp "${FILESDIR}/gentoo-filepaths.pm" "Slim/Utils/OS/Custom.pm" || die "Unable to install Gentoo custom OS module"

	# We're only keywording for amd64 and x86...
	#
	# Bin: armhf-linux arm-linux darwin i386-freebsd-64int i386-linux MSWin32-x86-multi-thread powerpc-linux sparc-linux x86_64-linux
	# CPAN/arch/*: arm-linux-gnueabihf-thread-multi-64int arm-linux-gnueabi-thread-multi-64int i386-linux-thread-multi i386-linux-thread-multi-64int MSWin32-x86-multi-thread powerpc-linux-thread-multi-64int x86_64-linux-thread-multi darwin-thread-multi-2level i386-freebsd-64int sparc-linux
	# CPAN/arch: 5.10 5.12 5.14 5.16 5.18 5.20 5.22 5.8
	if use amd64; then
		rm -r "${S}"/Bin/{armhf-linux,arm-linux,darwin,i386-freebsd-64int,i386-linux,MSWin32-x86-multi-thread,powerpc-linux,sparc-linux}
		rm -r "${S}"/CPAN/arch/*/{arm-linux-gnueabihf-thread-multi-64int,arm-linux-gnueabi-thread-multi-64int,i386-linux-thread-multi,i386-linux-thread-multi-64int,MSWin32-x86-multi-thread,powerpc-linux-thread-multi-64int,darwin-thread-multi-2level,i386-freebsd-64int,sparc-linux} 2>/dev/null
		#for pv in 5.8 5.10 5.12 5.14 5.16 5.18 5.20 5.22; do
		for pv in $( ls -1 CPAN/arch/ ); do
			if ! has_version "dev-lang/perl:0/${pv}"; then
				rm -r CPAN/arch/"${pv}"
			fi
		done
	fi
	# Some files are incorrectly marked as being executable...
	chmod 644 Firmware/*.{bin,version}
	chmod 644 \
		CPAN/DBI/Format/SQLMinus.pm \
		CPAN/DBI/Shell/*.pm \
		CPAN/DBI/Shell.pm \
		CPAN/Log/Log4perl/Layout/PatternLayout/Multiline.pm \
		CPAN/Net/UPnP/{AV,GW}/*.pm \
		CPAN/Net/UPnP/*.pm \
		CPAN/Net/UPnP.pm \
		HTML/Default/html/images/*.png \
		HTML/EN/html/ext/resources/images/default/form/*.gif \
		HTML/EN/html/images/*.png \
		HTML/EN/html/images/ServiceProviders/*.png \
		Slim/Plugin/Favorites/HTML/EN/html/images/*.png \
		Slim/Plugin/InternetRadio/HTML/EN/plugins/TuneIn/html/images/*.png \
		Slim/Plugin/JiveExtras/HTML/EN/plugins/JiveExtras/settings/*.html \
		Slim/Plugin/Live365/HTML/EN/plugins/Live365/html/images/icon.png \
		Slim/Plugin/MP3tunes/HTML/EN/plugins/MP3tunes/html/images/icon.png \
		Slim/Plugin/Pandora/HTML/EN/plugins/Pandora/html/images/icon.png \
		Slim/Plugin/Podcast/HTML/EN/plugins/Podcast/html/images/icon.png \
		Slim/Plugin/RandomPlay/HTML/EN/plugins/RandomPlay/html/images/icon.png \
		Slim/Plugin/Slacker/HTML/EN/plugins/Slacker/html/images/icon.png

	# Documentation
	for lang in ${LANGS}; do
		if ! use "l10n_${lang}"; then
			if [[ 'en' == "${lang}" ]]; then
				lang=''
			else
				lang+='.'
			fi
			if [[ -e "License.${lang}txt" ]]; then
				rm "License.${lang}txt"
			fi
		fi
	done
	
	use html && dohtml Changelog*.html
	if use doc; then
		dodoc Installation.txt
		dodoc License*.txt
	fi
	rm Changelog*.html
	rm Installation.txt
	rm License*.txt

	# Everthing into our package in the /opt hierarchy (LHS)
	dodir "${OPTDIR}"
	cp -aR "${S}"/* "${ED}${OPTDIR}" || die "Unable to install package files"

	dodoc "${FILESDIR}/Gentoo-plugins-README.txt"
	dodoc "${FILESDIR}/Gentoo-detailed-changelog.txt"

	# Preferences directory
	dodir "${PREFSDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${PREFSDIR}"
	fperms 770 "${PREFSDIR}"

	# Install init scripts (OpenRC)
	newconfd "${FILESDIR}/logitechmediaserver.conf.d" "${MY_PN}"
	newinitd "${FILESDIR}/logitechmediaserver.init.d" "${MY_PN}"

	# Install unit file (systemd)
	use systemd && systemd_dounit "${FILESDIR}/${MY_PN}.service"

	# Initialize server cache directory
	dodir "${CACHEDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${CACHEDIR}"
	fperms 770 "${CACHEDIR}"

	# Initialize the log directory
	dodir "${LOGDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}"
	fperms 770 "${LOGDIR}"
	touch "${ED}/${LOGDIR}/server.log"
	touch "${ED}/${LOGDIR}/scanner.log"
	touch "${ED}/${LOGDIR}/perfmon.log"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}/server.log"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}/scanner.log"
	fowners ${RUN_UID}:${RUN_GID} "${LOGDIR}/perfmon.log"

	# Initialise the user-installed plugins directory
	dodir "${USRPLUGINSDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${USRPLUGINSDIR}"
	fperms 770 "${USRPLUGINSDIR}"

	# Initialise the client playlists directory
	dodir "${CLIENTPLAYLISTSDIR}"
	fowners ${RUN_UID}:${RUN_GID} "${CLIENTPLAYLISTSDIR}"
	fperms 770 "${CLIENTPLAYLISTSDIR}"

	# Install logrotate support
	insinto /etc/logrotate.d
	newins "${FILESDIR}/logitechmediaserver.logrotate.d" "${MY_PN}"
}

lms_starting_instr() {
	elog "Logitech Media Server can be started with the following command (OpenRC):"
	elog "\t/etc/init.d/logitechmediaserver start"
	if use systemd; then
		elog "or (systemd):"
		elog "\tsystemctl start logitechmediaserver"
	fi
	elog ""
	elog "Logitech Media Server can be automatically started on each boot"
	elog "with the following command (OpenRC):"
	elog "\trc-update add logitechmediaserver default"
	if use systemd; then
		elog "or (systemd):"
		elog "\tsystemctl enable logitechmediaserver"
	fi
	elog ""
	elog "You might want to examine and modify the following configuration"
	elog "file before starting Logitech Media Server:"
	elog "\t/etc/conf.d/logitechmediaserver"
	elog ""

	# Discover the port number from the preferences, but if it isn't there
	# then report the standard one.
	httpport=$(gawk '$1 == "httpport:" { print $2 }' "${ROOT}${SVRPREFS}" 2>/dev/null)
	elog "You may access and configure Logitech Media Server by browsing to:"
	elog "\thttp://localhost:${httpport:-9000}/"
	elog ""
}

pkg_postinst() {
	# Point user to database configuration step, if an old installation
	# of SBS is found.
	if [ -f "${SBS_SVRPREFS}" ]; then
		elog "If this is a new installation of Logitech Media Server and you"
		elog "previously used Squeezebox Server (media-sound/squeezeboxserver)"
		elog "then you may migrate your previous preferences and plugins by"
		elog "running the following command (note that this will overwrite any"
		elog "current preferences and plugins):"
		elog "\temerge --config =${CATEGORY}/${PF}"
		elog ""
	fi

	# Tell use user where they should put any manually-installed plugins.
	elog "Manually installed plugins should be placed in the following"
	elog "directory:"
	elog "\t${USRPLUGINSDIR}"
	elog ""

	# Show some instructions on starting and accessing the server.
	lms_starting_instr
}

lms_remove_db_prefs() {
	MY_PREFS=$1

	einfo "Correcting database connection configuration:"
	einfo "\t${MY_PREFS}"
	TMPPREFS="${T}"/lmsserver-prefs-$$
	touch "${EROOT}${MY_PREFS}"
	sed -e '/^dbusername:/d' -e '/^dbpassword:/d' -e '/^dbsource:/d' < "${EROOT}${MY_PREFS}" > "${TMPPREFS}"
	mv "${TMPPREFS}" "${EROOT}${MY_PREFS}"
	chown ${RUN_UID}:${RUN_GID} "${EROOT}${MY_PREFS}"
	chmod 660 "${EROOT}${MY_PREFS}"
}

pkg_config() {
	einfo "Press ENTER to migrate any preferences from a previous installation of"
	einfo "Squeezebox Server (media-sound/squeezeboxserver) to this installation"
	einfo "of Logitech Media Server."
	einfo ""
	einfo "Note that this will remove any current preferences and plugins and"
	einfo "therefore you should take a backup if you wish to preseve any files"
	einfo "from this current Logitech Media Server installation."
	einfo ""
	einfo "Alternatively, press Control-C to abort now..."
	read

	# Preferences.
	einfo "Migrating previous Squeezebox Server configuration:"
	if [ -f "${SBS_SVRPREFS}" ]; then
		[ -d "${EROOT}${PREFSDIR}" ] && rm -rf "${EROOT}${PREFSDIR}"
		einfo "\tPreferences (${SBS_PREFSDIR})"
		cp -r "${EROOT}${SBS_PREFSDIR}" "${EROOT}${PREFSDIR}"
		chown -R ${RUN_UID}:${RUN_GID} "${EROOT}${PREFSDIR}"
		chmod -R u+w,g+w "${EROOT}${PREFSDIR}"
		chmod 770 "${EROOT}${PREFSDIR}"
	fi

	# Plugins installed through the built-in extension manager.
	if [ -d "${EROOT}${SBS_SVRPLUGINSDIR}" ]; then
		einfo "\tServer plugins (${SBS_SVRPLUGINSDIR})"
		[ -d "${EROOT}${SVRPLUGINSDIR}" ] && rm -rf "${EROOT}${SVRPLUGINSDIR}"
		cp -r "${EROOT}${SBS_SVRPLUGINSDIR}" "${EROOT}${SVRPLUGINSDIR}"
		chown -R ${RUN_UID}:${RUN_GID} "${EROOT}${SVRPLUGINSDIR}"
		chmod -R u+w,g+w "${EROOT}${SVRPLUGINSDIR}"
		chmod 770 "${EROOT}${SVRPLUGINSDIR}"
	fi

	# Plugins manually installed by the user.
	if [ -d "${EROOT}${SBS_USRPLUGINSDIR}" ]; then
		einfo "\tUser plugins (${SBS_USRPLUGINSDIR})"
		[ -d "${EROOT}${USRPLUGINSDIR}" ] && rm -rf "${EROOT}${USRPLUGINSDIR}"
		cp -r "${EROOT}${SBS_USRPLUGINSDIR}" "${EROOT}${USRPLUGINSDIR}"
		chown -R ${RUN_UID}:${RUN_GID} "${EROOT}${USRPLUGINSDIR}"
		chmod -R u+w,g+w "${EROOT}${USRPLUGINSDIR}"
		chmod 770 "${EROOT}${USRPLUGINSDIR}"
	fi

	# Remove the existing MySQL preferences from Squeezebox Server (if any).
	lms_remove_db_prefs "${SVRPREFS}"

	# Phew - all done. Give some tips on what to do now.
	einfo "Done."
	einfo ""
}
