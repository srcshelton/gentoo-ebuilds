# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 1778b0d083dee0e1263a6f7a8a76f1c2fa6128f7 $

EAPI=5
PYTHON_COMPAT=( python2_7 )

inherit python-single-r1

DESCRIPTION="USB enumeration utilities"
HOMEPAGE="http://linux-usb.sourceforge.net/"
SRC_URI="mirror://kernel/linux/utils/usb/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~arm-linux ~x86-linux"
IUSE="experimental -libudev python zlib"
REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	libudev? ( !zlib )
"

CDEPEND="virtual/libusb:1=
	libudev? ( virtual/libudev:= )
	!libudev? ( zlib? ( sys-libs/zlib:= ) )"
DEPEND="${CDEPEND}
	app-arch/xz-utils
	virtual/pkgconfig"
RDEPEND="${CDEPEND}
	sys-apps/hwids
	python? ( ${PYTHON_DEPS} )"

if [[ " ${USE} " =~ \ libudev\  ]]; then
	inherit autotools git-r3

	DEPEND="${DEPEND}
		dev-vcs/git"

	EGIT_REPO_URI="https://github.com/srcshelton/${PN}.git"
	if [[ " ${USE} " =~ \ experimental\  ]]; then
		EGIT_COMMIT="heads/nohwdb"
	else
		EGIT_COMMIT="tags/v${PV}-nohwdb"
	fi
fi

pkg_setup() {
	if use libudev && use zlib; then
		ewarn "The 'zlib' USE-flag is ineffective when sys-apps/usbutils is" \
			  "built with libudev support"
	fi

	use python && python-single-r1_pkg_setup
}

src_prepare() {
	if use libudev; then
		epatch "${FILESDIR}"/${PN}-006-stdint.patch
	else
		use experimental || epatch "${FILESDIR}"/${P}-stdint.patch
	fi
	sed -i -e '/^usbids/s:/usr/share:/usr/share/misc:' lsusb.py || die
	use python && python_fix_shebang lsusb.py

	use libudev || eautoreconf
}

src_configure() {
	local -a myconf
	myconf=(
		--datarootdir="${EPREFIX}/usr/share"
		--datadir="${EPREFIX}/usr/share/misc"
	)
	use libudev || myconf+=(
		--disable-usbids
		$(use_enable zlib)
	)
	econf "${myconf[@]}"
}

src_install() {
	for d in README* ChangeLog AUTHORS NEWS TODO CHANGES \
			THANKS BUGS FAQ CREDITS CHANGELOG ; do
		[[ -s "${d}" ]] && rm "${d}"
	done

	default

	use python || rm -f "${ED}"/usr/bin/lsusb.py
}

# vi: set diffopt=iwhite,filler:
