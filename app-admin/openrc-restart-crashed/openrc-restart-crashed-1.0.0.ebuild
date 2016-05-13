# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Report and optionally restart crashed OpenRC services"
HOMEPAGE="https://github.com/srcshelton/openrc-restart-crashed"
SRC_URI="https://github.com/srcshelton/openrc-restart-crashed/archive/v1.0.0.tar.gz -> openrc-restart-crashed-v1.0.0.tar.gz"
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
	doexe "openrc-restart-crashed"

	if use cron; then
		insinto "/etc/cron.d"
		newins "${FILESDIR}"/openrc-restart-crashed.cron openrc-restart-crashed
	fi
}
