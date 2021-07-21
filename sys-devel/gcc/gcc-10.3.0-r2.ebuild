# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PATCH_VER="3"

inherit toolchain

KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="-lib-only"

RDEPEND="
	!=sys-devel/gcc-libs-${PV}"
BDEPEND="${CATEGORY}/binutils"

src_prepare() {
	if has_version '>=sys-libs/glibc-2.32-r1'; then
		rm -v "${WORKDIR}/patch/23_all_disable-riscv32-ABIs.patch" || die
	fi

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
