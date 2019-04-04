# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit cmake-utils flag-o-matic git-r3

DESCRIPTION="Raspberry Pi userspace tools and libraries"
HOMEPAGE="https://github.com/raspberrypi/userland"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS="~aarch64 arm -*"
IUSE="examples udev"

DEPEND=""
RDEPEND=""

EGIT_REPO_URI="https://github.com/raspberrypi/userland"

PATCHES=(
	"${FILESDIR}"/${P}-gentoo.patch
	"${FILESDIR}"/${P}-pid.patch
)

pkg_setup() {
	append-ldflags $(no-as-needed)
}

src_configure() {
	local -a mycmakeargs
	
	mycmakeargs=( -DVMCS_INSTALL_PREFIX="/usr" )

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	dodir /usr/lib/opengl/raspberrypi/lib
	touch "${D}"/usr/lib/opengl/raspberrypi/.gles-only
	mv "${D}"/usr/lib/lib{EGL,GLESv2}* \
		"${D}"/usr/lib/opengl/raspberrypi/lib

	dodir /usr/lib/opengl/raspberrypi/include
	mv "${D}"/usr/include/{EGL,GLES,GLES2,KHR,WF} \
		"${D}"/usr/lib/opengl/raspberrypi/include
	mv "${D}"/usr/include/interface/vcos/pthreads/* \
		"${D}"/usr/include/interface/vcos/
	rmdir "${D}"/usr/include/interface/vcos/pthreads
	mv "${D}"/usr/include/interface/vmcs_host/linux/* \
		"${D}"/usr/include/interface/vmcs_host/
	rmdir "${D}"/usr/include/interface/vmcs_host/linux

	if use udev; then
		insinto "${D}"/$(get_udevdir)/rules.d
		doins "${FILESDIR}"/92-local-vchiq-permissions.rules
	fi

	if use examples; then
		dodir /usr/share/doc/${PF}
		mv "${D}"/usr/src/hello_pi "${D}"/usr/share/doc/${PF}/
	fi
	rmdir "${D}"/usr/src

	rm "${D}"/etc/init.d/vcfiled
	newinitd "${FILESDIR}"/${PN}-vcfiled.initd vcfiled
}

pkg_postinst() {
	ewarn "The package ${PN} only includes open-source Raspberry Pi"
	ewarn "utilities, and the sys-apps/raspberrypi-utilities-armv6 package is"
	ewarn "additionally required for certain closed-source components such as"
	ewarn "the VideoCore IV debugging tool 'vcdbg'."
}
