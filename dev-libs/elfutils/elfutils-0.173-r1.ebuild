# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic multilib-minimal

DESCRIPTION="Libraries/utilities to handle ELF objects (drop in replacement for libelf)"
HOMEPAGE="http://elfutils.org/"
SRC_URI="https://sourceware.org/elfutils/ftp/${PV}/${P}.tar.bz2"

LICENSE="|| ( GPL-2+ LGPL-3+ ) utils? ( GPL-3+ )"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 ~m68k ~mips ppc ppc64 s390 ~sh sparc x86 ~amd64-linux ~x86-linux"
IUSE="bzip2 lzma nls sep-usr static-libs test +threads +utils"

RDEPEND=">=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	bzip2? ( >=app-arch/bzip2-1.0.6-r4[${MULTILIB_USEDEP}] )
	lzma? ( >=app-arch/xz-utils-5.0.5-r1[${MULTILIB_USEDEP}] )
	!dev-libs/libelf"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	>=sys-devel/flex-2.5.4a
	sys-devel/m4"

PATCHES=(
	"${FILESDIR}"/${PN}-0.118-PaX-support.patch
	"${FILESDIR}"/${PN}-0.173-partial-core.patch
	"${FILESDIR}"/${PN}-0.175-disable-biarch-test-PR24158.patch
)

src_prepare() {
	default

	if ! use static-libs; then
		sed -i -e '/^lib_LIBRARIES/s:=.*:=:' -e '/^%.os/s:%.o$::' lib{asm,dw,elf}/Makefile.in || die
	fi
	sed -i 's:-Werror::' */Makefile.in || die
}

src_configure() {
	use test && append-flags -g #407135
	multilib-minimal_src_configure
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		$(use_enable nls) \
		$(use_enable threads thread-safety) \
		--program-prefix="eu-" \
		--with-zlib \
		$(use_with bzip2 bzlib) \
		$(use_with lzma)
}

multilib_src_test() {
	env	LD_LIBRARY_PATH="${BUILD_DIR}/libelf:${BUILD_DIR}/libebl:${BUILD_DIR}/libdw:${BUILD_DIR}/libasm" \
		LC_ALL="C" \
		emake check VERBOSE=1
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if use sep-usr && multilib_is_native_abi; then
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

	# These build quick, and are needed for most tests, so don't
	# disable their building when the USE flag is disabled.
	if ! use utils; then
		rm -rf "${ED}"/usr/bin || die
	fi
}
