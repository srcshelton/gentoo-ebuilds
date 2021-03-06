# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 6b611c29c069f1ca97d523dbe4827925fc411263 $
# $Header: /var/cvsroot/gentoo-x86/app-arch/unzip/unzip-6.0-r3.ebuild,v 1.10 2014/01/18 05:01:26 vapier Exp $

EAPI="5"

inherit eutils toolchain-funcs flag-o-matic

MY_PV="${PV//.}"
MY_PV="${MY_PV%_p*}"
MY_P="${PN}${MY_PV}"

DESCRIPTION="unzipper for pkzip-compressed files"
HOMEPAGE="http://www.info-zip.org/"
SRC_URI="mirror://sourceforge/infozip/${MY_P}.tar.gz
	mirror://debian/pool/main/u/${PN}/${PN}_${PV/_p/-}.debian.tar.xz"

LICENSE="Info-ZIP"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~arm-linux ~x86-linux"
KEYWORDS+="~ppc-aix ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="bzip2 natspec unicode"

DEPEND="bzip2? ( app-arch/bzip2 )
	natspec? ( dev-libs/libnatspec )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	local deb="${WORKDIR}"/debian/patches
	rm \
		"${deb}"/series \
		"${deb}"/02-branding-patch-this-is-debian-unzip \
		|| die
	epatch "${deb}"/*

	epatch "${FILESDIR}"/${PN}-6.0-no-exec-stack.patch
	use natspec && epatch "${FILESDIR}/${PN}-6.0-natspec.patch" #275244
	epatch "${FILESDIR}"/${PN}-6.0-irix.patch
	sed -i -r \
		-e '/^CFLAGS/d' \
		-e '/CFLAGS/s:-O[0-9]?:$(CFLAGS) $(CPPFLAGS):' \
		-e '/^STRIP/s:=.*:=true:' \
		-e "s:\<CC *= *\"?g?cc2?\"?\>:CC=\"$(tc-getCC)\":" \
		-e "s:\<LD *= *\"?(g?cc2?|ld)\"?\>:LD=\"$(tc-getCC)\":" \
		-e "s:\<AS *= *\"?(g?cc2?|as)\"?\>:AS=\"$(tc-getCC)\":" \
		-e 's:LF2 = -s:LF2 = :' \
		-e 's:LF = :LF = $(LDFLAGS) :' \
		-e 's:SL = :SL = $(LDFLAGS) :' \
		-e 's:FL = :FL = $(LDFLAGS) :' \
		-e "/^#L_BZ2/s:^$(use bzip2 && echo .)::" \
		-e 's:$(AS) :$(AS) $(ASFLAGS) :g' \
		-e 's:STRIP =.*$:STRIP = true:' \
		-e "s!CF = \$(CFLAGS) \$(CF_NOOPT)!CF = \$(CFLAGS) \$(CF_NOOPT) \$(CPPFLAGS)!" \
		unix/Makefile \
		|| die "sed unix/Makefile failed"

	# Delete bundled code to make sure we don't use it.
	rm -r bzip2 || die

	epatch_user
}

src_configure() {
	case ${CHOST} in
		i?86*-*linux*)       TARGET="linux_asm" ;;
		*linux*)             TARGET="linux_noasm" ;;
		i?86*-*bsd* | \
		i?86*-dragonfly*)    TARGET="freebsd" ;; # mislabelled bsd with x86 asm
		*bsd* | *dragonfly*) TARGET="bsd" ;;
		*-darwin*)           TARGET="macosx"; append-cppflags "-DNO_LCHMOD" ;;
		*-cygwin*)           TARGET="cygwin" ;;
		*-solaris*)          TARGET="generic" ;;
		mips-sgi-irix*)      TARGET="sgi"; append-cppflags "-DNO_LCHMOD" ;;
		*-interix3*)         TARGET="gcc"; append-flags "-DUNIX"; append-cppflags "-DNO_LCHMOD" ;;
		*-interix*)          TARGET="gcc"; append-flags "-DUNIX -DNO_LCHMOD" ;;
		*-aix*)              TARGET="gcc"; append-cppflags "-DNO_LCHMOD"; append-ldflags "-Wl,-blibpath:${EPREFIX}/usr/$(get_libdir)" ;;
		*-hpux*)             TARGET="gcc"; append-ldflags "-Wl,+b,${EPREFIX}/usr/$(get_libdir)" ;;
		*-mint*)             TARGET="generic" ;;
		*) die "Unknown target; please update the ebuild to handle ${CHOST}	" ;;
	esac

	[[ ${CHOST} == *linux* ]] && append-cppflags -DNO_LCHMOD
	use bzip2 && append-cppflags -DUSE_BZIP2
	use unicode && append-cppflags -DUNICODE_SUPPORT -DUNICODE_WCHAR -DUTF8_MAYBE_NATIVE
	append-cppflags -DLARGE_FILE_SUPPORT #281473
}

src_compile() {
	ASFLAGS="${ASFLAGS} $(get_abi_var CFLAGS)" \
		emake -f unix/Makefile ${TARGET} ||
		die "emake failed"
}

src_install() {
	dobin unzip funzip unzipsfx unix/zipgrep || die "dobin failed"
	dosym unzip /usr/bin/zipinfo || die
	doman man/*.1
	dodoc BUGS History* README ToDo WHERE
}
# vi: set diffopt=iwhite,filler:
