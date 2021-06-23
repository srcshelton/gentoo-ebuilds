# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit gnome2-utils gnome.org meson-multilib xdg

DESCRIPTION="Network-related giomodules for glib"
HOMEPAGE="https://gitlab.gnome.org/GNOME/glib-networking"

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="+gnome +libproxy +ssl test"
RESTRICT="!test? ( test )"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

RDEPEND="
	>=dev-libs/glib-2.67.0:2[${MULTILIB_USEDEP}]
	libproxy? ( >=net-libs/libproxy-0.4.11-r1:=[${MULTILIB_USEDEP}] )
	>=net-libs/gnutls-3.6.5:=[${MULTILIB_USEDEP}]
	ssl? ( app-misc/ca-certificates )
	gnome? ( gnome-base/gsettings-desktop-schemas )
"
DEPEND="${RDEPEND}
	test? ( net-libs/gnutls[pkcs11] )
"
BDEPEND="
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	test? ( sys-apps/dbus )
"

src_prepare() {
	xdg_src_prepare

	if ! use test ; then
		# Don't build tests unconditionally
		# This is a hack to avoid needing gnutls[pkcs11] when USE=-test
		# It may become a real runtime dependency in future
		# Please check!
		# bug #777462
		sed -i "/^subdir('tls\/tests')/d" meson.build || die
	fi
}

multilib_src_configure() {
	local emesonargs=(
		-Dgnutls=enabled
		-Dopenssl=disabled
		$(meson_feature libproxy)
		$(meson_feature gnome gnome_proxy)
		-Dinstalled_tests=false
		-Dstatic_modules=false
	)
	meson_src_configure
}

multilib_src_test() {
	dbus-run-session meson test -C "${BUILD_DIR}" || die 'tests failed'
}

pkg_postinst() {
	xdg_pkg_postinst

	multilib_pkg_postinst() {
		if [[ ${MERGE_TYPE} != "binary" ]] ; then
			if [[ -n "${ROOT:-}" ]] && [[ "${ROOT}" != '/' ]]; then
				local -x LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${ROOT%/}/$(get_libdir):${ROOT%/}/usr/$(get_libdir)"
			fi
			gnome2_giomodule_cache_update \
				|| die "Update GIO modules cache failed (for ${ABI}, merge type '${MERGE_TYPE}')"
		fi
	}
	if [[ ${MERGE_TYPE} == "binary" ]] ; then
		ewarn "Not running GIO modules cache update for binary installation"
		ewarn
		ewarn "Upon installation on destination host, please run:"
		ewarn "    gio-querymodules /usr/$(get_libdir)/gio/modules/"
		ewarn
	else
		multilib_foreach_abi multilib_pkg_postinst
	fi
}

pkg_postrm() {
	xdg_pkg_postrm

	multilib_pkg_postrm() {
		if [[ ${MERGE_TYPE} != "binary" ]] ; then
			if [[ -n "${ROOT:-}" ]] && [[ "${ROOT}" != '/' ]]; then
				local -x LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${ROOT%/}/$(get_libdir):${ROOT%/}/usr/$(get_libdir)"
			fi
			gnome2_giomodule_cache_update \
				|| die "Update GIO modules cache failed (for ${ABI}, merge type '${MERGE_TYPE}')"
		fi
	}
	if [[ ${MERGE_TYPE} == "binary" ]] ; then
		ewarn "Not running GIO modules cache update for binary installation"
		ewarn
		ewarn "Upon installation on destination host, please run:"
		ewarn "    gio-querymodules /usr/$(get_libdir)/gio/modules/"
		ewarn
	else
		multilib_foreach_abi multilib_pkg_postrm
	fi
}

# vi: set diffopt=iwhite,filler:
