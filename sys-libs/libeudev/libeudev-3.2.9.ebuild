# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

KV_min=2.6.39

inherit autotools multilib multilib-minimal

if [[ ${PV} = 9999* ]]; then
	EGIT_REPO_URI="https://github.com/gentoo/eudev.git"
	inherit git-r3
else
	SRC_URI="https://dev.gentoo.org/~blueness/${PN#lib}/${P#lib}.tar.gz"
	KEYWORDS="~alpha amd64 arm arm64 hppa ia64 ~mips ppc ppc64 ~riscv sparc x86"
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
BDEPEND="${COMMON_DEPEND}
	dev-util/gperf
	virtual/os-headers
	virtual/pkgconfig
	>=sys-devel/make-3.82-r4
	>=sys-kernel/linux-headers-${KV_min}
	>=dev-util/intltool-0.50
	test? ( app-text/tree dev-lang/perl )"

RDEPEND="${COMMON_DEPEND}
	acct-group/input
	acct-group/kvm
	acct-group/render
	!<sys-fs/lvm2-2.02.103
	!<sec-policy/selinux-base-2.20120725-r10
	!sys-fs/eudev
	!sys-fs/udev
	!sys-apps/systemd"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/udev.h
)

S="${WORKDIR}/${P#lib}"

#pkg_setup() {
#	CONFIG_CHECK="~BLK_DEV_BSG ~DEVTMPFS ~!IDE ~INOTIFY_USER ~!SYSFS_DEPRECATED ~!SYSFS_DEPRECATED_V2 ~SIGNALFD ~EPOLL ~FHANDLE ~NET ~UNIX"
#	linux-info_pkg_setup
#	get_running_version
#
#	# These are required kernel options, but we don't error out on them
#	# because you can build under one kernel and run under another.
#	if kernel_is lt ${KV_min//./ }; then
#		ewarn
#		ewarn "Your current running kernel version ${KV_FULL} is too old to run ${P}."
#		ewarn "Make sure to run udev under kernel version ${KV_min} or above."
#		ewarn
#	fi
#
#	# Unfortunately, the linux-info eclass does error :(
#}

# The multilib-build.eclass doesn't handle situation where the installed headers
# are different in ABIs. In this case, we install libgudev headers in native
# ABI but not for non-native ABI.
multilib_check_headers() { :; }

src_prepare() {
	# change rules back to group uucp instead of dialout for now
	sed -e 's/GROUP="dialout"/GROUP="uucp"/' -i rules/*.rules \
	|| die "failed to change group dialout to uucp"

	eapply_user

	[[ -d docs ]] && echo 'EXTRA_DIST =' > docs/gtk-doc.make

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
		--with-rootrundir="${EPREFIX%/}"/var/run
		--exec-prefix="${EPREFIX}"
		--bindir="${EPREFIX%/}"/bin
		--includedir="${EPREFIX%/}"/usr/include
		--libdir="${EPREFIX%/}"/usr/"$(get_libdir)"
		--with-rootlibexecdir="${EPREFIX%/}"/lib/udev
		--enable-split-usr
		--enable-manpages
		--disable-hwdb
		--disable-gudev
		--docdir=/usr/share/doc/${PF}
		--with-html-dir="/usr/share/doc/${PF}/html"
	)

	# Only build libudev for non-native_abi, and only install it to libdir,
	# that means all options only apply to native_abi
	if multilib_is_native_abi; then
		econf_args+=(
			--with-rootlibdir="${EPREFIX%/}"/$(get_libdir)
			--disable-introspection
			--disable-kmod
			$(use_enable static-libs static)
			--disable-selinux
			--disable-rule-generator
			--disable-gtk-doc
		)
	else
		econf_args+=(
			--disable-static
			--disable-introspection
			--disable-kmod
			--disable-selinux
			--disable-rule-generator
			--disable-gtk-doc
		)
	fi
	ECONF_SOURCE="${S}" econf "${econf_args[@]}"
}

multilib_src_compile() {
	#if multilib_is_native_abi; then
	#	emake
	#else
		emake -C src/shared
		emake -C src/libudev
	#fi
}

multilib_src_install() {
	#if multilib_is_native_abi; then
	#	emake DESTDIR="${D}" install
	#else
		emake -C src/libudev DESTDIR="${D}" install
	#fi
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
		addwrite /var/run
		default_src_test
	fi
}

multilib_src_install_all() {
	find "${D}" -name '*.la' -delete || die

	rm -rf "${ED%/}"/usr/share/doc/${PF}/LICENSE.*

	# drop distributed hwdb files, they override sys-apps/hwids
	rm -f "${ED%/}"/etc/udev/hwdb.d/*.hwdb

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
			&& -d ${ED%/}/usr/share/doc/${PF}/html/${htmldir}
		]]; then
			rm -rf "${EROOT}"usr/share/gtk-doc/html/${htmldir}
		fi
		if [[ -d ${ED%/}/usr/share/doc/${PF}/html/${htmldir} ]]; then
			dosym ../../doc/${PF}/html/${htmldir} \
				/usr/share/gtk-doc/html/${htmldir}
		fi
	done
}

pkg_postinst() {
	elog "For more information on eudev on Gentoo, writing udev rules, and"
	elog "fixing known issues visit: https://wiki.gentoo.org/wiki/Eudev"
}
