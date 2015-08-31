# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: b9df286d3c5b0f15e5b10881fac99372a844f61f $

EAPI="3"

inherit prefix

DESCRIPTION="Links to Apple's OpenGL X11 implementation"
HOMEPAGE="http://www.apple.com/"
LICENSE="public-domain"
KEYWORDS="-* ~ppc-macos ~x64-macos ~x86-macos"
SLOT=0
IUSE=""

DEPEND=">=app-eselect/eselect-opengl-1.0.8-r1
	x11-proto/glproto"
RDEPEND="${DEPEND}"

X11_OPENGL_PATHS=( "/usr/X11R6" "/opt/X11" )
X11_OPENGL_DIR=""

x11_makelink() {
	local target="${1}"; shift
	local path="${2}"; shift
	local -i rc=0

	# It would be cleaner to notify the user of an error and then return a non-
	# zero rc - but in thie case we do always want to abort, and doing so here
	# means that a failure message is always provided.
	#
	[[ -n "${target:-}" ]] || die "${FUNCNAME} invoked with empty target"

	if [[ -n "${path:-}" ]]; then
		pushd >/dev/null 2>&1 || die "Directory '${path}' does not exist or is not accessible"
	fi
	if [[ -e "${target}" ]]; then
		ln -s "${target}"
		rc=${?}
	else
		die "${target} missing"
	fi
	[[ -n "${path:-}" ]] && popd >/dev/null 2>&1

	return ${rc}
}

pkg_setup() {
	for X11_OPENGL_DIR in "${X11_OPENGL_PATHS[@]}"; do
		if [[ -d ${X11_OPENGL_DIR} ]]; then
			break
		else
			ewarn "${X11_OPENGL_DIR} not found"
		fi
	done
	[[ -d ${X11_OPENGL_DIR} ]] || \
		die "No X11 installation found - do you have X11/Xquartz installed?"
}

src_prepare() {
	cp "${FILESDIR}"/gl.pc .
	eprefixify gl.pc
}

src_install() {
	dodir /usr/lib/opengl/${PN}/{lib,include}
	dodir /usr/include/GL

	x11_makelink "${X11_OPENGL_DIR}"/include/GL "${ED}"/usr/lib/opengl/"${PN}"/include
	x11_makelink "${X11_OPENGL_DIR}"/lib/libGL.dylib "${ED}"/usr/lib/opengl/"${PN}"/lib

	x11_makelink "${X11_OPENGL_DIR}"/include/GL/glu.h "${ED}"/usr/include/GL
	x11_makelink "${X11_OPENGL_DIR}"/include/GL/GLwDrawA.h "${ED}"/usr/include/GL
	x11_makelink "${X11_OPENGL_DIR}"/include/GL/osmesa.h "${ED}"/usr/include/GL

	x11_makelink "${X11_OPENGL_DIR}"/lib/libGLU.dylib "${ED}"/usr/lib
	x11_makelink "${X11_OPENGL_DIR}"/lib/libGLw.a "${ED}"/usr/lib

	# bug #337965
	insinto /usr/lib/pkgconfig
	doins "${WORKDIR}"/gl.pc
}

pkg_postinst() {
	# Set as default VM if none exists
	eselect opengl set --use-old ${PN}

	elog "Note: you're using your OSX (pre-)installed OpenGL X11 implementation from ${X11_OPENGL_DIR}"
}
