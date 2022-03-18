# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit cmake flag-o-matic git-r3 udev

DESCRIPTION="Raspberry Pi userspace tools and libraries"
HOMEPAGE="https://github.com/raspberrypi/userland"
SRC_URI=""

LICENSE="BSD"
SLOT="0/1"
KEYWORDS="arm ~arm64 -*"
IUSE="-containers debug dtutils examples tools udev"

EGIT_REPO_URI="https://github.com/raspberrypi/userland"

CMAKE_MAKEFILE_GENERATOR='emake'

PATCHES=(
	# Install in $(get_libdir)
	# See https://github.com/raspberrypi/userland/pull/650
	"${FILESDIR}/${PN}-libdir.patch"
	# Don't install includes that collide.
	"${FILESDIR}/${PN}-include.patch"
	# See https://github.com/raspberrypi/userland/pull/655
	"${FILESDIR}/${PN}-libfdt-static.patch"
	# See https://github.com/raspberrypi/userland/pull/659
	"${FILESDIR}/${PN}-pkgconf-arm64.patch"
#	"${FILESDIR}"/${P}-pid.patch
)

src_prepare() {
	cmake_src_prepare
	#sed -i \
	#	-e 's:DESTINATION ${VMCS_INSTALL_PREFIX}/src:DESTINATION ${VMCS_INSTALL_PREFIX}/'"share/doc/${PF}:" \
	#	"${S}/makefiles/cmake/vmcs.cmake" || die "Failed sedding makefiles/cmake/vmcs.cmake"
	sed -i \
		-e 's:^install(TARGETS EGL GLESv2 OpenVG WFC:install(TARGETS:' \
		-e '/^install(TARGETS EGL_static GLESv2_static/d' \
		"${S}/interface/khronos/CMakeLists.txt" || die "Failed sedding interface/khronos/CMakeLists.txt"
}

src_configure() {
	local -a mycmakeargs

	append-ldflags $(no-as-needed)

	mycmakeargs=(
		-DVMCS_INSTALL_PREFIX="/usr"
		-DCMAKE_BUILD_TYPE=$(usex debug 'Debug' 'Release')
		-DARM64=$(usex arm64 'ON' 'OFF')
	)

	cmake_src_configure
}

src_install() {
	local lib='' ext='' bin=''

	cmake_src_install

	for lib in EGL GLESv2; do
		for ext in '.so' '_static.a'; do
			if [[ -e "${ED}/usr/lib/lib${lib}${ext}" ]]; then
				dodir /usr/lib/opengl/raspberrypi/lib
				touch "${ED}"/usr/lib/opengl/raspberrypi/.gles-only
				mv "${ED}/usr/lib/lib${lib}${ext}" \
					"${ED}"/usr/lib/opengl/raspberrypi/lib/
			fi
		done
	done

	dodir /usr/lib/opengl/raspberrypi/include
	for lib in EGL GLES GLES2 KHR WF; do
		if [[ -e "${ED}/usr/include/${lib}" ]]; then
			mv "${ED}/usr/include/${lib}" \
				"${ED}"/usr/lib/opengl/raspberrypi/include/
		fi
	done

	mv "${ED}"/usr/include/interface/vcos/pthreads/* \
		"${ED}"/usr/include/interface/vcos/
	rmdir "${ED}"/usr/include/interface/vcos/pthreads
	mv "${ED}"/usr/include/interface/vmcs_host/linux/* \
		"${ED}"/usr/include/interface/vmcs_host/
	rmdir "${ED}"/usr/include/interface/vmcs_host/linux

	if ! use arm64; then
		dodir /usr/$(get_libdir)/raspberrypi/plugins
		mv "${ED}"/usr/lib/plugins/* \
			"${ED}"/usr/$(get_libdir)/raspberrypi/plugins/
		rmdir "${ED}"/usr/lib/plugins
	fi

	if use udev; then
		udev_dorules "${FILESDIR}"/92-local-vchiq-permissions.rules
	fi

	if use examples; then
		dodir /usr/share/doc/${PF}
		mv "${ED}"/usr/src/hello_pi "${ED}"/usr/share/doc/${PF}/
	fi
	if [[ -d "${ED}"/usr/src ]]; then
		rm -r "${ED}"/usr/src || die
	fi

	if [[ -d "${ED}"/usr/share/install ]]; then
		rm -r "${ED}"/usr/share/install || die
	fi

	# containers on not built on ARM64
	if ! use arm64 && ! use containers; then
		rm "${ED}"/usr/bin/containers_* || die
	fi
	if ! use dtutils; then
		rm "${ED}"/usr/bin/{dtmerge,dtoverlay,dtoverlay-post,dtoverlay-pre,dtparam} || die
	fi
	if ! use tools; then
		if ! use arm64; then
			rm "${ED}"/usr/bin/{mmal_vc_diag,vcsmem} || die
		fi
		rm "${ED}"/usr/bin/{vchiq_test,vcmailbox} || die
	fi

	dodir /usr/sbin
	for bin in mmal_vc_diag vcgencmd vchiq_test vcmailbox vcsmem; do
		[[ -e "${ED}/usr/bin/${bin}" ]] && mv "${ED}/usr/bin/${bin}" "${ED}"/usr/sbin/
	done

	if [[ -d "${ED}"/usr/man ]]; then
		doman "${ED}"/usr/man/man1/*.1 "${ED}"/usr/man/man7/*.7
		rm -r "${ED}"/usr/man || die "Cannot remove directory '${ED%/}/usr/man': ${?}"
	fi

	#rm "${ED}"/etc/init.d/vcfiled || die
	#newinitd "${FILESDIR}"/${PN}-vcfiled.initd vcfiled
}

pkg_postinst() {
	ewarn "The package ${PN} only includes open-source Raspberry Pi"
	ewarn "utilities, and the sys-apps/raspberrypi-utilities-armv6 package is"
	ewarn "additionally required for certain closed-source components such as"
	ewarn "the VideoCore IV debugging tool 'vcdbg'."
}

# vi: set diffopt=iwhite,filler:
