# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Virtual for operating system headers"
SLOT="40400"
# KEYWORDS should match sys-kernel/linux-headers-4.4*
KEYWORDS="~alpha amd64 arm arm64 hppa ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="raspberrypi rockchip"
REQUIRED_USE="
	raspberrypi? ( || ( arm arm64 ) )
	rockchip? ( || ( arm arm64 ) )
"

# depend on SLOT 0 of linux-headers, because kernel-2.eclass
# sets a different SLOT for cross-building
RDEPEND="
	!prefix-guest? (
		kernel_linux? (
			!arm? (
				!arm64? (
					>=sys-kernel/linux-headers-4.4:0
				)
				arm64? (
					raspberrypi? (
						>=sys-kernel/raspberrypi-headers-4.4:0
					)
					!raspberrypi? (
						rockchip? (
							>=sys-kernel/rockchip-headers-4.4:0
						)
						!rockchip? (
							>=sys-kernel/linux-headers-4.4:0
						)
					)
				)
			)
			arm? (
				raspberrypi? (
					>=sys-kernel/raspberrypi-headers-4.4:0
				)
				!raspberrypi? (
					rockchip? (
						>=sys-kernel/rockchip-headers-4.4:0
					)
					!rockchip? (
						>=sys-kernel/linux-headers-4.4:0
					)
				)
			)
		)
		!kernel_linux? (
			!sys-kernel/linux-headers
		)
	)
	prefix-guest? (
		!sys-kernel/linux-headers
	)
"
