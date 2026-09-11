# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PARALLEL_MEMORY_MIN=1

inherit eapi9-ver flag-o-matic

MAN_PAGES_GENTOO_DIST=0
GENTOO_PATCH=2

DESCRIPTION="A somewhat comprehensive collection of Linux man pages"
HOMEPAGE="https://www.kernel.org/doc/man-pages/"

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://git.kernel.org/pub/scm/docs/man-pages/man-pages.git"
	inherit git-r3
elif [[ ${PV} == *_rc* ]] ; then
	MY_P=${PN}-${PV/_/-}

	SRC_URI="https://git.kernel.org/pub/scm/docs/man-pages/man-pages.git/snapshot/${MY_P}.tar.gz"
	S="${WORKDIR}"/${MY_P}
else
	if [[ ${MAN_PAGES_GENTOO_DIST} -eq 1 ]] ; then
		SRC_URI="https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-gentoo.tar.xz"
	else
		VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/alejandro-colomar.asc
		inherit verify-sig

		SRC_URI="
			https://www.kernel.org/pub/linux/docs/man-pages/Archive/${P}.tar.xz
			https://www.kernel.org/pub/linux/docs/man-pages/${P}.tar.xz
			verify-sig? (
				https://www.kernel.org/pub/linux/docs/man-pages/Archive/${P}.tar.sign
				https://www.kernel.org/pub/linux/docs/man-pages/${P}.tar.sign
			)
		"

		BDEPEND="verify-sig? ( >=sec-keys/openpgp-keys-alejandro-colomar-20260122 )"
	fi

	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~arm64-macos"
fi

SRC_URI+="
	mirror://gentoo/man-pages-gentoo-${GENTOO_PATCH}.tar.bz2
	https://dev.gentoo.org/~cardoe/files/man-pages-gentoo-${GENTOO_PATCH}.tar.bz2
"

LICENSE="man-pages GPL-2+ BSD"
SLOT="0"
# Keep the following in sync with app-i18n/man-pages-l10n
MY_L10N=( cs da de el es fi fr hu id it ko mk nb nl pl pt-BR ro ru sr sv uk vi )
IUSE="l10n_ja l10n_zh-CN ${MY_L10N[@]/#/l10n_}"
RESTRICT="binchecks"

RDEPEND="
	virtual/man
"
PDEPEND="
	l10n_ja? ( app-i18n/man-pages-ja )
	l10n_zh-CN? ( app-i18n/man-pages-zh_CN )
"
for lang in "${MY_L10N[@]}"; do
	PDEPEND+=" l10n_${lang}? ( app-i18n/man-pages-l10n[l10n_${lang}(-)] )"
done
unset lang

# The top-level GNUmakefile unconditionally discovers and includes every
# share/mk/**/*.mk fragment—including HTML/PDF generation, example compilation,
# checks, and every linter—regardless of the requested target.
# Those fragments eagerly create thousands of per-page targets. Worse, each
# generated target declares the complete $(MK) list as prerequisites.
# Version 6.16 added five more per-page lint families: blank lines, dashes,
# poems, quotes, and whitespace.
#
#Version	make -pn nothing text	arm64 Linux peak RSS
#6.10		789 MiB					303 MiB
#6.15		806 MiB					—
#6.16		1,007 MiB				—
#6.17		1,069 MiB				402 MiB
#
# For v6.17 this reduced the no-op arm64 Linux peak from approximately 402 MiB
# to 21 MiB, and reduced the printed make database from 1,069 MiB to 15.4 MiB.
#
_man_pages_emake() {
	local -a mk=(
		"${S}"/share/mk/build/_.mk
		"${S}"/share/mk/build/man/_.mk
		"${S}"/share/mk/build/man/nonso.mk
		"${S}"/share/mk/build/man/so.mk
		"${S}"/share/mk/install/_.mk
		"${S}"/share/mk/install/bin.mk
		"${S}"/share/mk/install/man.mk
		"${S}"/share/mk/lint/man/tbl.mk
	)

	emake -R "MK_=${mk[*]}" "$@"
}

src_unpack() {
	if [[ ${PV} == 9999 ]] ; then
		git-r3_src_unpack
		unpack man-pages-gentoo-${GENTOO_PATCH}.tar.bz2
	elif [[ ${PV} != *_rc* ]] && ! [[ ${MAN_PAGES_GENTOO_DIST} -eq 1 ]] && use verify-sig ; then
		verify-sig_uncompress_verify_unpack "${DISTDIR}"/${P}.tar.xz \
			"${DISTDIR}"/${P}.tar.sign
		unpack man-pages-gentoo-${GENTOO_PATCH}.tar.bz2
	else
		default
	fi
}

src_prepare() {
	default

	# installed by sys-libs/libxcrypt
	rm man/man3/crypt{,_r}.3 || die

	# passwd.5 installed by sys-apps/shadow, bug #776787
	rm man/man5/passwd.5 || die
}

src_configure() {
	export prefix="${EPREFIX}/usr"

	minimise-memory-usage
}

src_compile() {
	#emake -R
	_man_pages_emake build
}

src_test() {
	# We don't use the 'check' target right now because of known errors
	# https://lore.kernel.org/linux-man/0dfd5319-2d22-a8ad-f085-d635eb6d0678@gmail.com/T/#t
	#emake -R lint-man-tbl
	_man_pages_emake lint-man-tbl
}

src_install() {
	#emake -R DESTDIR="${D}" install
	_man_pages_emake DESTDIR="${D}" install
	dodoc README Changes*

	# Override with Gentoo specific or additional Gentoo pages
	cd "${WORKDIR}"/man-pages-gentoo || die
	doman */*
	dodoc README.Gentoo
}

pkg_postinst() {
	if ver_replacing -lt 5.13-r2 ; then
		# Avoid ACCEPT_LICENSE issues for users by default
		# bug #871636
		ewarn "This version of ${PN} no longer depends on sys-apps/man-pages-posix!"
		ewarn "Please install sys-apps/man-pages-posix yourself if needed."
	fi
}
