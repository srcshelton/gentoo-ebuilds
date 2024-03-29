# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
EGO_PN="github.com/containerd/${PN}"

inherit toolchain-funcs

if [[ ${PV} == *9999 ]]; then
	inherit golang-vcs
else
	MY_PV="${PV/_rc/-rc.}"
	EGIT_COMMIT="v${MY_PV}"
	CONTAINERD_COMMIT="bb71b10fd8f58240ca47fbb579b9d1028eea7c84"
	SRC_URI="https://${EGO_PN}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 ~arm ~arm64 ~ppc64"
	inherit golang-vcs-snapshot
fi

DESCRIPTION="A daemon to control runC"
HOMEPAGE="https://containerd.tools"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="apparmor +btrfs +cri hardened +seccomp"

DEPEND="btrfs? ( sys-fs/btrfs-progs )
	seccomp? ( sys-libs/libseccomp )"
RDEPEND=">=app-containers/runc-1.0.0_rc5
	seccomp? ( sys-libs/libseccomp )"

S=${WORKDIR}/${P}/src/${EGO_PN}

RESTRICT="test"

src_prepare() {
	default
	if [[ ${PV} != *9999* ]]; then
		sed -i -e "s/git describe --match.*$/echo ${PV})/"\
			-e "s/git rev-parse HEAD.*$/echo $CONTAINERD_COMMIT)/"\
			-e "s/-s -w//" \
			Makefile || die
	fi
}

src_compile() {
	local options=( $(usex btrfs "" "no_btrfs") $(usex cri "" "no_cri") $(usex seccomp "seccomp" "") $(usex apparmor "apparmor" "") )
	export GOPATH="${WORKDIR}/${P}" # ${PWD}/vendor
	LDFLAGS=$(usex hardened '-extldflags -fno-PIC' '') BUILDTAGS="${options[@]}" emake
}

src_install() {
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	keepdir /var/lib/containerd
	dobin bin/*
}
