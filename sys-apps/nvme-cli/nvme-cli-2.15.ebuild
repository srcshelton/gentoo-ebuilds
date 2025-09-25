# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson systemd udev

DESCRIPTION="NVM-Express user space tooling for Linux"
HOMEPAGE="https://github.com/linux-nvme/nvme-cli"
SRC_URI="https://github.com/linux-nvme/nvme-cli/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="GPL-2 GPL-2+"
SLOT="0"
KEYWORDS="amd64 arm64 ~loong ppc64 ~riscv ~sparc x86"
IUSE="+json -netapp pdc systemd udev"
REQUIRED_USE="
	netapp? ( udev )
	systemd? ( udev )
"

RDEPEND="
	>=sys-libs/libnvme-1.15:=[json?]
	json? ( dev-libs/json-c:= )
	sys-libs/zlib:=
"
DEPEND="
	${RDEPEND}
	virtual/os-headers
"
BDEPEND="
	virtual/pkgconfig
"

src_configure() {
	local emesonargs=(
		-Dversion-tag="${PV}"
		-Ddocs=all
		-Dhtmldir="${EPREFIX}/usr/share/doc/${PF}/html"
		-Dsystemddir="$(systemd_get_systemunitdir)"
		-Dudevrulesdir="${EPREFIX}$(get_udevdir)/rules.d"
		$(meson_feature json json-c)
		$(meson_use pdc pdc-enabled)
	)
	meson_src_configure
}

src_install() {
	default

	if ! use udev; then
		rm -rf "${ED}"/usr/lib/dracut
		rm "${ED}"/lib/udev/rules.d/*.rules
	else
		if use netapp; then
			rm "${ED}"/lib/udev/rules.d/*nvmf-netapp.rules
		fi
		if ! use systemd; then
			# Requires /usr/bin/systemctl...
			rm "${ED}"/lib/udev/rules.d/*nvmf-autoconnect.rules
		fi
	fi
	if [[ -d "${ED}"/lib/udev/rules.d ]]; then
		rmdir --ignore-fail-on-non-empty --parents "${ED}"/lib/udev/rules.d
	fi
}

pkg_postinst() {
	use !udev || udev_reload
}

pkg_postrm() {
	use !udev || udev_reload
}
