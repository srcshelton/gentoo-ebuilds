# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3
PYTHON_DEPEND="2"

inherit distutils

MY_PN="NoxSpellServer"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Python Aspell server"
HOMEPAGE="http://orangoo.com/labs/GoogieSpell/Download/Nox_Spell_Server/"
SRC_URI="http://orangoo.com/labs/uploads/NoxSpellServer.zip"
RESTRICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

RDEPEND="
	>=dev-lang/python-2.4
	>=app-text/aspell-0.60.0
	  dev-python/cherrypy
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_PN}"

src_prepare() {
	rm GPL.txt
	# We provide our own CherryPy...
	rm -r lib
}

src_install() {
	insinto /usr/bin
	doins nox_server.py
}
