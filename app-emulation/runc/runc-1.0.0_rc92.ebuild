# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit go-module linux-info

# update on bump, look for https://github.com/docker\
# docker-ce/blob/<docker ver OR branch>/components/engine/hack/dockerfile/install/runc.installer
RUNC_COMMIT=ff819c7e9184c13b7c2607fe6c30ae19403a7aff
CONFIG_CHECK="~USER_NS"

DESCRIPTION="runc container cli tools"
HOMEPAGE="http://runc.io"
MY_PV="${PV/_/-}"
#SRC_URI="https://github.com/opencontainers/${PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://github.com/opencontainers/${PN}/archive/${RUNC_COMMIT}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="Apache-2.0 BSD-2 BSD MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~x86"
IUSE="+ambient apparmor +doc hardened +kmem +seccomp selinux test"

DEPEND="seccomp? ( sys-libs/libseccomp )"

RDEPEND="
	${DEPEND}
	!app-emulation/docker-runc
	apparmor? ( sys-libs/libapparmor )
"

BDEPEND="
	doc? ( dev-go/go-md2man )
	test? ( "${RDEPEND}" )
"

# tests need busybox binary, and portage namespace
# sandboxing disabled: mount-sandbox pid-sandbox ipc-sandbox
# majority of tests pass
RESTRICT+=" test"

S="${WORKDIR}/${PN}-${RUNC_COMMIT}"

src_prepare() {
	default

	# grep -R '/run[/ )"]' . | grep -v 'var/run'
	sed -r \
		-e 's|/(run[/ )"])|/var/\1|g' \
		-i $( grep -HR '/run[/ )"]' . | grep -v 'var/run' | cut -d':' -f 1 ) ||
	die "Updating ${PN} to use '/var/run' failed: ${?}"
}

src_compile() {
	# Taken from app-emulation/docker-1.7.0-r1
	export CGO_CFLAGS="-I${ROOT}/usr/include"
	export CGO_LDFLAGS="$(usex hardened '-fno-PIC ' '')
		-L${ROOT}/usr/$(get_libdir)"

	# build up optional flags
	local options=(
		$(usev ambient)
		$(usev apparmor)
		$(usev seccomp)
		$(usev selinux)
		$(usex kmem '' 'nokmem')
	)

	myemakeargs=(
		BINDIR="${ED}/usr/bin"
		BUILDTAGS="${options[*]}"
		COMMIT=${RUNC_COMMIT}
		DESTDIR="${ED}"
		PREFIX="${ED}/usr"
	)

	emake "${myemakeargs[@]}" runc man
}

src_install() {
	emake "${myemakeargs[@]}" install install-bash

	local DOCS=( README.md PRINCIPLES.md docs/. )
	einstalldocs

	if use doc; then
		emake "${myemakeargs[@]}" install-man
	fi
}
