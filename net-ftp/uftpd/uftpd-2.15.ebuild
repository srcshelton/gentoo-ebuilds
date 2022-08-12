# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="The no nonsense TFTP/FTP server"
HOMEPAGE="https://github.com/troglobit/uftpd"
SRC_URI="https://github.com/troglobit/${PN}/releases/download/v${PV}/${P}.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="+ftpd test +tftpd"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-libs/libite-1.5
	>=dev-libs/libuev-2.2"

DEPEND="
	${RDEPEND}
	!net-misc/uftp
	!net-ftp/atftp
	tftpd? ( !net-ftp/tftp-hpa[server(+)] )
	test? (
		net-ftp/ftp
		net-ftp/tnftp
		>=net-ftp/tftp-hpa-5.2-r2[client]
	)"

src_test() {
	# can't run the tests in parallel since the order matters
	emake -j 1 check
}

src_install() {
	default

	if ! use ftpd; then
		rm \
				"${ED}/usr/sbin/in.ftpd" \
				"${ED}/usr/share/man/man8/in.ftpd.8"* ||
			die "Unable to remove files /usr/sbin/in.ftpd /usr/share/man/man8/in.ftpd.8*"
	fi
	if ! use tftpd; then
		rm \
				"${ED}/usr/sbin/in.tftpd" \
				"${ED}/usr/share/man/man8/in.tftpd.8"* ||
			die "Unable to remove files /usr/sbin/in.tftpd /usr/share/man/man8/in.tftpd.8*"
	fi
}
