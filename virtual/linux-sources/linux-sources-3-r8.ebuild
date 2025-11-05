# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for Linux kernel sources"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86"
IUSE="apple cix firmware mixtile raspberrypi"
REQUIRED_USE="
	apple? ( || ( arm arm64 ) )
	cix? ( || ( arm arm64 ) )
	mixtile? ( || ( arm arm64 ) )
	raspberrypi? ( || ( arm arm64 ) )
"

RDEPEND="
	firmware? ( sys-kernel/linux-firmware )
	mips? ( || (
		sys-kernel/mips-sources
		sys-kernel/gentoo-sources
		sys-kernel/vanilla-sources
	) )
	!mips? (
		arm64? ( || (
			apple? ( sys-kernel/asahi-sources )
			cix? ( sys-kernel/cix-sources )
			mixtile? ( sys-kernel/mixtile-sources )
			raspberrypi? ( sys-kernel/raspberrypi-sources )
			sys-kernel/gentoo-sources
			sys-kernel/vanilla-sources
		) )
		!arm64? ( || (
			sys-kernel/gentoo-sources
			sys-kernel/vanilla-sources
			sys-kernel/git-sources
			sys-kernel/pf-sources
			sys-kernel/rt-sources
			sys-kernel/zen-sources
			sys-kernel/gentoo-kernel
			sys-kernel/gentoo-kernel-bin
			sys-kernel/vanilla-kernel
			sys-kernel/linux-next
		) )
	)
"
