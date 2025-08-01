# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_OPTIONAL=1
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 toolchain-funcs usr-ldscript multilib-minimal

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://github.com/file/file"
	inherit autotools git-r3
else
	VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/file.asc
	inherit libtool verify-sig
	SRC_URI="https://astron.com/pub/file/${P}.tar.gz
		verify-sig? ( https://astron.com/pub/file/${P}.tar.gz.asc )"

	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"

	BDEPEND="verify-sig? ( sec-keys/openpgp-keys-file )"
fi

DESCRIPTION="Identify a file's format by scanning binary data for patterns"
HOMEPAGE="https://www.darwinsys.com/file/"

LICENSE="BSD-2"
SLOT="0"
IUSE="bzip2 lzip lzma python seccomp static-libs zlib zstd"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

COMMON_DEPEND="
	bzip2? ( app-arch/bzip2[${MULTILIB_USEDEP}] )
	lzip? ( app-arch/lzlib )
	lzma? ( app-arch/xz-utils[${MULTILIB_USEDEP}] )
	python? (
		${PYTHON_DEPS}
		!dev-python/python-magic
	)
	seccomp? ( >=sys-libs/libseccomp-2.5.4[${MULTILIB_USEDEP}] )
	zlib? ( >=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}] )
	zstd? ( app-arch/zstd:=[${MULTILIB_USEDEP}] )
"
DEPEND="
	${COMMON_DEPEND}
	python? ( dev-python/setuptools[${PYTHON_USEDEP}] )
"
RDEPEND="
	${COMMON_DEPEND}
	seccomp? ( >=sys-libs/libseccomp-2.5.4[${MULTILIB_USEDEP}] )
"
BDEPEND="${BDEPEND}
	python? (
		${PYTHON_DEPS}
		${DISTUTILS_DEPS}
	)
"

# https://bugs.gentoo.org/898676
QA_CONFIG_IMPL_DECL_SKIP=( makedev )

PATCHES=(
	"${FILESDIR}/file-5.43-seccomp-fstatat64-musl.patch" #789336, not upstream yet
	"${FILESDIR}/file-5.45-seccomp-sandbox.patch"
	"${FILESDIR}/file-5.46-zip.patch"
	"${FILESDIR}/file-5.46-buffer-overflow.patch"
)

src_prepare() {
	default

	if [[ ${PV} == 9999 ]] ; then
		eautoreconf
	else
		elibtoolize
	fi

	# Don't let python README kill main README, bug #60043
	mv python/README.md python/README.python.md || die

	# bug #662090
	sed -i 's@README.md@README.python.md@' python/setup.py || die
}

multilib_src_configure() {
	local myeconfargs=(
		--enable-fsect-man5
		$(use_enable bzip2 bzlib)
		$(multilib_native_use_enable lzip lzlib)
		$(use_enable lzma xzlib)
		$(use_enable seccomp libseccomp)
		$(use_enable static-libs static)
		$(use_enable zlib)
		$(use_enable zstd zstdlib)
	)

	econf "${myeconfargs[@]}"
}

build_src_configure() {
	local myeconfargs=(
		--disable-shared
		--disable-libseccomp
		--disable-bzlib
		--disable-xzlib
		--disable-zlib
	)

	econf_build "${myeconfargs[@]}"
}

need_build_file() {
	# When cross-compiling, we need to build up our own file
	# because people often don't keep matching host/target
	# file versions, bug #362941
	tc-is-cross-compiler && ! has_version -b "~${CATEGORY}/${P}"
}

src_configure() {
	local ECONF_SOURCE="${S}"

	if need_build_file ; then
		mkdir -p "${WORKDIR}"/build || die
		cd "${WORKDIR}"/build || die
		build_src_configure
	fi

	multilib-minimal_src_configure
}

multilib_src_compile() {
	if multilib_is_native_abi ; then
		emake
	else
		# bug #586444
		emake -C src magic.h
		emake -C src libmagic.la
	fi
}

src_compile() {
	if need_build_file ; then
		# bug #586444
		emake -C "${WORKDIR}"/build/src magic.h
		emake -C "${WORKDIR}"/build/src file
		local -x PATH="${WORKDIR}/build/src:${PATH}"
	fi

	multilib-minimal_src_compile

	if use python ; then
		cd python || die
		distutils-r1_src_compile
	fi
}

src_test() {
	multilib-minimal_src_test

	if use python ; then
		cd python || die
		distutils-r1_src_test
	fi
}

python_test() {
	eunittest
}

multilib_src_install() {
	if multilib_is_native_abi ; then
		default

		if use split-usr; then
			# need the libs in /
			gen_usr_ldscript -a magic
		fi
	else
		emake -C src install-{nodist_includeHEADERS,libLTLIBRARIES} DESTDIR="${D}"
	fi
}

multilib_src_install_all() {
	dodoc ChangeLog MAINT # README

	# Required for `file -C`
	insinto /usr/share/misc/magic
	doins -r magic/Magdir/*

	if use python ; then
		cd python || die
		distutils-r1_src_install
	fi

	find "${ED}" -type f -name "*.la" -delete || die
}
