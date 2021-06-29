# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic  # linux-info

DESCRIPTION="A Thread Stall Detector"
HOMEPAGE="https://git.kernel.org/pub/scm/utils/stalld/stalld.git/"
SRC_URI="https://git.kernel.org/pub/scm/utils/${PN}/${PN}.git/snapshot/${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"

RDEPEND="app-shells/bash"

CONFIG_CHECK="SCHED_DEBUG"
ERROR_SCHED_DEBUG="Kernel option 'CONFIG_SCHED_DEBUG' *must* be enabled for stalld to operate"

#pkg_setup() {
#	linux-info_pkg_setup
#}

src_prepare() {
	sed -e '/:=/ s|:=|?=|' \
		-e "/DOCDIR/ s|doc|doc/${P}|" \
		-e '/FILES/ s| gpl-2.0.txt||' \
		-e 's|make|$(MAKE)|' \
		-e '/LICDIR/ d' \
		-i Makefile ||
	die "sed failed: ${?}"

	sed -e 's|/run/|/var/run/|' \
		-e 's/^# ex: /# e.g.: /' \
		-e '/^[A-Z]\+=$/ s/^/#/' \
		-e 's/LOGONLY/LOGGING/' \
		redhat/stalld.conf > "${T}"/stalld.conf ||
	die "sed failed: ${?}"

	# VERSION pre-processor directive isn't being expanded?
	sed -e "s|VERSION|'${PV%.0}'|g" \
		-i src/stalld.c ||
	die "sed failed: ${?}"

	default
}

src_install() {
	default

	dodir /usr/sbin
	mv "${ED}"/usr/bin/stalld "${ED}"/usr/sbin/ ||
		die "Binary move failed: ${?}"

	dosbin scripts/throttlectl.sh

	newinitd "${FILESDIR}"/stalld.init stalld
	newconfd "${T}"/stalld.conf stalld
}
