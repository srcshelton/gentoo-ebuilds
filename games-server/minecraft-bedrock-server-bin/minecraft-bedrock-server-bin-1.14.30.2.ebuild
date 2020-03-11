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
