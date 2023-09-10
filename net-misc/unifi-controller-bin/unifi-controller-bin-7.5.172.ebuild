# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
CHECKREQS_DISK_VAR="1G"

inherit check-reqs plocale unpacker

MY_HASH="39991973d0"
#MY_DOC="372/2"

MY_P="${P/-bin}"
MY_PN="${PN/-bin}"
MY_PV="${PV/_rc}${MY_HASH:+-${MY_HASH}}"

DESCRIPTION="Ubiquiti UniFi Controller"
HOMEPAGE="https://www.ubnt.com/download/unifi/"
SRC_URI="
	https://dl.ui.com/unifi/${MY_PV}/unifi_sysvinit_all.deb -> unifi-${PV}_sysvinit_all.deb
	tools? (
		https://dl.ubnt.com/unifi/${MY_PV}/unifi_sh_api -> unifi-${PV}_api.sh
	)"
	#doc? (
	#	https://community.ui.com/ubnt/attachments/ubnt/Blog_UniFi/${MY_DOC}/UniFi-changelog-5.10.x.txt -> unifi-${MY_PV}_changelog.txt
	#)
RESTRICT="mirror"

LICENSE="GPL-3 UBNT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
PLOCALES="ar_SA bg ca cs da de_DE el en es_ES es_MX fr hu id it ja ja_JP ka ko mk nb nl pl pt_BR pt_PT ru ru_RU sk sl sv tr uk zh_hans zh_hant zh_CN zh_TW"
PLOCALE_BACKUP="en"
IUSE="systemd +tools $( for l in ${PLOCALES}; do echo "l10n_${l/_/-}"; done )" # doc

# debian control dependencies:
#  Package: unifi
#  Version: 7.5.172-22697-1
#  Section: java
#  Priority: optional
#  Architecture: all
#  Depends: adduser, binutils, coreutils, curl, libcap2, logrotate,
#   mongodb-server (>= 1:3.6.0) | mongodb-10gen (>= 3.6.0) | mongodb-org-server (>= 3.6.0),
#   mongodb-server (<< 1:5.0.0) | mongodb-10gen (<< 5.0.0) | mongodb-org-server (<< 5.0.0),
#   openjdk-17-jre-headless
#
DEPEND="
	acct-group/unifi
	acct-user/unifi
"

RDEPEND="
	${DEPEND}
	<dev-db/mongodb-5
	sys-libs/libcap
	virtual/jre:17
"

S="${WORKDIR}"

QA_PREBUILT="
	opt/${MY_P}/lib/native/*/*/libubnt_sdnotify_jni.so
	opt/${MY_P}/lib/native/*/*/libubnt_webrtc_jni.so
"

#pkg_setup() {
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

src_unpack() {
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

src_prepare_process_lingua() {
	local lingua="${*:-}"
	local d=''

	[[ -n "${lingua:-}" ]] || return 1

	for d in $( find usr/lib/unifi/webapps/ROOT/app-unifi/ -mindepth 3 -maxdepth 3 -type d -name locales ); do
		if [[ -d "${d}/${lingua//-/_}" ]]; then
			einfo "Removing locale data for language '${lingua//-/_}' from directory '$( cut -d'/' -f 7-8 <<<"${d}" )' ..."
			rm -r "${d}/${lingua//-/_}" || return 1
		fi
		if [[ -d "${d}/${lingua//_/-}" ]]; then
			einfo "Removing locale data for language '${lingua//_/-}' from directory '$( cut -d'/' -f 7-8 <<<"${d}" )' ..."
			rm -r "${d}/${lingua//_/-}" || return 1
		fi
	done

	return 0
}

src_prepare() {
	local lingua='' d=''

	if [[ "${ARCH}" == "arm64" ]]; then
		if ! use systemd; then
			rm usr/lib/unifi/lib/native/Linux/aarch64/libubnt_sdnotify_jni.so
		fi
		rm usr/lib/unifi/lib/native/Linux/x86_64/libubnt_{webrtc,sdnotify}_jni.so || die
	elif [[ "${ARCH}" == "amd64" ]]; then
		rm usr/lib/unifi/lib/native/Linux/aarch64/libubnt_{webrtc,sdnotify}_jni.so || die
		if ! use systemd; then
			rm usr/lib/unifi/lib/native/Linux/x86_64/libubnt_sdnotify_jni.so
		fi
	fi
	rmdir -p \
		usr/lib/unifi/lib/native/Linux/aarch64 \
		usr/lib/unifi/lib/native/Linux/x86_64 \
		2>/dev/null

	rm -r usr/lib/unifi/{bin,conf} || die

	default

	# The l10n eclass compares the locales defined in the string-variable
	# LINGUAS to those defined in PLOCALES, enabling all values if LINGUAS is
	# unset... which seems strange to me, as it makes the LINGUAS variable
	# rather than the active package USE flags the point of control.  We can
	# work around that, but I'm mystified as to why we have to?
	#
	einfo "Processing locales ..."
	local linguas l=''
	local -i found=0
	if [[ -n "${LINGUAS+set}" ]]; then
		linguas="${LINGUAS:-}"
	fi
	LINGUAS=""
	for l in ${PLOCALES//_/-}; do
		if use "l10n_${l}"; then
			LINGUAS="${LINGUAS:+${LINGUAS} }${l}"
			found=1
		fi
	done
	if ! (( found )); then
		if [[ -n "${PLOCALE_BACKUP+set}" ]]; then
			LINGUAS="${PLOCALE_BACKUP}"
		else
			unset LINGUAS
		fi
	fi
	plocale_for_each_disabled_locale src_prepare_process_lingua || die
	unset LINGUAS
	if [[ -n "${linguas+set}" ]]; then
		LINGUAS="${linguas:-}"
	fi

	echo "CONFIG_PROTECT=\"${EPREFIX%/}/var/lib/unifi/data\"" > "${T}/90${MY_PN}"
}

src_install() {
	local l=''

	insinto /opt/"${MY_P}"
	# As of 6.4.54, usr/lib/unifi contains 'bin conf dl lib webapps'; 'conf' is
	# empty, 'bin' contains 'ubnt-apttool' (both removed above):
	doins -r usr/lib/unifi/* || die "Installation failed"

	keepdir /var/lib/unifi/data
	keepdir /var/lib/unifi/webapp/work
	keepdir /var/log/unifi

	mkdir -p "${ED%/}"/var/run/unifi  # Try to keep QA checker happy - this is created by the init script

	dosym /var/lib/unifi/data /opt/"${MY_P}"/data
	dosym /var/lib/unifi/webapp/work /opt/"${MY_P}"/work
	dosym /var/log/unifi /opt/"${MY_P}"/logs
	dosym /var/run/unifi /opt/"${MY_P}"/run

	# Fix 'mongod' invocation...
	exeinto "/opt/${MY_P}/bin"
	newexe "${FILESDIR}"/mongod.sh mongod || die "Failed to install mongod wrapper"

	if use tools; then
		exeinto "/opt/${MY_P}/bin"
		newexe "${WORKDIR}"/unifi-${PV}_api.sh unifi-api.sh
	fi

	#use doc && newdoc "unifi-${MY_PV}_changelog.txt" "CHANGELOG-$(ver_cut '1-2').txt"

	insinto /var/lib/unifi/data
	doins "${FILESDIR}"/system.properties

	fowners -R unifi:unifi \
		/var/lib/unifi \
		/var/log/unifi

	for l in $( ls "${ED}"/opt/"${MY_P}"/lib/native/*/*/libubnt_*.so 2>/dev/null ); do
		fperms 755 "${l#${ED}}"
	done

	newinitd "${FILESDIR}"/unifi.initd unifi ||
		die "Could not create init script"
	newconfd "${FILESDIR}"/unifi.confd unifi ||
		die "Could not create conf file"
	sed -i -e "s|%INST_DIR%|/opt/${MY_P}|g" \
			"${ED%/}"/etc/{init,conf}.d/unifi ||
		die "Could not customise init scripts"

	doenvd "${T}/90${MY_PN}" || die "Could not configure environment"

	if use systemd; then
		sed -i -e "s|/usr/lib/unifi|${ED%/}/opt/${MY_P}|" \
				lib/systemd/system/unifi.service ||
			die "Could not customise systemd unit file"
		systemd_dounit lib/systemd/system/unifi.service
	fi

	rmdir -p "${ED%/}"/var/run/unifi 2>/dev/null  # Try to keep QA checker happy - this is created by the init script
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
