# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for operating system headers"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="rpi-all rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi-cm5"
REQUIRED_USE="
	rpi-all? ( !rpi0 !rpi02 !rpi1 !rpi-cm !rpi2 !rpi-cm2 !rpi3 !rpi-cm3 !rpi4 !rpi400 !rpi-cm4 !rpi-cm4s !rpi5 !rpi-cm5 )
	rpi-all? ( || ( arm arm64 ) )
	rpi0? ( || ( arm arm64 ) )
	rpi02? ( || ( arm arm64 ) )
	rpi1? ( || ( arm arm64 ) )
	rpi-cm? ( || ( arm arm64 ) )
	rpi2? ( || ( arm arm64 ) )
	rpi-cm2? ( || ( arm arm64 ) )
	rpi3? ( || ( arm arm64 ) )
	rpi-cm3? ( || ( arm arm64 ) )
	rpi4? ( || ( arm arm64 ) )
	rpi400? ( || ( arm arm64 ) )
	rpi-cm4? ( || ( arm arm64 ) )
	rpi5? ( || ( arm arm64 ) )
	rpi-cm5? ( || ( arm arm64 ) )
"

# depend on SLOT 0 of linux-headers, because kernel-2.eclass
# sets a different SLOT for cross-building
RDEPEND="
	!prefix-guest? (
		kernel_linux? ( || (
			rpi-all? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi0? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi02? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi1? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi-cm? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi2? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi-cm2? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi3? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi-cm3? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi4? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi400? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi-cm4? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			rpi5? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			sys-kernel/linux-headers:0
		) )
	)
	prefix-guest? (
		!sys-kernel/linux-headers
	)
"
