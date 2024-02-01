# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: usr-ldscript.eclass
# @MAINTAINER:
# Toolchain Ninjas <toolchain@gentoo.org>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: Defines the gen_usr_ldscript function.

case ${EAPI} in
	7|8) ;;
	*)
		# Silence warnings due to sys-apps/util-linux-2.33.2::unifi
		#
		# ... there doesn't seem to be any way to find the package repo from
		# within an eclass?

		if
			[[ "${CATEGORY:-}" == 'sys-apps' ]] &&
			[[ "${PN:-}" == 'util-linux' ]] &&
			[[ "${PV:-}" == '2.33.2' ]]
		then
			#ewarn "${ECLASS}: EAPI ${EAPI:-0} not supported"
			return 0
		else
			die "${ECLASS}: EAPI ${EAPI:-0} not supported"
		fi
		;;
esac

if [[ -z ${_USR_LDSCRIPT_ECLASS} ]]; then
_USR_LDSCRIPT_ECLASS=1

inherit multilib toolchain-funcs

IUSE="split-usr"

# ... for 'scanelf':
BDEPEND="app-misc/pax-utils"
DEPEND="${BDEPEND}"

# @FUNCTION: gen_usr_ldscript
# @USAGE: [-a] <list of libs to create linker scripts for>
# @DESCRIPTION:
# This function generate linker scripts in /usr/lib for dynamic
# libs in /lib.  This is to fix linking problems when you have
# the .so in /lib, and the .a in /usr/lib.  What happens is that
# in some cases when linking dynamic, the .a in /usr/lib is used
# instead of the .so in /lib due to gcc/libtool tweaking ld's
# library search path.  This causes many builds to fail.
# See bug #4411 for more info.
#
# Note that you should in general use the unversioned name of
# the library (libfoo.so), as ldconfig should usually update it
# correctly to point to the latest version of the library present.
gen_usr_ldscript() {
	local lib libdir="$(get_libdir)" output_format='' auto='false' suffix="$(get_libname)" ed="${ED:-}"
	local -i preexisting=0

	tc-is-static-only && return
	use prefix && return

	# The toolchain's sysroot is automatically prepended to paths in this
	# script. We therefore need to omit EPREFIX on standalone prefix (RAP)
	# systems. prefix-guest (non-RAP) systems don't apply a sysroot so EPREFIX
	# is still needed in that case. This is moot because the above line makes
	# the function a noop on prefix, but we keep this in case that changes.
	local prefix=$(usex prefix-guest "${EPREFIX}" "")

	# We only care about stuffing / for the native ABI. #479448
	if [[ $(type -t multilib_is_native_abi) == "function" ]] ; then
		multilib_is_native_abi || return 0
	fi

	# Eventually we'd like to get rid of this func completely #417451
	case ${CTARGET:-${CHOST}} in
	*-darwin*) ;;
	*-android*) return 0 ;;
	*linux*)
		use split-usr || return 0
		;;
	*) return 0 ;;
	esac

	if [[ "${1}" == "--live" ]] ; then
		ed="${ROOT:-}"
		ed="${ed%/}"
		shift
	fi

	# Just make sure it exists
	if ! [[ -d "${ed}/usr/${libdir}" ]]; then
		mkdir -p "${ed}/usr/${libdir}"
		chown root:root "${ed}/usr/${libdir}"
		chmod 0755 "${ed}/usr/${libdir}"
	fi

	if [[ "${1}" == '-a' ]] ; then
		auto=true
		shift
		if ! [[ -d "${ed}/${libdir}" ]]; then
			mkdir -p "${ed}/${libdir}"
			chown root:root "${ed}/${libdir}"
			chmod 0755 "${ed}/${libdir}"
		fi
	fi

	# OUTPUT_FORMAT gives hints to the linker as to what binary format
	# is referenced ... makes multilib saner
	local flags=( ${CFLAGS} ${LDFLAGS} -Wl,--verbose )
	if type -pf $(tc-getLD) &>/dev/null && $(tc-getLD) --version | grep -q 'GNU gold' ; then
		# If they're using gold, manually invoke the old bfd. #487696
		local d="${T}/bfd-linker"
		mkdir -p "${d}"
		ln -sf "$( type -P "${CHOST}-ld.bfd" )" "${d}"/ld
		flags+=( -B"${d}" )
	fi
	output_format=$($(tc-getCC) "${flags[@]}" 2>&1 | sed -n 's/^OUTPUT_FORMAT("\([^"]*\)",.*/\1/p')
	[[ -n ${output_format} ]] && output_format="OUTPUT_FORMAT ( ${output_format} )"

	for lib in "$@" ; do
		local tlib
		if ${auto} ; then
			lib="lib${lib}${suffix}"
		else
			# Ensure /lib/${lib} exists to avoid dangling scripts/symlinks.
			# This especially is for AIX where $(get_libname) can return ".a",
			# so /lib/${lib} might be moved to /usr/lib/${lib} (by accident).
			[[ -r ${ed}/${libdir}/${lib} ]] || die "Unable to read non-automatic source library '${ed}/${libdir}/${lib}': ${?}"
		fi

		case ${CTARGET:-${CHOST}} in
		*-darwin*)
			if ${auto} ; then
				tlib=$(scanmacho -qF'%S#F' "${ed}"/usr/${libdir}/${lib})
			else
				tlib=$(scanmacho -qF'%S#F' "${ed}"/${libdir}/${lib})
			fi
			[[ -z ${tlib} ]] && die "unable to read install_name from ${lib}"
			tlib=${tlib##*/}

			if ${auto} ; then
				mv "${ed}"/usr/${libdir}/${lib%${suffix}}.*${suffix#.} "${ed}"/${libdir}/ || die
				# some install_names are funky: they encode a version
				if [[ ${tlib} != ${lib%${suffix}}.*${suffix#.} ]] ; then
					mv "${ed}"/usr/${libdir}/${tlib%${suffix}}.*${suffix#.} "${ed}"/${libdir}/ || die
				fi
				rm -f "${ed}"/${libdir}/${lib}
			fi

			# Mach-O files have an id, which is like a soname, it tells how
			# another object linking against this lib should reference it.
			# Since we moved the lib from usr/lib into lib this reference is
			# wrong.  Hence, we update it here.  We don't configure with
			# libdir=/lib because that messes up libtool files.
			# Make sure we don't lose the specific version, so just modify the
			# existing install_name
			if [[ ! -w "${ed}/${libdir}/${tlib}" ]] ; then
				chmod u+w "${ed}/${libdir}/${tlib}" || die # needed to write to it
				local nowrite=yes
			fi
			install_name_tool \
				-id "${EPREFIX}"/${libdir}/${tlib} \
				"${ed}"/${libdir}/${tlib} || die "install_name_tool failed"
			if [[ -n ${nowrite} ]] ; then
				chmod u-w "${ed}/${libdir}/${tlib}" || die
			fi
			# Now as we don't use GNU binutils and our linker doesn't
			# understand linker scripts, just create a symlink.
			pushd "${ed}/usr/${libdir}" >/dev/null
			ln -snf "../../${libdir}/${tlib}" "${lib}"
			popd >/dev/null
			;;
		*)
			if ${auto}; then
				if ! [[ -s "${ed}/usr/${libdir}/${lib}" ]]; then
					die "file '${ed}/usr/${libdir}/${lib}' is missing"
				fi
				tlib="$( scanelf -qF'%S#F' "${ed}/usr/${libdir}/${lib}" )"
				if [[ -z "${tlib:-}" ]]; then
					if ! type -P file >/dev/null 2>&1; then
						ewarn "command 'file' not found"
					fi
					if
						file "${ed}/usr/${libdir}/${lib}" 2>/dev/null |
							grep -q -- 'ASCII text$' ||
						grep -aq -- 'GNU ld script' "${ed}/usr/${libdir}/${lib}"
					then
						ewarn "file '${ed}/usr/${libdir}/${lib}' is already a linker script"
						if [[ -x "${ed}/usr/${libdir}/${lib}" ]] && (( $(
								find "${ed}/${libdir}"/ -name "${tlib}*" -print 2>/dev/null | wc -l
						) )); then
							return 0
						else
							#
							# libbsd is now writing a linker script in order to
							# pull-in libmd for MD5 operations...
							if grep -q -- '/usr/' "${ed}/usr/${libdir}/${lib}"; then
								sed -e 's|/usr/|/|g' \
									-i "${ed}/usr/${libdir}/${lib}"
								ewarn "Existing linker-script updated - new content:"
								ewarn "$( cat "${ed}/usr/${libdir}/${lib}" )"
								preexisting=1
							else
								die "However, the library does not appear to have been correctly relocated"
							fi
						fi
					fi
					if ! (( preexisting )); then
						die "unable to read SONAME from ${lib}" \
							"('scanelf -qF'%S#F' \"${ed}/usr/${libdir}/${lib}\"' returned '$(
								scanelf -qF'%S#F' "${ed}"/usr/${libdir}/${lib}
							)': ${?})"
					fi
				fi
				mv "${ed}/usr/${libdir}/${lib}"* "${ed}/${libdir}"/ || die
				# some SONAMEs are funky: they encode a version before the .so
				if [[ ${tlib} != ${lib}* ]] ; then
					mv "${ed}/usr/${libdir}/${tlib}"* "${ed}/${libdir}"/ || die
				fi
				if (( preexisting )); then
					mv "${ed}/${libdir}/${lib}" "${ed}/usr/${libdir}"/
					mv "${ed}/${libdir}/${lib%.so}"*.{a,la} "${ed}/usr/${libdir}"/
				else
					rm -f "${ed}/${libdir}/${lib}"
				fi
			else # if ! ${auto}; then
				tlib=${lib}
			fi
			if ! (( preexisting )); then
				cat > "${ed}/usr/${libdir}/${lib}" <<-END_LDSCRIPT
				/* GNU ld script
				   Since Gentoo has critical dynamic libraries in /lib, and the static versions
				   in /usr/lib, we need to have a "fake" dynamic lib in /usr/lib, otherwise we
				   run into linking problems.  This "fake" dynamic lib is a linker script that
				   redirects the linker to the real lib.  And yes, this works in the cross-
				   compiling scenario as the sysroot-ed linker will prepend the real path.

				   See bug https://bugs.gentoo.org/4411 for more info.
				 */
				${output_format}
				GROUP ( ${prefix}/${libdir}/${tlib} )
				END_LDSCRIPT
			fi
			;;
		esac
		if ! (( preexisting )); then
			chmod a+x "${ed}/usr/${libdir}/${lib}" || die "could not change perms on ${lib}"
		fi
	done
}

fi # _USR_LDSCRIPT_ECLASS

# vi: set diffopt=filler,icase,iwhite:
