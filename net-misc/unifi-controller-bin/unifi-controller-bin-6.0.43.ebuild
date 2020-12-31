# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CHECKREQS_DISK_VAR="1G"

inherit check-reqs unpacker user

#MY_HASH="635f5234a0"
#MY_DOC="372/2"

MY_P="${P/-bin}"
MY_PN="${PN/-bin}"
MY_PV="${PV/_rc}${MY_HASH:+-${MY_HASH}}"

DESCRIPTION="Ubiquiti UniFi Controller"
HOMEPAGE="https://www.ubnt.com/download/unifi/"
SRC_URI="
	http://dl.ubnt.com/unifi/${MY_PV}/unifi_sysvinit_all.deb -> unifi-${MY_PV}_sysvinit_all.deb
	tools? (
		https://dl.ubnt.com/unifi/${MY_PV}/unifi_sh_api -> unifi-${MY_PV}_api.sh
	)"
	#doc? (
	#	https://community.ui.com/ubnt/attachments/ubnt/Blog_UniFi/${MY_DOC}/UniFi-changelog-5.10.x.txt -> unifi-${MY_PV}_changelog.txt
	#)
RESTRICT="mirror"

LICENSE="GPL-3 UBNT"
SLOT="0"
KEYWORDS="aarch64 amd64 arm x86"
IUSE="nls rpi1 systemd +tools" # doc
IUSE_LINGUAS=( bg ca cs da de_DE el en es_ES fr hu id it ja ka ko mk nb nl pl pt_BR pt_PT ru sk sl sv tr uk zh_CN zh_TW )
#for lingua in "${IUSE_LINGUAS[@]}"; do
#	IUSE+=" linguas_${lingua}"
#done
#unset lingua

# debian control dependencies:
#  adduser
#  binutils
#  coreutils
#  curl
#  jsvc (>=1.0.8)
#  libcap2
#  mongodb-server (>= 2.4.10) | mongodb-10gen (>= 2.4.14) | mongodb-org-server (>= 2.6.0),
#  mongodb-server (<< 1:3.6.0) | mongodb-10gen (<< 3.6.0) | mongodb-org-server (<< 3.6.0),
#  java8-runtime-headless
#
# The version of mongodb bundled with the Mac edition is v2.4.14 at the moment,
# but currently the oldest ebuild (and only v2.x) is v2.6.12.  The default
# version is currently v3.0.14 - but this crashes with the UniFi code, possibly
# documented in https://jira.mongodb.org/browse/SERVER-22334.
#
# As a result, we'll only accept the oldest or newer versions as dependencies.
#
# Ubiquiti recommend the use of MongoDB 3.4.x.
#
# ... which is now deprecated.  However, it is widely reported that the only issue with
# MongoDB 3.6.x is that the '--nohttpinterface' option is now deprecated, and causes an
# error if used.  The Ubiquiti code, of course, hard-codes this :(
#
# Worse, even though Ubiquiti's softare worked unofficially with MongoDB 4.0, it's still
# using ancient mongodb-3.4 Java libraries to connect to mongo, and MongoDB 4.2
# is no longer compatible >:(
#
DEPEND="
	>=virtual/jre-1.8.0
	<virtual/jre-1.9.0
	>=dev-db/mongodb-3.6
	<dev-db/mongodb-4.2
	acct-group/unifi
	acct-user/unifi
"

RDEPEND="${DEPEND}"

S="${WORKDIR}"

QA_PREBUILT="
	opt/${MY_P}/lib/native/*/*/libubnt_sdnotify_jni.so
	opt/${MY_P}/lib/native/*/*/libubnt_webrtc_jni.so
"

#pkg_setup () {
	# unifi controller uses mongodb as a data-store, and mongo immediately
	# requires >3GB of space on creation of a new store, if journaling is
	# enabled.  By default, UniFi disables mongo's journal - but if you
	# override this option then bear in mind that you'll need an additional
	# 3GB(!) of space on your /var partition, or you'll need to relocate
	# /var/lib/unifi to a larger drive.
	# 500M is the bare minimum required for a single AP and a handful of
	# clients - the likelihood is that (much?) more space will be required
	# in time...
#	check-reqs_pkg_setup
#}

src_unpack () {
	local file
	for file in ${A}; do
		if [[ "${file}" == *.jar ]]; then
			cp -r "${DISTDIR}"/"${file}" "${S}"/
		elif [[ "${file}" == *.deb ]]; then
			unpack_deb "${file}" || die
		else
			cp "${DISTDIR}"/"${file}" "${WORKDIR}"/
		fi
	done
}

src_prepare () {
	local lingua='' d=''

	if [[ "${ARCH}" == "aarch64" ]]; then
		rm usr/lib/unifi/lib/native/Linux/armv7/libubnt_{webrtc,sdnotify}_jni.so || die
		rm usr/lib/unifi/lib/native/Linux/x86_64/libubnt_{webrtc,sdnotify}_jni.so || die
	elif [[ "${ARCH}" == "arm" ]]; then
		rm usr/lib/unifi/lib/native/Linux/aarch64/libubnt_{webrtc,sdnotify}_jni.so || die
		if use rpi1; then
			rm usr/lib/unifi/lib/native/Linux/armv7/libubnt_{webrtc,sdnotify}_jni.so || die
		fi
		rm usr/lib/unifi/lib/native/Linux/x86_64/libubnt_{webrtc,sdnotify}_jni.so || die
	elif [[ "${ARCH}" == "amd64" ]]; then
		rm usr/lib/unifi/lib/native/Linux/aarch64/libubnt_{webrtc,sdnotify}_jni.so || die
		rm usr/lib/unifi/lib/native/Linux/armv7/libubnt_{webrtc,sdnotify}_jni.so || die
	else # [[ "${ARCH}" == "x86" ]]
		rm usr/lib/unifi/lib/native/Linux/aarch64/libubnt_{webrtc,sdnotify}_jni.so || die
		rm usr/lib/unifi/lib/native/Linux/armv7/libubnt_{webrtc,sdnotify}_jni.so || die
		rm usr/lib/unifi/lib/native/Linux/x86_64/libubnt_{webrtc,sdnotify}_jni.so || die
	fi
	rmdir -p \
		usr/lib/unifi/lib/native/Linux/aarch64 \
		usr/lib/unifi/lib/native/Linux/armv7 \
		usr/lib/unifi/lib/native/Linux/x86_64 \
		2>/dev/null

	rm -r usr/lib/unifi/lib/native/Windows || die
	if [[ ${CHOST} == *-darwin* ]] ; then
		rm -r usr/lib/unifi/lib/native/Linux || die
	else
		rm -r usr/lib/unifi/lib/native/Mac || die
	fi
	rmdir usr/lib/unifi/lib/native 2>/dev/null

	rm -r usr/lib/unifi/{bin,conf} || die

	default

	if use nls && (( ${#IUSE_LINGUAS[@]} )); then
		local lingua=''

		# unset LINGUAS => install all languages
		# empty LINGUAS => install 'en'

		# empty but not unset...
		if [[ -n "${LINGUAS+x}" ]] && ! [[ -n "${LINGUAS:-}" ]]; then
			#LINGUAS=''
			LINGUAS='en'
			eerror "USE flag 'nls' set but no language specified in 'LINGUAS' variable - defaulting to '${LINGUAS}'"
		elif [[  -n "${LINGUAS:-}" ]]; then
			#LINUGAS="<something>"
			for lingua in ${LINGUAS}; do
				if grep -q " ${lingua} " <<<" ${IUSE_LINGUAS[*]} "; then
					lingua='found'
					break
				fi
			done
			if [[ "${lingua}" == 'found' ]]; then
				einfo "USE flag 'nls' set - keeping languages '${LINGUAS}'"
			else
				eerror "No recognised languages in 'LINGUAS' list '${LINGUAS}' - installing all language files"
				unset LINGUAS
			fi
		else # ! [[ -n "${LINGUAS+x}" ]]
			#unset LINGUAS
			:
		fi

		# not unset...
		if [[ -n "${LINGUAS:-}" ]]; then
			for lingua in ${IUSE_LINGUAS[@]}; do
				#if ! use linguas_${lingua}; then
				if ! has "${lingua}" "${LINGUAS}"; then
					for d in $( find usr/lib/unifi/webapps/ROOT/app-unifi/ -mindepth 3 -maxdepth 3 -type d -name locales ); do
						if [[ -d "${d}/${lingua//-/_}" ]]; then
							einfo "Removing locale data for language '${lingua//-/_}' from directory '$( cut -d'/' -f 7-8 <<<"${d}" )' ..."
							rm -r "${d}/${lingua//-/_}" || die
						fi
						if [[ -d "${d}/${lingua//_/-}" ]]; then
							einfo "Removing locale data for language '${lingua//_/-}' from directory '$( cut -d'/' -f 7-8 <<<"${d}" )' ..."
							rm -r "${d}/${lingua//_/-}" || die
						fi
					done
				fi
			done
		fi
	fi

	echo "CONFIG_PROTECT=\"${EPREFIX%/}/var/lib/unifi/data\"" > "${T}/90${MY_PN}"
}

src_install () {
	insinto /opt/"${MY_P}"
	# As of 6.0.41, usr/lib/unifi contains 'dl lib webapps'
	doins -r usr/lib/unifi/* || die "Installation failed"

	keepdir /var/lib/unifi/data
	keepdir /var/lib/unifi/webapp/work
	keepdir /var/log/unifi

	mkdir -p "${ED%/}"/var/run/unifi # Try to keep QA checker happy - this is created by the init script

	dosym /var/lib/unifi/data /opt/"${MY_P}"/data
	dosym /var/lib/unifi/webapp/work /opt/"${MY_P}"/work
	dosym /var/log/unifi /opt/"${MY_P}"/logs
	dosym /var/run/unifi /opt/"${MY_P}"/run

	# Fix 'mongod' invocation...
	exeinto "/opt/${MY_P}/bin"
	newexe "${FILESDIR}"/mongod.sh mongod || die "Failed to install mongod wrapper"

	if use tools; then
		exeinto "/opt/${MY_P}/bin"
		newexe "${WORKDIR}"/unifi-${MY_PV}_api.sh unifi-api.sh
	fi

	#use doc && newdoc "unifi-${MY_PV}_changelog.txt" "CHANGELOG-$(ver_cut '1-2').txt"

	insinto /var/lib/unifi/data
	doins "${FILESDIR}"/system.properties

	fowners -R unifi:unifi \
		/var/lib/unifi \
		/var/log/unifi

	newinitd "${FILESDIR}"/unifi.initd unifi ||
		die "Could not create init script"
	newconfd "${FILESDIR}"/unifi.confd unifi ||
		die "Could not create conf file"
	sed -i -e "s|%INST_DIR%|/opt/${MY_P}|g" \
		"${ED%/}"/etc/{init,conf}.d/unifi \
	|| die "Could not customise init scripts"

	doenvd "${T}/90${MY_PN}" || die "Could not configure environment"

	if use systemd; then
		sed -i -e "s|/usr/lib/unifi|${ED%/}/opt/${MY_P}|" \
			lib/systemd/system/unifi.service \
		|| die "Could not customise systemd unit file"
		systemd_dounit lib/systemd/system/unifi.service
	fi

	rmdir -p "${ED%/}"/var/run/unifi 2>/dev/null # Try to keep QA checker happy - this is created by the init script
}

pkg_postinst() {
	elog "By default, ${MY_P} uses the following ports:"
	elog
	elog "    Web Interface:         8080"
	elog "    API:                   8443"
	elog "    Portal HTTP redirect:  8880"
	elog "    Portal HTTPS redirect: 8843"
	elog "    STUN:                  3478"
	elog
	elog "... and will attempt to connect to mongodb on localhost:27117"
	elog
	elog "Additionally, ports 8881 and 8882 are reserved, and 6789 is used"
	elog "for determining throughput."
	elog
	elog "From release 5.9.x onwards, port 8883/tcp must allow outbound traffic"
	elog
	elog "All of these ports may be customised by editing"
	elog
	elog "    /opt/${MY_P}/data/system.properties"
	elog
	elog "... but please note that the file will be re-written on each"
	elog "startup/shutdown, and any changes to the comments will be lost."
	elog
	elog "These settings cannot be passed as '-D' parameters to Java,"
	elog "${MY_P} only uses values from the properties file."
	elog
	elog "If the Web Interface/Inform port is changed from the default of"
	elog "8080, then all managed devices must be updated via debug console"
	elog "with the command:"
	elog
	elog "    set-inform http://<controller IP>:<new port>/inform"
	elog
	elog "... before they will be able to reconnect."

	if has_version '>=dev-java/oracle-jdk-bin-1.8.0.151' && has_version '<dev-java/oracle-jdk-bin-1.8.0.162'; then
		elog
		ewarn "Oracle Java SDK releases 1.8.0r151 to 1.8.0r161 prevent the"
		ewarn "UniFi Guest Portal from operating correctly - please upgrade"
		ewarn "or downgrade your Java installation to avoid this issue"
	fi

	elog
	ewarn "From ${PN}-5.6.20, the default behaviour is to immediately"
	ewarn "attempt to allocate 1GB of memory on startup.  If running on a"
	ewarn "memory-constrained system, please edit:"
	ewarn
	ewarn "    /opt/${MY_P}/data/system.properties"
	ewarn
	ewarn "... in order to set appropriate Java XMS and XMX (minimum and"
	ewarn "maximum memory constraints) values"
	elog
	ewarn "UniFi Controller 5.10+ requires at least firmware 4.0.9 for"
	ewarn "UAP/USW and at least firmware 4.4.34 for USG"
}

pkg_prerm() {
	local link

	# Clean-up any remaining symlinks, which would otherwise be protected and
	# not removed...
	if [[ -z "${REPLACED_BY_VERSION:-}" || "${REPLACED_BY_VERSION}" != "${PVR}" ]]; then
		# As of 6.0.41, /var/lib/unifi contains symlinks 'data logs run work'
		for link in data logs run work; do
			[[ -L "${EPREFIX%/}"/opt/"${MY_P}"/${link} ]] &&
				rm "${EPREFIX%/}"/opt/"${MY_P}"/${link}
		done
	fi
}
