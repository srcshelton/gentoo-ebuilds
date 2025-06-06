# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="An OCI container runtime monitor"
HOMEPAGE="https://github.com/containers/conmon"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/conmon.git"
else
	SRC_URI="https://github.com/containers/conmon/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm64 ~loong ~ppc64 ~riscv"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="+seccomp systemd"
RESTRICT="mirror test"

RDEPEND="dev-libs/glib:=
	seccomp? ( sys-libs/libseccomp )
	systemd? ( sys-apps/systemd:= )"
DEPEND="${RDEPEND}"
BDEPEND="dev-go/go-md2man"

src_prepare() {
	default
	sed -i -e "s|shell.*--exists libsystemd.* && echo \"0\"|shell echo $(usex systemd 0 1)|g;" Makefile || die
	echo -e "#!/bin/sh\necho $(usex seccomp 0 1)" > hack/seccomp-notify.sh || die
}

src_compile() {
	tc-export CC PKG_CONFIG
	export PREFIX="${EPREFIX}/usr" GOMD2MAN="$(command -v go-md2man)"
	default
}

src_install() {
	default
	dodir /usr/libexec/podman
	dosym -r "/usr/bin/${PN}" "/usr/libexec/podman/${PN}" || die
}
