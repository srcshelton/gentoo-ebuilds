# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCHVER="3"
ELF2FLT_VER=""
inherit toolchain-binutils

KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh ~sparc x86 ~amd64-fbsd ~x86-fbsd"

PATCHES=( "${FILESDIR}/${P}-nogoldtest.patch" )

src_prepare() {
	default

	if [[ "${ARCH}" == "amd64" ]]; then
		einfo "Updating lib(x)32 paths on AMD64 ..."

		#local LD32="$( get_abi_LIBDIR x86 )"
		local LDx32="$( get_abi_LIBDIR x32 )"
		#local LD64="$( get_abi_LIBDIR amd64 )"

		LDx32="${LDx32:-libx32}"

		sed -i \
			-e "/program interpreter$/{s:\"/libx32/ldx32.so.1\":\"/${LDx32}/ldx32.so.1\":}" \
				gold/x86_64.cc \
			|| die 'program interpreter replacement failed'
		sed -i \
		    -e "/LIBPATH_SUFFIX=/{s:=x32$:=${LDx32#lib}:}" \
			    ld/emulparams/elf32_x86_64.sh \
			|| die 'elf32_x86_64.sh patch failed'
	fi
}
