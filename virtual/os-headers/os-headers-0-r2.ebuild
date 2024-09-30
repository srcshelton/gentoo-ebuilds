# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual for operating system headers"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"

# depend on SLOT 0 of linux-headers, because kernel-2.eclass
# sets a different SLOT for cross-building
RDEPEND="
	!prefix-guest? (
		kernel_linux? (
			arm64? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			arm? ( || (
				sys-kernel/raspberrypi-headers:0
				sys-kernel/linux-headers:0
			) )
			!arm64? ( !arm? (
				sys-kernel/linux-headers:0
			) )
		)
	)
	prefix-guest? (
		!sys-kernel/linux-headers
	)
"
