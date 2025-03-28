# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: multilib.eclass
# @MAINTAINER:
# toolchain@gentoo.org
# @SUPPORTED_EAPIS: 7 8
# @BLURB: This eclass is for all functions pertaining to handling multilib configurations.
# @DESCRIPTION:
# This eclass is for all functions pertaining to handling multilib configurations.

if [[ -z ${_MULTILIB_ECLASS} ]]; then
_MULTILIB_ECLASS=1

case ${EAPI} in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

inherit toolchain-funcs

# Defaults:
export MULTILIB_ABIS=${MULTILIB_ABIS:-"default"}
export DEFAULT_ABI=${DEFAULT_ABI:-"default"}
export CFLAGS_default
export LDFLAGS_default
export CHOST_default=${CHOST_default:-${CHOST}}
export CTARGET_default=${CTARGET_default:-${CTARGET:-${CHOST_default}}}
export LIBDIR_default=${CONF_LIBDIR:-${LIBDIR_x86:-"lib"}}
export KERNEL_ABI=${KERNEL_ABI:-${DEFAULT_ABI}}

# @FUNCTION: has_multilib_profile
# @DESCRIPTION:
# Return true if the current profile is a multilib profile and lists more than
# one abi in ${MULTILIB_ABIS}.  When has_multilib_profile returns true, that
# profile should enable the 'multilib' use flag. This is so you can DEPEND on
# a package only for multilib or not multilib.
has_multilib_profile() {
	[ -n "${MULTILIB_ABIS}" -a "${MULTILIB_ABIS}" != "${MULTILIB_ABIS/ /}" ]
}

# @FUNCTION: get_abi_var
# @USAGE: <VAR> [ABI]
# @RETURN: returns the value of ${<VAR>_<ABI>} which should be set in make.defaults
# @INTERNAL
# @DESCRIPTION:
# ex:
# CFLAGS=$(get_abi_var CFLAGS sparc32) # CFLAGS=-m32
#
# Note that the preferred method is to set CC="$(tc-getCC) $(get_abi_CFLAGS)"
# This will hopefully be added to portage soon...
#
# If <ABI> is not specified, ${ABI} is used.
# If <ABI> is not specified and ${ABI} is not defined, ${DEFAULT_ABI} is used.
# If <ABI> is not specified and ${ABI} and ${DEFAULT_ABI} are not defined, we return an empty string.
get_abi_var() {
	local flag=$1
	local abi=${2:-${ABI:-${DEFAULT_ABI:-default}}}
	local var="${flag}_${abi}"
	echo ${!var}
}

# @FUNCTION: get_abi_CFLAGS
# @USAGE: [ABI]
# @DESCRIPTION:
# Alias for 'get_abi_var CFLAGS'
get_abi_CFLAGS() { get_abi_var CFLAGS "$@"; }

# @FUNCTION: get_abi_LDFLAGS
# @USAGE: [ABI]
# @DESCRIPTION:
# Alias for 'get_abi_var LDFLAGS'
get_abi_LDFLAGS() { get_abi_var LDFLAGS "$@"; }

# @FUNCTION: get_abi_CHOST
# @USAGE: [ABI]
# @DESCRIPTION:
# Alias for 'get_abi_var CHOST'
get_abi_CHOST() { get_abi_var CHOST "$@"; }

# @FUNCTION: get_abi_CTARGET
# @USAGE: [ABI]
# @DESCRIPTION:
# Alias for 'get_abi_var CTARGET'
get_abi_CTARGET() { get_abi_var CTARGET "$@"; }

# @FUNCTION: get_abi_FAKE_TARGETS
# @USAGE: [ABI]
# @DESCRIPTION:
# Alias for 'get_abi_var FAKE_TARGETS'
get_abi_FAKE_TARGETS() { get_abi_var FAKE_TARGETS "$@"; }

# @FUNCTION: get_abi_LIBDIR
# @USAGE: [ABI]
# @DESCRIPTION:
# Alias for 'get_abi_var LIBDIR'
get_abi_LIBDIR() { get_abi_var LIBDIR "$@"; }

# @FUNCTION: get_install_abis
# @DESCRIPTION:
# Return a list of the ABIs we want to install for with
# the last one in the list being the default.
get_install_abis() {
	local x order=""

	if [[ -z ${MULTILIB_ABIS} ]] ; then
		echo "default"
		return 0
	fi

	if [[ ${EMULTILIB_PKG} == "true" ]] ; then
		for x in ${MULTILIB_ABIS} ; do
			if [[ ${x} != "${DEFAULT_ABI}" ]] ; then
				has ${x} ${ABI_DENY} || order="${order} ${x}"
			fi
		done
		has ${DEFAULT_ABI} ${ABI_DENY} || order="${order} ${DEFAULT_ABI}"

		if [[ -n ${ABI_ALLOW} ]] ; then
			local ordera=""
			for x in ${order} ; do
				if has ${x} ${ABI_ALLOW} ; then
					ordera="${ordera} ${x}"
				fi
			done
			order=${ordera}
		fi
	else
		order=${DEFAULT_ABI}
	fi

	if [[ -z ${order} ]] ; then
		die "The ABI list is empty.  Are you using a proper multilib profile?  Perhaps your USE flags or MULTILIB_ABIS are too restrictive for this package."
	fi

	echo ${order}
	return 0
}

# @FUNCTION: get_all_abis
# @DESCRIPTION:
# Return a list of the ABIs supported by this profile.
# the last one in the list being the default.
get_all_abis() {
	local x order="" mvar dvar

	mvar="MULTILIB_ABIS"
	dvar="DEFAULT_ABI"
	if [[ -n $1 ]] ; then
		mvar="$1_${mvar}"
		dvar="$1_${dvar}"
	fi

	if [[ -z ${!mvar} ]] ; then
		echo "default"
		return 0
	fi

	for x in ${!mvar}; do
		if [[ ${x} != ${!dvar} ]] ; then
			order="${order:+${order} }${x}"
		fi
	done
	order="${order:+${order} }${!dvar}"

	echo ${order}
	return 0
}

# @FUNCTION: get_all_libdirs
# @DESCRIPTION:
# Returns a list of all the libdirs used by this profile.  This includes
# those that might not be touched by the current ebuild and always includes
# "lib".
get_all_libdirs() {
	local libdirs abi

	for abi in ${MULTILIB_ABIS}; do
		libdirs+=" $(get_abi_LIBDIR ${abi})"
	done
	[[ " ${libdirs} " != *" lib "* ]] && libdirs+=" lib"

	echo "${libdirs}"
}

# @FUNCTION: is_final_abi
# @DESCRIPTION:
# Return true if ${ABI} is the last ABI on our list (or if we're not
# using the new multilib configuration.  This can be used to determine
# if we're in the last (or only) run through src_{unpack,compile,install}
is_final_abi() {
	has_multilib_profile || return 0
	set -- $(get_install_abis)
	local LAST_ABI=$#
	[[ ${!LAST_ABI} == ${ABI} ]]
}

# @FUNCTION: number_abis
# @DESCRIPTION:
# echo the number of ABIs we will be installing for
number_abis() {
	set -- `get_install_abis`
	echo $#
}

# @FUNCTION: get_exeext
# @DESCRIPTION:
# Returns standard executable program suffix (null, .exe, etc.)
# for the current platform identified by CHOST.
#
# Example:
#     get_exeext
#     Returns: null string (almost everywhere) || .exe (mingw*) || ...
get_exeext() {
	case ${CHOST} in
		mingw*|*-mingw*)  echo ".exe";;
	esac
}

# @FUNCTION: get_libname
# @USAGE: [version]
# @DESCRIPTION:
# Returns libname with proper suffix {.so,.dylib,.dll,etc} and optionally
# supplied version for the current platform identified by CHOST.
#
# Example:
#     get_libname ${PV}
#     Returns: .so.${PV} (ELF) || .${PV}.dylib (MACH) || ...
get_libname() {
	local libname
	local ver=$1
	case ${CHOST} in
		mingw*|*-mingw*) libname="dll";;
		*-darwin*)       libname="dylib";;
		*)               libname="so";;
	esac

	if [[ -z $* ]] ; then
		echo ".${libname}"
	else
		for ver in "$@" ; do
			case ${CHOST} in
				*-darwin*) echo ".${ver}.${libname}";;
				*)         echo ".${libname}.${ver}";;
			esac
		done
	fi
}

# @FUNCTION: get_modname
# @USAGE:
# @DESCRIPTION:
# Returns modulename with proper suffix {.so,.bundle,etc} for the current
# platform identified by CHOST.
#
# Example:
#     libfoo$(get_modname)
#     Returns: libfoo.so (ELF) || libfoo.bundle (MACH) || ...
get_modname() {
	local modname
	local ver=$1
	case ${CHOST} in
		*-darwin*)                modname="bundle";;
		*)                        modname="so";;
	esac

	echo ".${modname}"
}

# @FUNCTION: multilib_env
# @USAGE:
# @DESCRIPTION:
# This is for the toolchain to setup profile variables when pulling in
# a crosscompiler (and thus they aren't set in the profile).
#
# This must only be used by toolchain packages.
multilib_env() {
	local CTARGET=${1:-${CTARGET}}
	local cpu=${CTARGET%%*-}

	if [[ ${CTARGET} = *-musl* ]]; then
		# musl has no multilib support and can run only in 'lib':
		# - https://bugs.gentoo.org/675954
		# - https://gcc.gnu.org/PR90077
		# - https://github.com/gentoo/musl/issues/245
		: "${MULTILIB_ABIS=default}"
		: "${DEFAULT_ABI=default}"
		export MULTILIB_ABIS DEFAULT_ABI
		return
	fi

	case ${cpu} in
		aarch64*)
			# Not possible to do multilib with aarch64 and a single toolchain.
			export CFLAGS_arm=${CFLAGS_arm-}
			case ${cpu} in
			aarch64*be) export CHOST_arm="armv8b-${CTARGET#*-}";;
			*)          export CHOST_arm="armv8l-${CTARGET#*-}";;
			esac
			CHOST_arm=${CHOST_arm/%-gnu/-gnueabi}
			export CTARGET_arm=${CHOST_arm}
			export LIBDIR_arm="lib"

			export CFLAGS_arm64=${CFLAGS_arm64-}
			export CHOST_arm64=${CTARGET}
			export CTARGET_arm64=${CHOST_arm64}
			export LIBDIR_arm64="lib64"

			: "${MULTILIB_ABIS=arm64}"
			: "${DEFAULT_ABI=arm64}"
		;;
		x86_64*)
			export CFLAGS_x86=${CFLAGS_x86--m32}
			export CHOST_x86=${CTARGET/x86_64/i686}
			CHOST_x86=${CHOST_x86/%-gnux32/-gnu}
			export CTARGET_x86=${CHOST_x86}
			if [[ ${SYMLINK_LIB} == "yes" ]] ; then
				[[ -z "${LIBDIR_x86}" ]] && export LIBDIR_x86="lib32"
			else
				[[ -z "${LIBDIR_x86}" ]] && export LIBDIR_x86="lib"
			fi

			export CFLAGS_amd64=${CFLAGS_amd64--m64}
			export CHOST_amd64=${CTARGET/%-gnux32/-gnu}
			export CTARGET_amd64=${CHOST_amd64}
			[[ -z "${LIBDIR_amd64}" ]] && export LIBDIR_amd64="lib64"

			export CFLAGS_x32=${CFLAGS_x32--mx32}
			export CHOST_x32=${CTARGET/%-gnu/-gnux32}
			export CTARGET_x32=${CHOST_x32}
			[[ -z "${LIBDIR_x32}" ]] && export LIBDIR_x32="libx32"

			case ${CTARGET} in
			*-gnux32)
				: "${MULTILIB_ABIS=x32 amd64 x86}"
				: "${DEFAULT_ABI=x32}"
				;;
			*)
				: "${MULTILIB_ABIS=amd64 x86}"
				: "${DEFAULT_ABI=amd64}"
				;;
			esac
		;;
		loongarch64*)
			export CFLAGS_lp64d=${CFLAGS_lp64d--mabi=lp64d}
			export CHOST_lp64d=${CTARGET}
			export CTARGET_lp64d=${CTARGET}
			export LIBDIR_lp64d=${LIBDIR_lp64d-lib64}

			: "${MULTILIB_ABIS=lp64d}"
			: "${DEFAULT_ABI=lp64d}"
		;;
		mips64*|mipsisa64*)
			export CFLAGS_o32=${CFLAGS_o32--mabi=32}
			export CHOST_o32=${CTARGET/mips64/mips}
			export CHOST_o32=${CHOST_o32/mipsisa64/mipsisa32}
			export CTARGET_o32=${CHOST_o32}
			export LIBDIR_o32="lib"

			export CFLAGS_n32=${CFLAGS_n32--mabi=n32}
			export CHOST_n32=${CTARGET}
			export CTARGET_n32=${CHOST_n32}
			export LIBDIR_n32="lib32"

			export CFLAGS_n64=${CFLAGS_n64--mabi=64}
			export CHOST_n64=${CTARGET}
			export CTARGET_n64=${CHOST_n64}
			export LIBDIR_n64="lib64"

			: "${MULTILIB_ABIS=n64 n32 o32}"
			: "${DEFAULT_ABI=n32}"
		;;
		powerpc64*)
			export CFLAGS_ppc=${CFLAGS_ppc--m32}
			export CHOST_ppc=${CTARGET/powerpc64/powerpc}
			export CTARGET_ppc=${CHOST_ppc}
			export LIBDIR_ppc="lib"

			export CFLAGS_ppc64=${CFLAGS_ppc64--m64}
			export CHOST_ppc64=${CTARGET}
			export CTARGET_ppc64=${CHOST_ppc64}
			export LIBDIR_ppc64="lib64"

			: "${MULTILIB_ABIS=ppc64 ppc}"
			: "${DEFAULT_ABI=ppc64}"
		;;
		riscv64*)
			: "${MULTILIB_ABIS=lp64d lp64 ilp32d ilp32}"
			: "${DEFAULT_ABI=lp64d}"

			# the default abi is set to the 1-level libdir default

			local _libdir_riscvdefaultabi_variable="LIBDIR_${DEFAULT_ABI}"
			local _libdir_riscvdefaultabi=${!_libdir_riscvdefaultabi_variable}
			export ${_libdir_riscvdefaultabi_variable}=${_libdir_riscvdefaultabi:-lib64}

			# all other abi are set to the 2-level libdir default

			export CFLAGS_lp64d=${CFLAGS_lp64d--mabi=lp64d -march=rv64gc}
			export CHOST_lp64d=${CTARGET}
			export CTARGET_lp64d=${CTARGET}
			export LIBDIR_lp64d=${LIBDIR_lp64d-lib64/lp64d}

			export CFLAGS_lp64=${CFLAGS_lp64--mabi=lp64 -march=rv64imac}
			export CHOST_lp64=${CTARGET}
			export CTARGET_lp64=${CTARGET}
			export LIBDIR_lp64=${LIBDIR_lp64-lib64/lp64}

			export CFLAGS_ilp32d=${CFLAGS_ilp32d--mabi=ilp32d -march=rv32imafdc}
			export CHOST_ilp32d=${CTARGET/riscv64/riscv32}
			export CTARGET_ilp32d=${CTARGET/riscv64/riscv32}
			export LIBDIR_ilp32d=${LIBDIR_ilp32d-lib32/ilp32d}

			export CFLAGS_ilp32=${CFLAGS_ilp32--mabi=ilp32 -march=rv32imac}
			export CHOST_ilp32=${CTARGET/riscv64/riscv32}
			export CTARGET_ilp32=${CTARGET/riscv64/riscv32}
			export LIBDIR_ilp32=${LIBDIR_ilp32-lib32/ilp32}
		;;
		riscv32*)
			: "${MULTILIB_ABIS=ilp32d ilp32}"
			: "${DEFAULT_ABI=ilp32d}"

			# the default abi is set to the 1-level libdir default

			local _libdir_riscvdefaultabi_variable="LIBDIR_${DEFAULT_ABI}"
			local _libdir_riscvdefaultabi=${!_libdir_riscvdefaultabi_variable}
			export ${_libdir_riscvdefaultabi_variable}=${_libdir_riscvdefaultabi:-lib}

			# all other abi are set to the 2-level libdir default

			export CFLAGS_ilp32d=${CFLAGS_ilp32d--mabi=ilp32d -march=rv32imafdc}
			export CHOST_ilp32d=${CTARGET}
			export CTARGET_ilp32d=${CTARGET}
			export LIBDIR_ilp32d=${LIBDIR_ilp32d-lib32/ilp32d}

			export CFLAGS_ilp32=${CFLAGS_ilp32--mabi=ilp32 -march=rv32imac}
			export CHOST_ilp32=${CTARGET}
			export CTARGET_ilp32=${CTARGET}
			export LIBDIR_ilp32=${LIBDIR_ilp32-lib32/ilp32}
		;;
		s390x*)
			export CFLAGS_s390=${CFLAGS_s390--m31} # the 31 is not a typo
			export CHOST_s390=${CTARGET/s390x/s390}
			export CTARGET_s390=${CHOST_s390}
			export LIBDIR_s390="lib"

			export CFLAGS_s390x=${CFLAGS_s390x--m64}
			export CHOST_s390x=${CTARGET}
			export CTARGET_s390x=${CHOST_s390x}
			export LIBDIR_s390x="lib64"

			: "${MULTILIB_ABIS=s390x s390}"
			: "${DEFAULT_ABI=s390x}"
		;;
		sparc64*)
			export CFLAGS_sparc32=${CFLAGS_sparc32--m32}
			export CHOST_sparc32=${CTARGET/sparc64/sparc}
			export CTARGET_sparc32=${CHOST_sparc32}
			export LIBDIR_sparc32="lib"

			export CFLAGS_sparc64=${CFLAGS_sparc64--m64}
			export CHOST_sparc64=${CTARGET}
			export CTARGET_sparc64=${CHOST_sparc64}
			export LIBDIR_sparc64="lib64"

			: "${MULTILIB_ABIS=sparc64 sparc32}"
			: "${DEFAULT_ABI=sparc64}"
		;;
		*)
			: "${MULTILIB_ABIS=default}"
			: "${DEFAULT_ABI=default}"
		;;
	esac

	export MULTILIB_ABIS DEFAULT_ABI
}

# @FUNCTION: multilib_toolchain_setup
# @DESCRIPTION:
# Hide multilib details here for packages which are forced to be compiled for a
# specific ABI when run on another ABI (like x86-specific packages on amd64)
multilib_toolchain_setup() {
	local v vv

	export ABI=$1

	local save_restore_variables=(
		CBUILD
		CHOST
		AR
		CC
		CXX
		F77
		FC
		LD
		NM
		OBJCOPY
		OBJDUMP
		PKG_CONFIG
		RANLIB
		READELF
		STRINGS
		STRIP
		PKG_CONFIG_LIBDIR
		PKG_CONFIG_PATH
		PKG_CONFIG_SYSTEM_INCLUDE_PATH
		PKG_CONFIG_SYSTEM_LIBRARY_PATH
	)

	# First restore any saved state we have laying around.
	if [[ ${_DEFAULT_ABI_SAVED} == "true" ]] ; then
		for v in "${save_restore_variables[@]}" ; do
			vv="_abi_saved_${v}"
			[[ ${!vv+set} == "set" ]] && export ${v}="${!vv}" || unset ${v}
			unset ${vv}
		done
		unset _DEFAULT_ABI_SAVED
	fi

	if [[ ${ABI} != ${DEFAULT_ABI} ]] ; then
		# Backup multilib state so we can restore it later
		for v in "${save_restore_variables[@]}" ; do
			vv="_abi_saved_${v}"
			[[ ${!v+set} == "set" ]] && export ${vv}="${!v}" || unset ${vv}
		done
		export _DEFAULT_ABI_SAVED="true"

		# Set CBUILD only if not cross-compiling.
		if [[ ${CBUILD} == "${CHOST}" ]]; then
			export CBUILD=$(get_abi_CHOST $1)
		fi

		# Set the CHOST native first so that we pick up the native
		# toolchain and not a cross-compiler by accident #202811.
		#
		# Make sure ${save_restore_variables[@]} list matches below.
		export CHOST=$(get_abi_CHOST ${DEFAULT_ABI})

		export AR="$(tc-getAR)" # Avoid 'ar', use '${CHOST}-ar'
		export CC="$(tc-getCC) $(get_abi_CFLAGS)"
		export CXX="$(tc-getCXX) $(get_abi_CFLAGS)"
		export F77="$(tc-getF77) $(get_abi_CFLAGS)"
		export FC="$(tc-getFC) $(get_abi_CFLAGS)"
		export LD="$(tc-getLD) $(get_abi_LDFLAGS)"
		export NM="$(tc-getNM)" # Avoid 'nm', use '${CHOST}-nm'
		export OBJCOPY="$(tc-getOBJCOPY)" # Avoid 'objcopy', use '${CHOST}-objcopy'
		export OBJDUMP="$(tc-getOBJDUMP)" # Avoid 'objdump', use '${CHOST}-objdump'
		export PKG_CONFIG="$(tc-getPKG_CONFIG)"
		export RANLIB="$(tc-getRANLIB)" # Avoid 'ranlib', use '${CHOST}-ranlib'
		export READELF="$(tc-getREADELF)" # Avoid 'readelf', use '${CHOST}-readelf'
		export STRINGS="$(tc-getSTRINGS)" # Avoid 'strings', use '${CHOST}-strings'
		export STRIP="$(tc-getSTRIP)" # Avoid 'strip', use '${CHOST}-strip'

		export CHOST=$(get_abi_CHOST $1)
		export PKG_CONFIG_LIBDIR=${EPREFIX}/usr/$(get_libdir)/pkgconfig
		export PKG_CONFIG_PATH=${EPREFIX}/usr/share/pkgconfig
		export PKG_CONFIG_SYSTEM_INCLUDE_PATH=${EPREFIX}/usr/include
		export PKG_CONFIG_SYSTEM_LIBRARY_PATH=${EPREFIX}/$(get_libdir):${EPREFIX}/usr/$(get_libdir)
	fi
}

fi
