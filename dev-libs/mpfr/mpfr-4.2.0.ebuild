# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH="${BROOT}"/usr/share/openpgp-keys/vincentlefevre.asc
inherit usr-ldscript verify-sig multilib-minimal

# Upstream distribute patches before a new release is made
# See https://www.mpfr.org/mpfr-current/#bugs for the latest version (and patches)

# Check whether any patches touch e.g. manuals!
# https://archives.gentoo.org/gentoo-releng-autobuilds/message/c2dd39fc4ebc849db6bb0f551739e2ed
MY_PV=${PV%%_p*}
MY_PATCH=$(ver_cut 5-)
MY_PATCHES=()
MY_P=${PN}-${MY_PV/_/-}

DESCRIPTION="Library for multiple-precision floating-point computations with exact rounding"
HOMEPAGE="https://www.mpfr.org/ https://gitlab.inria.fr/mpfr"
SRC_URI="https://www.mpfr.org/${PN}-$(ver_cut 1-3)/${MY_P}.tar.xz
	verify-sig? ( https://www.mpfr.org/${PN}-$(ver_cut 1-3)/${MY_P}.tar.xz.asc )"

if [[ ${PV} == *_p* ]] ; then
	# If this is a patch release, we have to download each of the patches:
	# -_pN = N patches
	# - patch file names are like: patch01, patch02, ..., patch10, patch12, ..
	#
	# => name the ebuild _pN where N is the number of patches on the 'bugs' page.
	for ((my_patch_index=1; my_patch_index <= MY_PATCH; my_patch_index++)); do
		SRC_URI+=" $(printf "https://www.mpfr.org/${PN}-$(ver_cut 1-3)/patch%02d -> ${PN}-$(ver_cut 1-3)-patch%02d.patch " ${my_patch_index}{,})"
		MY_PATCHES+=( "${DISTDIR}"/$(printf ${PN}-$(ver_cut 1-3)-patch%02d.patch ${my_patch_index}) )
	done
	unset my_patch_index
fi
S="${WORKDIR}/${MY_P}"

LICENSE="LGPL-2.1"
# This is a critical package; if SONAME changes, bump subslot but also add
# preserve-libs.eclass usage to pkg_*inst! See e.g. the readline ebuild.
SLOT="0/6" # libmpfr.so version
if [[ ${PV} != *_rc* ]] ; then
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ~ppc ppc64 ~riscv ~s390 ~sparc x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
fi
IUSE="static-libs"

RDEPEND=">=dev-libs/gmp-5.0.0:=[${MULTILIB_USEDEP},static-libs?]"
DEPEND="${RDEPEND}"
BDEPEND="verify-sig? ( sec-keys/openpgp-keys-vincentlefevre )"

PATCHES=(
	# Apply the upstream patches released out-of-band; generated above
	"${MY_PATCHES[@]}"

	# Additional patches
)

HTML_DOCS=( doc/FAQ.html )

src_unpack() {
	use verify-sig && verify-sig_verify_detached "${DISTDIR}"/${MY_P}.tar.xz{,.asc}

	# Avoid src_unpack noise from patches
	unpack ${MY_P}.tar.xz
}

src_prepare() {
	default

	# 4.1.0_p13's patch10 patches a .texi file *and* the corresponding
	# info file. We need to make sure the info file is newer, so the
	# build doesn't try to run makeinfo. Won't be needed on next release.
	#touch "${S}/doc/mpfr.info" || die
}

multilib_src_configure() {
	# bug #476336#19
	# Make sure mpfr doesn't go probing toolchains it shouldn't
	ECONF_SOURCE="${S}" \
		user_redefine_cc=yes \
		econf $(use_enable static-libs static)
}

multilib_src_install_all() {
	rm "${ED}"/usr/share/doc/${PF}/COPYING* || die

	gen_usr_ldscript -a mpfr

	if ! use static-libs ; then
		find "${ED}"/usr -name '*.la' -delete || die
	fi
}
