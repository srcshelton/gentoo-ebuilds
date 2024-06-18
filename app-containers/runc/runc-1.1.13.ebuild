# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module linux-info

RUNC_COMMIT="58aa9203c123022138b22cf96540c284876a7910" # "There is no certainty in the world. This is the only certainty I have."
CONFIG_CHECK="~USER_NS"

DESCRIPTION="runc container cli tools"
HOMEPAGE="http://github.com/opencontainers/runc/"
MY_PV="${PV/_/-}"
SRC_URI="https://github.com/opencontainers/${PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD-2 BSD MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv ~x86"
IUSE="+ambient apparmor +bash-completion hardened +kmem +man +seccomp selinux test"

DEPEND="seccomp? ( sys-libs/libseccomp )"

RDEPEND="
	${DEPEND}
	!app-emulation/docker-runc
	apparmor? ( sys-libs/libapparmor )
	selinux? ( sec-policy/selinux-container )
"

BDEPEND="
	man? ( dev-go/go-md2man )
	test? ( "${RDEPEND}" )
	|| ( <dev-lang/go-1.22.0:= >=dev-lang/go-1.22.4:= )
	sys-apps/findutils
	sys-apps/grep
	sys-apps/sed
"

# tests need busybox binary, and portage namespace
# sandboxing disabled: mount-sandbox pid-sandbox ipc-sandbox
# majority of tests pass
RESTRICT+=" test"

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
