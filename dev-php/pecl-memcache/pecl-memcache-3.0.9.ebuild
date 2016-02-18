# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: cdf98be4f8db8bed22b1227abe253a3b185bf222 $

EAPI="5"

GITHUB_USERNAME="websupport-sk"
GITHUB_PROJECT="${PN}"
GITHUB_COMMIT="fdbd46bbc6f53ed6e024521895e142cbfc9b3340"

PHP_EXT_PECL_PKG="${PN#pecl-}"
MY_PV="${PV/_}"
PECL_PKG="${PHP_EXT_PECL_PKG}"
PECL_PKG_V="${PHP_EXT_PECL_PKG}-${MY_PV}"

S="${WORKDIR}/${PN}-${GITHUB_COMMIT}"

#FILENAME="${PHP_EXT_PECL_PKG}.zip"
FILENAME="${P#pecl-}.zip"
SRC_URI="https://codeload.github.com/${GITHUB_USERNAME}/${GITHUB_PROJECT}/zip/${GITHUB_COMMIT} -> ${P#pecl-}.zip"
HOMEPAGE="https://github.com/${GITHUB_USERNAME}/${GITHUB_PROJECT}"

PHP_EXT_NAME="memcache"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"
DOCS="README"

USE_PHP="php7-0 php5-6 php5-5 php5-4"

#inherit php-ext-pecl-r2
#inherit php-ext-source-r2
inherit flag-o-matic autotools multilib eutils

KEYWORDS="amd64 hppa ppc64 x86"

DESCRIPTION="PHP extension for using memcached"

LICENSE="PHP-3"
SLOT="0"
IUSE="+session"

DEPEND="sys-libs/zlib
		dev-lang/php:*[session?]"
RDEPEND="${DEPEND}"
DEPEND="${DEPEND}
		>=sys-devel/m4-1.4.3
		>=sys-devel/libtool-1.5.18"

# The test suite requires memcached to be running.
RESTRICT='mirror test'

[[ -z "${PHP_EXT_S}" ]] && PHP_EXT_S="${S}"

#Make sure at least one target is installed.
REQUIRED_USE="${PHP_EXT_OPTIONAL_USE}${PHP_EXT_OPTIONAL_USE:+? ( }|| ( "
for target in ${USE_PHP}; do
	IUSE="${IUSE} php_targets_${target}"
	target=${target/+}
	REQUIRED_USE+="php_targets_${target} "
	slot=${target/php}
	slot=${slot/-/.}
	PHPDEPEND="${PHPDEPEND}
	php_targets_${target}? ( dev-lang/php:${slot} )"
done
REQUIRED_USE+=") ${PHP_EXT_OPTIONAL_USE:+ )}"

RDEPEND="${RDEPEND}
	${PHP_EXT_OPTIONAL_USE}${PHP_EXT_OPTIONAL_USE:+? ( }
	${PHPDEPEND}
	${PHP_EXT_OPTIONAL_USE:+ )}"

DEPEND="${DEPEND}
	${PHP_EXT_OPTIONAL_USE}${PHP_EXT_OPTIONAL_USE:+? ( }
	${PHPDEPEND}
	${PHP_EXT_OPTIONAL_USE:+ )}
"

phpize() {
	if [[ "${PHP_EXT_SKIP_PHPIZE}" != 'yes' ]] ; then
		# Create configure out of config.m4. We use autotools_run_tool
		# to avoid some warnings about WANT_AUTOCONF and
		# WANT_AUTOMAKE (see bugs #329071 and #549268).
		autotools_run_tool ${PHPIZE}
		# force run of libtoolize and regeneration of related autotools
		# files (bug 220519)
		rm aclocal.m4
		eautoreconf
	fi
}

php_get_slots() {
	local s slot
	for slot in ${USE_PHP}; do
		use php_targets_${slot} && s+=" ${slot/-/.}"
	done
	echo $s
}

php_init_slot_env() {
	libdir=$(get_libdir)

	PHPIZE="${EPREFIX}/usr/${libdir}/${1}/bin/phpize"
	PHPCONFIG="${EPREFIX}/usr/${libdir}/${1}/bin/php-config"
	PHPCLI="${EPREFIX}/usr/${libdir}/${1}/bin/php"
	PHPCGI="${EPREFIX}/usr/${libdir}/${1}/bin/php-cgi"
	PHP_PKG="$(best_version =dev-lang/php-${1:3}*)"
	PHPPREFIX="${EPREFIX}/usr/${libdir}/${slot}"
	EXT_DIR="$(${PHPCONFIG} --extension-dir 2>/dev/null)"
	PHP_CURRENTSLOT=${1:3}

	PHP_EXT_S="${WORKDIR}/${1}"
	cd "${PHP_EXT_S}"
}

buildinilist() {
	# Work out the list of <ext>.ini files to edit/add to
	if [[ -z "${PHPSAPILIST}" ]] ; then
		PHPSAPILIST="apache2 cli cgi fpm embed phpdbg"
	fi

	PHPINIFILELIST=""
	local x
	for x in ${PHPSAPILIST} ; do
		if [[ -f "${EPREFIX}/etc/php/${x}-${1}/php.ini" ]] ; then
			PHPINIFILELIST="${PHPINIFILELIST} etc/php/${x}-${1}/ext/${PHP_EXT_NAME}.ini"
		fi
	done
	PHPFULLINIFILELIST="${PHPFULLINIFILELIST} ${PHPINIFILELIST}"
}

addtoinifile() {
	local inifile="${WORKDIR}/${3}"
	if [[ ! -d $(dirname ${inifile}) ]] ; then
		mkdir -p $(dirname ${inifile})
	fi

	# Are we adding the name of a section?
	if [[ ${1:0:1} == "[" ]] ; then
		echo "${1}" >> "${inifile}"
		my_added="${1}"
	else
		echo "${1}=${2}" >> "${inifile}"
		my_added="${1}=${2}"
	fi

	if [[ -z "${4}" ]] ; then
		einfo "Added '${my_added}' to /${3}"
	else
		einfo "${4} to /${3}"
	fi

	insinto /$(dirname ${3})
	doins "${inifile}"
}

addextension() {
	if [[ "${PHP_EXT_ZENDEXT}" = "yes" ]] ; then
		# We need the full path for ZendEngine extensions
		# and we need to check for debugging enabled!
		if has_version "dev-lang/php:${PHP_CURRENTSLOT}[threads]" ; then
			if has_version "dev-lang/php:${PHP_CURRENTSLOT}[debug]" ; then
				ext_type="zend_extension_debug_ts"
			else
				ext_type="zend_extension_ts"
			fi
			ext_file="${EXT_DIR}/${1}"
		else
			if has_version "dev-lang/php:${PHP_CURRENTSLOT}[debug]"; then
				ext_type="zend_extension_debug"
			else
				ext_type="zend_extension"
			fi
			ext_file="${EXT_DIR}/${1}"
		fi

		# php-5.3 unifies zend_extension loading and just requires the
		# zend_extension keyword with no suffix
		# TODO: drop previous code and this check once <php-5.3 support is
		# discontinued
		if has_version '>=dev-lang/php-5.3' ; then
			ext_type="zend_extension"
		fi
	else
		# We don't need the full path for normal extensions!
		ext_type="extension"
		ext_file="${1}"
	fi

	addtoinifile "${ext_type}" "${ext_file}" "${2}" "Extension added"
}

createinifiles() {
	local slot
	for slot in $(php_get_slots); do
		php_init_slot_env ${slot}
		# Pull in the PHP settings

		# Build the list of <ext>.ini files to edit/add to
		buildinilist ${slot}


		# Add the needed lines to the <ext>.ini files
		local file
		if [[ "${PHP_EXT_INI}" = "yes" ]] ; then
			for file in ${PHPINIFILELIST}; do
				addextension "${PHP_EXT_NAME}.so" "${file}"
			done
		fi

		# Symlink the <ext>.ini files from ext/ to ext-active/
		local inifile
		for inifile in ${PHPINIFILELIST} ; do
			if [[ -n "${PHP_EXT_INIFILE}" ]]; then
				cat "${FILESDIR}/${PHP_EXT_INIFILE}" >> "${ED}/${inifile}"
				einfo "Added content of ${FILESDIR}/${PHP_EXT_INIFILE} to ${inifile}"
			fi
			inidir="${inifile/${PHP_EXT_NAME}.ini/}"
			inidir="${inidir/ext/ext-active}"
			dodir "/${inidir}"
			dosym "/${inifile}" "/${inifile/ext/ext-active}"
		done

		# Add support for installing PHP files into a version dependant directory
		PHP_EXT_SHARED_DIR="${EPREFIX}/usr/share/php/${PHP_EXT_NAME}"
	done
}

addtoinifiles() {
	local x
	for x in ${PHPFULLINIFILELIST} ; do
		addtoinifile "${1}" "${2}" "${x}" "${3}"
	done
}

src_unpack() {
	unpack ${A}
	local slot orig_s="${PHP_EXT_S}"
	for slot in $(php_get_slots); do
		cp -r "${orig_s}" "${WORKDIR}/${slot}" || die "Failed to copy source ${orig_s} to PHP target directory"
	done
}

src_prepare() {
	local slot orig_s="${PHP_EXT_S}"
	for slot in $(php_get_slots); do
		php_init_slot_env ${slot}
		phpize
	done
}

src_configure() {
	my_conf="--enable-memcache --with-zlib-dir=/usr $(use_enable session memcache-session)"

	# net-snmp creates this file #385403
	addpredict /usr/share/snmp/mibs/.index
	local varlib="/var/lib"
	if [[ -L "${varlib}" ]]; then
		varlib="$( readlink -e "${varlib}" )"
	fi
	addpredict "${varlib}"/net-snmp/mib_indexes
	unset varlib

	local slot
	for slot in $(php_get_slots); do
		php_init_slot_env ${slot}
		# Set the correct config options
		econf --with-php-config=${PHPCONFIG} ${my_conf}  || die "Unable to configure code to compile"
	done
}

src_compile() {
	# net-snmp creates this file #324739
	addpredict /usr/share/snmp/mibs/.index
	local varlib="/var/lib"
	if [[ -L "${varlib}" ]]; then
		varlib="$( readlink -e "${varlib}" )"
	fi
	addpredict "${varlib}"/net-snmp/mib_indexes
	unset varlib

	# shm extension createss a semaphore file #173574
	addpredict /session_mm_cli0.sem
	local slot
	for slot in $(php_get_slots); do
		php_init_slot_env ${slot}
		emake || die "Unable to make code"

	done
}

src_install() {
	local slot
	for slot in $(php_get_slots); do
		php_init_slot_env ${slot}

		# Let's put the default module away. Strip $EPREFIX from
		# $EXT_DIR before calling newins (which handles EPREFIX itself).
		insinto "${EXT_DIR#$EPREFIX}"
		newins "modules/${PHP_EXT_NAME}.so" "${PHP_EXT_NAME}.so" || die "Unable to install extension"

		local doc
		for doc in ${DOCS} ; do
			[[ -s ${doc} ]] && dodoc ${doc}
		done

		INSTALL_ROOT="${D}" emake install-headers
	done
	createinifiles

	for doc in ${DOCS} "${WORKDIR}"/package.xml CREDITS ; do
		[[ -s ${doc} ]] && dodoc ${doc}
	done

	if has examples ${IUSE} && use examples ; then
		insinto /usr/share/doc/${CATEGORY}/${PF}/examples
		doins -r examples/*
	fi

	addtoinifiles "memcache.allow_failover" "true"
	addtoinifiles "memcache.max_failover_attempts" "20"
	addtoinifiles "memcache.chunk_size" "32768"
	addtoinifiles "memcache.default_port" "11211"
	addtoinifiles "memcache.hash_strategy" "consistent"
	addtoinifiles "memcache.hash_function" "crc32"
	addtoinifiles "memcache.redundancy" "1"
	addtoinifiles "memcache.session_redundancy" "2"
	addtoinifiles "memcache.protocol" "ascii"
}

src_test() {
	for slot in `php_get_slots`; do
		php_init_slot_env ${slot}
		NO_INTERACTION="yes" emake test || die "emake test failed for slot ${slot}"
	done
}
