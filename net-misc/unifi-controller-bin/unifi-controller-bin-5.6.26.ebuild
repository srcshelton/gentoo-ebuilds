# Distributed under the terms of the GNU General Public License v2

EAPI=6
CHECKREQS_DISK_VAR="500M"

inherit check-reqs unpacker user

MY_P="${P/-bin}"
MY_PN="${PN/-bin}"
MY_PV="${PV/_rc}"

DESCRIPTION="Ubiquiti UniFi Controller"
HOMEPAGE="https://www.ubnt.com/download/unifi/"
SRC_URI="
	http://dl.ubnt.com/unifi/${MY_PV}/unifi_sysvinit_all.deb -> unifi-${MY_PV}_sysvinit_all.deb
	tools? (
		https://dl.ubnt.com/unifi/${MY_PV}/unifi_sh_api -> unifi-${MY_PV}_api.sh
	)"
RESTRICT="mirror"

LICENSE="GPL-3 UBNT-20170717"
SLOT="0"
KEYWORDS="amd64 arm x86"
IUSE="nls rpi1 systemd +tools"
UNIFI_LINGUAS=( ca cs da de_DE el en es_ES nl pl pt_PT sv tr zh_CN )
IUSE+=" ${UNIFI_LINGUAS[@]/#/linguas_}"

# debian control dependencies:
#  binutils
#  coreutils
#  jsvc
#  mongodb-server (>=2.4.10) | mongodb-10gen (>=2.4.14) | mongodb-org-server (>=2.6.0)
#  openjdk-7-jre-headless | java8-runtime-headless

# The version of mongodb bundled with the Mac edition is v2.4.14 at the moment,
# but currently the oldest ebuild (and only v2.x) is v2.6.12.  The default
# version is currently v3.0.14 - but this crashes with the UniFi code, possibly
# documented in https://jira.mongodb.org/browse/SERVER-22334.
# As a result, we'll only accept the oldest or newer versions as dependencies.
DEPEND="
	|| (
		~dev-db/mongodb-2.6.12
		>=dev-db/mongodb-3.2
	)
	>=virtual/jre-1.7.0
"
RDEPEND="${DEPEND}"

S="${WORKDIR}"

QA_PREBUILT="opt/${MY_P}/lib/native/*/*/libubnt_webrtc_jni.so"

pkg_setup () {
	# unifi controller uses mongodb as a data-store, and mongo immediately
	# requires >3GB of space on creation of a new store, if journaling is
	# enabled.  By default, UniFi disables mongo's journal - but if you
	# override this option then bear in mind that you'll need an additional
	# 3GB(!) of space on your /var partition, or you'll need to relocate
	# /var/lib/unifi to a larger drive.
	# 500M is the bare minimum required for a single AP and a handful of
	# clients - the likelihood is that (much?) more space will be required
	# in time...
	check-reqs_pkg_setup

	enewgroup unifi
	enewuser unifi -1 -1 /var/lib/unifi unifi
}

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
	cd "${S}"

	if [[ "${ARCH}" == "arm" ]]; then
		rm usr/lib/unifi/lib/native/Linux/x86_64/libubnt_webrtc_jni.so
		use rpi1 && rm usr/lib/unifi/lib/native/Linux/armhf/libubnt_webrtc_jni.so
	elif [[ "${ARCH}" == "amd64" ]]; then
		rm usr/lib/unifi/lib/native/Linux/armhf/libubnt_webrtc_jni.so
	else # [[ "${ARCH}" == "x86" ]]
		rm usr/lib/unifi/lib/native/Linux/x86_64/libubnt_webrtc_jni.so
		rm usr/lib/unifi/lib/native/Linux/armhf/libubnt_webrtc_jni.so
	fi
	rmdir -p usr/lib/unifi/lib/native/Linux/x86_64 usr/lib/unifi/lib/native/Linux/armhf 2>/dev/null

	rm -r usr/lib/unifi/lib/native/Windows
	if [[ ${CHOST} == *-darwin* ]] ; then
		rm -r usr/lib/unifi/lib/native/Linux
	else
		rm -r usr/lib/unifi/lib/native/Mac
	fi
	rmdir usr/lib/unifi/lib/native 2>/dev/null

	rm -r usr/lib/unifi/{bin,conf}
}

src_prepare () {
	default

	if use nls; then
		local lingua=''
		for lingua in ${UNIFI_LINGUAS[@]}; do
			if ! use linguas_${lingua}; then
				rm -r usr/lib/unifi/webapps/ROOT/app-unifi/locales/"${lingua}" || die
			fi
		done
	fi

	echo "CONFIG_PROTECT=\"${EPREFIX%/}/var/lib/unifi/data\"" > "${T}/90${MY_PN}"
}

src_install () {
	local d
	for d in conf data db logs run; do # Do we still need conf & db?
		if [[ -d usr/lib/unifi/${d} ]]; then
			rmdir usr/lib/unifi/${d} || die "Cannot remove directory 'unifi/${d}': ${?}"
		fi
	done

	insinto /opt/"${MY_P}"
	doins -r usr/lib/unifi/* || die "Installation failed"

	keepdir /var/lib/unifi/backup
	keepdir /var/lib/unifi/conf # ?
	keepdir /var/lib/unifi/data
	keepdir /var/lib/unifi/db # ?
	keepdir /var/lib/unifi/webapp/work
	keepdir /var/log/unifi

	mkdir -p "${ED%/}"/var/run/unifi # Try to keep QA checker happy - this is created by the init script

	dosym /var/lib/unifi/backup /opt/"${MY_P}"/backup
	dosym /var/lib/unifi/conf /opt/"${MY_P}"/conf
	dosym /var/lib/unifi/data /opt/"${MY_P}"/data
	dosym /var/lib/unifi/db /opt/"${MY_P}"/db
	dosym /var/lib/unifi/webapp/work /opt/"${MY_P}"/work
	dosym /var/log/unifi /opt/"${MY_P}"/logs
	dosym /var/run/unifi /opt/"${MY_P}"/run

	# <sigh>
	dodir /opt/"${MY_P}"/bin
	dosym /usr/bin/mongod /opt/"${MY_P}"/bin/mongod

	if use tools; then
		insinto /opt/"${MY_P}"/bin
		newins "${WORKDIR}"/unifi-${MY_PV}_api.sh unifi-api.sh
		fperms 755 /opt/"${MY_P}"/bin/unifi-api.sh
	fi

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
}

pkg_prerm() {
	local link

	# Clean-up any remaining symlinks, which would otherwise be protected and
	# not removed...
	if [[ -z "${REPLACED_BY_VERSION:-}" || "${REPLACED_BY_VERSION}" != "${PVR}" ]]; then
		for link in data logs run work; do
			[[ -L "${EPREFIX%/}"/opt/"${MY_P}"/${link} ]] &&
				rm "${EPREFIX%/}"/opt/"${MY_P}"/${link}
		done
	fi
}
