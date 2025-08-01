# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit dot-a meson-multilib usr-ldscript

DESCRIPTION="zstd fast compression library"
HOMEPAGE="https://facebook.github.io/zstd/"
SRC_URI="https://github.com/facebook/zstd/releases/download/v${PV}/${P}.tar.gz"
S="${WORKDIR}"/${P}/build/meson

LICENSE="|| ( BSD GPL-2 )"
SLOT="0/1"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="+contrib lz4 +lzma static-libs test zlib"
RESTRICT="!test? ( test )"

RDEPEND="
	lzma? ( app-arch/xz-utils )
	lz4? ( app-arch/lz4:= )
	zlib? ( sys-libs/zlib )
"
DEPEND="${RDEPEND}"
# Despite meson-multilib.eclass inheriting meson.eclass which inherits
# ninja-utils.eclass which has a BDEPEND for app-alternatives/ninja, dependency
# resolution for app-arch/zstd is not pulling-in dev-build/ninja with
# sys-apps/portage-3.0.67 :(
BDEPEND=">=dev-build/ninja-1.8.2"

MESON_PATCHES=(
	# Workaround until Valgrind bugfix lands
	"${FILESDIR}"/${PN}-1.5.4-no-find-valgrind.patch
)

PATCHES=(
	"${FILESDIR}"/${PN}-1.5.7-move-pragma-before-static.patch
)

src_prepare() {
	cd "${WORKDIR}"/${P} || die
	default

	cd "${S}" || die
	eapply "${MESON_PATCHES[@]}"
}

src_configure() {
	use static-libs && lto-guarantee-fat
	multilib-minimal_src_configure
}

multilib_src_configure() {
	local native_file="${T}"/meson.${CHOST}.${ABI}.ini.local

	# This replaces the no-find-valgrind patch once bugfix lands in a meson
	# release + we can BDEPEND on it (https://github.com/mesonbuild/meson/pull/11372)
	cat >> ${native_file} <<-EOF || die
	[binaries]
	valgrind='valgrind-falseified'
	EOF

	local emesonargs=(
		-Ddefault_library=$(multilib_native_usex static-libs both shared)

		$(meson_native_true bin_programs)
		$(use contrib && meson_native_true bin_contrib)
		$(meson_use test bin_tests)

		$(meson_native_use_feature zlib)
		$(meson_native_use_feature lzma)
		$(meson_native_use_feature lz4)

		--native-file "${native_file}"
	)

	meson_src_configure
}

multilib_src_test() {
	meson_src_test --timeout-multiplier=2
}

multilib_src_install() {
	meson_src_install

	if multilib_is_native_abi; then
		gen_usr_ldscript -a zstd
	fi
}
multilib_src_install_all() {
	if ! use contrib && [[ -e "${ED}"/usr/bin/pzstd ]]; then
		rm "${ED}"/usr/bin/pzstd
	fi

	einstalldocs
	strip-lto-bytecode
}
