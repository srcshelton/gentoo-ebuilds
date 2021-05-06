# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PATCH_VER="4"

inherit toolchain

KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="-lib-only"

RDEPEND="
	!=sys-devel/gcc-libs-${PV}"
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

src_prepare() {
	toolchain_src_prepare

	if [[ "${ARCH}" == 'amd64' ]]; then
		local LD32="$( get_abi_LIBDIR x86 )"
		local LDx32="$( get_abi_LIBDIR x32 )"
		local LD64="$( get_abi_LIBDIR amd64 )"
		sed -i \
			-e "/^#define GLIBC_DYNAMIC_LINKER32/{s:/lib/:/${LD32:-lib}/:}" \
			-e "/^#define GLIBC_DYNAMIC_LINKERX32/{s:/libx32/:/${LDx32:-libx32}/:}" \
			-e "/^#define GLIBC_DYNAMIC_LINKER64/{s:/lib64/:/${LD64:-lib64}/:}" \
				gcc/config/i386/linux64.h \
			|| die 'LIBDIR replacement failed'

		einfo "Using the following LIBDIR defines:"
		grep 'GLIBC_DYNAMIC_LINKER' gcc/config/i386/linux64.h

		sed -i \
			-e "/^MULTILIB_OSDIRNAMES[+ ]= m64=/{s:=../lib64$:=../${LD64:-lib64}:}" \
			-e "/^MULTILIB_OSDIRNAMES[+ ]= m32=/{s:=\$(if \$(wildcard \$(shell echo \$(SYSTEM_HEADER_DIR))/../../usr/lib32),../lib32,../lib):../${LD32:-lib}/:}" \
			-e "/^MULTILIB_OSDIRNAMES[+ ]= mx32=/{s:=../libx32$:=../${LDx32:-libx32}:}" \
				gcc/config/i386/t-linux64 \
			|| die 'DIRNAMES replacement failed'

		einfo "Using the following DIRNAMES defines:"
		grep 'MULTILIB_OSDIRNAMES' gcc/config/i386/t-linux64

		sed -i \
			-e "/^const char \*__gnat_default_libgcc_subdir = \"libx32\";$/{s:\"libx32\":\"${LDx32:-libx32}\":}" \
				gcc/ada/link.c \
			|| die 'ADA replacement failed'

		einfo "Further x32 references detected:"
		grep -RHF 'libx32' gcc/ | grep -Ev 'GLIBC_DYNAMIC_LINKER|MULTILIB_OSDIRNAMES|gcc/ada/link.c'
	fi
}

src_install() {
	toolchain_src_install

	if use lib-only; then
		einfo "Removing non-library directories..."

		mv "${ED%/}/usr/share/gcc-data/${CHOST:-fail}/${PV}" "${T}"/data || die
		mv "${ED%/}/usr/lib/gcc/${CHOST:-fail}/${PV}" "${T}"/lib || die
		mv "${ED%/}/usr/libexec/gcc/${CHOST:-fail}/${PV}" "${T}"/libexec || die

		rm -r "${ED}"/*

		mkdir -p "${ED%/}/usr/lib/gcc/${CHOST}" "${ED%/}/usr/libexec/gcc/${CHOST}" "${ED%/}/usr/share/gcc-data/${CHOST}" || die
		mv "${T}"/data "${ED%/}/usr/share/gcc-data/${CHOST}/${PV}" || die
		mv "${T}"/lib "${ED%/}/usr/lib/gcc/${CHOST}/${PV}" || die
		mv "${T}"/libexec "${ED%/}/usr/libexec/gcc/${CHOST}/${PV}" || die

		pushd "${ED%/}/usr/lib/gcc/${CHOST}/${PV}" >/dev/null || die
		rm -r include include-fixed plugin/include
		rm *.o *.a *.spec *.la plugin/gtype.state
		popd >/dev/null || die

		pushd "${ED%/}/usr/libexec/gcc/${CHOST}/${PV}" >/dev/null || die
		rm -r plugin
		ls -1 | grep -v '.so' | xargs rm
		popd >/dev/null || die

		keepdir "/usr/${CHOST}/gcc-bin/${PV}"
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
	ls "${src_dir}/${src_so}"* >/dev/null 2>&1 || return 1

	while read -r so; do
		so="$( basename "${so}" )"
		einfo "Making '${src_dir%/}/${so}' available in '${dst_dir}/' ..."
		if [[ -e "${dst_dir}/${so}" ]] && ! [[ -L "${dst_dir}/${so}" ]]; then
			ewarn "Not replacing non-symlink '${dst_dir%/}/${so}'"
		else
			if [[ -n "${dst_rel:-}" ]]; then
				if [[ -s "${dst_dir}/${dst_rel}/${so}" ]]; then
					ln -s "${dst_rel}/${so}" "${dst_dir}/${so}"
				else
					warn "Could not resolve path '${dst_dir}/${dst_rel}/${so}', creating absolute symlink ..."
					ln -s "${src_dir}/${so}" "${dst_dir}/${so}"
				fi
			else
				ln -s "${src_dir}/${so}" "${dst_dir}/${so}"
			fi
		fi
	done < <( ls -1 "${src_dir}/${src_so}"* )

	return 0
} # pkg_postinst_fix_so

pkg_postinst() {
	local best="$( best_version "${CATEGORY}/${PN}" )"

	if use lib-only; then
		if [[ -n "${best}" ]] && [[ "${CATEGORY}/${PF}" != "${best}" ]]; then
			einfo "Not updating library directory, latest version is '${best}' (this is '${CATEGORY}/${PF}')"
		else
			pkg_postinst_fix_so "${EROOT}/usr/lib/gcc/${CHOST}/${PV}" 'libstdc++.so' "${EROOT}/usr/$(get_libdir)" "../lib/gcc/${CHOST}/${PV}" ||
				die "Couldn't link library 'libstdc++.so'"
			pkg_postinst_fix_so "${EROOT}/usr/lib/gcc/${CHOST}/${PV}" 'libgcc_s.so' "${EROOT}/usr/$(get_libdir)" "../lib/gcc/${CHOST}/${PV}" ||
				die "Couldn't link library 'libgcc_s.so'"
		fi
	fi
}

# vi: set diffopt=iwhite,filler:
