# Copyright 2020-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit systemd

DESCRIPTION="Early OOM Daemon for Linux"
HOMEPAGE="https://github.com/rfjakob/earlyoom"

LICENSE="MIT"
SLOT="0"
if [ "${PV}" = "9999" ]; then
	EGIT_REPO_URI="https://github.com/rfjakob/earlyoom.git"
	inherit git-r3
else
	SRC_URI="https://github.com/rfjakob/earlyoom/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 x86"
fi
IUSE="doc systemd test"

BDEPEND="
	doc? ( virtual/pandoc )
	test? ( dev-lang/go )
"

#tests don't work
RESTRICT=test

src_compile() {
	VERSION="v${PV}" emake earlyoom
	use doc && VERSION="v${PV}" emake earlyoom.1
	use systemd && emake PREFIX=/usr earlyoom.service
}

src_install() {
	dobin earlyoom
	use doc && doman earlyoom.1

	insinto /etc/conf.d
	newins earlyoom.default earlyoom

	newinitd "${FILESDIR}/${PN}-r1" "${PN}"
	use systemd && systemd_dounit earlyoom.service
}
