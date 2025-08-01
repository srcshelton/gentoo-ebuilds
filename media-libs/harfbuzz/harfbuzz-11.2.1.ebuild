# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

PARALLEL_MEMORY_MIN=2

inherit flag-o-matic meson-multilib python-any-r1 xdg-utils

DESCRIPTION="An OpenType text shaping engine"
HOMEPAGE="https://harfbuzz.github.io/"

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://github.com/harfbuzz/harfbuzz.git"
	inherit git-r3
else
	SRC_URI="https://github.com/harfbuzz/harfbuzz/releases/download/${PV}/${P}.tar.xz"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
fi

LICENSE="Old-MIT ISC icu"
# 0.9.18 introduced the harfbuzz-icu split; bug #472416
# 3.0.0 dropped some unstable APIs; bug #813705
# 6.0.0 changed libharfbuzz-subset.so ABI
SLOT="0/6.0.0"

IUSE="+cairo debug doc experimental +glib +graphite icu +introspection test +truetype"
RESTRICT="!test? ( test )"
REQUIRED_USE="introspection? ( glib )"

RDEPEND="
	cairo? ( x11-libs/cairo:=[${MULTILIB_USEDEP}] )
	glib? ( >=dev-libs/glib-2.38:2[${MULTILIB_USEDEP}] )
	graphite? ( >=media-gfx/graphite2-1.2.1:=[${MULTILIB_USEDEP}] )
	icu? ( >=dev-libs/icu-51.2-r1:=[${MULTILIB_USEDEP}] )
	introspection? ( >=dev-libs/gobject-introspection-1.34:= )
	truetype? ( >=media-libs/freetype-2.5.0.1:2=[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	sys-apps/help2man
	virtual/pkgconfig
	doc? ( dev-util/gtk-doc )
	introspection? ( dev-util/glib-utils )
"

src_prepare() {
	default

	xdg_environment_reset

	# bug #790359
	filter-flags -fexceptions -fthreadsafe-statics

	if ! use debug ; then
		append-cppflags -DHB_NDEBUG
	fi
}

multilib_src_configure() {
	# harfbuzz-gobject only used for introspection, bug #535852
	local emesonargs=(
		-Dcoretext=disabled
		-Dchafa=disabled
		-Dfontations=disabled
		-Dwasm=disabled

		$(meson_feature cairo)
		$(meson_feature glib)
		$(meson_feature graphite graphite2)
		$(meson_feature icu)
		$(meson_feature introspection gobject)
		$(meson_feature test tests)
		$(meson_feature truetype freetype)

		$(meson_native_use_feature doc docs)
		$(meson_native_use_feature introspection)
		# Breaks building tests..
		#$(meson_native_use_feature utilities)

		$(meson_use experimental experimental_api)
	)

	if (( ( $( # <- Syntax
			head /proc/meminfo |
				grep -m 1 '^MemAvailable:' |
				awk '{ print $2 }'
		) / ( 1024 * 1024 ) ) < PARALLEL_MEMORY_MIN ))
	then
		if [[ "${EMERGE_DEFAULT_OPTS:-}" == *-j* ]]; then
			ewarn "make.conf or environment contains parallel build directive,"
			ewarn "memory usage may be increased" \
				"(or adjust \$EMERGE_DEFAULT_OPTS)"
		fi
		ewarn "Lowering make parallelism for low-memory build-host ..."
		if ! [[ -n "${MAKEOPTS:-}" ]]; then
			export MAKEOPTS='-j1'
		elif ! [[ "${MAKEOPTS}" == *-j* ]]; then
			export MAKEOPTS="-j1 ${MAKEOPTS}"
		else
			export MAKEOPTS="-j1 $( sed 's/-j\s*[0-9]\+//' <<<"${MAKEOPTS}" )"
		fi
		if test-flag-CC '-Wa,--reduce-memory-overheads'; then
			ewarn "Instructing 'as' to use less memory ..."
			append-ldflags '-Wa,--reduce-memory-overheads'
		fi
		for flag in no-keep-memory reduce-memory-overheads \
			no-map-whole-files no-mmap-output-file
		do
			if test-flag-CCLD "-Wl,--${flag}"; then
				ewarn "Instructing 'ld' to use less memory with '--${flag}' ..."
				append-ldflags "-Wl,--${flag}"
			fi
		done
		ewarn "Disabling LTO support ..."
		filter-lto
	fi

	meson_src_configure
}

multilib_src_test() {
	# harfbuzz:src / check-static-inits times out on hppa
	meson_src_test --timeout-multiplier 5
}
