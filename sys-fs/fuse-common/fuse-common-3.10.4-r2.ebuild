# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit tmpfiles udev

MY_P=fuse-${PV}
DESCRIPTION="Common files for multiple slots of sys-fs/fuse"
HOMEPAGE="https://github.com/libfuse/libfuse"
SRC_URI="https://github.com/libfuse/libfuse/releases/download/${MY_P}/${MY_P}.tar.xz"
S=${WORKDIR}/${MY_P}

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86"
IUSE="+tmpfiles +udev"

BDEPEND="virtual/pkgconfig"
RDEPEND="
	acct-group/cuse
	!<sys-fs/fuse-2.9.7-r1:0
"

src_install() {
	if use udev; then
		udev_newrules util/udev.rules 99-fuse.rules
		udev_newrules - 99-cuse.rules <<-EOF
			KERNEL=="cuse", GROUP="cuse"
		EOF
	else
		rmdir -p "${ED}$(get_udevdir)"/rules.d
	fi
	use tmpfiles && newtmpfiles - static-nodes-permissions-cuse.conf <<-EOF
		z /dev/cuse 0660 root cuse - -
	EOF

	if use kernel_linux ; then
		newinitd "${FILESDIR}"/fuse.init fuse
	else
		die "We don't know what init code install for your kernel, please file a bug."
	fi

	insinto /etc
	doins util/fuse.conf
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process static-nodes-permissions-cuse.conf
	use !udev || udev_reload
}

pkg_postrm() {
	use !udev || udev_reload
}
