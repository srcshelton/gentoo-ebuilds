# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
#CMAKE_MAKEFILE_GENERATOR='emake'
EGIT_REPO="userland"
EGIT_COMMIT="96a7334ae9d5fc9db7ac92e59852377df63f1848"

inherit cmake flag-o-matic udev

DESCRIPTION="Raspberry Pi userspace tools and libraries"
HOMEPAGE="https://github.com/raspberrypi/userland"
SRC_URI="https://github.com/raspberrypi/${EGIT_REPO}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 arm arm64"
IUSE="-containers debug devicetree examples gps tools udev"
REQUIRED_USE="
	containers? ( arm )
"

BDEPEND="
	virtual/os-headers
	gps? ( sci-geosciences/gpsd )
"
RDEPEND="
	acct-group/video
	sys-apps/raspberrypi-tools
	devicetree? ( sys-apps/raspberrypi-tools[devicetree] )
	gps? ( sci-geosciences/gpsd )
"

S="${WORKDIR}/${EGIT_REPO}-${EGIT_COMMIT}"
DOCS=()

PATCHES=(
	# See https://github.com/raspberrypi/userland/pull/559
	"${FILESDIR}/${PN}-vchi_cfg.h.patch"
	# Install in $(get_libdir)
	# See https://github.com/raspberrypi/userland/pull/650
	"${FILESDIR}/${PN}-libdir.patch"
	# See https://github.com/raspberrypi/userland/pull/655
	"${FILESDIR}/${PN}-libfdt-static.patch"
	# See https://github.com/raspberrypi/userland/pull/659
	"${FILESDIR}/${PN}-pkgconf-arm64.patch"
	# See https://github.com/raspberrypi/userland/pull/661
	"${FILESDIR}/${PN}-CMakeLists.txt.patch"
	# See https://github.com/raspberrypi/userland/pull/666
	"${FILESDIR}/${PN}-dma-buf.h.patch"
	# See https://github.com/raspberrypi/userland/pull/670
	"${FILESDIR}/${PN}-native.patch"
	# See https://github.com/raspberrypi/userland/pull/683
	"${FILESDIR}/${PN}-bcm2711.patch"
	# See https://github.com/raspberrypi/userland/pull/689
	"${FILESDIR}/${PN}-drop-debug-statements.patch"
	# See https://github.com/raspberrypi/userland/pull/692
	"${FILESDIR}/${PN}-vc_dispmanx_egl.h.patch"
	# See https://github.com/raspberrypi/userland/pull/700
	#"${FILESDIR}/${PN}-bash-completion.patch"
	# See https://github.com/raspberrypi/userland/pull/703
	"${FILESDIR}/${PN}-vcgencmd.1.patch"
	# See https://github.com/raspberrypi/userland/pull/719
	"${FILESDIR}/${PN}-libexecinfo.patch"
	# Don't install includes that collide.
	"${FILESDIR}/${PN}-include.patch"
)

src_prepare() {
	if use gps; then
		# sci-geosciences/gpsd is unstable on arm(64) and the USE-flag is
		# currently masked...
		#
		# See https://github.com/raspberrypi/userland/pull/662
		eapply "${FILESDIR}/${PN}-libgps.patch"
	fi

	# https://github.com/raspberrypi/userland/pull/689#issuecomment-826880275
	rm -r helpers/vc_image \
			vcinclude/vc_image_types.h \
			helpers/v3d/v3d_common.h ||
		die

	# https://github.com/raspberrypi/userland/pull/697
	sed -e '/define WORK_DIR/s:/tmp/.dtoverlays:/var/run/dtoverlays:' \
		-i host_applications/linux/apps/dtoverlay/dtoverlay_main.c || die

	sed -e '/^cmake_minimum_required(VERSION 2.8)$/s:2.8:2.8.12:' \
		-i CMakeLists.txt \
		-i interface/vcos/CMakeLists.txt \
		-i host_applications/linux/apps/gencmd/CMakeLists.txt \
		-i host_applications/linux/apps/dtoverlay/CMakeLists.txt \
		-i host_applications/linux/apps/dtmerge/CMakeLists.txt \
		-i helpers/dtoverlay/CMakeLists.txt || die
	cmake_src_prepare

	sed \
		-e 's:^install(TARGETS EGL GLESv2 OpenVG WFC:install(TARGETS:' \
		-e '/^install(TARGETS EGL_static GLESv2_static/d' \
		-i interface/khronos/CMakeLists.txt ||
		die "Failed to update interface/khronos/CMakeLists.txt"
}

src_configure() {
	local -a mycmakeargs=()

	append-ldflags $(no-as-needed)

	mycmakeargs=(
		-DVMCS_INSTALL_PREFIX="${EPREFIX}/usr"
		-DCMAKE_BUILD_TYPE=$(usex debug 'Debug' 'Release')
		-DARM64=$(usex arm64 'ON' 'OFF')
		-DAMD64=$(usex amd64 'ON' 'OFF')
	)

	cmake_src_configure
}

src_install() {
	local lib='' ext='' bin='' file=''

	cmake_src_install

	if use udev; then
		udev_dorules "${FILESDIR}"/92-local-vchiq-permissions.rules
	fi

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

	if [[ -d "${ED}"/usr/src/hello_pi ]]; then
		if use examples; then
			dodir /usr/src/raspberrypi
			mv "${ED}"/usr/src/hello_pi "${ED}"/usr/src/raspberrypi/
		else
			rm -r "${ED}"/usr/src || die
		fi
	fi

	if [[ -d "${ED}"/usr/share/install ]]; then
		rm -r "${ED}"/usr/share/install || die
	fi

	# containers on not built on ARM64
	if ! use arm64 && ! use containers; then
		rm "${ED}"/usr/bin/containers_* || die
	fi

	if ! use devicetree; then
		rm "${ED}"/usr/bin/{dtoverlay-pre,dtoverlay-post} || die
	fi
	# dtmerge is now provided by sys-apps/raspberrypi-tools
	rm "${ED}"/usr/bin/dtmerge "${ED}"/usr/man/man1/dtmerge.1*|| die

	if ! use tools; then
		if ! use arm64; then
			rm "${ED}"/usr/bin/{mmal_vc_diag,vcsmem} || die
		fi
		rm "${ED}"/usr/bin/vchiq_test || die
	fi
	ewarn "'vcmailbox' is now provided by sys-apps/raspberrypi-tools"
	rm "${ED}"/usr/bin/vcmailbox || die

	for bin in mmal_vc_diag vcgencmd vchiq_test vcmailbox vcsmem; do
		case "${bin}" in
			vcgencmd)
				ewarn "'vcgencmd' is now provided by sys-apps/raspberrypi-tools"
				continue
				;;
		esac
		if [[ -e "${ED}/usr/bin/${bin}" ]]; then
			{ dosbin "${ED}/usr/bin/${bin}" && rm "${ED}/usr/bin/${bin}" ; } || die
		fi
	done

	# See also https://github.com/raspberrypi/userland/pull/717
	if [[ -d "${ED}"/usr/man ]]; then
		for file in \
			man1/dtoverlay.1 man1/dtparam.1 \
			man1/vcgencmd.1 man1/vcmailbox.1 man7/vcmailbox.7 \
			man7/raspiotp.7 man7/raspirev.7
		do
			rm "${ED}/usr/man/${file}" ||
				die "Unable to remove duplicate man page '${file}': ${?}"
		done
		doman "${ED}"/usr/man/man1/*.1 # "${ED}"/usr/man/man7/*.7
		rm -r "${ED}"/usr/man || die "Cannot remove directory '${ED%/}/usr/man': ${?}"
	fi

	# Now provided by sys-apps/raspberrypi-tools...
	#if use bash-completion; then
	#	newbashcomp host_applications/linux/apps/gencmd/vcgencmd-completion.bash vcgencmd
	#fi

	# Clean-up files duplicated by sys-apps/raspberrypi-tools...
	for file in dtoverlay dtparam; do
		rm "${ED}/usr/bin/${file}" || die "Unable to remove duplicate binary '${file}': ${?}"
	done
}

pkg_postinst() {
	if use udev; then
		udev_reload
	fi

	ewarn
	ewarn "The data in this package is ancient and deprecated:"
	ewarn "Please migrate to sys-apps/raspberrypi-tools."
	ewarn

	elog "The package ${PN} only includes open-source Raspberry Pi"
	elog "utilities:"
	elog
	elog "sys-apps/raspberrypi-utilities-armv6 provides 32-bit closed-source"
	elog "components such as the VideoCore IV debugging tool 'vcdbg';"
	elog "sys-apps/raspberrypi-tools provides a 64-bit equivalent, 'vclog'."
	elog
	elog "The 'dtmerge', 'dtoverlay', 'dtparam', 'vcgencmd' and 'vcmailbox'"
	elog "sources exist in both this package's repo as well as that of"
	elog "sys-apps/raspberrypi-tools - the latter is more recently updated,"
	elog "and so the binaries from this package are no longer installed."
}

# vi: set diffopt=iwhite,filler:
