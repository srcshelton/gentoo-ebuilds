# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/raspberrypi-mkimage/raspberrypi-mkimage-0_p20120201.ebuild,v 1.3 2014/11/27 13:45:18 pacho Exp $

EAPI=5
PYTHON_COMPAT=( python{2_6,2_7,3_2,3_3,3_4} )

inherit eutils distutils-r1

DESCRIPTION="Raspberry Pi kernel mangling tools"
HOMEPAGE="https://github.com/raspberrypi/tools/"
SRC_URI="https://raw.githubusercontent.com/raspberrypi/tools/318aa31e7fd550f15e0b7be678cd52a6257bba72/mkimage/mkknlimg -> ${P}-mkknlimg.pl
https://raw.githubusercontent.com/raspberrypi/tools/318aa31e7fd550f15e0b7be678cd52a6257bba72/mkimage/knlinfo -> ${P}-knlinfo.pl"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 arm ~x86"
IUSE=""

DEPEND=""
RDEPEND="${PYTHON_DEPS}"

src_unpack() {
	mkdir "${S}" || die
	cp {"${FILESDIR}"/${PN}-0_p20120201-,"${S}"/}imagetool-uncompressed.py || die
	cp "${DISTDIR}"/${P}-mkknlimg.pl "${S}"/mkknlimg
	cp "${DISTDIR}"/${P}-knlinfo.pl "${S}"/knlinfo
}

python_prepare_all() {
	epatch "${FILESDIR}"/${PN}-0_p20120201-imagetool-uncompressed.patch
	sed -e '/^load_to_mem("/s:(":("'${EPREFIX}'/usr/share/'${PN}'/:' \
		-e '1s:python2:python:' \
		-i imagetool-uncompressed.py || die
	python_copy_sources
}

python_prepare() {
	cd "${BUILD_DIR}" || die
	case ${EPYTHON} in
		python3.1|python3.2|python3.3)
			epatch "${FILESDIR}"/${PN}-0_p20120201-imagetool-uncompressed-python3.patch
			;;
	esac
	mv imagetool-uncompressed.py rpi-imagetool-uncompressed.py
}

python_compile() { :; }

python_install() {
	cd "${BUILD_DIR}" || die
	python_doscript rpi-imagetool-uncompressed.py
}

python_install_all() {
	insinto /usr/share/${PN}
	newins {"${FILESDIR}"/${PN}-0_p20120201-,}args-uncompressed.txt
	newins {"${FILESDIR}"/${PN}-0_p20120201-,}boot-uncompressed.txt
	exeinto /usr/bin
	newexe mkknlimg rpi-mkknlimg
	newexe knlinfo rpi-knlinfo
}
