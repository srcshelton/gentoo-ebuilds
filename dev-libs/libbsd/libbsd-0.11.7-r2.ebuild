# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/guillemjover.asc
inherit autotools flag-o-matic multilib usr-ldscript verify-sig multilib-minimal

DESCRIPTION="Library to provide useful functions commonly found on BSD systems"
HOMEPAGE="https://libbsd.freedesktop.org/wiki/ https://gitlab.freedesktop.org/libbsd/libbsd"
SRC_URI="https://${PN}.freedesktop.org/releases/${P}.tar.xz
	verify-sig? ( https://${PN}.freedesktop.org/releases/${P}.tar.xz.asc )"

LICENSE="BEER-WARE BSD BSD-2 BSD-4 ISC MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="static-libs"

RDEPEND="app-crypt/libmd[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	virtual/os-headers:31700
"
BDEPEND="verify-sig? ( sec-keys/openpgp-keys-guillemjover )"

PATCHES=(
	"${FILESDIR}/libbsd-build-Fix-version-script-linker-support-detection.patch"
	"${FILESDIR}/libbsd-0.11.7-musl-lfs.patch"
)

src_prepare() {
	default

	# Drop on next release, only needed for lld patch
	eautoreconf
}

multilib_src_configure() {
	# Broken (still) with lld-17 (bug #922342, bug #915068)
	append-ldflags $(test-flags-CCLD -Wl,--undefined-version)

	# bug 911726, https://gitlab.freedesktop.org/libbsd/libbsd/-/issues/26
	filter-flags -fno-semantic-interposition

	# The build system will install libbsd-ctor.a despite USE="-static-libs"
	# which is correct, see:
	# https://gitlab.freedesktop.org/libbsd/libbsd/commit/c5b959028734ca2281250c85773d9b5e1d259bc8
	ECONF_SOURCE="${S}" econf $(use_enable static-libs static)
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	find "${ED}" -type f -name "*.la" -delete || die

	if multilib_is_native_abi; then
		if use split-usr; then
			# need the libs in /
			gen_usr_ldscript -a bsd
		fi

		# ld scripts on standalone prefix (RAP) systems should have the prefix
		# stripped from any paths, as the sysroot is automatically prepended.
		local ldscript="${ED}/usr/$(get_libdir)/${PN}$(get_libname)"
		if use prefix && ! use prefix-guest &&
				grep -qIF "ld script" "${ldscript}" 2>/dev/null
		then
			sed -i "s|${EPREFIX}/|/|g" "${ldscript}" || die
		fi

		# pkg-config can't find the libbsd .pc files by default :(
		dodir /usr/$(get_libdir)/pkgconfig &&
			mv "${ED}"/$(get_libdir)/pkgconfig/* "${ED}"/usr/$(get_libdir)/pkgconfig/ &&
			rmdir "${ED}"/$(get_libdir)/pkgconfig || die
	fi
}
