# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools systemd

ETHERCODES_DATE=20200628
DESCRIPTION="An ethernet monitor program that keeps track of ethernet/IP address pairings"
HOMEPAGE="https://ee.lbl.gov/"
SRC_URI="
	https://ee.lbl.gov/downloads/${PN}/${P}.tar.gz
	https://dev.gentoo.org/~jsmolic/distfiles/ethercodes.dat-${ETHERCODES_DATE}.xz
"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="amd64 ~hppa ppc ~riscv sparc x86"
IUSE="selinux systemd"

DEPEND="
	acct-group/arpwatch
	net-libs/libpcap
	sys-libs/ncurses:=
"
RDEPEND="
	${DEPEND}
	acct-user/arpwatch
	virtual/mta
	selinux? ( sec-policy/selinux-arpwatch )
"

PATCHES=(
	# sent upstream on 2023-12-05
	"${FILESDIR}"/0001-Fix-configure-check-for-time.h.patch
	"${FILESDIR}"/0002-Avoid-using-undocumented-internals-for-DNS.patch
)

src_prepare() {
	default

	# Temporary for 0001-Fix-configure-check-for-time.h.patch
	eautoreconf
}

src_install() {
	dosbin arp2ethers arpfetch arpsnmp arpwatch bihourly.sh massagevendor.py update-ethercodes.sh
	doman arpsnmp.8 arpwatch.8

	insinto /usr/share/arpwatch
	newins "${WORKDIR}"/ethercodes.dat-${ETHERCODES_DATE} ethercodes.dat

	insinto /usr/share/arpwatch/awk
	doins d.awk duplicates.awk e.awk euppertolower.awk p.awk

	diropts --group=arpwatch --mode=770
	keepdir /var/lib/arpwatch
	dodoc README CHANGES

	newconfd "${FILESDIR}"/arpwatch.confd-r2 arpwatch
	newinitd "${FILESDIR}"/arpwatch.initd-r2 arpwatch

	if use systemd; then
		systemd_dounit "${FILESDIR}/arpwatch.service"
		systemd_install_serviced "${FILESDIR}/arpwatch.conf"
	fi
}

pkg_postinst() {
	# Previous revisions installed /var/lib/arpwatch with the wrong
	# ownership. Instead of the intended arpwatch:root, it was left as
	# root:root. If we find any such mis-owned directories, we fix them,
	# and then set the permission bits how we want them in *this*
	# revision.
	#
	# The "--from" flag ensures that we only fix directories that need
	# fixing, and the "&& chmod" ensures that we only adjust the
	# permissions if the owner also needed fixing.
	chown \
				--from=root:root \
				--no-dereference \
			:arpwatch \
				"${ROOT}"/var/lib/arpwatch &&
		chmod 770 "${ROOT}"/var/lib/arpwatch
}

# vi: set diffopt=filler,iwhite:
