# Copyright 2020-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GO_OPTIONAL=1
inherit go-module systemd toolchain-funcs

DESCRIPTION="Early OOM Daemon for Linux"
HOMEPAGE="https://github.com/rfjakob/earlyoom"

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://github.com/rfjakob/earlyoom.git"
	inherit git-r3
else
	SRC_URI="https://github.com/rfjakob/earlyoom/archive/v${PV}.tar.gz -> ${P}.tar.gz
		test? ( https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}-deps.tar.xz )"

	KEYWORDS="amd64 x86"
fi

LICENSE="MIT"
SLOT="0"
IUSE="debug man systemd test"
RESTRICT="
	!test? ( test )
	mirror
"

BDEPEND="
	man? ( virtual/pandoc )
	test? (
		dev-lang/go
		dev-util/cppcheck
	)
"

src_unpack() {
	default

	use test && go-module_src_unpack
}

src_prepare() {
	if ! use debug; then
		sed \
				-e '/CFLAGS/ s/ -g / -Wl,-s /' \
				-i Makefile ||
			die
	fi

	default
}

src_compile() {
	tc-export CC

	emake \
		PREFIX="${EPREFIX}"/usr \
		VERSION="v${PV}" \
		SYSTEMDUNITDIR="$(systemd_get_systemunitdir)" \
		earlyoom earlyoom.service $(usev man 'earlyoom.1')
}

src_install() {
	dobin earlyoom

	use man && doman earlyoom.1

	insinto /etc/conf.d
	newins earlyoom.default earlyoom

	newinitd "${FILESDIR}"/${PN}-r1 ${PN}
	use systemd && systemd_dounit earlyoom.service
}
