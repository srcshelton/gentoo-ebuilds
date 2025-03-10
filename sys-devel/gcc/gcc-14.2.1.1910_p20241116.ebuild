# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

TOOLCHAIN_PATCH_DEV="sam"
TOOLCHAIN_HAS_TESTS=1
PATCH_GCC_VER="$(ver_cut 1-2).0"
PATCH_VER="3"
CLEAR_PATCH_VER="$(ver_cut 4)"
MUSL_VER="1"
MUSL_GCC_VER="$(ver_cut 1).1.0"
PYTHON_COMPAT=( python3_{10..12} )

PARALLEL_MEMORY_MIN=6

if [[ -n ${TOOLCHAIN_GCC_RC} ]] ; then
	# Cheesy hack for RCs
	MY_PV=$(ver_cut 1).$((($(ver_cut 2) + 1))).$((($(ver_cut 3) - 1)))-RC-$(ver_cut 6)
	MY_P=${PN}-${MY_PV}
	GCC_TARBALL_SRC_URI="mirror://gcc/snapshots/${MY_PV}/${MY_P}.tar.xz"
	TOOLCHAIN_SET_S=no
	S="${WORKDIR}"/${MY_P}
fi

inherit flag-o-matic toolchain usr-ldscript

if tc_is_live ; then
	# Needs to be after inherit (for now?), bug #830908
	EGIT_BRANCH=releases/gcc-$(ver_cut 1)
elif [[ -z ${TOOLCHAIN_USE_GIT_PATCHES} ]] ; then
	# m68k doesnt build (ICE, bug 932733)
	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86"
fi

SRC_URI="${SRC_URI}
	https://github.com/clearlinux-pkgs/${PN}/archive/refs/tags/${SLOT}.1.0-${CLEAR_PATCH_VER}.tar.gz"
RESTRICT="mirror"

IUSE="-lib-only"

if [[ ${CATEGORY} != cross-* ]] ; then
	# Technically only if USE=hardened *too* right now, but no point in
	# complicating it further.
	# If GCC is enabling CET by default, we need glibc to be built with support
	# for it.
	# bug #830454
	COMMON_DEPEND="elibc_glibc? ( sys-libs/glibc[cet(-)?] )"
	RDEPEND="${COMMON_DEPEND}
		!sys-devel/gcc-libs:${SLOT}"
	DEPEND="${COMMON_DEPEND}"
	BDEPEND="amd64? ( >=${CATEGORY}/binutils-2.30[cet(-)?] )
		sys-apps/texinfo
		sys-devel/flex"
fi

LIB_ONLY_GCC_CONFIG_FILES=( gcc-ld.so.conf gcc.env gcc.config gcc.defs )

pkg_pretend() {
	if is-flagq -fopenmp; then
		if ! _tc_use_if_iuse openmp; then
			ewarn "CFLAGS contains '-fopenmp' but USE flags do not contain" \
				"'openmp'"
			ewarn "Filtering flags '-fopenmp' ..."
			filter-flags -fopenmp
		fi
	fi

	toolchain_pkg_pretend
}

src_prepare() {
	local f='' d=''
	local -a upstreamed_patches=(
		# add them here
	)
	for f in "${upstreamed_patches[@]}"; do
		rm -v "${WORKDIR}/patch/${f}" || die
	done

	toolchain_src_prepare

	eapply "${FILESDIR}/${PN}-13-fix-cross-fixincludes.patch"

	# Apply additional Clear Linux patches, if present...
	# (%patch0 brings gcc from ${SLOT}.1.0 to the actual release)
	if [[ -d "${WORKDIR}/${PN}-${SLOT}.1.0-${CLEAR_PATCH_VER}" ]]; then
		d="${WORKDIR}/${PN}-${SLOT}.1.0-${CLEAR_PATCH_VER}"
		grep '^%patch' "${d}/${PN}.spec" |
			awk '{print $1}' |
			grep -v '^%patch0' |
			while read -r f; do
				grep -i "^${f#"%"}\s*:" "${d}/${PN}.spec"
			done |
			awk '{print $3}' |
			while read -r f; do
				nonfatal eapply "${d}/${f}" ||
					ewarn "Clear Linux ${PN}-${SLOT}.1.0-${CLEAR_PATCH_VER}" \
						"patch '${f}' failed to apply: ${?}"
			done
	fi

	if [[ "${ARCH}" == 'amd64' && "$( get_abi_LIBDIR x32 )" != 'libx32' ]]
	then
		einfo "Architecture is 'amd64' - adjusting default paths for" \
			"potential custom x32 ABI library paths"

		local LD32="$( get_abi_LIBDIR x86 )"
		local LDx32="$( get_abi_LIBDIR x32 )"
		local LD64="$( get_abi_LIBDIR amd64 )"

		einfo "Using the following libdir paths:"
		einfo "  32-bit libraries in '${LD32:=lib}'"
		einfo "  Long-mode 32-bit libraries in '${LDx32:=libx32}'"
		einfo "  64-bit libraries in '${LD64:=lib64}'"

		sed \
				-e "/^#define GLIBC_DYNAMIC_LINKER32 /{s:/lib/:/${LD32}/:}" \
				-e "/^#define GLIBC_DYNAMIC_LINKERX32 /{s:/libx32/:/${LDx32}/:}" \
				-e "/^#define GLIBC_DYNAMIC_LINKER64 /{s:/lib64/:/${LD64}/:}" \
				-i gcc/config/i386/linux64.h ||
			die 'linux64.h patch failed'
		einfo "Using the following GLIBC_DYNAMIC_LINKER defines:"
		einfo "$(
			grep -F 'GLIBC_DYNAMIC_LINKER' gcc/config/i386/linux64.h |
				sed 's/^/  /g'
		)"

		for f in linux gnu; do
			sed \
					-e "s:/lib has i386 libraries.$:/${LD32} has i386 libraries.:" \
					-e "s:/lib64 has x86-64 libraries.$:/${LD64} has x86-64 libraries.:" \
					-e "s:/libx32 has x32 libraries.$:/${LDx32} has x32 libraries.:" \
					-e "/^MULTILIB_OSDIRNAMES[+ ]= m64=/{s:=../lib64\\$:=../${LD64}$:}" \
					-e "/^MULTILIB_OSDIRNAMES[+ ]= m32=/{s:=\$(if \$(wildcard \$(shell echo \$(SYSTEM_HEADER_DIR))/../../usr/lib32),../lib32,../lib)\\$:../${LD32}$:}" \
					-e "/^MULTILIB_OSDIRNAMES[+ ]= mx32=/{s:=../libx32\\$:=../${LDx32}$:}" \
					-i "gcc/config/i386/t-${f}64" ||
				die "t-${f}64 patch failed"
			einfo "Using the following MULTILIB_OSDIRNAMES definitions in gcc/config/i386/t-${f}64:"
			einfo "$(
				grep -A $( wc -l < gcc/config/i386/t-${f}64 ) -m 1 '^# To support' gcc/config/i386/t-${f}64 |
					grep -v -e '^comma=' -e '^MULTILIB_OPTIONS' -e '^MULTILIB_DIRNAMES' |
					sed 's/^/  /g'
			)"
		done

		sed \
				-e "/^const char \*__gnat_default_libgcc_subdir = \"libx32\";$/{s:\"libx32\":\"${LDx32}\":}" \
				-i gcc/ada/link.c ||
			die 'link.c patch failed'
		einfo "Using the following GNAT/ADA declarations:"
		einfo "$(
			grep '__gnat_default_libgcc_subdir.*lib[36x]' gcc/ada/link.c |
				sed 's/^/  /g'
		)"

		einfo "Checking for further 'x32' references ..."
		output="$( grep -RHF 'libx32' gcc/ | grep -Ev 'GLIBC_DYNAMIC_LINKER|MULTILIB_OSDIRNAMES|gcc/ada/link.c|gcc/ada/ChangeLog-2012' )"
		if [[ -n "${output}" ]]; then
			ewarn "Further x32 references detected:"
			ewarn "${output}"
			die "x32 references detected"
		else
			einfo "... none found"
		fi
	fi

	eapply_user
}

src_configure() {
	local flag

	if (( ( $( # <- Syntax
			head /proc/meminfo |
				grep -m 1 '^MemAvailable:' |
				awk '{ print $2 }'
		) / ( 1024 * 1024 ) ) < PARALLEL_MEMORY_MIN ))
	then
		if [[ "${EMERGE_DEFAULT_OPTS:-}" == *-j* ]]; then
			ewarn "make.conf or environment contains parallel build directive,"
			ewarn "memory usage may be increased" \
				"(or adjust \$EMERGE_DEFAULT_OPTS)"
		fi
		ewarn "Lowering make parallelism for low-memory build-host ..."
		if ! [[ -n "${MAKEOPTS:-}" ]]; then
			export MAKEOPTS='-j1'
		elif ! [[ "${MAKEOPTS}" == *-j* ]]; then
			export MAKEOPTS="-j1 ${MAKEOPTS}"
		else
			export MAKEOPTS="-j1 $( sed 's/-j\s*[0-9]\+//' <<<"${MAKEOPTS}" )"
		fi
		if test-flag-CC '-Wa,--reduce-memory-overheads'; then
			ewarn "Instructing 'as' to use less memory ..."
			append-ldflags '-Wa,--reduce-memory-overheads'
		fi
		for flag in no-keep-memory reduce-memory-overheads \
			no-map-whole-files no-mmap-output-file
		do
			if test-flag-CCLD "-Wl,--${flag}"; then
				ewarn "Instructing 'ld' to use less memory with '--${flag}' ..."
				append-ldflags "-Wl,--${flag}"
			fi
		done
		ewarn "Disabling LTO support ..."
		filter-lto
	fi

	toolchain_src_configure
}

src_install() {
	local file='' dest='' destdir=''

	toolchain_src_install

	if use lib-only; then
		einfo "Removing non-library directories ..."

		mv "${ED%/}/usr/share/gcc-data/${CHOST:-fail}/$(ver_cut 1)" "${T}"/data || die
		mv "${ED%/}/usr/lib/gcc/${CHOST:-fail}/$(ver_cut 1)" "${T}"/lib || die
		mv "${ED%/}/usr/libexec/gcc/${CHOST:-fail}/$(ver_cut 1)" "${T}"/libexec || die

		rm -r "${ED}"/*

		mkdir -p "${ED%/}/usr/lib/gcc/${CHOST}" "${ED%/}/usr/libexec/gcc/${CHOST}" "${ED%/}/usr/share/gcc-data/${CHOST}" || die
		mv "${T}"/data "${ED%/}/usr/share/gcc-data/${CHOST}/$(ver_cut 1)" || die
		mv "${T}"/lib "${ED%/}/usr/lib/gcc/${CHOST}/$(ver_cut 1)" || die
		mv "${T}"/libexec "${ED%/}/usr/libexec/gcc/${CHOST}/$(ver_cut 1)" || die

		pushd "${ED%/}/usr/lib/gcc/${CHOST}/$(ver_cut 1)" >/dev/null || die
		rm -r include include-fixed plugin/include
		rm *.o *.a *.spec *.la plugin/gtype.state
		popd >/dev/null || die

		pushd "${ED%/}/usr/libexec/gcc/${CHOST}/$(ver_cut 1)" >/dev/null || die
		find . -mindepth 1 -maxdepth 1 -not -name '*.so' -exec rm -r {} +
		popd >/dev/null || die

		keepdir "/usr/${CHOST}/gcc-bin/$(ver_cut 1)"

		einfo "Writing static gcc-config configuration ..."

		for file in "${LIB_ONLY_GCC_CONFIG_FILES[@]}"; do
			case "${file}" in
				gcc-ld.so.conf)
					dest="/etc/ld.so.conf.d/05${PN}-${CHOST}.conf" ;;
				gcc.env)
					dest="/etc/env.d/04${PN}-${CHOST}" ;;
				gcc.config)
					dest="/etc/env.d/${PN}/config-${CHOST}" ;;
				gcc.defs)
					dest="/etc/env.d/${PN}/${CHOST}-$(ver_cut 1)" ;;
				*)
					die "Unknown file '${file}'" ;;
			esac
			sed <"${FILESDIR}/${file}" \
					-e "s/%CHOST%/${CHOST}/g" \
					-e "s/%PV%/$(ver_cut 1)/g" \
				>"${T}/${file}" || die "Failed templating file '${file}': ${?}"
			insinto "$( dirname "${dest}" )"
			newins "${T}/${file}" "$( basename "${dest}" )" || die "Writing gcc-config data to '${dest}' failed: ${?}"
		done
	fi
}

pkg_preinst_find_seq() {
	local file="${1:-}"

	[[ -n "${file:-}" ]] || return 1

	#if ! [[ -e "${file}" ]]; then
	#	printf '%s' "${file}"
	#	return 0
	#fi

	path="$( dirname "${file}" )"
	name="$( basename "${file}" )"

	local -i counter=0

	while [[ -e "$( printf '%s/._cfg%04d_%s' "${path}" ${counter} "${name}" )" ]]; do
		(( counter++ ))
	done

	printf '%s/._cfg%04d_%s' "${path}" ${counter} "${name}"
} # pkg_preinst_find_seq

pkg_preinst() {
	local src='' dest=''

	if use lib-only; then
		for file in "${LIB_ONLY_GCC_CONFIG_FILES[@]}"; do
			case "${file}" in
				gcc-ld.so.conf)
					src="/etc/ld.so.conf.d/05${PN}-${CHOST}.conf" ;;
				gcc.env)
					src="/etc/env.d/04${PN}-${CHOST}" ;;
				gcc.config)
					src="/etc/env.d/${PN}/config-${CHOST}" ;;
				gcc.defs)
					src="/etc/env.d/${PN}/${CHOST}-$(ver_cut 1)" ;;
				*)
					die "Unknown file '${file}'" ;;
			esac
			if [[ -e "${src}" ]]; then
				dest="$( pkg_preinst_find_seq "${src}" )" || die "Failed to generate sequence for file '${src}': ${?}"
				mv "${src}" "${dest}" || die "Moving gcc-config data from '${ED%/}/${src}' to '${ED%/}${dest}' failed: ${?}"
			fi
		done
	fi
}

pkg_postinst_fix_so() {
	local src_dir="${1:-}"
	local src_so="${2:-}"
	local dst_dir="${3:-}"
	local dst_rel="${4:-}"

	local so=''

	[[ -d "${src_dir:-}/" ]] || return 1
	[[ -d "${dst_dir:-}/" ]] || return 1
	ls "${src_dir}/${src_so}".so* >/dev/null 2>&1 || return 1

	while read -r so; do
		so="$( basename "${so}" )"
		einfo "Making '${src_dir%/}/${so}' available in '${dst_dir}/' ..."
		if [[ -e "${dst_dir}/${so}" ]] && ! [[ -L "${dst_dir}/${so}" ]]; then
			ewarn "Not replacing non-symlink '${dst_dir%/}/${so}'"
		else
			if [[ -n "${dst_rel:-}" ]]; then
				if [[ -s "${dst_dir}/${dst_rel}/${so}" ]]; then
					ln -sf "${dst_rel}/${so}" "${dst_dir}/${so}"
				else
					warn "Could not resolve path '${dst_dir}/${dst_rel}/${so}', creating absolute symlink ..."
					ln -sf "${src_dir}/${so}" "${dst_dir}/${so}"
				fi
			else
				ln -sf "${src_dir}/${so}" "${dst_dir}/${so}"
			fi
		fi
	done < <( ls -1 "${src_dir}/${src_so}".so* )

	return 0
} # pkg_postinst_fix_so

pkg_postinst() {
	pkg_config

	if use lib-only; then
		for file in "${LIB_ONLY_GCC_CONFIG_FILES[@]}"; do
			case "${file}" in
				gcc-ld.so.conf)
					dest="/etc/ld.so.conf.d/05${PN}-${CHOST}.conf" ;;
				gcc.env)
					dest="/etc/env.d/04${PN}-${CHOST}" ;;
				gcc.config)
					dest="/etc/env.d/${PN}/config-${CHOST}" ;;
				gcc.defs)
					dest="/etc/env.d/${PN}/${CHOST}-$(ver_cut 1)" ;;
				*)
					die "Unknown file '${file}'" ;;
			esac
			if ! [[ -e "${dest}" ]]; then
				path="$( dirname "${dest}" )"
				name="$( basename "${dest}" )"
				if [[ -e "${path}/._cfg0000_${name}" && ! -e "${dest}" ]]; then
					mv "${path}/._cfg0000_${name}" "${dest}" || die "Moving gcc-config data from '${path}._cfg0000_${name}' to '${dest}' failed: ${?}"
				fi
			fi
		done
	fi
}

pkg_config() {
	local best="$( best_version "${CATEGORY}/${PN}" )"
	local file='' dest='' path='' name=''

	if use lib-only || use split-usr; then
		if [[ -n "${best}" ]] && [[ "${CATEGORY}/${PF}" != "${best}" ]]; then
			einfo "Not updating library directory, latest version is '${best}' (this is '${CATEGORY}/${PF}')"
		else
			for file in libstdc++ libgcc_s $(usex openmp 'libgomp' ''); do
				find "${EROOT}/usr/$(get_libdir)" -name "${file}.so*" -type l -exec rm -v {} +
				pkg_postinst_fix_so \
						"${EROOT}/usr/lib/gcc/${CHOST}/$(ver_cut 1)" \
						"${file}" \
						"${EROOT}/usr/$(get_libdir)" \
						"../lib/gcc/${CHOST}/$(ver_cut 1)" ||
					die "Couldn't link library '${file}.so'*"
			done
			for file in libatomic; do
				find "${EROOT}/usr/$(get_libdir)" -name "${file}.so*" -exec rm -v {} +
				find "${EROOT}/usr/lib/gcc/${CHOST}/$(ver_cut 1)" -name "${file}.so*" -print0 |
					xargs -0rI '{}' cp -av {} "${EROOT}/usr/$(get_libdir)/"
				gen_usr_ldscript --live -a "${file#lib}"
			done

		fi
	fi
}

# vi: set diffopt=filler,iwhite:
