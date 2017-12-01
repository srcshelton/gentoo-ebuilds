# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils flag-o-matic multilib systemd toolchain-funcs udev

DESCRIPTION="Tool for running RAID systems - replacement for the raidtools"
HOMEPAGE="http://neil.brown.name/blog/mdadm"
DEB_PR=4
SRC_URI="mirror://kernel/linux/utils/raid/mdadm/${P}.tar.xz
		mirror://debian/pool/main/m/mdadm/${PN}_3.4-${DEB_PR}.debian.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86"
IUSE="static"

DEPEND="virtual/pkgconfig
	app-arch/xz-utils"
RDEPEND=">=sys-apps/util-linux-2.16"

# The tests edit values in /proc and run tests on software raid devices.
# Thus, they shouldn't be run on systems with active software RAID devices.
RESTRICT="test"

rundir="/dev/.mdadm"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-3.4-sysmacros.patch #580188
}

mdadm_emake() {
	local myconf=()

	# We should probably make corosync & libdlm into USE flags. #573782

	myconf+=( PKG_CONFIG="$(tc-getPKG_CONFIG)" )
	myconf+=( CC="$(tc-getCC)" )
	myconf+=( CWFLAGS="-Wall" )
	myconf+=( CXFLAGS="${CFLAGS}" )
	myconf+=( COROSYNC="-DNO_COROSYNC" )
	myconf+=( DLM="-DNO_DLM" )

	if use udev; then
		myconf+=( UDEVDIR="$(get_udevdir)" )
	fi

	if use systemd; then
		myconf+=( SYSTEMD_DIR="$(systemd_get_unitdir)" )
	else
		myconf+=( RUN_DIR="${rundir}" )
		myconf+=( MAP_DIR="${rundir}" )
	fi

	emake \
		"${myconf[@]}" \
		"$@"
}

src_compile() {
	use static && append-ldflags -static
	mdadm_emake all mdassemble
}

src_test() {
	mdadm_emake test

	sh ./test || die
}

src_install() {
	mdadm_emake DESTDIR="${D}" install
	if use systemd; then
		mdadm_emake DESTDIR="${D}" install-systemd
	fi
	dosbin mdassemble
	dodoc ChangeLog INSTALL TODO README* ANNOUNCE-${PV}

	if ! use udev; then
		rm -v "${ED}"/$(get_udevdir)/rules.d/*.rules
		rmdir -p "${ED}"/$(get_udevdir)/rules.d
	fi

	insinto /etc
	newins mdadm.conf-example mdadm.conf
	newinitd "${FILESDIR}"/mdadm.rc mdadm
	newconfd "${FILESDIR}"/mdadm.confd mdadm
	newinitd "${FILESDIR}"/mdraid.rc mdraid
	newconfd "${FILESDIR}"/mdraid.confd mdraid

	# From the Debian patchset
	dodoc "${WORKDIR}"/debian/README.checkarray
	dosbin "${WORKDIR}"/debian/checkarray
	insinto /etc/default
	newins "${FILESDIR}"/etc-default-mdadm mdadm

	exeinto /etc/cron.weekly
	newexe "${FILESDIR}"/mdadm.weekly mdadm
}

pkg_postinst() {
	if use systemd && ! systemd_is_booted; then
		if [[ -z ${REPLACING_VERSIONS} ]] ; then
			# Only inform people the first time they install.
			elog "If you're not relying on kernel auto-detect of your RAID"
			elog "devices, you need to add 'mdraid' to your 'boot' runlevel:"
			elog "	rc-update add mdraid boot"
		fi
	fi
}
