# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/fuse/fuse-2.9.2.ebuild,v 1.15 2014/08/10 20:19:38 slyfox Exp $

EAPI=5
inherit eutils libtool linux-info udev toolchain-funcs

MY_P=${P/_/-}
DESCRIPTION="An interface for filesystems implemented in userspace"
HOMEPAGE="http://fuse.sourceforge.net"
SRC_URI="https://github.com/libfuse/libfuse/releases/download/${PN}_2_9_4/${P}.tar.gz" # Really...

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux"
IUSE="examples kernel_linux kernel_FreeBSD static-libs udev"

PDEPEND="kernel_FreeBSD? ( sys-fs/fuse4bsd )"
DEPEND="virtual/pkgconfig"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	if use kernel_linux ; then
		if kernel_is lt 2 6 9 ; then
			die "Your kernel is too old."
		fi
		CONFIG_CHECK="~FUSE_FS"
		FUSE_FS_WARNING="You need to have FUSE module built to use user-mode utils"
		linux-info_pkg_setup
	fi
}

src_prepare() {
	# sandbox violation with mtab writability wrt #438250
	# don't sed configure.in without eautoreconf because of maintainer mode
	sed -i 's:umount --fake:true --fake:' configure || die
	elibtoolize
}

src_configure() {
	econf \
		INIT_D_PATH="${EPREFIX}/etc/init.d" \
		MOUNT_FUSE_PATH="${EPREFIX}/sbin" \
		UDEV_RULES_PATH="${EPREFIX}/$(get_udevdir)/rules.d" \
		$(use_enable static-libs static) \
		--disable-example
}

src_install() {
	default

	dodoc AUTHORS ChangeLog Filesystems README \
		README.NFS NEWS doc/how-fuse-works \
		doc/kernel.txt FAQ

	if use examples ; then
		docinto examples
		dodoc example/*
	fi

	if use kernel_linux ; then
		newinitd "${FILESDIR}"/fuse.init fuse
	elif use kernel_FreeBSD ; then
		insinto /usr/include/fuse
		doins include/fuse_kernel.h
		newinitd "${FILESDIR}"/fuse-fbsd.init fuse
	else
		die "We don't know what init code install for your kernel, please file a bug."
	fi

	prune_libtool_files
	rm -rf "${D}"/dev

	if ! use udev; then
		rm "${ED}"/$(get_udevdir)/rules.d/99-fuse.rules
		rmdir -p "${ED}"/$(get_udevdir)/rules.d
	fi

	dodir /etc
	cat > "${ED}"/etc/fuse.conf <<-EOF
		# Set the maximum number of FUSE mounts allowed to non-root users.
		# The default is 1000.
		#
		#mount_max = 1000

		# Allow non-root users to specify the 'allow_other' or 'allow_root'
		# mount options.
		#
		#user_allow_other
	EOF
}
