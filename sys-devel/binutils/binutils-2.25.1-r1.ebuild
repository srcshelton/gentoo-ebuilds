# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 6e65a7795a9e0bb7a294823b400b9cfd5be98808 $

EAPI="4"

PATCHVER="1.1"
ELF2FLT_VER=""
inherit toolchain-binutils

KEYWORDS="alpha amd64 ~arm arm64 ~hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd -sparc-fbsd ~x86-fbsd"

src_prepare() {
	toolchain-binutils_src_prepare

	if [[ "${ARCH}" == "amd64" ]]; then
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
