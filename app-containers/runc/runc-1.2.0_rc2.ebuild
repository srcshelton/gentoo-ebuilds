# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module linux-info

RUNC_COMMIT="f2d2ee5e45af3c9b38dfd639ac92f43c3055ce4e" # "TRUE or FALSE, it's a problem!"
CONFIG_CHECK="~USER_NS"

DESCRIPTION="runc container cli tools"
HOMEPAGE="http://github.com/opencontainers/runc/"
MY_PV="${PV/_rc/-rc.}"
SRC_URI="https://github.com/opencontainers/${PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD-2 BSD MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv ~x86"
IUSE="+ambient apparmor +bash-completion hardened +kmem +man +seccomp selinux test"

# sys-libs/glibc - see https://github.com/golang/go/issues/65625#issuecomment-1939390070
DEPEND="
	>=sys-libs/glibc-2.32
	seccomp? ( sys-libs/libseccomp )
"

RDEPEND="
	${DEPEND}
	!app-emulation/docker-runc
	apparmor? ( sys-libs/libapparmor )
	selinux? ( sec-policy/selinux-container )
"

# dev-lang/go - see https://github.com/opencontainers/runc/issues/4233
BDEPEND="
	>=dev-lang/go-1.20
	<dev-lang/go-1.22
	man? ( dev-go/go-md2man )
	test? ( "${RDEPEND}" )
	sys-apps/findutils
	sys-apps/grep
	sys-apps/sed
"

# tests need busybox binary, and portage namespace
# sandboxing disabled: mount-sandbox pid-sandbox ipc-sandbox
# majority of tests pass
RESTRICT="test"

S="${WORKDIR}/${PN}-${MY_PV}"

src_prepare() {
	default

	# Fix run path...
	grep -Rl '[^r]/run/' . | xargs -r -- sed -ri -e 's|([ "=/])/run|\1/var/run|' || die
}

src_compile() {
	# Taken from app-containers/docker-1.7.0-r1
	export CGO_CFLAGS="-I${ESYSROOT}/usr/include"
	export CGO_LDFLAGS="$(usex hardened '-fno-PIC ' '')
		-L${ESYSROOT}/usr/$(get_libdir)"

	# build up optional flags
	local options=(
		$(usev ambient)
		$(usev apparmor)
		$(usev seccomp)
		$(usev selinux)
		$(usex kmem '' 'nokmem')
	)

	myemakeargs=(
		BUILDTAGS="${options[*]}"
		COMMIT="${RUNC_COMMIT}"
	)

	emake "${myemakeargs[@]}" runc man
}

src_install() {
	myemakeargs+=(
		PREFIX="${ED%/}/usr"
		BINDIR="${ED%/}/usr/bin"
		MANDIR="${ED%/}/usr/share/man"
	)
	emake "${myemakeargs[@]}" install
	if use bash-completion; then
		emake "${myemakeargs[@]}" install-bash
	fi
	if use man; then
		emake "${myemakeargs[@]}" install-man
	fi

	local DOCS=( README.md PRINCIPLES.md docs/. )
	einstalldocs
}

src_test() {
	emake "${myemakeargs[@]}" localunittest
}
