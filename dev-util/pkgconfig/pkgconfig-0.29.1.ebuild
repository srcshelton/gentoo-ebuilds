# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

# Do not inherit autotools in non-live ebuild - causes circular dependency, bug #550856
inherit eutils flag-o-matic libtool multilib multilib-minimal

MY_P=pkg-config-${PV}

if [[ ${PV} == *9999* ]]; then
	# 1.12 is only needed for tests due to some am__check_pre / LOG_DRIVER
	# weirdness with "/bin/bash /bin/sh" in arguments chain with >=1.13
	WANT_AUTOMAKE=1.12
	EGIT_REPO_URI="https://anongit.freedesktop.org/git/pkg-config.git"
	EGIT_CHECKOUT_DIR=${WORKDIR}/${MY_P}
	inherit autotools git-r3
else
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
	SRC_URI="https://pkgconfig.freedesktop.org/releases/${MY_P}.tar.gz"
	INTERNAL_GLIB_CYGWIN_PATCHES=2.38.2
fi

[[ -n ${INTERNAL_GLIB_CYGWIN_PATCHES} ]] &&
SRC_URI+=" internal-glib? ( elibc_Cygwin? (
	https://github.com/haubi/pkgconfig-glib-cygwin-patches/archive/v${INTERNAL_GLIB_CYGWIN_PATCHES}.zip
	-> pkgconfig-glib-cygwin-patches-${INTERNAL_GLIB_CYGWIN_PATCHES}.zip
) )"

DESCRIPTION="Package config system that manages compile/link flags"
HOMEPAGE="https://pkgconfig.freedesktop.org/wiki/"

LICENSE="GPL-2"
SLOT="0"
IUSE="elibc_FreeBSD elibc_glibc elibc_Cygwin hardened internal-glib"

RDEPEND="!internal-glib? ( >=dev-libs/glib-2.34.3[${MULTILIB_USEDEP}] )
	!dev-util/pkgconf[pkg-config]
	!dev-util/pkg-config-lite
	!dev-util/pkgconfig-openbsd[pkg-config]
	virtual/libintl"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

DOCS=( AUTHORS NEWS README )

src_prepare() {
	sed -i -e "s|^prefix=/usr\$|prefix=${EPREFIX}/usr|" check/simple.pc || die #434320

	[[ -n ${INTERNAL_GLIB_CYGWIN_PATCHES} ]] &&
	use internal-glib && use elibc_Cygwin &&
	EPATCH_FORCE=yes EPATCH_SUFFIX=patch \
	epatch "${WORKDIR}"/pkgconfig-glib-cygwin-patches-${INTERNAL_GLIB_CYGWIN_PATCHES}

	epatch "${FILESDIR}"/${PN}-0.29-vasnprintf.patch

	eapply_user

	if [[ ${PV} == *9999* ]]; then
		eautoreconf
	else
		elibtoolize
	fi

	if [[ ${CHOST} == *-solaris* ]] ; then
		# fix standards conflicts
		sed -i \
			-e 's/\(_XOPEN_SOURCE\(_EXTENDED\)\?\|__EXTENSIONS__\)/  \1_DISABLED/' \
			-e '/\<_XOPEN_SOURCE\>/s/2/600/' \
			glib/configure || die
		sed -i -e '/#define\s\+_POSIX_SOURCE/d' \
			glib/glib/giounix.c || die
	fi
}

multilib_src_configure() {
	local myconf

	if use internal-glib; then
		myconf+=' --with-internal-glib'
		# non-glibc platforms use GNU libiconv, but configure needs to
		# know about that not to get confused when it finds something
		# outside the prefix too
		if use prefix && use !elibc_glibc ; then
			myconf+=" --with-libiconv=gnu"
			# add the libdir for libtool, otherwise it'll make love with system
			# installed libiconv
			append-ldflags "-L${EPREFIX}/usr/$(get_libdir)"
			# the glib objects reference symbols from these frameworks,
			# not good, esp. since Carbon should be deprecated
			[[ ${CHOST} == *-darwin* ]] && \
				append-ldflags -framework CoreFoundation -framework Carbon
			if [[ ${CHOST} == *-solaris* ]] ; then
				# required due to __EXTENSIONS__
				append-cppflags -DENABLE_NLS
				# similar to Darwin
				append-ldflags -lintl
			fi
		fi
	else
		if ! has_version --host-root dev-util/pkgconfig; then
			export GLIB_CFLAGS="-I${EPREFIX}/usr/include/glib-2.0 -I${EPREFIX}/usr/$(get_libdir)/glib-2.0/include"
			export GLIB_LIBS="-lglib-2.0"
		fi
	fi

	use ppc64 && use hardened && replace-flags -O[2-3] -O1

	# Force using all the requirements when linking, so that needed -pthread
	# lines are inherited between libraries
	use elibc_FreeBSD && myconf+=' --enable-indirect-deps'

	[[ ${PV} == *9999* ]] && myconf+=' --enable-maintainer-mode'

	ECONF_SOURCE=${S} \
	econf \
		--docdir="${EPREFIX}"/usr/share/doc/${PF}/html \
		--with-system-include-path="${EPREFIX}"/usr/include \
		--with-system-library-path="${EPREFIX}"/usr/$(get_libdir) \
		${myconf}
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if use prefix; then
		# Add an explicit reference to $EPREFIX to PKG_CONFIG_PATH to
		# simplify cross-prefix builds
		echo "PKG_CONFIG_PATH=${EPREFIX}/usr/$(get_libdir)/pkgconfig:${EPREFIX}/usr/share/pkgconfig" >> "${T}"/99${PN}
		doenvd "${T}"/99${PN}
	fi
}
