# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib-build

DESCRIPTION="Virtual for libudev providers"

SLOT="0/1"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="systemd"

# eudev used not to provide v251 APIs, see
# https://github.com/eudev-project/eudev/issues/249
RDEPEND="
	!systemd? ( || (
		>=sys-fs/eudev-3.2.14[${MULTILIB_USEDEP}]
		>=sys-apps/systemd-utils-251[udev,${MULTILIB_USEDEP}]
	) )
	systemd? ( >=sys-apps/systemd-251:0/2[${MULTILIB_USEDEP}] )
"
