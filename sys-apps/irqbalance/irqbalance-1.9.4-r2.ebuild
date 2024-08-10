# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info meson optfeature systemd udev

DESCRIPTION="Distribute hardware interrupts across processors on a multiprocessor system"
HOMEPAGE="https://github.com/Irqbalance/irqbalance"
SRC_URI="https://github.com/Irqbalance/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${P}/contrib"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~loong ppc ppc64 ~riscv x86"
IUSE="caps +numa selinux systemd thermal tui udev"
# Hangs
RESTRICT="test"

DEPEND="
	dev-libs/glib:2
	caps? ( sys-libs/libcap-ng )
	numa? ( sys-process/numactl )
	systemd? ( sys-apps/systemd:= )
	thermal? ( dev-libs/libnl:3 )
	tui? ( sys-libs/ncurses:=[unicode(+)] )
"
BDEPEND="
	virtual/pkgconfig
"
RDEPEND="
	${DEPEND}
	selinux? ( sec-policy/selinux-irqbalance )
"

pkg_setup() {
	CONFIG_CHECK="~PCI_MSI"
	linux-info_pkg_setup
}

src_prepare() {
	local f=''

	default

	(
		cd "${WORKDIR}/${P}" || die
		eapply "${FILESDIR}/${P}-drop-protectkerneltunables.patch"
	)

	# Follow systemd policies
	# https://wiki.gentoo.org/wiki/Project:Systemd/Ebuild_policy
	sed \
		-e 's/ $IRQBALANCE_ARGS//' \
		-e '/EnvironmentFile/d' \
		-i "${WORKDIR}/${P}/misc/irqbalance.service" || die

	# Fix use of '/run/'

	for f in "${WORKDIR}/${P}/irqbalance.h" \
			"${WORKDIR}/${P}/ui/irqbalance-ui.h"
	do
		sed \
				-s '/SOCKET_TMPFS/s|/run/|/var/run/|' \
				-i "${f}" ||
			die "sed failed on file '${f}': ${?}"
	done
}

src_configure() {
	local emesonargs=(
		$(meson_feature caps capng)
		$(meson_feature numa)
		$(meson_feature systemd)
		$(meson_feature thermal)
		$(meson_feature tui ui)
	)

	meson_src_configure
}

src_install() {
	meson_src_install

	dodir /usr/sbin || die
	mv "${ED}"/usr/bin/irqbalance "${ED}"/usr/sbin/ || die

	newinitd "${FILESDIR}"/irqbalance.init.5 irqbalance
	newconfd "${FILESDIR}"/irqbalance.confd-2 irqbalance
	use systemd && systemd_dounit "${WORKDIR}"/${P}/misc/irqbalance.service
	use udev && udev_dorules "${WORKDIR}"/${P}/misc/90-irqbalance.rules
}

pkg_postrm() {
	use !udev || udev_reload
}

pkg_postinst() {
	use !udev || udev_reload
	optfeature "thermal events support (requires USE=thermal)" sys-power/thermald
}
