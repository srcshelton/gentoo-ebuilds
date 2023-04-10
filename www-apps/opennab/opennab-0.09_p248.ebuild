# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit webapp

DESCRIPTION="Nabaztag/tag OpenNab server"
HOMEPAGE="http://opennab.sourceforge.net/"
SRC_URI="https://sourceforge.net/code-snapshots/svn/o/op/opennab/code/opennab-code-r${PVR#*_p}-trunk.zip"
RESTRICT="nomirror"

LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
IUSE="test demo"

RDEPEND="virtual/httpd-php
	dev-lang/php"

need_httpd_cgi

S="${WORKDIR}"

src_install() {
	local dir

	use test || rm -r "${S}"/vl/tests
	use demo || rm -r "${S}"/vl/api_demo

	webapp_src_preinst

	dodoc readme.txt

	insinto "${MY_HTDOCSDIR}"
	doins -r broad vl

	webapp_serverowned "${MY_HTDOCSDIR}"/vl/burrows
	webapp_serverowned "${MY_HTDOCSDIR}"/vl/config
	webapp_serverowned "${MY_HTDOCSDIR}"/vl/logs
	webapp_serverowned "${MY_HTDOCSDIR}"/vl/users
	for dir in $( find "${MY_HTDOCSDIR}"/vl/plugins/ -mindepth 2 -maxdepth 2 -type d -name files ); do
		webapp_serverowned "${dir}"
	done

	webapp_configfile  "${MY_HTDOCSDIR}"/vl/config/opennab.ini

	webapp_src_install
}
