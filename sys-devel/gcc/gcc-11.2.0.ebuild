# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

TOOLCHAIN_PATCH_DEV="slyfox"
PATCH_VER="1"
MUSL_VER="1"

inherit toolchain

KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="-lib-only"

RDEPEND="
	!=sys-devel/gcc-libs-${PV}"
BDEPEND="${CATEGORY}/binutils"

src_prepare() {
	toolchain_src_prepare

	if tc-is-cross-compiler ; then
		# bug #803371
		eapply "${FILESDIR}"/gcc-11.2.0-cross-compile-include.patch
	fi

	eapply_user

	if [[ "${ARCH}" == 'amd64' && "$( get_abi_LIBDIR x32 )" != 'libx32' ]]; then
		einfo "Architecture is 'amd64' - adjusting default paths for potential custom x32 ABI library paths"

		local LD32="$( get_abi_LIBDIR x86 )"
		local LDx32="$( get_abi_LIBDIR x32 )"
		local LD64="$( get_abi_LIBDIR amd64 )"

		einfo "Using the following libdir paths:"
		einfo "  32-bit libraries in '${LD32:=lib}'"
		einfo "  Long-mode 32-bit libraries in '${LDx32:=libx32}'"
		einfo "  64-bit libraries in '${LD64:=lib64}'"

		sed -i \
			-e "/^#define GLIBC_DYNAMIC_LINKER32 /{s:/lib/:/${LD32}/:}" \
			-e "/^#define GLIBC_DYNAMIC_LINKERX32 /{s:/libx32/:/${LDx32}/:}" \
			-e "/^#define GLIBC_DYNAMIC_LINKER64 /{s:/lib64/:/${LD64}/:}" \
				gcc/config/i386/linux64.h \
			|| die 'linux64.h patch failed'
		einfo "Using the following GLIBC_DYNAMIC_LINKER defines:"
		einfo "$(
			grep -F 'GLIBC_DYNAMIC_LINKER' gcc/config/i386/linux64.h |
			sed 's/^/  /g'
		)"

		sed -i \
			-e "s:/lib has i386 libraries.$:/${LD32} has i386 libraries.:" \
			-e "s:/lib64 has x86-64 libraries.$:/${LD64} has x86-64 libraries.:" \
			-e "s:/libx32 has x32 libraries.$:/${LDx32} has x32 libraries.:" \
			-e "/^MULTILIB_OSDIRNAMES[+ ]= m64=/{s:=../lib64\\$:=../${LD64}$:}" \
			-e "/^MULTILIB_OSDIRNAMES[+ ]= m32=/{s:=\$(if \$(wildcard \$(shell echo \$(SYSTEM_HEADER_DIR))/../../usr/lib32),../lib32,../lib)\\$:../${LD32}$:}" \
			-e "/^MULTILIB_OSDIRNAMES[+ ]= mx32=/{s:=../libx32\\$:=../${LDx32}$:}" \
				gcc/config/i386/t-linux64 \
			|| die 't-linux64 patch failed'
		einfo "Using the following MULTILIB_OSDIRNAMES definitions:"
		einfo "$(
			grep -A $( wc -l < gcc/config/i386/t-linux64 ) -m 1 '^# To support' gcc/config/i386/t-linux64 |
			grep -v -e '^comma=' -e '^MULTILIB_OPTIONS' -e '^MULTILIB_DIRNAMES' |
			sed 's/^/  /g'
		)"

		sed -i \
			-e "/^const char \*__gnat_default_libgcc_subdir = \"libx32\";$/{s:\"libx32\":\"${LDx32}\":}" \
				gcc/ada/link.c \
			|| die 'link.c patch failed'
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
			sleep 10
		else
			einfo "... none found"
		fi
	fi
}

src_install() {
	toolchain_src_install

	if use lib-only; then
		einfo "Removing non-library directories..."

		mv "${ED%/}/usr/share/gcc-data/${CHOST:-fail}/${PV%_p*}" "${T}"/data || die
		mv "${ED%/}/usr/lib/gcc/${CHOST:-fail}/${PV%_p*}" "${T}"/lib || die
		mv "${ED%/}/usr/libexec/gcc/${CHOST:-fail}/${PV%_p*}" "${T}"/libexec || die

		rm -r "${ED}"/*

		mkdir -p "${ED%/}/usr/lib/gcc/${CHOST}" "${ED%/}/usr/libexec/gcc/${CHOST}" "${ED%/}/usr/share/gcc-data/${CHOST}" || die
		mv "${T}"/data "${ED%/}/usr/share/gcc-data/${CHOST}/${PV%_p*}" || die
		mv "${T}"/lib "${ED%/}/usr/lib/gcc/${CHOST}/${PV%_p*}" || die
		mv "${T}"/libexec "${ED%/}/usr/libexec/gcc/${CHOST}/${PV%_p*}" || die

		pushd "${ED%/}/usr/lib/gcc/${CHOST}/${PV%_p*}" >/dev/null || die
		rm -r include include-fixed plugin/include
		rm *.o *.a *.spec *.la plugin/gtype.state
		popd >/dev/null || die

		pushd "${ED%/}/usr/libexec/gcc/${CHOST}/${PV%_p*}" >/dev/null || die
		rm -r plugin
		ls -1 | grep -v '.so' | xargs rm
		popd >/dev/null || die

		keepdir "/usr/${CHOST}/gcc-bin/${PV%_p*}"
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
					ln -sf "${dst_rel}/${so}" "${dst_dir}/${so}"
				else
					warn "Could not resolve path '${dst_dir}/${dst_rel}/${so}', creating absolute symlink ..."
					ln -sf "${src_dir}/${so}" "${dst_dir}/${so}"
				fi
			else
				ln -sf "${src_dir}/${so}" "${dst_dir}/${so}"
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
			pkg_postinst_fix_so "${EROOT}/usr/lib/gcc/${CHOST}/${PV%_p*}" 'libstdc++.so' "${EROOT}/usr/$(get_libdir)" "../lib/gcc/${CHOST}/${PV%_p*}" ||
				die "Couldn't link library 'libstdc++.so'"
			pkg_postinst_fix_so "${EROOT}/usr/lib/gcc/${CHOST}/${PV%_p*}" 'libgcc_s.so' "${EROOT}/usr/$(get_libdir)" "../lib/gcc/${CHOST}/${PV%_p*}" ||
				die "Couldn't link library 'libgcc_s.so'"
		fi
	fi
}

# vi: set diffopt=iwhite,filler:
