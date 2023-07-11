# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Virtual to select between different tmpfiles.d handlers"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="systemd tmpfiles"

RDEPEND="
	!prefix-guest? (
		systemd? ( sys-apps/systemd )
		!systemd? (
			tmpfiles? ( || (
				sys-apps/systemd-utils[tmpfiles]
				sys-apps/systemd-tmpfiles
			) )
		)
	)
"