# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit python-single-r1

MY_PN="NoxSpellServer"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Python Aspell server"
#HOMEPAGE="http://orangoo.com/labs/GoogieSpell/Download/Nox_Spell_Server/"
#SRC_URI="http://orangoo.com/labs/uploads/NoxSpellServer.zip -> NoxSpellServer-1.1.zip"
HOMEPAGE="http://web.archive.org/web/20160625095952/http://orangoo.com/labs/GoogieSpell/Download/Nox_Spell_Server/"
SRC_URI="http://web.archive.org/web/20160625105556/http://orangoo.com/labs/uploads/NoxSpellServer.zip -> NoxSpellServer-1.1.zip"
RESTRICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

RDEPEND="
	>=dev-lang/python-2.3
	>=app-text/aspell-0.60.0
	  dev-python/cherrypy
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_PN}"

src_prepare() {
	default

	rm GPL.txt
	# We provide our own CherryPy...
	rm -r lib

	sed -i \
		-e '1 s/python2.4/python/' \
		   nox_server.py
}

src_install() {
	exeinto /usr/bin
	doexe nox_server.py
}
