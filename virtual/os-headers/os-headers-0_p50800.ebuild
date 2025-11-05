# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Virtual for operating system headers"
SLOT="50800"
# KEYWORDS should match sys-kernel/linux-headers-5.8*
KEYWORDS="~alpha amd64 arm arm64 hppa ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="cix raspberrypi rockchip"
REQUIRED_USE="
	cix? ( || ( arm arm64 ) )
	raspberrypi? ( || ( arm arm64 ) )
	rockchip? ( || ( arm arm64 ) )
"

# depend on SLOT 0 of linux-headers, because kernel-2.eclass
# sets a different SLOT for cross-building
RDEPEND="
	!prefix-guest? (
		kernel_linux? ( || (
			arm? (
				cix? ( >=sys-kernel/cix-headers-5.8:0 )
				raspberrypi? ( >=sys-kernel/raspberrypi-headers-5.8:0 )
				rockchip? ( >=sys-kernel/rockchip-headers-5.8:0 )
			)
			arm64? (
				cix? ( >=sys-kernel/cix-headers-5.8:0 )
				raspberrypi? ( >=sys-kernel/raspberrypi-headers-5.8:0 )
				rockchip? ( >=sys-kernel/rockchip-headers-5.8:0 )
			)
			>=sys-kernel/linux-headers-5.8:0
		) )
		!kernel_linux? (
			!sys-kernel/linux-headers
		)
	)
	prefix-guest? (
		!sys-kernel/linux-headers
	)
"
