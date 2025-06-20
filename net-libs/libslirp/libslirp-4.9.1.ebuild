# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

KEYWORDS="amd64 arm64 ~loong ~m68k ~ppc ppc64 ~riscv x86"
MY_P="${PN}-v${PV}"
SRC_URI="https://gitlab.freedesktop.org/slirp/libslirp/-/archive/v${PV}/${MY_P}.tar.gz -> ${P}.tar.gz"
DESCRIPTION="A TCP-IP emulator used to provide virtual networking services"
HOMEPAGE="https://gitlab.freedesktop.org/slirp/libslirp"

LICENSE="BSD"
SLOT="0"
IUSE="static-libs valgrind"
RESTRICT="mirror"

RDEPEND="dev-libs/glib:="
# Valgrind usage is automagic but it's not so bad given it's a header-only dep.
DEPEND="
	${RDEPEND}
	valgrind? ( dev-debug/valgrind )
"

S=${WORKDIR}/${MY_P}

src_prepare() {
	echo "${PV}" > .tarball-version || die
	cat >build-aux/git-version-gen <<-EOF || die
		#! /bin/sh

		printf '%s' "$(
				cat "${S}/.tarball-version"
			)"
	EOF
	default
}

src_configure() {
	local emesonargs=(
		-Ddefault_library=$(usex static-libs both shared)
	)
	meson_src_configure
}
