# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson-multilib usr-ldscript

DESCRIPTION="Extremely Fast Compression algorithm"
HOMEPAGE="https://github.com/lz4/lz4"
SRC_URI="https://github.com/lz4/lz4/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD-2 GPL-2"
SLOT="0/1.10.0-meson"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="static-libs systemd test"
RESTRICT="!test? ( test )"

EMESON_SOURCE=${S}/build/meson

PATCHES=(
	"${FILESDIR}/${PV}-fix-freestanding-test.patch"
	# https://github.com/lz4/lz4/pull/1485
	"${FILESDIR}/${PV}-meson-do-not-force-c99-mode.patch"
)

multilib_src_configure() {
	local emesonargs=(
		-Dtests=$(usex test true false)
		-Ddefault_library=$(usex static-libs both shared)
		# https://bugs.gentoo.org/940641
		-Dossfuzz=false
	)
	# with -Dprograms=false, the test suite is only rudimentary,
	# so build them for testing non-native ABI as well
	if multilib_is_native_abi || use test; then
		emesonargs+=(
			-Dprograms=true
		)
	fi

	meson_src_configure
}

multilib_src_install() {
	meson_src_install

	if multilib_is_native_abi && use systemd; then
		# lib64/libsystemd.so.0.37.0: liblz4.so.1 => /usr/lib64/liblz4.so.1
		gen_usr_ldscript -a lz4
	fi
}
