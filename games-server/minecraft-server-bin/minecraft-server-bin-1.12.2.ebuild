# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_PN="${PN%-bin}"
MY_PN="${MY_PN//-/_}"

DESCRIPTION="Minecraft: Java Edition Multiplayer Server"
HOMEPAGE="https://minecraft.net/en-us/download/server"
SRC_URI="https://s3.amazonaws.com/Minecraft.Download/versions/${PV}/${MY_PN}.${PV}.jar"
RESTRICT="mirror"

LICENSE="Mojang"
SLOT="0"
KEYWORDS="amd64 arm x86"
#IUSE="tools"

DEPEND="acct-group/minecraft
	acct-user/minecraft"
BDEPEND="sys-apps/shadow"
RDEPEND="${DEPEND}
	>=virtual/jre-1.6
	!games-server/minecraft-server"

S="${WORKDIR}"

src_unpack() {
	# Don't unpack the Jar file!
	:
}

src_install() {
	local p
	p="/opt/${PN%-bin}-${PV}"

	dodir "${p}"/conf

	usermod -d "${p}" minecraft

	insinto "${p}"
	newins "${DISTDIR}/${MY_PN}.${PV}.jar" "${PN%-bin}.jar"
	insinto "${p}"/conf
	doins "${FILESDIR}"/server.properties
	doins "${FILESDIR}"/eula.txt

	fowners -R minecraft:minecraft "${p}"/conf

	echo "CONFIG_PROTECT=\"${EPREFIX}/${p}/conf\"" > "${T}/90${PN%-bin}"

	newconfd "${FILESDIR}"/"${PN%-bin}".confd "${PN%-bin}"
	newinitd "${FILESDIR}"/"${PN%-bin}".initd "${PN%-bin}"
	sed -i "s|%INST_DIR%|/opt/${PN%-bin}-${PV}|g" "${ED}"/etc/{init,conf}.d/"${PN%-bin}" || \
		die "Could not customise init script"

	doenvd "${T}/90${PN%-bin}" || die "Could not configure environment"
}
