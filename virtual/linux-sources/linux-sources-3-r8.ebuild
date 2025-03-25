# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for Linux kernel sources"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="apple firmware raspberrypi rockchip"
REQUIRED_USE="
	apple? ( || ( arm arm64 ) )
	raspberrypi? ( || ( arm arm64 ) )
	rockchip? ( || ( arm arm64 ) )
"

RDEPEND="
	firmware? ( sys-kernel/linux-firmware )
	mips? ( || (
		sys-kernel/mips-sources
		sys-kernel/gentoo-sources
		sys-kernel/vanilla-sources
	) )
	!mips? (
		arm64? (
			raspberrypi? ( || (
				sys-kernel/raspberrypi-sources
				sys-kernel/gentoo-sources
				sys-kernel/vanilla-sources
			) )
			!raspberrypi? (
				rockchip? (
					sys-kernel/mixtile-sources
					sys-kernel/gentoo-sources
					sys-kernel/vanilla-sources
				)
				!rockchip? (
					apple? (
						sys-kernel/asahi-sources
						sys-kernel/gentoo-sources
						sys-kernel/vanilla-sources
					)
					!apple? (
						sys-kernel/gentoo-sources
						sys-kernel/vanilla-sources
					)
				)
			)
		)
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
