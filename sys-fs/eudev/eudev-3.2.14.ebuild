# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KV_MIN=2.6.39

inherit linux-info toolchain-funcs udev multilib-minimal

if [[ ${PV} = 9999* ]]; then
	EGIT_REPO_URI="https://github.com/eudev-project/eudev.git"
	inherit autotools git-r3
else
	MY_PV=${PV/_pre/-pre}
	SRC_URI="https://github.com/eudev-project/eudev/releases/download/v${MY_PV}/${PN}-${MY_PV}.tar.gz"
	S="${WORKDIR}"/${PN}-${MY_PV}

	if [[ ${PV} != *_pre* ]] ; then
		KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
	fi
fi

DESCRIPTION="Linux dynamic and persistent device naming support (aka userspace devfs)"
HOMEPAGE="https://github.com/eudev-project/eudev"

LICENSE="LGPL-2.1 MIT GPL-2"
SLOT="0"
IUSE="hwdb -init -kmod predictable-ifnames -rule-generator selinux static-libs test udev"
RESTRICT="!test? ( test )"

COMMON_DEPEND="
	>=sys-apps/util-linux-2.20
	virtual/libcrypt:=
	kmod? ( >=sys-apps/kmod-16 )
	selinux? ( >=sys-libs/libselinux-2.1.9 )
	!sys-apps/gentoo-systemd-integration
	!sys-apps/systemd
"
DEPEND="
	${COMMON_DEPEND}
	|| ( >=sys-kernel/raspberrypi-headers-${KV_MIN} >=sys-kernel/linux-headers-${KV_MIN} )
"
RDEPEND="
	${COMMON_DEPEND}
	acct-group/audio
	acct-group/cdrom
	acct-group/dialout
	acct-group/disk
	acct-group/floppy
	acct-group/input
	acct-group/kmem
	acct-group/kvm
	acct-group/lp
	acct-group/render
	acct-group/sgx
	acct-group/tape
	acct-group/tty
	acct-group/usb
	acct-group/video
	sys-apps/hwdata
	!sys-apps/systemd-utils[udev]
	!sys-fs/udev
	!sys-apps/systemd
	!sys-apps/hwids[udev]
"
BDEPEND="
	dev-util/gperf
	virtual/os-headers
	virtual/pkgconfig
	test? (
		app-text/tree
		dev-lang/perl
	)
"
PDEPEND="init? ( >=sys-fs/udev-init-scripts-26 )"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/udev.h
)

pkg_pretend() {
	use udev || return

	ewarn
	ewarn "As of 2013-01-29, ${PN} provides the new interface renaming functionality,"
	ewarn "as described in the URL below:"
	ewarn "https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames"
	ewarn
	ewarn "This functionality is enabled BY DEFAULT because eudev has no means of synchronizing"
	ewarn "between the default or user-modified choice of sys-fs/udev.  If you wish to disable"
	ewarn "this new iface naming, please be sure that /etc/udev/rules.d/80-net-name-slot.rules"
	ewarn "exists: touch /etc/udev/rules.d/80-net-name-slot.rules"
	ewarn
}

pkg_setup() {
	CONFIG_CHECK="~BLK_DEV_BSG ~DEVTMPFS ~INOTIFY_USER ~SIGNALFD ~EPOLL ~FHANDLE ~NET ~UNIX" # ~!IDE
	linux-info_pkg_setup
	get_running_version

	if kernel_is lt 6.4.0; then
		CONFIG_CHECK="${CONFIG_CHECK} ~!SYSFS_DEPRECATED ~!SYSFS_DEPRECATED_V2"
	fi

	# These are required kernel options, but we don't error out on them
	# because you can build under one kernel and run under another.
	if kernel_is lt ${KV_MIN//./ }; then
		ewarn
		ewarn "Your current running kernel version ${KV_FULL} is too old to run ${P}."
		ewarn "Make sure to run udev under kernel version ${KV_MIN} or above."
		ewarn
	fi
}

src_prepare() {
	default

	# Change rules back to group uucp instead of dialout for now
	sed -e 's/GROUP="dialout"/GROUP="uucp"/' -i rules/*.rules \
		|| die "failed to change group dialout to uucp"

	if [[ ${PV} == 9999* ]] ; then
		eautoreconf
	fi
}

multilib_src_configure() {
	# bug #463846
	tc-export CC
	# bug #502950
	export cc_cv_CFLAGS__flto=no

	local myeconfargs=(
		ac_cv_search_cap_init=
		ac_cv_header_sys_capability_h=yes

		DBUS_CFLAGS=' '
		DBUS_LIBS=' '

		--with-rootprefix="${EPREFIX}"
		--with-rootrundir=/var/run
		--exec-prefix="${EPREFIX}"
		--bindir="${EPREFIX}"/bin
		--sbindir="${EPREFIX}"/sbin
		--includedir="${EPREFIX}"/usr/include
		--libdir="${EPREFIX}/usr/$(get_libdir)"
		--with-rootlibexecdir="${EPREFIX}"/lib/udev
		--enable-split-usr
		--enable-manpages
	)

	# Only build libudev for non-native_abi, and only install it to libdir,
	# that means all options only apply to native_abi
	if multilib_is_native_abi ; then
		myeconfargs+=(
			--with-rootlibdir="${EPREFIX}/$(get_libdir)"
			$(use_enable kmod)
			$(use_enable static-libs static)
			$(use_enable selinux)
			$(use_enable rule-generator)
		)
	else
		myeconfargs+=(
			--disable-static
			--disable-kmod
			--disable-selinux
			--disable-rule-generator
			--disable-hwdb
		)
	fi

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_compile() {
	if multilib_is_native_abi ; then
		emake
	else
		emake -C src/shared
		emake -C src/libudev
	fi
}

multilib_src_test() {
	# Make sandbox get out of the way.
	# These are safe because there is a fake root filesystem put in place,
	# but sandbox seems to evaluate the paths of the test i/o instead of the
	# paths of the actual i/o that results. Also only test for native abi
	if multilib_is_native_abi ; then
		addread /sys
		addwrite /dev
		addwrite /var/run

		default
	fi
}

multilib_src_install() {
	if multilib_is_native_abi ; then
		emake DESTDIR="${D}" install
	else
		emake -C src/libudev DESTDIR="${D}" install
	fi
}

multilib_src_install_all() {
	find "${ED}" -name '*.la' -delete || die

	if ! use udev; then
		rm -r "${ED}"/usr/share/man "${ED}"/sbin "${ED}"/bin
		[[ -d "${ED}$(get_udevdir)" ]] && rm -r "${ED}$(get_udevdir)"
		use hwdb || rm -r "${ED}"/etc/udev
	else
		insinto "$(get_udevdir)"/rules.d
		doins "${FILESDIR}"/40-gentoo.rules

		use rule-generator && doinitd "${FILESDIR}"/udev-postmount
		if ! use predictable-ifnames; then
			dodir /etc/udev/rules.d
			touch "${ED}"/etc/udev/rules.d/80-net-name-slot.rules
		fi
		use hwdb || rm -r "${ED}"/etc/udev/hwdb.d
	fi
}

pkg_postrm() {
	use udev && udev_reload
}

pkg_postinst() {
	if use udev; then
		udev_reload

		#mkdir -p "${EROOT}"/var/run

		# "losetup -f" is confused if there is an empty /dev/loop/, Bug #338766
		# So try to remove it here (will only work if empty).
		rmdir "${EROOT}"/dev/loop 2>/dev/null
		if [[ -d ${EROOT}/dev/loop ]]; then
			ewarn "Please make sure your remove /dev/loop,"
			ewarn "else losetup may be confused when looking for unused devices."
		fi

		# REPLACING_VERSIONS should only ever have zero or 1 values but in case it doesn't,
		# process it as a list.  We only care about the zero case (new install) or the case where
		# the same version is being re-emerged.  If there is a second version, allow it to abort.
		local rv rvres=doitnew
		for rv in ${REPLACING_VERSIONS} ; do
			if [[ ${rvres} == doit* ]]; then
				if [[ ${rv%-r*} == ${PV} ]]; then
					rvres=doit
				else
					rvres=${rv}
				fi
			fi
		done

		#if has_version 'sys-apps/hwids[udev]'; then
			udevadm hwdb --update --root="${ROOT}"

			# https://cgit.freedesktop.org/systemd/systemd/commit/?id=1fab57c209035f7e66198343074e9cee06718bda
			# reload database after it has be rebuilt, but only if we are not upgrading
			# also pass if we are -9999 since who knows what hwdb related changes there might be
			if [[ ${rvres} == doit* ]] && [[ -z ${ROOT} ]] && [[ ${PV} != "9999" ]]; then
				udevadm control --reload
			fi
		#fi

		if [[ ${rvres} != doitnew ]]; then
			ewarn
			ewarn "You need to restart eudev as soon as possible to make the"
			ewarn "upgrade go into effect:"
			ewarn "\t/etc/init.d/udev --nodeps restart"
		fi

		if use rule-generator &&
				[[ -x $(type -P rc-update) ]] &&
				rc-update show |
					grep udev-postmount |
					grep -qsv 'boot\|default\|sysinit'
		then
			ewarn
			ewarn "Please add the udev-postmount init script to your default runlevel"
			ewarn "to ensure the legacy rule-generator functionality works as reliably"
			ewarn "as possible."
			ewarn "\trc-update add udev-postmount default"
		fi

		elog
		elog "For more information on eudev on Gentoo, writing udev rules, and"
		elog "fixing known issues visit: https://wiki.gentoo.org/wiki/Eudev"
	fi
}
