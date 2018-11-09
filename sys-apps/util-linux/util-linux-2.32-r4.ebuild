# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit toolchain-funcs libtool flag-o-matic bash-completion-r1 \
	pam python-single-r1 multilib-minimal multiprocessing systemd

MY_PV="${PV/_/-}"
MY_P="${PN}-${MY_PV}"

if [[ ${PV} == 9999 ]] ; then
	inherit git-r3 autotools
	EGIT_REPO_URI="https://git.kernel.org/pub/scm/utils/util-linux/util-linux.git"
else
	[[ "${PV}" = *_rc* ]] || \
	KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~amd64-linux ~x86-linux"
	SRC_URI="mirror://kernel/linux/utils/util-linux/v${PV:0:4}/${MY_P}.tar.xz"
fi

DESCRIPTION="Various useful Linux utilities"
HOMEPAGE="https://www.kernel.org/pub/linux/utils/util-linux/ https://github.com/karelzak/util-linux"

LICENSE="GPL-2 LGPL-2.1 BSD-4 MIT public-domain"
SLOT="0"
IUSE="build caps +cramfs fdformat kill ncurses nls pam python +readline selinux slang static-libs +suid systemd test tty-helpers udev unicode userland_GNU"

# Most lib deps here are related to programs rather than our libs,
# so we rarely need to specify ${MULTILIB_USEDEP}.
RDEPEND="caps? ( sys-libs/libcap-ng )
	cramfs? ( sys-libs/zlib:= )
	ncurses? ( >=sys-libs/ncurses-5.2-r2:0=[unicode?] )
	nls? ( virtual/libintl[${MULTILIB_USEDEP}] )
	pam? ( sys-libs/pam )
	python? ( ${PYTHON_DEPS} )
	readline? ( sys-libs/readline:0= )
	selinux? ( >=sys-libs/libselinux-2.2.2-r4[${MULTILIB_USEDEP}] )
	slang? ( sys-libs/slang )
	!build? ( systemd? ( sys-apps/systemd ) )
	udev? ( virtual/libudev:= )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
	static-libs? ( ncurses? ( sys-libs/ncurses[static-libs?] ) readline? ( sys-libs/readline[static-libs?] ) )
	test? ( sys-devel/bc )
	virtual/os-headers"
RDEPEND+="
	kill? (
		!sys-apps/coreutils[kill]
		!sys-process/procps[kill]
	)
	!net-wireless/rfkill
	!sys-process/schedutils
	!sys-apps/setarch
	!<sys-apps/sysvinit-2.88-r7
	!<sys-libs/e2fsprogs-libs-1.41.8
	!<sys-fs/e2fsprogs-1.41.8
	!<app-shells/bash-completion-2.7-r1"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	default

	eapply "${FILESDIR}"/${P}-add-missing-lintl.patch
	touch -r "${S}"/configure "${S}"/libsmartcols/src/Makemodule.am || die
	touch -r "${S}"/configure "${S}"/libuuid/src/Makemodule.am || die

	sed -e 's|/run/|/var/run/|' \
		-i disk-utils/fsck.* term-utils/agetty.c misc-utils/blkid.8 \
	|| die

	# Prevent uuidd test failure due to socket path limit. #593304
	sed -i \
		-e "s|UUIDD_SOCKET=\"\$(mktemp -u \"\${TS_OUTDIR}/uuiddXXXXXXXXXXXXX\")\"|UUIDD_SOCKET=\"\$(mktemp -u \"${T}/uuiddXXXXXXXXXXXXX.sock\")\"|g" \
		tests/ts/uuid/uuidd || die "Failed to fix uuidd test"

	if ! use userland_GNU; then
		# test runner is using GNU-specific xargs call
		sed -i -e 's:xargs:gxargs:' tests/run.sh || die
		# test requires util-linux uuidgen (which we don't build)
		rm tests/ts/uuid/oids || die
	fi

	if [[ ${PV} == 9999 ]] ; then
		po/update-potfiles
		eautoreconf
	fi

	# Undo bad ncurses handling by upstream. #601530
	sed -i -E \
		-e '/NCURSES_/s:(ncursesw?)[56]-config:$PKG_CONFIG \1:' \
		-e 's:(ncursesw?)[56]-config --version:$PKG_CONFIG --exists --print-errors \1:' \
		configure || die

	elibtoolize
}

lfs_fallocate_test() {
	# Make sure we can use fallocate with LFS #300307
	cat <<-EOF > "${T}"/fallocate.${ABI}.c
		#define _GNU_SOURCE
		#include <fcntl.h>
		main() { return fallocate(0, 0, 0, 0); }
	EOF
	append-lfs-flags
	$(tc-getCC) ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} "${T}"/fallocate.${ABI}.c -o /dev/null >/dev/null 2>&1 \
		|| export ac_cv_func_fallocate=no
	rm -f "${T}"/fallocate.${ABI}.c
}

multilib_src_configure() {
	lfs_fallocate_test
	# The scanf test in a run-time test which fails while cross-compiling.
	# Blindly assume a POSIX setup since we require libmount, and libmount
	# itself fails when the scanf test fails. #531856
	tc-is-cross-compiler && export scanf_cv_alloc_modifier=ms
	export ac_cv_header_security_pam_misc_h=$(multilib_native_usex pam) #485486
	export ac_cv_header_security_pam_appl_h=$(multilib_native_usex pam) #545042

	# Disabled by default:
	# --enable-chfn-chsh      build chfn and chsh
	# --disable-login         do not build login
	# --disable-nologin       do not build nologin
	# --disable-su            do not build su

	# Enabled by default:
	# --disable-agetty        do not build agetty
	# --disable-bash-completion
	# --enable-line           build line
	# --disable-partx         do not build addpart, delpart, partx
	# --disable-raw           do not build raw
	# --disable-rename        do not build rename
	# --disable-rfkill        do not build rfkill
	# --disable-schedutils    do not build chrt, ionice, taskset

	# USE-flag dependent:
	# --disable-makeinstall-chown
	# --disable-makeinstall-setuid
	# --disable-nls           do not use Native Language Support
	# --disable-widechar      do not compile wide character support
	# --disable-setpriv       do not build setpriv
	# --enable-static[=PKGS]  build static libraries [default=yes]
	# --disable-cramfs        do not build fsck.cramfs, mkfs.cramfs
	# --disable-fdformat      do not build fdformat
	# --disable-mesg          do not build mesg
	# --disable-wall          do not build wall
	# --enable-write          build write
	# --disable-kill          do not build kill

	# Non-native builds, Enabled by default:
	# --disable-libuuid       do not build libuuid and uuid utilities
	# --disable-libblkid      do not build libblkid and many related utilities
	# --disable-libsmartcols  do not build libsmartcols
	# --disable-libfdisk      do not build libfdisk

	# Additional options now enabled:
	# --enable-static-programs=losetup,mount,umount,fdisk,sfdisk,blkid,nsenter,unshare (all require static-libs)
	# --enable-sulogin-emergency-mount

	# --disable-all-programs  disable everything, might be overridden
	# --disable-assert        turn off assertions
	# --disable-bfs           do not build mkfs.bfs
	# --disable-cal           do not build cal
	# --disable-chfn-chsh-password
	# --disable-chmem         do not build chmem
	# --disable-chsh-only-listed
	# --disable-colors-default
	# --disable-dependency-tracking
	# --disable-eject         do not build eject
	# --disable-fallocate     do not build fallocate
	# --disable-fsck          do not build fsck
	# --disable-hwclock       do not build hwclock
	# --disable-ipcrm         do not build ipcrm
	# --disable-ipcs          do not build ipcs
	# --disable-largefile     omit support for large files
	# --disable-last          do not build last
	# --disable-libmount      do not build libmount
	# --disable-libtool-lock  avoid locking (might break parallel builds)
	# --disable-logger        do not build logger
	# --disable-losetup       do not build losetup
	# --disable-lslogins      do not build lslogins
	# --disable-lsmem         do not build lsmem
	# --disable-minix         do not build fsck.minix, mkfs.minix
	# --disable-more          do not build more
	# --disable-mount         do not build mount(8) and umount(8)
	# --disable-mountpoint    do not build mountpoint
	# --disable-nsenter       do not build nsenter
	# --disable-option-checking  ignore unrecognized --enable/--with options
	# --disable-pg-bell       let pg not ring the bell on invalid keys
	# --disable-pivot_root    do not build pivot_root
	# --disable-plymouth_support
	# --disable-pylibmount    do not build pylibmount
	# --disable-rpath         do not hardcode runtime library paths
	# --disable-runuser       do not build runuser
	# --disable-setterm       do not build setterm
	# --disable-silent-rules  verbose build output (undo: "make V=0")
	# --disable-sulogin       do not build sulogin
	# --disable-switch_root   do not build switch_root
	# --disable-symvers       disable library symbol versioning [default=auto]
	# --disable-tls           disable use of thread local support
	# --disable-ul            do not build ul
	# --disable-unshare       do not build unshare
	# --disable-use-tty-group do not install wall and write setgid tty
	# --disable-utmpdump      do not build utmpdump
	# --disable-uuidd         do not build the uuid daemon
	# --disable-wdctl         do not build wdctl
	# --disable-zramctl       do not build zramctl

	# --enable-asan           compile with Address Sanitizer
	# --enable-libmount-support-mtab
	# --enable-libuuid-force-uuidd
	# --enable-login-chown-vcs
	# --enable-login-stat-mail
	# --enable-newgrp         build newgrp
	# --enable-pg             build pg
	# --enable-tunelp         build tunelp
	# --enable-usrdir-path    use only /usr paths in PATH env. variable
	# --enable-vipw           build vipw

	local myeconfargs=(
		--enable-fs-paths-extra="${EPREFIX}/usr/sbin:${EPREFIX}/bin:${EPREFIX}/usr/bin"
		--with-bashcompletiondir="$(get_bashcompdir)"
		$(multilib_native_use_enable suid makeinstall-chown)
		$(multilib_native_use_enable suid makeinstall-setuid)
		$(multilib_native_use_with python)
		$(multilib_native_use_with readline)
		$(multilib_native_use_with slang)
		$(multilib_native_use_with systemd)
		$(multilib_native_use_with udev)
		$(multilib_native_usex ncurses "$(use_with unicode ncursesw)" '--without-ncursesw')
		$(multilib_native_usex ncurses "$(use_with !unicode ncurses)" '--without-ncurses')
		$(tc-has-tls || echo --disable-tls)
		$(use_enable nls)
		$(use_enable unicode widechar)
		$(use_enable static-libs static)
		$(use_with selinux)
		$(usex ncurses '' '--without-tinfo')
	)
	# build programs only on GNU, on *BSD we want libraries only
	if multilib_is_native_abi && use userland_GNU; then
		myeconfargs+=(
			--disable-chfn-chsh
			--disable-login
			--disable-nologin
			--disable-su
			--enable-agetty
			--enable-bash-completion
			--enable-line
			--enable-partx
			--enable-raw
			--enable-rename
			--enable-rfkill
			--enable-schedutils
			--enable-sulogin-emergency-mount
			$(usex systemd "--with-systemdsystemunitdir=\"$(systemd_get_systemunitdir)\"" '--without-systemdsystemunitdir')
			$(use_enable caps setpriv)
			$(use_enable cramfs)
			$(use_enable fdformat)
			$(use_enable tty-helpers mesg)
			$(use_enable tty-helpers wall)
			$(use_enable tty-helpers write)
			$(use_enable kill)
			$(usex static-libs '--enable-static-programs=losetup,mount,umount,fdisk,sfdisk,blkid,nsenter,unshare')
		)
	else
		myeconfargs+=(
			--disable-all-programs
			--disable-bash-completion
			--without-systemdsystemunitdir
			# build libraries
			--enable-libuuid
			--enable-libblkid
			--enable-libsmartcols
			--enable-libfdisk
		)
		if use userland_GNU; then
			# those libraries don't work on *BSD
			myeconfargs+=(
				--enable-libmount
			)
		fi
	fi
	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_test() {
	emake check TS_OPTS="--parallel=$(makeopts_jobs) --nonroot"
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if multilib_is_native_abi && use userland_GNU; then
		# need the libs in /
		gen_usr_ldscript -a blkid fdisk mount smartcols uuid

		use python && python_optimize
	fi
}

multilib_src_install_all() {
	dodoc AUTHORS NEWS README* Documentation/{TODO,*.txt,releases/*}

	# e2fsprogs-libs didnt install .la files, and .pc work fine
	find "${ED}" -name "*.la" -delete || die

	if ! use userland_GNU; then
		# manpage collisions
		# TODO: figure out a good way to keep them
		rm "${ED%/}"/usr/share/man/man3/uuid* || die
	fi

	if use pam; then
		newpamd "${FILESDIR}/runuser.pamd" runuser
		newpamd "${FILESDIR}/runuser-l.pamd" runuser-l
	fi

	# Note:
	# Bash completion for "runuser" command is provided by same file which
	# would also provide bash completion for "su" command. However, we don't
	# use "su" command from this package.
	# This triggers a known QA warning which we ignore for now to magically
	# keep bash completion for "su" command which shadow package does not
	# provide.
}

pkg_postinst() {
	if ! use tty-helpers; then
		elog "The mesg/wall/write tools have been disabled due to USE=-tty-helpers."
	fi

	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "The agetty util now clears the terminal by default. You"
		elog "might want to add --noclear to your /etc/inittab lines."
	fi
}
