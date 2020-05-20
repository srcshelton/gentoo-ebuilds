# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit cmake-utils flag-o-matic git-r3

DESCRIPTION="Raspberry Pi userspace tools and libraries"
HOMEPAGE="https://github.com/raspberrypi/userland"
SRC_URI=""

LICENSE="BSD"
SLOT="0/1"
KEYWORDS="~aarch64 arm -*"
IUSE="-containers examples tools"

DEPEND=""
RDEPEND=""

EGIT_REPO_URI="https://github.com/raspberrypi/userland"

pkg_setup() {
	append-ldflags $(no-as-needed)
}

src_prepare() {
	# Not required after commit d9ffcca70e730c02059591035bce4439341f4175 on the 16th April...
	#epatch "${FILESDIR}"/${P}-gnu_source.patch

	epatch "${FILESDIR}"/${P}-pid.patch
}

src_configure() {
	local -a mycmakeargs

	mycmakeargs=(
		-DVMCS_INSTALL_PREFIX="/usr"
	)

	cmake-utils_src_configure
}

src_install() {
	local bin

	cmake-utils_src_install

	dodir /usr/lib/opengl/raspberrypi/lib
	touch "${ED}"/usr/lib/opengl/raspberrypi/.gles-only
	mv "${ED}"/usr/lib/lib{EGL,GLESv2}* \
		"${ED}"/usr/lib/opengl/raspberrypi/lib/

	dodir /usr/lib/opengl/raspberrypi/include
	mv "${ED}"/usr/include/{EGL,GLES,GLES2,KHR,WF} \
		"${ED}"/usr/lib/opengl/raspberrypi/include/

	mv "${ED}"/usr/include/interface/vcos/pthreads/* \
		"${ED}"/usr/include/interface/vcos/
	rmdir "${ED}"/usr/include/interface/vcos/pthreads
	mv "${ED}"/usr/include/interface/vmcs_host/linux/* \
		"${ED}"/usr/include/interface/vmcs_host/
	rmdir "${ED}"/usr/include/interface/vmcs_host/linux

	dodir /usr/$(get_libdir)/raspberrypi/plugins
	mv "${ED}"/usr/lib/plugins/* \
		"${ED}"/usr/$(get_libdir)/raspberrypi/plugins/
	rmdir "${ED}"/usr/lib/plugins

	if use examples; then
		dodir /usr/share/doc/${PF}
		mv "${ED}"/usr/src/hello_pi "${ED}"/usr/share/doc/${PF}/
	fi
	rm -r "${ED}"/usr/src

	rm -r "${ED}"/usr/share/install

	if ! use containers; then
		rm "${ED}"/usr/bin/containers_*
	fi
	if ! use tools; then
		rm "${ED}"/usr/bin/{mmal_vc_diag,vchiq_test,vcmailbox,vcsmem}
	fi

	dodir /usr/sbin
	for bin in mmal_vc_diag vcgencmd vchiq_test vcmailbox vcsmem; do
		[[ -e "${ED}/usr/bin/${bin}" ]] && mv "${ED}/usr/bin/${bin}" "${ED}"/usr/sbin/
	done

	rm "${ED}"/etc/init.d/vcfiled
	newinitd "${FILESDIR}"/${PN}-vcfiled.initd vcfiled
}

pkg_postinst() {
	ewarn "The package ${PN} only includes open-source Raspberry Pi"
	ewarn "utilities, and the sys-apps/raspberrypi-utilities-armv6 package is"
	ewarn "additionally required for certain closed-source components such as"
	ewarn "the VideoCore IV debugging tool 'vcdbg'."
}
