# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="An OCI container runtime monitor"
HOMEPAGE="https://github.com/containers/conmon"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/conmon.git"
else
	SRC_URI="https://github.com/containers/conmon/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm64 ~ppc64 ~riscv"
	EGIT_COMMIT="3a9715d28cb4cf0e671dfbc4211d4458534db189"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="+seccomp systemd"
RESTRICT="mirror test"

RDEPEND="dev-libs/glib:=
	systemd? ( sys-apps/systemd:= )"
DEPEND="${RDEPEND}
	seccomp? ( sys-libs/libseccomp )"
BDEPEND="dev-go/go-md2man"
PATCHES=(
	"${FILESDIR}/conmon-2.1.8-Makefile.patch"
	"${FILESDIR}/conmon-2.1.9-conn_sock.c.patch"
)

src_prepare() {
	default
	if use systemd; then
		sed \
			-e 's|shell $(PKG_CONFIG) --exists libsystemd.* && echo "0"|shell echo "0"|g;' \
			-i Makefile || die
	else
		sed \
			-e 's|shell $(PKG_CONFIG) --exists libsystemd.* && echo "0"|shell echo "1"|g;' \
			-i Makefile || die
	fi

	if use seccomp; then
		echo -e '#!/bin/sh\necho "0"' > hack/seccomp-notify.sh || die
	else
		echo -e '#!/bin/sh\necho "1"' > hack/seccomp-notify.sh || die
	fi
}

src_compile() {
	tc-export CC PKG_CONFIG
	export PREFIX=${EPREFIX}/usr GOMD2MAN=go-md2man
	if [[ ${PV} == *9999* ]]; then
		default
	else
		emake GIT_COMMIT="${EGIT_COMMIT}"
	fi
}

src_install() {
	default

	dodir /usr/libexec/podman
	dosym -r /usr/bin/"${PN}" /usr/libexec/podman/conmon || die
}
