# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="base for all cron ebuilds"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE=""

S=${WORKDIR}

DEPEND="
	acct-group/cron
	acct-user/cron"
RDEPEND="${DEPENDS}"

src_install() {
	newsbin "${FILESDIR}"/run-crons-${PV} run-crons

	diropts -m0750
	keepdir /etc/cron.{hourly,daily,weekly,monthly}

	keepdir /var/spool/cron/lastrun
	diropts -m0750 -o root -g cron
	keepdir /var/spool/cron
}
