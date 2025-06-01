# Copyright 2003-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/elfutils.gpg
inherit autotools flag-o-matic usr-ldscript multilib-minimal

DESCRIPTION="Libraries/utilities to handle ELF objects (drop in replacement for libelf)"
HOMEPAGE="https://sourceware.org/elfutils/"
if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://sourceware.org/git/elfutils.git"
	inherit git-r3

	BDEPEND="sys-devel/bison
		sys-devel/flex"
else
	inherit verify-sig
	SRC_URI="https://sourceware.org/elfutils/ftp/${PV}/${P}.tar.bz2
		verify-sig? ( https://sourceware.org/elfutils/ftp/${PV}/${P}.tar.bz2.sig )"

	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"

	BDEPEND="verify-sig? ( >=sec-keys/openpgp-keys-elfutils-20240301 )"
fi

LICENSE="|| ( GPL-2+ LGPL-3+ ) utils? ( GPL-3+ )"
SLOT="0"
IUSE="bzip2 debuginfod lzma nls stacktrace static-libs test +utils valgrind zstd"
RESTRICT="!test? ( test )"

RDEPEND="
	!dev-libs/libelf
	>=sys-libs/zlib-1.2.8-r1[static-libs?,${MULTILIB_USEDEP}]
	bzip2? ( >=app-arch/bzip2-1.0.6-r4[static-libs?,${MULTILIB_USEDEP}] )
	debuginfod? (
		>=app-arch/libarchive-3.1.2:=
		dev-db/sqlite:3=
		>=dev-libs/json-c-0.11:=[${MULTILIB_USEDEP}]
		>=net-libs/libmicrohttpd-0.9.33:=
		>=net-misc/curl-7.29.0[static-libs?,${MULTILIB_USEDEP}]
	)
	lzma? ( >=app-arch/xz-utils-5.0.5-r1[static-libs?,${MULTILIB_USEDEP}] )
	stacktrace? ( dev-util/sysprof )
	zstd? ( app-arch/zstd:=[static-libs?,${MULTILIB_USEDEP}] )
	elibc_musl? (
		dev-libs/libbsd
		sys-libs/argp-standalone
		sys-libs/fts-standalone
		sys-libs/obstack-standalone
	)
"
DEPEND="
	${RDEPEND}
	valgrind? ( dev-debug/valgrind )
"
BDEPEND+="
	app-alternatives/lex[flex]
	sys-devel/flex
	sys-devel/m4
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"

PATCHES=(
	"${FILESDIR}"/${PN}-0.189-musl-aarch64-regs.patch
	"${FILESDIR}"/${PN}-0.191-musl-macros.patch
	"${FILESDIR}"/${P}-libelf-static-link-libeu.patch
	"${FILESDIR}"/${P}-configure-better-error-message.patch
	"${FILESDIR}"/${P}-stacktrace-maybe-uninit.patch
	"${FILESDIR}"/${PN}-0.191-musl-configure-better-error-h-check.patch
)

src_prepare() {
	default

	eautoreconf

	if ! use static-libs; then
		sed -i -e '/^lib_LIBRARIES/s:=.*:=:' -e '/^%.os/s:%.o$::' lib{asm,dw,elf}/Makefile.in || die
	fi

	# https://sourceware.org/PR23914
	sed -i 's:-Werror::' */Makefile.in || die
}

src_configure() {
	# bug #407135
	use test && append-flags -g

	# bug 660738
	filter-flags -fno-asynchronous-unwind-tables

	multilib-minimal_src_configure
}

multilib_src_configure() {
	unset LEX YACC

	local myeconfargs=(
		$(use_enable nls)
		$(multilib_native_use_enable debuginfod)
		# Could do dummy if needed?
		$(use_enable debuginfod libdebuginfod)
		$(multilib_native_use_enable stacktrace)
		$(use_enable valgrind valgrind-annotations)

		# explicitly disable thread safety, it's not recommended by upstream
		# doesn't build either on musl.
		--disable-thread-safety

		# Valgrind option is just for running tests under it; dodgy under sandbox
		# and indeed even w/ glibc with newer instructions.
		--disable-valgrind
		--program-prefix="eu-"
		--with-zlib
		$(use_with bzip2 bzlib)
		$(use_with lzma)
		$(use_with zstd)
	)

	[[ ${PV} == 9999 ]] && myeconfargs+=( --enable-maintainer-mode )

	# Needed because sets alignment macro
	is-flagq -fsanitize=address && myeconfargs+=( --enable-sanitize-address )
	is-flagq -fsanitize=undefined && myeconfargs+=( --enable-sanitize-undefined )

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_test() {
	env LD_LIBRARY_PATH="${BUILD_DIR}/libelf:${BUILD_DIR}/libebl:${BUILD_DIR}/libdw:${BUILD_DIR}/libasm" \
		LC_ALL="C" \
		emake check VERBOSE=1
}

multilib_src_install() {
	default

	if use split-usr && multilib_is_native_abi; then
		# Rather than being named libelf.so.0.170, libs are instead named
		# libelf-0.170.so...
		# The comments in gen_usr_ldscript indicate that this is sometimes the
		# case, but, as below, gen_usr_ldscript then does the wrong thing.
		# Indeed, if called as 'gen_usr_ldscript "libelf-${PV}"' then it
		# doesn't seem to do *anything*.
		#gen_usr_ldscript "libelf-${PV}"
		gen_usr_ldscript -a elf

		# We now have a broken symlink libelf.so.1 -> libelf-0.170.so in /lib*
		# and the original library plus the ld script in /usr/lib*
		if [[
			     -f "${ED%/}/usr/$(get_libdir)/libelf-${PV}.so"
			&&   -L "${ED%/}/$(get_libdir)/libelf.so.1"
			&& ! -r "${ED%/}/$(get_libdir)/libelf.so.1"
		]]; then
			ewarn "Fixing-up bad gen_usr_ldscript result ..."
			mv "${ED%/}/usr/$(get_libdir)/libelf-${PV}.so" "${ED%/}/$(get_libdir)/"
		fi
	fi
}

multilib_src_install_all() {
	einstalldocs

	dodoc NOTES

	# These build quick, and are needed for most tests, so we don't
	# disable building them when the USE flag is disabled.
	if ! use utils; then
		rm -rf "${ED}"/usr/bin || die
	fi
}
