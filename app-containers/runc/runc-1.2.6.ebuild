# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module linux-info

RUNC_COMMIT="e89a29929c775025419ab0d218a43588b4c12b9a" # "Hasta la victoria, siempre."
CONFIG_CHECK="~USER_NS"

DESCRIPTION="runc container cli tools"
HOMEPAGE="https://github.com/opencontainers/runc/"
MY_PV="${PV/_/-}"
SRC_URI="https://github.com/opencontainers/${PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${MY_PV}"

LICENSE="Apache-2.0 BSD-2 BSD MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv ~x86"
IUSE="apparmor +bash-completion hardened +man +seccomp selinux test"

# sys-libs/glibc - see https://github.com/golang/go/issues/65625#issuecomment-1939390070
DEPEND="
	>=sys-libs/glibc-2.32
	apparmor? ( sys-libs/libapparmor )
	seccomp? ( sys-libs/libseccomp )
"

RDEPEND="
	${DEPEND}
	selinux? ( sec-policy/selinux-container )
	!app-emulation/docker-runc
"

# dev-lang/go - see https://github.com/opencontainers/runc/issues/4233
BDEPEND="
	>=dev-lang/go-1.23.0
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

src_prepare() {
	default

	# Fix run path...
	grep -Rl '[^r]/run/' . | xargs -r -- sed -ri -e 's|([ "=/])/run|\1/var/run|' || die
}

src_compile() {
	# Taken from app-containers/docker-1.7.0-r1
	CGO_CFLAGS="${CGO_CFLAGS:-} -I${ESYSROOT}/usr/include"
	CGO_LDFLAGS="${CGO_LDFLAGS:-} $(usex hardened '-fno-PIC ' '')
		-L${ESYSROOT}/usr/$(get_libdir)"

	# build up optional flags
	#
	# (no)kmem support was removed in v1.0.0-rc94 - kernel memory is
	# ignored
	# apparmor & selinux are default-enabled since v1.0.0-rc93, but we
	# still want to control the resulting dependencies...
	local options=(
		$(usev apparmor)
		$(usev seccomp)
		$(usev selinux)
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
