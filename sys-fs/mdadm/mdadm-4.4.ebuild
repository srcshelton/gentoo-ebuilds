# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic systemd toolchain-funcs udev

DEB_PF="4.4-3"
DESCRIPTION="Tool for running RAID systems - replacement for the raidtools"
HOMEPAGE="https://github.com/md-raid-utilities/mdadm https://git.kernel.org/pub/scm/utils/mdadm/mdadm.git/"
SRC_URI="https://git.kernel.org/pub/scm/utils/mdadm/mdadm.git/snapshot/${P}.tar.gz
	mirror://debian/pool/main/m/mdadm/${PN}_${DEB_PF}.debian.tar.xz"

LICENSE="GPL-2"
SLOT="0"
if [[ "${PV}" != *_rc* ]] ; then
	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ppc ppc64 ~riscv sparc x86"
fi
IUSE="corosync static systemd +udev"
REQUIRED_USE="static? ( !udev )"

BDEPEND="app-arch/xz-utils
	virtual/pkgconfig"
DEPEND="udev? ( virtual/libudev:= )
	corosync? ( sys-cluster/corosync )"
RDEPEND="${DEPEND}
	>=sys-apps/util-linux-2.16"

# The tests edit values in /proc and run tests on software raid devices.
# Thus, they shouldn't be run on systems with active software RAID devices.
RESTRICT="test"

rundir="/dev/.mdadm"

PATCHES=(
	"${WORKDIR}/debian/patches/debian"
)

mdadm_emake() {
	# We should probably make libdlm into USE flags (bug #573782)
	local args=(
		PKG_CONFIG="$(tc-getPKG_CONFIG)"
		CC="$(tc-getCC)"
		CWFLAGS="-Wall -fPIE"
		CXFLAGS="${CFLAGS}"
		LDFLAGS="${LDFLAGS}"
		COROSYNC="$(usev !corosync '-DNO_COROSYNC')"
		DLM="-DNO_DLM"

		# bug #732276
		STRIP=

		"$@"
	)

	if use udev; then
		args+=( UDEVDIR="$(get_udevdir)" )
	fi

	if use systemd; then
		args+=( SYSTEMD_DIR="$(systemd_get_systemunitdir)" )
	else
		args+=( RUN_DIR="${rundir}" )
		args+=( MAP_DIR="${rundir}" )
	fi

	emake "${args[@]}"
}

src_prepare() {
	if [[ -s "${WORKDIR}"/debian/patches/debian/0012-bin-directory.patch ]]; then
		rm "${WORKDIR}"/debian/patches/debian/0012-bin-directory.patch || die
	else
		die "Could not remove Debian '0012-bin-directory.patch' - aborting to save host system"
	fi

	default
}

src_compile() {
	use static && append-ldflags -static

	# CPPFLAGS won't work for this
	use udev || append-cflags -DNO_LIBUDEV

	# bug 907082
	use elibc_musl && append-cppflags -D_LARGEFILE64_SOURCE

	mdadm_emake all
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
	einstalldocs

	if ! use udev; then
		rm -v "${ED}$(get_udevdir)"/rules.d/*.rules
		rmdir -p "${ED}$(get_udevdir)"/rules.d
	fi

	# install mdcheck_start.service, needed for systemd units (bug #833000)
	exeinto /usr/share/mdadm/
	doexe misc/mdcheck

	insinto /etc
	newins documentation/mdadm.conf-example mdadm.conf
	newinitd "${FILESDIR}"/mdadm.rc mdadm
	newconfd "${FILESDIR}"/mdadm.confd mdadm
	newinitd "${FILESDIR}"/mdraid.rc mdraid
	newconfd "${FILESDIR}"/mdraid.confd mdraid

	# From the Debian patchset
	dodoc "${WORKDIR}"/debian/local/doc/README.checkarray
	dosbin "${WORKDIR}"/debian/local/bin/checkarray
	insinto /etc/default
	newins "${FILESDIR}"/etc-default-mdadm mdadm

	exeinto /etc/cron.weekly
	newexe "${FILESDIR}"/mdadm.weekly mdadm
}

pkg_postinst() {
	use !udev || udev_reload
	if use systemd && ! systemd_is_booted; then
		if [[ -z ${REPLACING_VERSIONS} ]] ; then
			# Only inform people the first time they install.
			elog "If you're not relying on kernel auto-detect of your RAID"
			elog "devices, you need to add 'mdraid' to your 'boot' runlevel:"
			elog "	rc-update add mdraid boot"
		fi
	fi
}

pkg_postrm() {
	use !udev || udev_reload
}
