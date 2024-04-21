# Copyright 2021-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake optfeature toolchain-funcs xdg-utils

DESCRIPTION="A monitor of resources"
HOMEPAGE="https://github.com/aristocratos/btop"
SRC_URI="
	https://github.com/aristocratos/btop/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ~loong ~m68k ~mips ~ppc ppc64 ~riscv x86"
IUSE="gui +themes"

IDEPEND="
	gui? (
		dev-util/desktop-file-utils
		x11-misc/shared-mime-info
	)
"

pkg_setup() {
	if [[ "${MERGE_TYPE}" != "binary" ]]; then
		if tc-is-clang ; then
			if [[ "$(clang-major-version)" -lt 16 ]]; then
				die "sys-process/btop requires >=sys-devel/clang-16.0.0 to build."
			fi
		elif ! tc-is-gcc ; then
			die "$(tc-getCXX) is not a supported compiler. Please use sys-devel/gcc or >=sys-devel/clang-16.0.0 instead."
		fi
	fi
}

src_configure() {
	local mycmakeargs=(
		-DBTOP_GPU=true
		-DBTOP_RSMI_STATIC=false
		# Fortification can be set in CXXFLAGS instead
		-DBTOP_FORTIFY=false
	)
	cmake_src_configure
}

src_install() {
	default

	use gui ||
		rm -r "${ED}"/usr/share/{applications,icons}
	use themes ||
		rm -r "${ED}"/usr/share/btop/themes
	rmdir -p "${ED}"/usr/share/btop &>/dev/null
}

pkg_preinst() {
	local f

	if use gui; then
		# From xdg.eclass...

		declare -a XDG_ECLASS_DESKTOPFILES=() XDG_ECLASS_ICONFILES=() \
			XDG_ECLASS_MIMEINFOFILES=()

		while IFS= read -r -d '' f; do
			XDG_ECLASS_DESKTOPFILES+=( ${f} )
		done < <( # <- Syntax
			cd "${ED}" &&
				find 'usr/share/applications' -type f -print0 2>/dev/null
		)

		while IFS= read -r -d '' f; do
			XDG_ECLASS_ICONFILES+=( ${f} )
		done < <( # <- Syntax
			cd "${ED}" &&
				find 'usr/share/icons' -type f -print0 2>/dev/null
		)

		while IFS= read -r -d '' f; do
			XDG_ECLASS_MIMEINFOFILES+=( ${f} )
		done < <( # <- Syntax
			cd "${ED}" &&
				find 'usr/share/mime' -type f -print0 2>/dev/null
		)
	fi
}

pkg_postinst() {
	if use gui; then
		# From xdg.eclass...

		if [[ ${#XDG_ECLASS_DESKTOPFILES[@]} -gt 0 ]]; then
			xdg_desktop_database_update
		else
			debug-print "No .desktop files to add to database"
		fi

		if [[ ${#XDG_ECLASS_ICONFILES[@]} -gt 0 ]]; then
			xdg_icon_cache_update
		else
			debug-print "No icon files to add to cache"
		fi

		if [[ ${#XDG_ECLASS_MIMEINFOFILES[@]} -gt 0 ]]; then
			xdg_mimeinfo_database_update
		else
			debug-print "No mime info files to add to database"
		fi
	fi

	optfeature "GPU monitoring support (Radeon GPUs)" dev-util/rocm-smi
	optfeature "GPU monitoring support (NVIDIA GPUs)" x11-drivers/nvidia-drivers
}

pkg_postrm() {
	if use gui; then
		# From xdg.eclass...

		if [[ ${#XDG_ECLASS_DESKTOPFILES[@]} -gt 0 ]]; then
			xdg_desktop_database_update
		else
			debug-print "No .desktop files to add to database"
		fi

		if [[ ${#XDG_ECLASS_ICONFILES[@]} -gt 0 ]]; then
			xdg_icon_cache_update
		else
			debug-print "No icon files to add to cache"
		fi

		if [[ ${#XDG_ECLASS_MIMEINFOFILES[@]} -gt 0 ]]; then
			xdg_mimeinfo_database_update
		else
			debug-print "No mime info files to add to database"
		fi
	fi
}
