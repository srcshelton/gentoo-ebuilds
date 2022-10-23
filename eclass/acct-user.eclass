# Copyright 2019-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: acct-user.eclass
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# Mike Gilbert <floppym@gentoo.org>
# @AUTHOR:
# Michael Orlitzky <mjo@gentoo.org>
# Michał Górny <mgorny@gentoo.org>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: Eclass used to create and maintain a single user entry
# @DESCRIPTION:
# This eclass represents and creates a single user entry.  The name
# of the user is derived from ${PN}, while (preferred) UID needs to
# be specified via ACCT_USER_ID.  Additional variables are provided
# to override the default home directory, shell and add group
# membership.  Packages needing the user in question should depend
# on the package providing it.
#
# The ebuild needs to call acct-user_add_deps after specifying
# ACCT_USER_GROUPS.
#
# Example:
# If your package needs user 'foo' belonging to same-named group, you
# create 'acct-user/foo' package and add an ebuild with the following
# contents:
#
# @CODE
# EAPI=8
# inherit acct-user
# ACCT_USER_ID=200
# ACCT_USER_GROUPS=( foo )
# acct-user_add_deps
# @CODE
#
# Then you add appropriate dependencies to your package.  Note that
# the build system might need to resolve names, too.  The dependency
# type(s) should be: BDEPEND if the user must be resolvable at build
# time (e.g. 'fowners' uses it in src_install), IDEPEND if it must be
# resolvable at install time (e.g. 'fowners' uses it in pkg_preinst),
# and RDEPEND in every case.

if [[ -z ${_ACCT_USER_ECLASS} ]]; then
_ACCT_USER_ECLASS=1

case ${EAPI:-0} in
	7|8) ;;
	*) die "EAPI=${EAPI:-0} not supported";;
esac

inherit user-info

[[ ${CATEGORY} == acct-user ]] ||
	die "Ebuild error: this eclass can be used only in acct-user category!"

BDEPEND="sys-apps/shadow"

IUSE="systemd"


# << Eclass variables >>

# @ECLASS_VARIABLE: ACCT_USER_NAME
# @INTERNAL
# @DESCRIPTION:
# The name of the user.  This is forced to ${PN} and the policy prohibits
# it from being changed.
ACCT_USER_NAME=${PN}
readonly ACCT_USER_NAME

# @ECLASS_VARIABLE: ACCT_USER_ID
# @REQUIRED
# @DESCRIPTION:
# Preferred UID for the new user.  This variable is obligatory, and its
# value must be unique across all user packages.  This can be overriden
# in make.conf through ACCT_USER_<UPPERCASE_USERNAME>_ID variable.
#
# Overlays should set this to -1 to dynamically allocate UID.  Using -1
# in ::gentoo is prohibited by policy.

# @ECLASS_VARIABLE: ACCT_USER_ENFORCE_ID
# @DESCRIPTION:
# If set to a non-null value, the eclass will require the user to have
# specified UID.  If the user already exists with another UID, or
# the UID is taken by another user, the install will fail.
: ${ACCT_USER_ENFORCE_ID:=}

# @ECLASS_VARIABLE: ACCT_USER_NO_MODIFY
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-null value, the eclass will not make any changes
# to an already existing user.
: ${ACCT_USER_NO_MODIFY:=}

# @ECLASS_VARIABLE: ACCT_USER_COMMENT
# @DEFAULT_UNSET
# @DESCRIPTION:
# The comment to use for the user.  If not specified, the package
# DESCRIPTION will be used.  This can be overridden in make.conf through
# ACCT_USER_<UPPERCASE_USERNAME>_COMMENT variable.

# @ECLASS_VARIABLE: ACCT_USER_SHELL
# @DESCRIPTION:
# The shell to use for the user.  If not specified, a 'nologin' variant
# for the system is used.  This can be overriden in make.conf through
# ACCT_USER_<UPPERCASE_USERNAME>_SHELL variable.
: ${ACCT_USER_SHELL:=/sbin/nologin}

# @ECLASS_VARIABLE: ACCT_USER_HOME
# @DESCRIPTION:
# The home directory for the user.  If not specified, /dev/null is used.
# The directory will be created with appropriate permissions if it does
# not exist.  When updating, existing home directory will not be moved.
# This can be overriden in make.conf through
# ACCT_USER_<UPPERCASE_USERNAME>_HOME variable.
: ${ACCT_USER_HOME:=/dev/null}

# @ECLASS_VARIABLE: ACCT_USER_HOME_OWNER
# @DEFAULT_UNSET
# @DESCRIPTION:
# The ownership to use for the home directory, in chown ([user][:group])
# syntax.  Defaults to the newly created user, and its primary group.
# This can be overriden in make.conf through
# ACCT_USER_<UPPERCASE_USERNAME>_HOME_OWNER variable.

# @ECLASS_VARIABLE: ACCT_USER_HOME_PERMS
# @DESCRIPTION:
# The permissions to use for the home directory, in chmod (octal
# or verbose) form.  This can be overriden in make.conf through
# ACCT_USER_<UPPERCASE_USERNAME>_HOME_PERMS variable.
: ${ACCT_USER_HOME_PERMS:=0755}

# @ECLASS_VARIABLE: ACCT_USER_GROUPS
# @REQUIRED
# @DESCRIPTION:
# List of groups the user should belong to.  This must be a bash
# array.  The first group specified is the user's primary group, while
# the remaining groups (if any) become supplementary groups.
#
# This can be overriden in make.conf through
# ACCT_USER_<UPPERCASE_USERNAME>_GROUPS variable, or appended to
# via ACCT_USER_<UPPERCASE_USERNAME>_GROUPS_ADD.  Please note that
# due to technical limitations, the override variables are not arrays
# but space-separated lists.


# << Boilerplate ebuild variables >>
: ${DESCRIPTION:="System user: ${ACCT_USER_NAME}"}
: ${SLOT:=0}
: ${KEYWORDS:=alpha amd64 arm arm64 hppa ia64 ~loong m68k ~mips ppc ppc64 ~riscv s390 sparc x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris}
S=${WORKDIR}


# << API functions >>

# @FUNCTION: acct-user_add_deps
# @DESCRIPTION:
# Generate appropriate RDEPEND from ACCT_USER_GROUPS.  This must be
# called if ACCT_USER_GROUPS are set.
acct-user_add_deps() {
	debug-print-function ${FUNCNAME} "${@}"

	# ACCT_USER_GROUPS sanity check
	if [[ $(declare -p ACCT_USER_GROUPS) != "declare -a"* ]]; then
		die 'ACCT_USER_GROUPS must be an array.'
	elif [[ ${#ACCT_USER_GROUPS[@]} -eq 0 ]]; then
		die 'ACCT_USER_GROUPS must not be empty.'
	fi

	RDEPEND+=${ACCT_USER_GROUPS[*]/#/ acct-group/}
	_ACCT_USER_ADD_DEPS_CALLED=1
}


# << Helper functions >>

# @FUNCTION: eislocked
# @USAGE: <user>
# @INTERNAL
# @DESCRIPTION:
# Check whether the specified user account is currently locked.
# Returns 0 if it is locked, 1 if it is not, 2 if the platform
# does not support determining it.
eislocked() {
	[[ $# -eq 1 ]] || die "usage: ${FUNCNAME} <user>"

	if [[ ${EUID} -ne 0 ]]; then
		einfo "Insufficient privileges to execute ${FUNCNAME[0]}"
		return 0
	fi

	case ${CHOST} in
	*-freebsd*|*-dragonfly*|*-netbsd*)
		[[ $(egetent "$1" | cut -d: -f2) == '*LOCKED*'* ]]
		;;

	*-openbsd*)
		return 2
		;;

	*)
		# NB: 'no password' and 'locked' are indistinguishable
		# but we also expire the account which is more clear
		local shadow
		if [[ -n "${ROOT}" ]]; then
			shadow=$(grep "^$1:" "${ROOT}/etc/shadow")
		else
			shadow=$(getent shadow "$1")
		fi

		[[ $( echo ${shadow} | cut -d: -f2) == '!'* ]] &&
			[[ $(echo ${shadow} | cut -d: -f8) == 1 ]]
		;;
	esac
}

# << Phase functions >>
EXPORT_FUNCTIONS pkg_pretend src_install pkg_preinst pkg_postinst \
	pkg_prerm

# @FUNCTION: acct-user_pkg_pretend
# @DESCRIPTION:
# Performs sanity checks for correct eclass usage, and early-checks
# whether requested UID can be enforced.
acct-user_pkg_pretend() {
	debug-print-function ${FUNCNAME} "${@}"

	# verify that acct-user_add_deps() has been called
	# (it verifies ACCT_USER_GROUPS itself)
	if [[ -z ${_ACCT_USER_ADD_DEPS_CALLED} ]]; then
		die "Ebuild error: acct-user_add_deps must have been called in global scope!"
	fi

	# verify ACCT_USER_ID
	[[ -n ${ACCT_USER_ID} ]] || die "Ebuild error: ACCT_USER_ID must be set!"
	[[ ${ACCT_USER_ID} -ge -1 ]] || die "Ebuild error: ACCT_USER_ID=${ACCT_USER_ID} invalid!"
	local user_id=${ACCT_USER_ID}

	# check for the override
	local override_name=${ACCT_USER_NAME^^}
	local override_var=ACCT_USER_${override_name//-/_}_ID
	if [[ -n ${!override_var} ]]; then
		user_id=${!override_var}
		[[ ${user_id} -ge -1 ]] || die "${override_var}=${user_id} invalid!"
	fi

	# check for ACCT_USER_ID collisions early
	if [[ ${user_id} -ne -1 && -n ${ACCT_USER_ENFORCE_ID} ]]; then
		local user_by_id=$(egetusername "${user_id}")
		local user_by_name=$(egetent passwd "${ACCT_USER_NAME}")
		if [[ -n ${user_by_id} ]]; then
			if [[ ${user_by_id} != ${ACCT_USER_NAME} ]]; then
				eerror "The required UID is already taken by another user."
				eerror "  UID: ${user_id}"
				eerror "  needed for: ${ACCT_USER_NAME}"
				eerror "  current user: ${user_by_id}"
				die "UID ${user_id} taken already"
			fi
		elif [[ -n ${user_by_name} ]]; then
			eerror "The requested user exists already with wrong UID."
			eerror "  username: ${ACCT_USER_NAME}"
			eerror "  requested UID: ${user_id}"
			eerror "  current entry: ${user_by_name}"
			die "Username ${ACCT_USER_NAME} exists with wrong UID"
		fi
	fi
}

# @FUNCTION: acct-user_src_install
# @DESCRIPTION:
# Installs a keep-file into the user's home directory to ensure it is
# owned by the package, and sysusers.d file.
acct-user_src_install() {
	debug-print-function ${FUNCNAME} "${@}"

	# Replace reserved characters in comment
	: ${ACCT_USER_COMMENT:=${DESCRIPTION//[:,=]/;}}

	# serialize for override support
	local ACCT_USER_GROUPS=${ACCT_USER_GROUPS[*]}

	# support make.conf overrides
	local override_name=${ACCT_USER_NAME^^}
	override_name=${override_name//-/_}
	local var
	for var in ACCT_USER_{ID,COMMENT,SHELL,HOME{,_OWNER,_PERMS},GROUPS}; do
		local var_name=ACCT_USER_${override_name}_${var#ACCT_USER_}
		if [[ -n ${!var_name} ]]; then
			ewarn "${var_name}=${!var_name} override in effect, support will not be provided."
		else
			var_name=${var}
		fi
		declare -g "_${var}=${!var_name}"
	done
	var_name=ACCT_USER_${override_name}_GROUPS_ADD
	if [[ -n ${!var_name} ]]; then
		ewarn "${var_name}=${!var_name} override in effect, support will not be provided."
		_ACCT_USER_GROUPS+=" ${!var_name}"
	fi

	if [[ -n ${_ACCT_USER_COMMENT//[^:,=]} ]]; then
		die "Invalid characters in user comment: '${_ACCT_USER_COMMENT//[^:,=]}'"
	fi

	# deserialize into an array
	local groups=( ${_ACCT_USER_GROUPS} )

	if [[ ${_ACCT_USER_HOME} != /dev/null ]]; then
		# note: we can't set permissions here since the user isn't
		# created yet
		keepdir "${_ACCT_USER_HOME}"
	fi

	if use systemd; then
		insinto /usr/lib/sysusers.d
		newins - ${CATEGORY}-${ACCT_USER_NAME}.conf < <(
			printf "u\t%q\t%q\t%q\t%q\t%q\n" \
				"${ACCT_USER_NAME}" \
				"${_ACCT_USER_ID/#-*/-}:${groups[0]}" \
			"${_ACCT_USER_COMMENT}" \
				"${_ACCT_USER_HOME}" \
				"${_ACCT_USER_SHELL/#-*/-}"
			if [[ ${#groups[@]} -gt 1 ]]; then
				printf "m\t${ACCT_USER_NAME}\t%q\n" \
					"${groups[@]:1}"
			fi
		)
	fi
}

# @FUNCTION: acct-user_pkg_preinst
# @DESCRIPTION:
# Creates the user if it does not exist yet.  Sets permissions
# of the home directory in install image.
acct-user_pkg_preinst() {
	debug-print-function ${FUNCNAME} "${@}"

	unset _ACCT_USER_ADDED

	if [[ ${EUID} -ne 0 ]]; then
		einfo "Insufficient privileges to execute ${FUNCNAME[0]}"
		return
	fi

	if egetent passwd "${ACCT_USER_NAME}" >/dev/null; then
		elog "User ${ACCT_USER_NAME} already exists"
		return
	fi

	local groups=( ${_ACCT_USER_GROUPS} )
	local aux_groups=${groups[*]:1}
	local opts=(
		--system
		--no-create-home
		--no-user-group
		--comment "${_ACCT_USER_COMMENT}"
		--home-dir "${_ACCT_USER_HOME}"
		--shell "${_ACCT_USER_SHELL}"
		--gid "${groups[0]}"
		--groups "${aux_groups// /,}"
	)

	if [[ ${_ACCT_USER_ID} -ne -1 ]] &&
		! egetent passwd "${_ACCT_USER_ID}" >/dev/null
	then
		opts+=( --uid "${_ACCT_USER_ID}" )
	fi

	if [[ -n ${ROOT} ]]; then
		opts+=( --prefix "${ROOT}" )
	fi

	elog "Adding user ${ACCT_USER_NAME}"
	useradd "${opts[@]}" "${ACCT_USER_NAME}" || die
	_ACCT_USER_ADDED=1

	if [[ ${_ACCT_USER_HOME} != /dev/null ]]; then
		# default ownership to user:group
		if [[ -z ${_ACCT_USER_HOME_OWNER} ]]; then
			if [[ -n "${ROOT}" ]]; then
				local euid=$(egetent passwd ${ACCT_USER_NAME} | cut -d: -f3)
				local egid=$(egetent passwd ${ACCT_USER_NAME} | cut -d: -f4)
				_ACCT_USER_HOME_OWNER=${euid}:${egid}
			else
				_ACCT_USER_HOME_OWNER=${ACCT_USER_NAME}:${groups[0]}
			fi
		fi
		# Path might be missing due to INSTALL_MASK, etc.
		# https://bugs.gentoo.org/691478
		if [[ ! -e "${ED}/${_ACCT_USER_HOME#/}" ]]; then
			eerror "Home directory is missing from the installation image:"
			eerror "  ${_ACCT_USER_HOME}"
			eerror "Check INSTALL_MASK for entries that would cause this."
			die "${_ACCT_USER_HOME} does not exist"
		fi
		fowners "${_ACCT_USER_HOME_OWNER}" "${_ACCT_USER_HOME}"
		fperms "${_ACCT_USER_HOME_PERMS}" "${_ACCT_USER_HOME}"
	fi
}

# @FUNCTION: acct-user_pkg_postinst
# @DESCRIPTION:
# Updates user properties if necessary.  This needs to be done after
# new home directory is installed.
acct-user_pkg_postinst() {
	debug-print-function ${FUNCNAME} "${@}"

	if [[ -n ${_ACCT_USER_ADDED} ]]; then
		# We just added the user; no need to update it
		return
	fi

	if [[ ${EUID} -ne 0 ]]; then
		einfo "Insufficient privileges to execute ${FUNCNAME[0]}"
		return
	fi

	if [[ -n ${ACCT_USER_NO_MODIFY} ]]; then
		ewarn "User ${ACCT_USER_NAME} already exists; Not touching existing user"
		ewarn "due to set ACCT_USER_NO_MODIFY."
		return
	fi

	local groups=( ${_ACCT_USER_GROUPS} )
	local aux_groups=${groups[*]:1}
	local opts=(
		--comment "${_ACCT_USER_COMMENT}"
		--home "${_ACCT_USER_HOME}"
		--shell "${_ACCT_USER_SHELL}"
		--gid "${groups[0]}"
		--groups "${aux_groups// /,}"
	)

	if eislocked "${ACCT_USER_NAME}"; then
		opts+=( --expiredate "" --unlock )
	fi

	if [[ -n ${ROOT} ]]; then
		opts+=( --prefix "${ROOT}" )
	fi

	elog "Updating user ${ACCT_USER_NAME}"
	if ! usermod "${opts[@]}" "${ACCT_USER_NAME}" 2>"${T}/usermod-error.log"; then
		# usermod outputs a warning if unlocking the account would result in an
		# empty password. Hide stderr in a text file and display it if usermod
		# fails.
		cat "${T}/usermod-error.log" >&2
		die "usermod failed"
	fi
}

# @FUNCTION: acct-user_pkg_prerm
# @DESCRIPTION:
# Ensures that the user account is locked out when it is removed.
acct-user_pkg_prerm() {
	debug-print-function ${FUNCNAME} "${@}"

	if [[ -n ${REPLACED_BY_VERSION} ]]; then
		return
	fi

	if [[ ${EUID} -ne 0 ]]; then
		einfo "Insufficient privileges to execute ${FUNCNAME[0]}"
		return
	fi

	if [[ ${ACCT_USER_ID} -eq 0 ]]; then
		elog "Refusing to lock out the superuser (UID 0)"
		return
	fi

	if [[ -n ${ACCT_USER_NO_MODIFY} ]]; then
		elog "Not locking user ${ACCT_USER_NAME} due to ACCT_USER_NO_MODIFY"
		return
	fi

	if ! egetent passwd "${ACCT_USER_NAME}" >/dev/null; then
			ewarn "User account not found: ${ACCT_USER_NAME}"
			ewarn "Locking process will be skipped."
			return
		fi

	local opts=(
		--expiredate 1
		--lock
		--comment "$(egetcomment "${ACCT_USER_NAME}"); user account removed @ $(date +%Y-%m-%d)"
		--shell /sbin/nologin
	)

	if [[ -n ${ROOT} ]]; then
		opts+=( --prefix "${ROOT}" )
	fi

	elog "Locking user ${ACCT_USER_NAME}"
	usermod "${opts[@]}" "${ACCT_USER_NAME}" || die
}

fi

# vi: set diffopt=iwhite,filler:
