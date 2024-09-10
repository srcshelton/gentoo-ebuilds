# Copyright 2016-2018 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Report and optionally restart crashed OpenRC services"
HOMEPAGE="https://github.com/srcshelton/openrc-restart-crashed"
SRC_URI="https://github.com/srcshelton/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm x86"
IUSE="+cron"

RDEPEND="
	>=app-shells/bash-4.0
	sys-apps/openrc
	cron? ( virtual/cron )"

src_install() {
	exeinto "/usr/local/sbin"
	doexe "${PN}"

	if use cron; then
		insinto "/etc/cron.d"
		newins "${FILESDIR}/${PN}.cron" "${PN}"
	fi
}
