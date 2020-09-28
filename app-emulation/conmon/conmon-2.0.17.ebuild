# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_COMMIT="41877362fc4685d55e0473d2e4a1cbe5e1debee0"
DESCRIPTION="An OCI container runtime monitor"
HOMEPAGE="https://github.com/containers/conmon"
SRC_URI="https://github.com/containers/conmon/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"
RESTRICT="mirror test"

RDEPEND="dev-libs/glib:=
	systemd? ( sys-apps/systemd:= )"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PN}-${EGIT_COMMIT}"

src_prepare() {
	default

	if ! use systemd; then
		sed -e 's| $(PKG_CONFIG) --exists libsystemd-journal | false |' \
			-e 's| $(PKG_CONFIG) --exists libsystemd | false |' \
			-i Makefile || die
	fi
}

src_compile() {
	emake GIT_COMMIT="${EGIT_COMMIT}" \
		all
}

src_install() {
	emake DESTDIR="${D}" \
		PREFIX="/usr" \
		install
	dodir /usr/libexec/podman
	ln -s "${ED}/usr/"{bin,libexec/podman}/conmon || die
	dodoc README.md
}
