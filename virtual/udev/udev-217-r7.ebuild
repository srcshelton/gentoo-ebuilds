# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Virtual to select between different udev daemon providers"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="systemd"

RDEPEND="
	!systemd? ( || (
		sys-fs/eudev
		sys-apps/systemd-utils[udev]
	) )
	systemd? ( >=sys-apps/systemd-217 )
"
