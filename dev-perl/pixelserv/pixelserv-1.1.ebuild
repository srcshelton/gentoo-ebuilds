# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A super minimal webserver, it's only purpose is serving a pixel gif"
HOMEPAGE="https://proxytunnel.sourceforge.io/pixelserv.php"
SRC_URI="https://proxytunnel.sourceforge.io/files/pixelserv.pl.txt
	https://proxytunnel.sourceforge.io/files/pixelserv-inetd.pl.txt"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm64 arm x86"
IUSE="-xinetd"

S="${WORKDIR}"

src_install() {
	if use xinetd; then
		newbin "${DISTDIR}"/pixelserv-inetd.pl.txt pixelserv.pl
	else
		newsbin "${DISTDIR}"/pixelserv.pl.txt pixelserv.pl
	fi
}

pkg_postinst() {
	if use xinetd; then
		elog "To use ${PN} with (x)inetd support, add the following line"
		elog "to '/etc/services':"
		elog
		elog "  pixelserv 65000/tcp  # pixelserv, ad. blocker"
		elog
		elog "... and then add the following lines to '/etc/inetd.conf':"
		elog
		elog "  pixelserv stream tcp nowait nobody /usr/bin/pixelserv.pl pixelserv.pl"
		elog
		elog "... or the following stanza to '/etc/xinetd.d/pixelserv':"
		elog
		elog "  # default: on"
		elog "  # description: Serve a 1x1 pixel"
		elog
		elog "  service redis {"
		elog "          disable         = no"
		elog "          socket_type     = stream"
		elog "          protocol        = tcp"
		elog "          wait            = no"
		elog "          user            = nobody"
		elog "          group           = nogroup"
		elog "          #only_from       = 127.0.0.1"
		elog "          port            = 65000"
		elog "  }"
	fi
}
