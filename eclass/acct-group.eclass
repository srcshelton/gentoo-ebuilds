# Copyright 2019-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: acct-group.eclass
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# Mike Gilbert <floppym@gentoo.org>
# @AUTHOR:
# Michael Orlitzky <mjo@gentoo.org>
# Michał Górny <mgorny@gentoo.org>
# @SUPPORTED_EAPIS: 7 8 9
# @BLURB: Eclass used to create and maintain a single group entry
# @DESCRIPTION:
# This eclass represents and creates a single group entry.  The name
# of the group is derived from ${PN}, while (preferred) GID needs to
# be specified via ACCT_GROUP_ID.  Packages (and users) needing the group
# in question should depend on the package providing it.
#
# Example:
# If your package needs group 'foo', you create 'acct-group/foo' package
# and add an ebuild with the following contents:
#
# @CODE
# EAPI=8
# inherit acct-group
# ACCT_GROUP_ID=200
# @CODE
#
# Then you add appropriate dependencies to your package.  Note that
# the build system might need to resolve names, too.  The dependency
# type(s) should be: BDEPEND if the group must be resolvable at build
# time (e.g. 'fowners' uses it in src_install), IDEPEND if it must be
# resolvable at install time (e.g. 'fowners' uses it in pkg_preinst),
# and RDEPEND in every case.

if [[ -z ${_ACCT_GROUP_ECLASS} ]]; then
_ACCT_GROUP_ECLASS=1

case ${EAPI} in
	7|8|9) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

inherit user-info

[[ ${CATEGORY} == acct-group ]] ||
	die "Ebuild error: this eclass can be used only in acct-group category!"

DEPEND='sys-apps/baselayout'
BDEPEND='sys-apps/grep'
RDEPEND="${DEPEND}"

IUSE="systemd"


# << Eclass variables >>

# @ECLASS_VARIABLE: ACCT_GROUP_NAME
# @DESCRIPTION:
# The name of the group.  This is forced to ${PN} and the policy
# prohibits it from being changed.  The variable is left writable for
# use in overlays; package naming restrictions would prohibit some
# otherwise-valid group names.
ACCT_GROUP_NAME=${PN}

# @ECLASS_VARIABLE: ACCT_GROUP_ID
# @REQUIRED
# @DESCRIPTION:
# Preferred GID for the new group.  This variable is obligatory, and its
# value must be unique across all group packages.  This can be overridden
# in make.conf through ACCT_GROUP_<UPPERCASE_USERNAME>_ID variable.
#
# Overlays should set this to -1 to dynamically allocate GID.  Using -1
# in ::gentoo is prohibited by policy.

# @ECLASS_VARIABLE: ACCT_GROUP_ENFORCE_ID
# @DESCRIPTION:
# If set to a non-null value, the eclass will require the group to have
# specified GID.  If the group already exists with another GID, or
# the GID is taken by another group, the install will fail.
: "${ACCT_GROUP_ENFORCE_ID:=}"


# << Boilerplate ebuild variables >>
: "${DESCRIPTION:="System group: ${ACCT_GROUP_NAME}"}"
: "${SLOT:=0}"
: "${KEYWORDS:=~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~arm64-macos ~x64-macos ~x64-solaris}"
S=${WORKDIR}


# << Phase functions >>

# @FUNCTION: acct-group_pkg_pretend
# @DESCRIPTION:
# Performs sanity checks for correct eclass usage, and early-checks
# whether requested GID can be enforced.
acct-group_pkg_pretend() {
	debug-print-function ${FUNCNAME} "$@"

	# verify ACCT_GROUP_ID
	[[ -n ${ACCT_GROUP_ID} ]] || die "Ebuild error: ACCT_GROUP_ID must be set!"
	[[ ${ACCT_GROUP_ID} -ge -1 ]] || die "Ebuild error: ACCT_GROUP_ID=${ACCT_GROUP_ID} invalid!"
	local group_id=${ACCT_GROUP_ID}

	# check for the override, use PN in case this is an overlay and
	# ACCT_GROUP_NAME is not PN and not valid in a bash variable name
	local override_name=${PN^^}
	local override_var=ACCT_GROUP_${override_name//-/_}_ID
	if [[ -n ${!override_var} ]]; then
		group_id=${!override_var}
		[[ ${group_id} -ge -1 ]] || die "${override_var}=${group_id} invalid!"
	fi

	# check for ACCT_GROUP_ID collisions early
	if [[ ${group_id} -ne -1 && -n ${ACCT_GROUP_ENFORCE_ID} ]]; then
		local group_by_id=$(egetgroupname "${group_id}")
		local group_by_name=$(egetent group "${ACCT_GROUP_NAME}")
		if [[ -n ${group_by_id} ]]; then
			if [[ ${group_by_id} != ${ACCT_GROUP_NAME} ]]; then
				eerror "The required GID is already taken by another group."
				eerror "  GID: ${group_id}"
				eerror "  needed for: ${ACCT_GROUP_NAME}"
				eerror "  current group: ${group_by_id}"
				die "GID ${group_id} taken already"
			fi
		elif [[ -n ${group_by_name} ]]; then
			eerror "The requested group exists already with wrong GID."
			eerror "  groupname: ${ACCT_GROUP_NAME}"
			eerror "  requested GID: ${group_id}"
			eerror "  current entry: ${group_by_name}"
			die "Group ${ACCT_GROUP_NAME} exists with wrong GID"
		fi
	fi
}

# @FUNCTION: acct-group_src_install
# @DESCRIPTION:
# Installs sysusers.d file for the group.
acct-group_src_install() {
	debug-print-function ${FUNCNAME} "$@"

	# check for the override, use PN in case this is an overlay and
	# ACCT_GROUP_NAME is not PN and not valid in a bash variable name
	local override_name=${PN^^}
	local override_var=ACCT_GROUP_${override_name//-/_}_ID
	if [[ -n ${!override_var} ]]; then
		ewarn "${override_var}=${!override_var} override in effect, support will not be provided."
		_ACCT_GROUP_ID=${!override_var}
	else
		_ACCT_GROUP_ID=${ACCT_GROUP_ID}
	fi

	if use systemd; then
		insinto /usr/lib/sysusers.d
		newins - ${CATEGORY}-${ACCT_GROUP_NAME}.conf < <( # <- Syntax
			printf "g\t%q\t%q\n" \
				"${ACCT_GROUP_NAME}" \
				"${_ACCT_GROUP_ID/#-*/-}"
		)
	fi
}

_acct_group_fallback_groupadd() {
	local group_name=${1}
	local -i group_id=${2}
	local group_file="${ROOT:-}/etc/group"
	local gshadow_file="${ROOT:-}/etc/gshadow"

	case ${group_name} in
		''|*:*|*$'\n'*)
			die "Invalid group name for shell fallback: '${group_name}'"
			;;
	esac
	[[ -f ${group_file} ]] ||
		die "Unable to locate group database '${group_file}'"

	local name password gid members
	if (( group_id != -1 )); then
		while IFS=: read -r name password gid members; do
			[[ ${gid} == "${group_id}" ]] && break
		done < "${group_file}"
	else
		gid=
	fi
	if [[ ${gid} == "${group_id}" ]]; then
		if [[ -n ${ACCT_GROUP_ENFORCE_ID} ]]; then
			die "GID ${group_id} taken already"
		fi
		group_id=-1
	fi

	if (( group_id == -1 )); then
		local -i min=101 max=999
		local item value
		if [[ -r ${ROOT:-}/etc/login.defs ]]; then
			while read -r item value _; do
				[[ -n ${value} && ${value} != *[!0-9]* ]] || continue
				case ${item} in
					SYS_GID_MIN) min=${value} ;;
					SYS_GID_MAX) max=${value} ;;
				esac
			done < "${ROOT:-}/etc/login.defs"
		fi
		for (( group_id = max; group_id >= min; --group_id )); do
			while IFS=: read -r name password gid members; do
				[[ ${gid} == "${group_id}" ]] && continue 2
			done < "${group_file}"
			break
		done
		(( group_id >= min )) || die "Unable to allocate a free system GID"
	fi

	printf '%s:x:%s:\n' "${group_name}" "${group_id}" >> "${group_file}" ||
		die "Unable to append group '${group_name}' to '${group_file}'"

	if [[ -f ${gshadow_file} ]]; then
		printf '%s:!::\n' "${group_name}" >> "${gshadow_file}" ||
			die "Unable to append group '${group_name}' to '${gshadow_file}'"
	fi
}

# @FUNCTION: acct-group_pkg_preinst
# @DESCRIPTION:
# Creates the group if it does not exist yet.
acct-group_pkg_preinst() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${EUID} -ne 0 || -n ${EPREFIX} ]]; then
		einfo "Insufficient privileges to execute ${FUNCNAME[0]}"
		return
	fi

	if egetent group "${ACCT_GROUP_NAME}" >/dev/null; then
		elog "Group ${ACCT_GROUP_NAME} already exists"
		return
	fi

	local opts=( --system )
	local group_id=-1

	if [[ ${_ACCT_GROUP_ID} -ne -1 ]] &&
		! egetent group "${_ACCT_GROUP_ID}" >/dev/null
	then
		group_id=${_ACCT_GROUP_ID}
		opts+=( --gid "${_ACCT_GROUP_ID}" )
	fi

	if [[ -n ${ROOT} ]]; then
		opts+=( --prefix "${ROOT}" )
	fi

	elog "Adding group ${ACCT_GROUP_NAME}"
	if type -fp groupadd >/dev/null; then
		groupadd "${opts[@]}" "${ACCT_GROUP_NAME}" || die "groupadd failed with status $?"
	elif [[ -z ${ROOT} ]] && type -fp busybox >/dev/null; then
		local bbopts=( -S )
		(( group_id == -1 )) || bbopts+=( -g "${group_id}" )
		busybox addgroup "${bbopts[@]}" "${ACCT_GROUP_NAME}" || die "addgroup failed with status $?"
	else
		_acct_group_fallback_groupadd "${ACCT_GROUP_NAME}" "${_ACCT_GROUP_ID}"
	fi
}

fi

EXPORT_FUNCTIONS pkg_pretend src_install pkg_preinst

# vi: set diffopt=iwhite,filler:
