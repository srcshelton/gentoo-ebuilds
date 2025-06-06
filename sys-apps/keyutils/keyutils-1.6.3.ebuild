# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit linux-info toolchain-funcs usr-ldscript multilib-minimal

DESCRIPTION="Linux Key Management Utilities"
HOMEPAGE="https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git"
SRC_URI="https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git/snapshot/${P}.tar.gz"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0/1.9"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ~ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux"
IUSE="static static-libs test"
RESTRICT="!test? ( test )"

RDEPEND=""
DEPEND="!prefix? ( || (
	virtual/os-headers:20611
	) )"

PATCHES=(
	"${FILESDIR}"/${PN}-1.6-makefile-fixup.patch
	"${FILESDIR}"/${PN}-1.5.10-disable-tests.patch #519062 #522050
	"${FILESDIR}"/${PN}-1.5.9-header-extern-c.patch
	"${FILESDIR}"/${PN}-1.6.3-fix-rpmspec-check.patch
)

pkg_setup() {
	# To prevent a failure in test phase and false positive bug reports
	# we are enforcing the following options because testsuite expects
	# that these options are available. I.e. testsuite only decides based
	# on kernel version which tests will be called, no feature checking.
	if use test ; then
		CONFIG_CHECK="KEYS"
		ERROR_KEYS="You must have CONFIG_KEYS to run the package testsuite!"

		if kernel_is -ge 2 6 10 && kernel_is -lt 4 0 0 ; then
			CONFIG_CHECK="${CONFIG_CHECK} KEYS_DEBUG_PROC_KEYS"
			ERROR_KEYS_DEBUG_PROC_KEYS="You must have CONFIG_KEYS_DEBUG_PROC_KEYS to run the package testsuite!"
		fi

		if kernel_is -ge 4 7 ; then
			CONFIG_CHECK="${CONFIG_CHECK} KEY_DH_OPERATIONS"
			ERROR_KEY_DH_OPERATIONS="You must have CONFIG_KEY_DH_OPERATIONS to run the package testsuite!"
		fi
	else
		CONFIG_CHECK="~KEYS"
		ERROR_KEYS="You will be unable to use this package on this system because CONFIG_KEYS is not set!"

		if kernel_is -ge 4 7 ; then
			CONFIG_CHECK="${CONFIG_CHECK} ~KEY_DH_OPERATIONS"
			ERROR_KEY_DH_OPERATIONS="You will be unable to use Diffie-Hellman on this system because CONFIG_KEY_DH_OPERATIONS is not set!"
		fi
	fi

	linux-info_pkg_setup
}

src_prepare() {
	default

	# The lsb check is useless, so avoid spurious command not found messages.
	sed -i -e 's,lsb_release,:,' tests/prepare.inc.sh || die
	# Some tests call the kernel which calls userspace, but that will
	# run the install keyutils rather than the locally compiled one,
	# so disable round trip tests.
	rm -rf tests/keyctl/requesting/{bad-args,piped,valid}

	# Fix 'libkeyutils.pc' file mode...
	sed -i -e '/PKGCONFIG_DIR/s/$(INSTALL) -D /$(INSTALL) -D -m 0644 /' \
		Makefile || die

	multilib_copy_sources
}

multilib_src_compile() {
	tc-export AR CC CXX
	sed -i \
		-e "1iRPATH = $(usex static -static '')" \
		-e '/^C.*FLAGS/s|:=|+=|' \
		-e 's:-Werror::' \
		-e '/^BUILDFOR/s:=.*:=:' \
		-e "/^LIBDIR/s:=.*:= /usr/$(get_libdir):" \
		-e '/^USRLIBDIR/s:=.*:=$(LIBDIR):' \
		-e "s: /: ${EPREFIX}/:g" \
		-e '/^NO_ARLIB/d' \
		Makefile || die

	# We need the static lib in order to statically link programs.
	if use static ; then
		export NO_ARLIB=0
		# Hack the progs to depend on the static lib instead.
		sed -i \
			-e '/^.*:.*[$](DEVELLIB)$/s:$(DEVELLIB):$(ARLIB) $(SONAME):' \
			Makefile || die
	else
		export NO_ARLIB=$(usex static-libs 0 1)
	fi
	emake
}

multilib_src_test() {
	# Execute the locally compiled code rather than the
	# older versions already installed in the system.
	LD_LIBRARY_PATH=${BUILD_DIR} \
	PATH="${BUILD_DIR}:${PATH}" \
	emake test
}

multilib_src_install() {
	# Possibly undo the setting for USE=static (see src_compile).
	export NO_ARLIB=$(usex static-libs 0 1)

	default
	use static || gen_usr_ldscript -a keyutils
}

multilib_src_install_all() {
	dodoc README
}
