# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/eudev/eudev-3.0.ebuild,v 1.1 2015/03/20 00:11:55 blueness Exp $

EAPI="5"

KV_min=2.6.39

inherit autotools eutils multilib user multilib-minimal

if [[ ${PV} = 9999* ]]; then
	EGIT_REPO_URI="https://github.com/gentoo/eudev.git"
	inherit git-2
else
	SRC_URI="https://dev.gentoo.org/~blueness/${PN#lib}/${P#lib}.tar.gz"
	KEYWORDS="~amd64 ~arm ~hppa ~mips ~ppc ~ppc64 ~x86"
fi

DESCRIPTION="Linux dynamic and persistent device naming support (aka userspace devfs)"
HOMEPAGE="https://github.com/gentoo/eudev"

LICENSE="LGPL-2.1 MIT GPL-2"
SLOT="0"
IUSE="doc static-libs test"

COMMON_DEPEND=">=sys-apps/util-linux-2.20
	!<sys-libs/glibc-2.11
	!sys-apps/gentoo-systemd-integration
	!sys-apps/systemd
	abi_x86_32? (
		!<=app-emulation/emul-linux-x86-baselibs-20130224-r7
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
	)"
DEPEND="${COMMON_DEPEND}
	dev-util/gperf
	virtual/os-headers
	virtual/pkgconfig
	>=sys-devel/make-3.82-r4
	>=sys-kernel/linux-headers-${KV_min}
	>=dev-util/intltool-0.50
	test? ( app-text/tree dev-lang/perl )"

RDEPEND="${COMMON_DEPEND}
	!<sys-fs/lvm2-2.02.103
	!<sec-policy/selinux-base-2.20120725-r10
	!sys-fs/eudev
	!sys-fs/udev
	!sys-apps/systemd"

PDEPEND=""

S="${WORKDIR}/${P#lib}"

# The multilib-build.eclass doesn't handle situation where the installed headers
# are different in ABIs. In this case, we install libgudev headers in native
# ABI but not for non-native ABI.
multilib_check_headers() { :; }

src_prepare() {
	epatch_user

	echo 'EXTRA_DIST =' > docs/gtk-doc.make

	# This may break without WANT_AUTOMAKE=1.13, but we
	# we want this so we can fix problems upstream.
	eautoreconf
}

multilib_src_configure() {
	tc-export CC #463846
	export cc_cv_CFLAGS__flto=no #502950

	# Keep sorted by ./configure --help and only pass --disable flags
	# when *required* to avoid external deps or unnecessary compile
	local econf_args
	econf_args=(
		ac_cv_search_cap_init=
		ac_cv_header_sys_capability_h=yes
		DBUS_CFLAGS=' '
		DBUS_LIBS=' '
		--with-rootprefix=
		--docdir=/usr/share/doc/${PF}
		--libdir=/usr/$(get_libdir)
		--with-rootlibexecdir=/lib/udev
		--with-html-dir="/usr/share/doc/${PF}/html"
		--enable-split-usr
		--exec-prefix=/

		--disable-gudev
	)

	# Only build libudev for non-native_abi, and only install it to libdir,
	# that means all options only apply to native_abi
	if multilib_is_native_abi; then
		econf_args+=(
			--with-rootlibdir=/$(get_libdir)
			--disable-gtk-doc
			--disable-introspection
			--disable-kmod
			--disable-selinux
			$(use_enable static-libs static)
		)
	else
		econf_args+=(
			--disable-gtk-doc
			--disable-introspection
			--disable-kmod
			--disable-selinux
			--disable-static
		)
	fi
	ECONF_SOURCE="${S}" econf "${econf_args[@]}"
}

multilib_src_compile() {
	emake -C src/shared
	emake -C src/libudev
}

multilib_src_install() {
	emake -C src/libudev DESTDIR="${D}" install
}

multilib_src_test() {
	# make sandbox get out of the way
	# these are safe because there is a fake root filesystem put in place,
	# but sandbox seems to evaluate the paths of the test i/o instead of the
	# paths of the actual i/o that results.
	# also only test for native abi
	if multilib_is_native_abi; then
		addread /sys
		addwrite /dev
		addwrite /run
		default_src_test
	fi
}

multilib_src_install_all() {
	prune_libtool_files --all
	rm -rf "${ED}"/usr/share/doc/${PF}/LICENSE.*

	# drop distributed hwdb files, they override sys-apps/hwids
	rm -f "${ED}"/etc/udev/hwdb.d/*.hwdb

	# We can't re-generate an hwdb.bin files from hwdb.d or sys-apps/hwids if
	# we're only installing libudev, so we have to ship a binary blob :(
	#
	# This is required for, at least, sys-apps/usbutils.  Without further
	# configuration, the only directory examined for this file is /etc/udev,
	# rather than any lib/udev directories.
	#
	# This one is from ubuntu-14.04.2-LTS...
	insinto /etc/udev
	doins "${FILESDIR}"/hwdb.bin

	if use doc; then
		insinto /usr/share/doc/${PF}/html/libudev
		doins "${S}"/docs/libudev/html/*
	fi
}

pkg_preinst() {
	local htmldir
	for htmldir in gudev libudev; do
		if [[
			   -d ${EROOT}usr/share/gtk-doc/html/${htmldir}
			&& -d ${ED}/usr/share/doc/${PF}/html/${htmldir}
		]]; then
			rm -rf "${EROOT}"usr/share/gtk-doc/html/${htmldir}
		fi
		if [[ -d ${ED}/usr/share/doc/${PF}/html/${htmldir} ]]; then
			dosym ../../doc/${PF}/html/${htmldir} \
				/usr/share/gtk-doc/html/${htmldir}
		fi
	done
}
