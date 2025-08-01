# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck shell=bash
# shellcheck disable=SC2155

# @ECLASS: linux-info.eclass
# @MAINTAINER:
# kernel@gentoo.org
# @AUTHOR:
# Original author: John Mylchreest <johnm@gentoo.org>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: eclass used for accessing kernel related information
# @DESCRIPTION:
# This eclass is used as a central eclass for accessing kernel
# related information for source or binary already installed.
# It is vital for linux-mod.eclass to function correctly, and is split
# out so that any ebuild behaviour "templates" are abstracted out
# using additional eclasses.
#
# "kernel config" in this file means:
# The .config of the currently installed sources is used as the first
# preference, with a fall-back to bundled config (/proc/config.gz) if
# available.
#
# Before using any of the config-handling functions in this eclass, you must
# ensure that one of the following functions has been called (in order of
# preference), otherwise you will get bugs like #364041):
# linux-info_pkg_setup
# linux-info_get_any_version
# get_version
# get_running_version

case ${EAPI} in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_LINUX_INFO_ECLASS} ]]; then
_LINUX_INFO_ECLASS=1

# A Couple of env vars are available to effect usage of this eclass
# These are as follows:

# @ECLASS_VARIABLE: CHECKCONFIG_DONOTHING
# @USER_VARIABLE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Do not error out in check_extra_config if CONFIG settings are not met.
# This is a user flag and should under _no circumstances_ be set in the ebuild.
: "${CHECKCONFIG_DONOTHING:=""}"

# @ECLASS_VARIABLE: KERNEL_DIR
# @DESCRIPTION:
# A string containing the directory of the target kernel sources. The default
# value is "/usr/src/linux"
KERNEL_DIR="${KERNEL_DIR:-${ROOT%/}/usr/src/linux}"

# @ECLASS_VARIABLE: CONFIG_CHECK
# @DEFAULT_UNSET
# @DESCRIPTION:
# A string containing a list of .config options to check for before proceeding
# with the install.
#
#   e.g.: CONFIG_CHECK="MTRR"
#
# You can also check that an option doesn't exist by
# prepending it with an exclamation mark (!).
#
#   e.g.: CONFIG_CHECK="!MTRR"
#
# To simply warn about a missing option, prepend a '~'.
# It may be combined with '!'.
#
# In general, most checks should be non-fatal. The only time fatal checks
# should be used is for building kernel modules or cases that a compile will
# fail without the option.
#
# This is to allow usage of binary kernels, and minimal systems without kernel
# sources.

# @ECLASS_VARIABLE: ERROR_<CFG>
# @DEFAULT_UNSET
# @DESCRIPTION:
# A string containing the error message to display when the check against
# CONFIG_CHECK fails. <CFG> should reference the appropriate option used in
# CONFIG_CHECK.
#
# e.g.: ERROR_MTRR="MTRR exists in the .config but shouldn't!!"
#
# CONFIG_CHECK="CFG" with ERROR_<CFG>="Error Message" will die
# CONFIG_CHECK="~CFG" with ERROR_<CFG>="Error Message" calls eerror without
#     dying
# CONFIG_CHECK="~CFG" with WARNING_<CFG>="Warning Message" calls ewarn without
#     dying

# @ECLASS_VARIABLE: KBUILD_OUTPUT
# @DEFAULT_UNSET
# @DESCRIPTION:
# A string passed on commandline, or set from the kernel makefile. It contains
# the directory which is to be used as the kernel object directory.

# There are also a couple of variables which are set by this, and shouldn't be
# set by hand. These are as follows:

# @ECLASS_VARIABLE: KERNEL_MAKEFILE
# @INTERNAL
# @DESCRIPTION:
# According to upstream documentation, by default, when make looks for the
# makefile, it tries the following names, in order: GNUmakefile, makefile and
# Makefile. Set this variable to the proper Makefile name or the eclass will
# search in this order for it.
#
# See https://www.gnu.org/software/make/manual/make.html
: "${KERNEL_MAKEFILE:=""}"

# @ECLASS_VARIABLE: KV_FULL
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's a string containing the full kernel version.
# ie: 2.6.9-gentoo-johnm-r1

# @ECLASS_VARIABLE: KV_MAJOR
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's an integer containing the kernel major version.
# ie: 2

# @ECLASS_VARIABLE: KV_MINOR
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's an integer containing the kernel minor version.
# ie: 6

# @ECLASS_VARIABLE: KV_PATCH
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's an integer containing the kernel patch version.
# ie: 9

# @ECLASS_VARIABLE: KV_EXTRA
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's a string containing the kernel EXTRAVERSION.
# ie: -gentoo

# @ECLASS_VARIABLE: KV_LOCAL
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's a string containing the kernel LOCALVERSION
# concatenation.
# ie: -johnm

# @ECLASS_VARIABLE: KV_DIR
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's a string containing the kernel source directory,
# will be null if KERNEL_DIR is invalid.

# @ECLASS_VARIABLE: KV_OUT_DIR
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# A read-only variable. It's a string containing the kernel object directory,
# will be KV_DIR unless KBUILD_OUTPUT is used. This should be used for
# referencing .config.

# @ECLASS_VARIABLE: SKIP_KERNEL_CHECK
# @USER_VARIABLE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Do not check for kernel sources or a running kernel version.
# Main use-case is for chroots.
# This is a user flag and should under _no circumstances_ be set in the ebuild.
: "${SKIP_KERNEL_CHECK:=""}"

# @ECLASS_VARIABLE: SKIP_KERNEL_BINPKG_ENV_RESET
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, do not reset the kernel environment variables when merging a package
# as a binpkg.
# Main use-case is for kernel modules, i.e. linux-mod-r1.eclass.
# This should be set before running linux-info_pkg_setup

# And to ensure all the weirdness with crosscompile
inherit toolchain-funcs

# @FUNCTION: set_arch_to_kernel
# @DESCRIPTION:
# Set the env ARCH to match what the kernel expects.
set_arch_to_kernel() { export ARCH=$(tc-arch-kernel); }

# @FUNCTION: set_arch_to_pkgmgr
# @DESCRIPTION:
# Set the env ARCH to match what the package manager expects.
set_arch_to_pkgmgr() { export ARCH=$(tc-arch); }

# @FUNCTION: qout
# @DESCRIPTION:
# qout <einfo | ewarn | eerror> is a quiet call when EBUILD_PHASE should not
# have visible output.
qout() {
	local outputmsg='' type=''
	type="${1}"
	if (( ${#} > 1 )); then
		shift
		outputmsg="${*:-}"
	fi
	case "${EBUILD_PHASE}" in
		depend)  unset outputmsg;;
		clean)   unset outputmsg;;
		preinst) unset outputmsg;;
	esac
	[[ -n "${outputmsg:-}" ]] && ${type} "${outputmsg}"
}

# @FUNCTION: qeinfo
# @DESCRIPTION:
# qeinfo is a quiet einfo call when EBUILD_PHASE should not have visible
# output.
qeinfo() { qout einfo "${@}" ; }

# @FUNCTION: qewarn
# @DESCRIPTION:
# qewarn is a quiet ewarn call when EBUILD_PHASE should not have visible
# output.
qewarn() { qout ewarn "${@}" ; }

# @FUNCTION: qeerror
# @DESCRIPTION:
# qeerror is a quiet error call when EBUILD_PHASE should not have visible
# output.
qeerror() { qout eerror "${@}" ; }

# File Functions
# ---------------------------------------

# @FUNCTION: getfilevar
# @USAGE: <variable> <configfile>
# @RETURN: the value of the variable
# @DESCRIPTION:
# It detects the value of the variable defined in the file 'configfile'. This
# is done by including the 'configfile', and printing the variable with Make.
# It WILL break if your makefile has missing dependencies!
getfilevar() {
	local basefname='' basedname=''
	local -i ERROR=0

	[[ -z "${1:-}" ]] && ERROR=1
	[[ ! -f "${2:-}" ]] && ERROR=1

	if (( ERROR )); then
		echo -e "\n"
		eerror "getfilevar requires 2 variables, with the second a valid file."
		eerror "   getfilevar <VARIABLE> <CONFIGFILE>"
	else
		basefname="$(basename "${2}")"
		basedname="$(dirname "${2}")"

		# We use nonfatal because we want the caller to take care of things
		# #373151
		# Pass need-config= to make to avoid config check in kernel Makefile.
		# Pass dot-config=0 to avoid the config check in kernels prior to 5.4.
		#
		# shellcheck disable=SC2086
		echo -e "e:\\n\\t@echo \$(${1})\\ninclude ${basefname}" | \
			nonfatal emake -C "${basedname}" --no-print-directory M="${T}" \
				KBUILD_OUTPUT='' \
			ARCH="$(tc-arch-kernel)" \
				dot-config=0 need-config='' need-compiler='' \
				-s -f - 2>/dev/null
	fi
}

# @FUNCTION: getfilevar_noexec
# @USAGE: <variable> <configfile>
# @RETURN: the value of the variable
# @DESCRIPTION:
# It detects the value of the variable defined in the file 'configfile'.
# This is done with sed matching an expression only. If the variable is
# defined, you will run into problems. See getfilevar for those cases.
getfilevar_noexec() {
	local basefname='' basedname='' mycat=''
	local -i ERROR=0
	mycat='cat'

	[[ -z "${1}" ]] && ERROR=1
	[[ ! -f "${2}" ]] && ERROR=1
	[[ "${2%.gz}" != "${2}" ]] && mycat='zcat'

	if (( ERROR )); then
		echo -e "\n"
		eerror "getfilevar_noexec requires 2 variables, with the second a valid file."
		eerror "   getfilevar_noexec <VARIABLE> <CONFIGFILE>"
	else
		${mycat} "${2}" | \
		sed -n \
		-e "/^[[:space:]]*${1}[[:space:]]*:\\?=[[:space:]]*\(.*\)\$/{
			s,^[^=]*[[:space:]]*=[[:space:]]*,,g ;
			s,[[:space:]]*\$,,g ;
			p
		}"
	fi
}

# @ECLASS_VARIABLE: _LINUX_CONFIG_EXISTS_DONE
# @INTERNAL
# @DESCRIPTION:
# This is only set if one of the linux_config_*exists functions has been
# called.  We use it for a QA warning that the check for a config has not been
# performed, as linux_chkconfig* in non-legacy mode WILL return an undefined
# value if no config is available at all.
_LINUX_CONFIG_EXISTS_DONE=

# @FUNCTION: linux_config_qa_check
# @INTERNAL
# @DESCRIPTION:
# Helper function which returns an error before the function argument is run if
# no config exists
linux_config_qa_check() {
	local f="$1"

	if [[ -z "${_LINUX_CONFIG_EXISTS_DONE}" ]]; then
		ewarn "QA: You called $f before any linux_config_exists!"
		ewarn "QA: The return value of $f will NOT guaranteed later!"
	fi

	if ! use kernel_linux; then
		die "$f called on non-Linux system, please fix the ebuild"
	fi
}

# @FUNCTION: linux_config_src_exists
# @RETURN: true or false
# @DESCRIPTION:
# It returns true if .config exists in a build directory otherwise false
linux_config_src_exists() {
	export _LINUX_CONFIG_EXISTS_DONE=1
	use kernel_linux && [[ -n ${KV_OUT_DIR} && -s ${KV_OUT_DIR}/.config ]]
}

# @FUNCTION: linux_config_bin_exists
# @RETURN: true or false
# @DESCRIPTION:
# It returns true if .config exists in /proc, otherwise false
linux_config_bin_exists() {
	export _LINUX_CONFIG_EXISTS_DONE=1
	use kernel_linux && [[ -s /proc/config.gz ]]
}

# @FUNCTION: linux_config_exists
# @RETURN: true or false
# @DESCRIPTION:
# It returns true if .config exists otherwise false
#
# This function MUST be checked before using any of the linux_chkconfig_*
# functions.
linux_config_exists() {
	linux_config_src_exists || linux_config_bin_exists
}

# @FUNCTION: linux_config_path
# @DESCRIPTION:
# Echo the name of the config file to use.  If none are found,
# then return false.
linux_config_path() {
	if linux_config_src_exists; then
		echo "${KV_OUT_DIR}/.config"
	elif linux_config_bin_exists; then
		echo "/proc/config.gz"
	else
		return 1
	fi
}

# @FUNCTION: require_configured_kernel
# @DESCRIPTION:
# This function verifies that the current kernel is configured (it checks
# against the existence of .config) otherwise it dies.
require_configured_kernel() {
	[[ -n ${SKIP_KERNEL_CHECK} ]] && return

	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	if ! linux_config_src_exists; then
		qeerror "Could not find a usable .config in the kernel source" \
			"directory."
		qeerror "Please ensure that ${KERNEL_DIR} points to a configured set" \
			"of Linux sources."
		qeerror "If you are using KBUILD_OUTPUT, please set the environment" \
			"var so that"
		qeerror "it points to the necessary object directory so that it" \
			"might find .config."
		die "Kernel not configured; no .config found in ${KV_OUT_DIR}"
	fi

	get_version || die "Unable to determine configured kernel version"
}

# @FUNCTION: linux_chkconfig_present
# @USAGE: <option>
# @RETURN: true or false
# @DESCRIPTION:
# It checks that CONFIG_<option>=y or CONFIG_<option>=m is present in the
# current kernel .config
# If linux_config_exists returns false, the results of this are UNDEFINED. You
# MUST call linux_config_exists first.
linux_chkconfig_present() {
	[[ -n ${SKIP_KERNEL_CHECK} ]] && return
	linux_config_qa_check linux_chkconfig_present
	[[ $(getfilevar_noexec "CONFIG_$1" "$(linux_config_path)") == [my] ]]
}

# @FUNCTION: linux_chkconfig_module
# @USAGE: <option>
# @RETURN: true or false
# @DESCRIPTION:
# It checks that CONFIG_<option>=m is present in the current kernel .config
# If linux_config_exists returns false, the results of this are UNDEFINED. You
# MUST call linux_config_exists first.
linux_chkconfig_module() {
	[[ -n ${SKIP_KERNEL_CHECK} ]] && return
	linux_config_qa_check linux_chkconfig_module
	[[ $(getfilevar_noexec "CONFIG_$1" "$(linux_config_path)") == m ]]
}

# @FUNCTION: linux_chkconfig_builtin
# @USAGE: <option>
# @RETURN: true or false
# @DESCRIPTION:
# It checks that CONFIG_<option>=y is present in the current kernel .config
# If linux_config_exists returns false, the results of this are UNDEFINED. You
# MUST call linux_config_exists first.
linux_chkconfig_builtin() {
	[[ -n ${SKIP_KERNEL_CHECK} ]] && return
	linux_config_qa_check linux_chkconfig_builtin
	[[ $(getfilevar_noexec "CONFIG_$1" "$(linux_config_path)") == y ]]
}

# @FUNCTION: linux_chkconfig_string
# @USAGE: <option>
# @RETURN: CONFIG_<option>
# @DESCRIPTION:
# It prints the CONFIG_<option> value of the current kernel .config (it
# requires a configured kernel).
# If linux_config_exists returns false, the results of this are UNDEFINED. You
# MUST call linux_config_exists first.
linux_chkconfig_string() {
	[[ -n ${SKIP_KERNEL_CHECK} ]] && return
	linux_config_qa_check linux_chkconfig_string
	getfilevar_noexec "CONFIG_$1" "$(linux_config_path)"
}

# Versioning Functions
# ---------------------------------------

# @FUNCTION: kernel_is
# @USAGE: [-lt -gt -le -ge -eq] <major_number> [minor_number patch_number]
# @RETURN: true or false
# @DESCRIPTION:
# It returns true when the current kernel version satisfies the comparison
# against the passed version.
# -eq is the default comparison.
#
# @CODE
# For Example where KV = 2.6.9
# kernel_is 2 4   returns false
# kernel_is 2     returns true
# kernel_is 2 6   returns true
# kernel_is 2 6 8 returns false
# kernel_is 2 6 9 returns true
# @CODE

# Note: duplicated in kernel-2.eclass
kernel_is() {
	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	# If we haven't determined the version yet, we need to.
	linux-info_get_any_version

	# Now we can continue
	local operator=''

	# Huston, we have a problem: a SKIP_KERNEL_CHECK flag has been added to
	# avoid kernel-version checks (e.g. in containers) - but the semantics of
	# kernel_is mean that the intended non-failure result is often false. We
	# therefore can't reliably fix this without adding an additional parameter
	# to specify the non-failure case, but we can guess at a mostly-safe
	# default, having looked at the usage in current ebuilds...
	local -i skip=0

	case ${1#-} in
	  lt) operator="-lt"; skip=1; shift;;
	  gt) operator="-gt"; shift;;
	  le) operator="-le"; skip=1; shift;;
	  ge) operator="-ge"; shift;;
	  eq) operator="-eq"; shift;;
	   *) operator="-eq";;
	esac
	[[ $# -gt 3 ]] &&
		die "Error in ${ECLASS}_${FUNCNAME[0]}(): too many parameters"

	[[ -n ${SKIP_KERNEL_CHECK} ]] && return ${skip}

	ver_test \
		"${KV_MAJOR:-0}.${KV_MINOR:-0}.${KV_PATCH:-0}" \
		"${operator}" \
		"${1:-${KV_MAJOR:-0}}.${2:-${KV_MINOR:-0}}.${3:-${KV_PATCH:-0}}"
}

# @ECLASS_VARIABLE: get_version_warning_done
# @INTERNAL
# @DESCRIPTION:
# Internal variable, so we know to only print the warning once.
get_version_warning_done=

# @FUNCTION: get_version
# @DESCRIPTION:
# It gets the version of the kernel inside KERNEL_DIR and populates the KV_FULL
# variable
# (if KV_FULL is already set it does nothing).
#
# The kernel version variables (KV_MAJOR, KV_MINOR, KV_PATCH, KV_EXTRA and
# KV_LOCAL) are also set.
#
# The KV_DIR is set using the KERNEL_DIR env var, the KV_OUT_DIR is set using a
# valid KBUILD_OUTPUT (in a decreasing priority list, we look for the env var,
# makefile var or the
# symlink /lib/modules/${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}/build).
get_version() {
	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	local tmplocal=''

	[[ -n "${SKIP_KERNEL_CHECK:-}" ]] && return 0

	# No need to execute this twice assuming KV_FULL is populated.
	# We can force by unsetting KV_FULL.
	[[ -n "${KV_FULL:-}" ]] && return 0

	# If we don't know KV_FULL, then we need to.
	# Make sure KV_DIR isn't set since we need to work it out via KERNEL_DIR.
	unset KV_DIR

	# KV_DIR will contain the full path to the sources directory we should use
	[[ -z "${get_version_warning_done}" ]] && \
	qeinfo "Determining the location of the kernel source code"
	[[ -d "${KERNEL_DIR}" ]] && KV_DIR="${KERNEL_DIR}"

	if [[ -z "${KV_DIR}" ]]; then
		if [[ -z "${get_version_warning_done}" ]]; then
			get_version_warning_done=1
			qewarn "Unable to find kernel sources at ${KERNEL_DIR}"
			#qeinfo "This package requires Linux sources."
			if [[ "${KERNEL_DIR}" == '/usr/src/linux' ]] ; then
				qeinfo "Please make sure that ${KERNEL_DIR} points at your" \
					"running kernel, "
				qeinfo "(or the kernel you wish to build against)."
				qeinfo "Alternatively, set the KERNEL_DIR environment" \
					"variable to the kernel sources location"
			else
				qeinfo "Please ensure that the KERNEL_DIR environment" \
					"variable points at full Linux sources of the kernel you" \
					"wish to compile against."
			fi
		fi
		return 1
	fi

	# See if the kernel dir is actually an output dir. #454294
	if [[ -z "${KBUILD_OUTPUT}" && -L "${KERNEL_DIR}/source" ]]; then
		KBUILD_OUTPUT=${KERNEL_DIR}
		KERNEL_DIR=$(readlink -f "${KERNEL_DIR}/source")
		KV_DIR=${KERNEL_DIR}
	fi

	if [[ -z "${get_version_warning_done}" ]]; then
		qeinfo "Found kernel source directory:"
		qeinfo "    ${KV_DIR}"
	fi

	kernel_get_makefile

	if [[ ! -s ${KERNEL_MAKEFILE} ]]; then
		if [[ -z "${get_version_warning_done}" ]]; then
			get_version_warning_done=1
			qeerror "Could not find a Makefile in the kernel source directory."
			qeerror "Please ensure that ${KERNEL_DIR} points to a complete" \
				"set of Linux sources"
		fi
		return 1
	fi

	# And contrary to existing functions, I feel we shouldn't trust the
	# directory name to find version information as this seems insane.
	# So we parse ${KERNEL_MAKEFILE}.
	KV_MAJOR=$(getfilevar VERSION "${KERNEL_MAKEFILE}")
	KV_MINOR=$(getfilevar PATCHLEVEL "${KERNEL_MAKEFILE}")
	KV_PATCH=$(getfilevar SUBLEVEL "${KERNEL_MAKEFILE}")
	KV_EXTRA=$(getfilevar EXTRAVERSION "${KERNEL_MAKEFILE}")

	if [[ -z "${KV_MAJOR}" || -z "${KV_MINOR}" || -z "${KV_PATCH}" ]]; then
		if [[ -z "${get_version_warning_done}" ]]; then
			get_version_warning_done=1
			qeerror "Could not detect kernel version."
			qeerror "Please ensure that ${KERNEL_DIR} points to a complete" \
				"set of Linux sources."
		fi
		return 1
	fi

	# Assume there is no local version to begin with.
	KV_FULL="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}"

	# There may be separate source and output directories. Has the user set
	# KBUILD_OUTPUT? If not, automatically fall back to finding the most
	# relevant output directory. If so, but it doesn't exist, don't fall back
	# as that's probably undesirable.
	if [[ -n "${KBUILD_OUTPUT:-}" ]]; then
		if [[ -d "${KBUILD_OUTPUT}" ]]; then
			KV_OUT_DIR=${KBUILD_OUTPUT}
		else
			die "KBUILD_OUTPUT is set to ${KBUILD_OUTPUT} but it doesn't exist"
		fi
	else
		for KV_OUT_DIR in "${SYSROOT}" "${ROOT}" ""; do
			# We cannot use the local version to find the output directory
			# because that is where it is written to.
			KV_OUT_DIR+="/lib/modules/${KV_FULL}/build"
			# build is often a symlink. This function is usually run in
			# pkg_setup as root, so fully resolve it now in case the
			# unprivileged user doesn't have permission to do it later. If we
			# don't have permission now, then this will fall back to KV_DIR
			# below, which is probably where the build symlink points to
			# anyway.
			KV_OUT_DIR=$(realpath -q -e "${KV_OUT_DIR}") && break
		done
	fi

	if [[ -d ${KV_OUT_DIR} ]]; then
		qeinfo "Found kernel object directory:"
		qeinfo "    ${KV_OUT_DIR}"
	else
		# Just use KV_DIR as a last resort.
		KV_OUT_DIR="${KV_DIR:-}"
	fi

	# Grab the kernel release from the output directory.
	# TODO: we MUST detect kernel.release being out of date, and 'return 1'
	#       from this function.
	if [[ -s "${KV_OUT_DIR}"/include/config/kernel.release ]]; then
		KV_LOCAL="$(<"${KV_OUT_DIR}"/include/config/kernel.release)"
	elif [[ -s "${KV_OUT_DIR}"/.kernelrelease ]]; then
		KV_LOCAL="$(<"${KV_OUT_DIR}"/.kernelrelease)"
	else
		KV_LOCAL=''
	fi

	# KV_LOCAL currently contains the full release; discard the first bits.
	local tmplocal="${KV_LOCAL#"${KV_FULL}"}"

	# If the updated local version was not changed, the tree is not prepared.
	# Clear out KV_LOCAL in that case.
	# TODO: this does not detect a change in the localversion part between
	# kernel.release and the value that would be generated.
	if [[ "${KV_LOCAL}" == "${tmplocal}" ]]; then
		KV_LOCAL=''
	else
		KV_LOCAL="${tmplocal}"
	fi

	# Append the local version now that we (maybe) have it.
	KV_FULL+="${KV_LOCAL}"

	qeinfo "Found sources for kernel version:"
	qeinfo "    ${KV_FULL}"

	return 0
}

# @FUNCTION: get_running_version
# @DESCRIPTION:
# It gets the version of the current running kernel and the result is the same
# as get_version() if the function can find the sources.
get_running_version() {
	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	local kv=$(uname -r)

	if [[ -f ${ROOT%/}/lib/modules/${kv}/source/Makefile ]]; then
		KERNEL_DIR=$(readlink -f "${ROOT%/}/lib/modules/${kv}/source")
		if [[ -f ${ROOT%/}/lib/modules/${kv}/build/Makefile ]]; then
			KBUILD_OUTPUT=$(readlink -f "${ROOT%/}/lib/modules/${kv}/build")
		fi
		get_version && return 0
	fi

	KV_FULL=${kv}

	# This handles a variety of weird kernel versions.  Make sure to update
	# tests/linux-info_get_running_version.sh if you want to change this.
	local kv_full=${KV_FULL//[-+_]*}
	KV_MAJOR="$(ver_cut 1 "${kv_full}")"
	KV_MINOR="$(ver_cut 2 "${kv_full}")"
	KV_PATCH="$(ver_cut 3 "${kv_full}")"
	KV_EXTRA="${KV_FULL#"${KV_MAJOR}.${KV_MINOR}${KV_PATCH:+".${KV_PATCH}"}"}"
	: "${KV_PATCH:=0}"

	return 0
}

# This next function is named with the eclass prefix to avoid conflicts with
# some old versionator-like eclass functions.

# @FUNCTION: linux-info_get_any_version
# @DESCRIPTION:
# This attempts to find the version of the sources, and otherwise falls back to
# the version of the running kernel.
linux-info_get_any_version() {
	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	if [[ ${MERGE_TYPE} == binary && -z ${SKIP_KERNEL_BINPKG_ENV_RESET} ]]
	then
		unset KV_FULL _LINUX_CONFIG_EXISTS_DONE KV_OUT_DIR
		SKIP_KERNEL_BINPKG_ENV_RESET=1
	fi

	if ! get_version; then
		ewarn "Unable to calculate Linux Kernel version for build," \
			"attempting to use running version"
	fi

	if [[ -z ${KV_FULL} ]] && ! get_running_version; then
		die "Unable to determine any Linux Kernel version, please report a bug"
	fi
}

# ebuild check functions
# ---------------------------------------

# @FUNCTION: check_kernel_built
# @DESCRIPTION:
# This function verifies that the current kernel sources have been already
# prepared otherwise it dies.
check_kernel_built() {
	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	# If we haven't determined the version yet, we need to

	[[ -n ${SKIP_KERNEL_CHECK} ]] && return

	require_configured_kernel

	local versionh_path
	if kernel_is -ge 3 7; then
		versionh_path="include/generated/uapi/linux/version.h"
	else
		versionh_path="include/linux/version.h"
	fi

	if [[ ! -f "${KV_OUT_DIR}/${versionh_path}" ]]; then
		eerror "These sources have not yet been prepared."
		eerror "We cannot build against an unprepared tree."
		eerror "To resolve this, please type the following:"
		eerror
		eerror "# cd ${KV_DIR}"
		eerror "# make oldconfig"
		eerror "# make modules_prepare"
		eerror
		eerror "Then please try merging this module again."
		die "Kernel sources need compiling first"
	fi
}

# @FUNCTION: check_modules_supported
# @DESCRIPTION:
# This function verifies that the current kernel support modules (it
# checks CONFIG_MODULES=y) otherwise it dies.
check_modules_supported() {
	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	# If we haven't determined the version yet, we need to.
	require_configured_kernel

	if ! linux_chkconfig_builtin "MODULES"; then
		eerror "These sources do not support loading external modules."
		eerror "to be able to use this module please enable \"Loadable" \
			"modules support\""
		eerror "in your kernel, recompile and then try merging this module" \
			"again."
		die "No support for external modules in ${KV_FULL} config"
	fi
}

# @FUNCTION: check_extra_config
# @DESCRIPTION:
# It checks the kernel config options specified by CONFIG_CHECK. It dies only
# when a required config option (i.e. the prefix ~ is not used) doesn't satisfy
# the directive. Ignored on non-Linux systems.
check_extra_config() {
	use kernel_linux || return

	local config negate die error reworkmodulenames
	local soft_errors_count=0 hard_errors_count=0 config_required=0
	# Store the value of the QA check, because otherwise we won't catch usages
	# after if check_extra_config is called AND other direct calls are done
	# later.
	local old_LINUX_CONFIG_EXISTS_DONE="${_LINUX_CONFIG_EXISTS_DONE}"

	# If we haven't determined the version yet, we need to.
	linux-info_get_any_version

	if [[ -n "${CONFIG_CHECK:-}" ]]; then
		if [[ -z "${PORTAGE_TMPDIR:-}" ]] ||
				[[ -z "${CATEGORY:-}" ]] ||
				[[ -z "${PN:-}" ]] ||
				[[ -z "${SLOT:-}" ]]
		then
			ewarn "PORTAGE_TMPDIR, CATEGORY, PN or SLOT unset - cannot" \
				"record CONFIG_CHECK configuration data"
		fi
		local location='/var/lib/portage/eclass/linux-info'
		local dir="${ED:-"${PORTAGE_TMPDIR%"/"}/portage/${CATEGORY}/${PF}/image/${EPREFIX:+"${EPREFIX%"/"}/"}"}"
		dir="${dir%"/"}/${location#"/"}"
		local name="${PN}-${SLOT//\//_}" components='/'
		until [[ -d "${dir}" ]]; do
			if ! [[ -d "${components}" ]]; then
				mkdir "${components}" ||
					die "mkdir() on '${components}' failed: ${?}"
				# Some ebuilds, such as dev-libs/glib, build and install
				# dependencies from src_configure - which causes issues if
				# we've already run and created root-owned directories which
				# other portage helpers (einstalldocs in the case above) can't
				# then write to, since they run as portage:portage :(
				chmod 0777 "${components}" ||
					die "chmod() on '${components}' failed: ${?}"
			fi
			components="${components%"/"}/$( cut -d'/' -f 2 <<<"${dir#"${components%/}"}" )"
		done
		if touch "${dir}/${name}"; then
			printf $'IUSE=%s\nUSE=%s\n\n' > "${dir}/${name}" \
				"${IUSE:-}" \
				"${USE:-}"
			printf $'CONFIG_CHECK=%s\n' >> "${dir}/${name}" \
				"$( xargs -rn 1 <<<"${CONFIG_CHECK}" | xargs -r )"
			local chk=''
			while read -r chk; do
				if [[ -n "${chk:-}" && -n "${!chk:-}" ]]; then
					printf $'%s=%s\n' >>"${dir}/${name}" \
						"${chk}" \
						"${!chk}"
				fi
			done < <(
					# The original logic below only allows for 'CHECK',
					# '~CHECK', '!CHECK', or '~!CHECK' (e.g. '~' must preceed
					# '!')...
					xargs -rn 1 <<<"${CONFIG_CHECK}" |
						sed 's/^~// ; s/^!//' |
						sed 's/^/ERROR_/'
					xargs -rn 1 <<<"${CONFIG_CHECK}" |
						sed 's/^~// ; s/^!//' |
						sed 's/^/WARNING_/'
				)
			unset chk
			einfo "Created '${location}/${name}' with kernel dependencies"
		else
			ewarn "Cannot create directory '${dir}': ${?}"
		fi
		unset name dir location
	fi

	# Determine if we really need a .config. The only time when we don't need
	# one is when all of the CONFIG_CHECK options are prefixed with "~".
	for config in ${CONFIG_CHECK}; do
		if [[ "${config:0:1}" != "~" ]]; then
			config_required=1
			break
		fi
	done

	if [[ ${config_required} == 0 ]]; then
		# In the case where we don't require a .config, we can now bail out
		# if the user has no .config as there is nothing to do. Otherwise
		# code later will cause a failure due to missing .config.
		if ! linux_config_exists; then
			ewarn "Unable to check for the following kernel config options due"
			ewarn "to absence of any configured kernel sources or compiled"
			ewarn "config:"
			for config in ${CONFIG_CHECK}; do
				config=${config#\~}
				config=${config#\!}
				local_error="ERROR_${config}"
				msg="${!local_error}"
				if [[ -z ${msg} ]]; then
					local_error="WARNING_${config}"
					msg="${!local_error}"
				fi
				ewarn " - ${config}${msg:+ - }${msg}"
			done
			ewarn "You're on your own to make sure they are set if needed."
			export LINUX_CONFIG_EXISTS_DONE="${old_LINUX_CONFIG_EXISTS_DONE}"
			return 0
		fi
	elif ! linux_config_exists; then
		qeerror "Could not find a neither a usable .config in the kernel" \
			"source directory"
		qeerror "nor a /proc/config.gz file,"
		qeerror "Please ensure that ${KERNEL_DIR} points to a configured set" \
			"of Linux sources."
		qeerror "If you are using KBUILD_OUTPUT, please set the environment" \
			"var so that"
		qeerror "it points to the necessary object directory so that it" \
			"might find .config"
		qeerror "or have a properly configured kernel to produce a config.gz" \
			"file. (CONFIG_IKCONFIG)."
		die "Kernel not configured; no .config found in ${KV_OUT_DIR} or" \
			"/proc/config.gz found"
	fi

	ebegin "Checking for suitable kernel configuration options"

	for config in ${CONFIG_CHECK}; do
		# If we specify any fatal, ensure we honor them
		die=1
		error=0
		negate=0
		reworkmodulenames=0

		if [[ ${config:0:1} == "~" ]]; then
			die=0
			config=${config:1}
		elif [[ ${config:0:1} == "@" ]]; then
			die=0
			reworkmodulenames=1
			config=${config:1}
		fi
		if [[ ${config:0:1} == "!" ]]; then
			negate=1
			config=${config:1}
		fi

		if [[ ${negate} == 1 ]]; then
			linux_chkconfig_present "${config}" && error=2
		elif [[ ${reworkmodulenames} == 1 ]]; then
			local temp_config="${config//*:}" i n
			config="${config//:*}"
			if linux_chkconfig_present "${config}"; then
				for i in ${MODULE_NAMES}; do
					n="${i//${temp_config}}"
					[[ -z ${n//\(*} ]] && \
						MODULE_IGNORE="${MODULE_IGNORE} ${temp_config}"
				done
				error=2
			fi
		else
			linux_chkconfig_present "${config}" || error=1
		fi

		if [[ ${error} -gt 0 ]]; then
			local report_func="eerror" local_error
			local_error="ERROR_${config}"
			local_error="${!local_error}"

			if [[ -z "${local_error}" ]]; then
				# using old, deprecated format.
				local_error="${config}_ERROR"
				local_error="${!local_error}"
			fi
			if [[ ${die} == 0 && -z "${local_error}" ]]; then
				#soft errors can be warnings
				local_error="WARNING_${config}"
				local_error="${!local_error}"
				if [[ -n "${local_error}" ]] ; then
					report_func="ewarn"
				fi
			fi

			if [[ -z "${local_error}" ]]; then
				[[ ${error} == 1 ]] \
					&& local_error="is not set when it should be." \
					|| local_error="should not be set. But it is."
				local_error="CONFIG_${config}:\t ${local_error}"
			fi
			if [[ ${die} == 0 ]]; then
				${report_func} "  ${local_error}"
				soft_errors_count=$(( soft_errors_count + 1 ))
			else
				${report_func} "  ${local_error}"
				hard_errors_count=$(( hard_errors_count + 1 ))
			fi
		fi
	done

	if [[ ${hard_errors_count} -gt 0 ]]; then
		eend 1
		eerror "Please check to make sure these options are set correctly."
		eerror "Failure to do so may cause unexpected problems."
		eerror "Once you have satisfied these options, please try merging"
		eerror "this package again."
		export LINUX_CONFIG_EXISTS_DONE="${old_LINUX_CONFIG_EXISTS_DONE}"
		die "Incorrect kernel configuration options"
	elif [[ ${soft_errors_count} -gt 0 ]]; then
		eend 1
		ewarn "Please check to make sure these options are set correctly."
		ewarn "Failure to do so may cause unexpected problems."
	else
		eend 0
	fi
	export LINUX_CONFIG_EXISTS_DONE="${old_LINUX_CONFIG_EXISTS_DONE}"
}

# @FUNCTION: check_zlibinflate
# @DESCRIPTION:
# Function to make sure a ZLIB_INFLATE configuration has the required symbols.
check_zlibinflate() {
	if ! use kernel_linux; then
		die "${FUNCNAME[0]}() called on non-Linux system, please fix the ebuild"
	fi

	# If we haven't determined the version yet, we need to.
	require_configured_kernel

	# although I restructured this code - I really really really don't
	# support it!

	# bug #27882 - zlib routines are only linked into the kernel if something
	# compiled into the kernel calls them
	#
	# plus, for the cloop module, it appears that there's no way to get cloop.o
	# to include a static zlib if CONFIG_MODVERSIONS is on

	einfo "Determining the usability of ZLIB_INFLATE support in your kernel"

	ebegin "checking ZLIB_INFLATE"
	linux_chkconfig_builtin CONFIG_ZLIB_INFLATE
	eend $? || die

	ebegin "checking ZLIB_DEFLATE"
	linux_chkconfig_builtin CONFIG_ZLIB_DEFLATE
	eend $? || die

	local -i LINENO_START LINENO_END LINENO_AMOUNT
	local SYMBOLS=''
	local x=''

	LINENO_END="$( # <- Syntax
			grep -n 'CONFIG_ZLIB_INFLATE y' "${KV_DIR}"/lib/Config.in |
				cut -d : -f 1
		)"
	LINENO_START="$( # <- Syntax
			head -n $LINENO_END "${KV_DIR}"/lib/Config.in |
				grep -n 'if \[' |
				tail -n 1 |
				cut -d : -f 1
		)"
	(( LINENO_AMOUNT = LINENO_END - LINENO_START ))
	(( LINENO_END = LINENO_END - 1 ))
	SYMBOLS="$( # <- Syntax
			head -n $LINENO_END "${KV_DIR}"/lib/Config.in |
				tail -n $LINENO_AMOUNT |
				sed -e 's/^.*\(CONFIG_[^\" ]*\).*/\1/g;'
		)"

	# okay, now we have a list of symbols
	# we need to check each one in turn, to see whether it is set or not
	for x in ${SYMBOLS} ; do
		if [[ "${!x}" = 'y' ]]; then
			# We have a winner!
			einfo "${x} ensures zlib is linked into your kernel - excellent"
			return 0
		fi
	done

	eerror
	eerror "This kernel module requires ZLIB library support."
	eerror "You have enabled zlib support in your kernel, but haven't enabled"
	eerror "enabled any option that will ensure that zlib is linked into your"
	eerror "kernel."
	eerror
	eerror "Please ensure that you enable at least one of these options:"
	eerror

	for x in ${SYMBOLS} ; do
		eerror "  * $x"
	done

	eerror
	eerror "Please remember to recompile and install your kernel, and reboot"
	eerror "into your new kernel before attempting to load this kernel module."

	die "Kernel doesn't include zlib support"
}

################################
# Default pkg_setup
# Also used when inheriting linux-mod to force a get_version call
# @FUNCTION: linux-info_pkg_setup
# @DESCRIPTION:
# Force a get_version() call when inherited from linux-mod.eclass and then
# check if the kernel is configured to support the options specified in
# CONFIG_CHECK (if not null)
linux-info_pkg_setup() {
	use kernel_linux || return

	linux-info_get_any_version

	[[ -n "${CONFIG_CHECK}" && -z ${CHECKCONFIG_DONOTHING} ]] &&
		check_extra_config
}

# @FUNCTION: kernel_get_makefile
# @DESCRIPTION:
# Support the possibility that the Makefile could be one of the following and
# should be checked in the order described here:
# https://www.gnu.org/software/make/manual/make.html
# Order of checking and valid Makefiles names:  GNUMakefile, makefile, Makefile
kernel_get_makefile() {
	local mf=''

	for mf in GNUMakefile makefile Makefile; do
		if [[ -s "${KV_DIR}/${mf}" ]]; then
			KERNEL_MAKEFILE="${KV_DIR}/${mf}"
			break
		fi
	done
}

fi

EXPORT_FUNCTIONS pkg_setup
