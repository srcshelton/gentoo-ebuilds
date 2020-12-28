# Portions Copyright 1999-2016 Gentoo Foundation
# Portions Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit udev

MY_PN="WALinuxAgent"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="Windows Azure Linux Agent"
HOMEPAGE="https://github.com/Azure/WALinuxAgent"
SRC_URI="${HOMEPAGE}/archive/v${PV}.tar.gz"
RESTRICT="mirror"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE="+udev"

# waagent declares no reliance on 'eix', but then calls it unconditionally on
# Gentoo when 'checkPackageInstalled' or 'checkPackageUpdateable' are called.
DEPEND=""
RDEPEND="
	app-admin/sudo
	app-portage/eix
	sys-apps/grep
	sys-apps/iproute2
	sys-apps/sed
	sys-apps/shadow
	sys-apps/util-linux
	sys-block/parted
	>=dev-lang/python-2.6
	>=dev-libs/openssl-1.0.0:*
	>=net-misc/openssh-5.3"
	#dev-python/pyasn1 # Referenced in Dockerfile, but doesn't seem to be used...

S="${WORKDIR}/${MY_P}"

src_prepare() {
	sed -i \
		-e '/Provisioning.DeleteRootPassword/s/=.*$/=n/' \
		-e '/Provisioning.SshHostKeyPairType/s/=.*$/=ed25519/' \
		"${S}"/config/waagent.conf
}

src_install() {
	newsbin bin/waagent2.0 waagent

	# The waagent script contains init scripts for every supported OS
	# (including Gentoo) - but we want to package-manage all components, so the
	# init script has been extracted to the file below... although this does
	# make it somewhat non-standard.
	newinitd "${FILESDIR}"/waagent.initd waagent

	dodoc Changelog README.md

	insinto "/etc"
	doins config/waagent.conf

	insinto /etc/logrotate.d
	newins config/waagent.logrotate waagent
	newins config/waagent-extn.logrotate waagent-extensions

	keepdir /var/lib/waagent

	if use udev; then
		insinto $(get_udevdir)/rules.d
		doins config/66-azure-storage.rules
		doins config/99-azure-product-uuid.rules
	fi
}
