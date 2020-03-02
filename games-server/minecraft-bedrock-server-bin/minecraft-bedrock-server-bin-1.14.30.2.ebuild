# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit readme.gentoo-r1

MY_PN="${PN/-bin}"
DESCRIPTION="The official bedrock server for the sandbox video game"
HOMEPAGE="https://www.minecraft.net/"
SRC_URI="https://minecraft.azureedge.net/bin-linux/bedrock-server-${PV}.zip"

LICENSE="Mojang"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	acct-group/minecraft
	acct-user/minecraft
"
	#app-misc/dtach

RESTRICT="bindist mirror"

S="${WORKDIR}"

#-rwxr-xr-x  1 portage portage 181740696 Dec 12 23:37 bedrock_server
#-rw-r--r--  1 portage portage     19374 Dec 12 23:01 bedrock_server_how_to.html
#drwxr-xr-x  8 portage portage      4096 Dec 12 23:09 behavior_packs
#drwxr-xr-x  9 portage portage      4096 Dec 12 23:09 definitions
#-rwxr-xr-x  1 portage portage    710368 Dec 12 23:09 libCrypto.so
#-rw-r--r--  1 portage portage         3 Dec 12 23:01 permissions.json
#-rw-r--r--  1 portage portage       185 Dec 12 23:01 release-notes.txt
#drwxr-xr-x  4 portage portage      4096 Dec 12 23:09 resource_packs
#-rw-r--r--  1 portage portage      3623 Dec 12 23:01 server.properties
#drwxr-xr-x 11 portage portage      4096 Dec 12 23:09 structures
#-rw-r--r--  1 portage portage         3 Dec 12 23:01 whitelist.json

src_install() {
	exeinto "/opt/${MY_PN}"
	doexe bedrock_server libCrypto.so

	insinto "/opt/${MY_PN}"
	doins -r *_packs definitions structures *.json *.properties
	fowners minecraft:minecraft "/opt/${MY_PN}"
	fowners minecraft:minecraft "/opt/${MY_PN}/permissions.json"
	fowners minecraft:minecraft "/opt/${MY_PN}/whitelist.json"

	newinitd "${FILESDIR}"/minecraft-server.initd-r3 minecraft-bedrock-server

	echo >"${T}/99${MY_PN}" "CONFIG_PROTECT=\"/opt/${MY_PN}/permissions.json /opt/${MY_PN}/whitelist.json /opt/${MY_PN}/server.properties\""
	doenvd "${T}/99${MY_PN}"

	dodoc *.html *.txt

	keepdir "/var/log/${MY_PN}"

	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog
}
