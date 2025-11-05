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
IUSE="bash-completion dracut +json -netapp pdc systemd udev zsh-completion"
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

src_prepare() {
	default

	# Try to adopt standard paths...
	sed -e '/WDC_REASON_ID_PATH_NAME/ s#usr/local/nvmecli#var/lib/nvme-cli#' \
		-e '/make the nvmecli dir in/ s#nvmecli#nvme-cli#' \
		-e '/make the nvme/ s#usr/local#var/lib#' \
		-e '/save off the error reason identifier/ s#usr/local/nvmecli#var/lib/nvme-cli#' \
		-i plugins/wdc/wdc-nvme.c || die

	sed -e 's#usr/local/etc#etc#g' \
		-i Documentation/* || die

	sed -s '/prefix=/ s#usr/local#usr#' \
		-i meson.build || die
}

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
	local f=''

	default

	if [[ -d "${ED}"/usr/local ]]; then
		eerror "ebuild attempted to install into '/usr/local':"
		find "${ED}"/usr -type f |
			while read -r f; do
				eerror "  ${f}"
			done
		die "ebuild requires '/usr/local' fix"
	fi

	if [[ -d "${ED}"/usr/etc ]]; then
		mv "${ED}"/usr/etc "${ED}"/
	fi

	if [[ -d "${ED}"/usr/lib/udev ]]; then
		dodir /lib
		mv "${ED}"/usr/lib/udev "${ED}"/lib/
	fi

	if ! use udev; then
		rm "${ED}"/lib/udev/rules.d/*.rules
	else
		if ! use netapp; then
			rm "${ED}"/lib/udev/rules.d/*nvmf-netapp.rules
		fi
		if ! use systemd; then
			# Requires /usr/bin/systemctl...
			rm "${ED}"/lib/udev/rules.d/*nvmf-autoconnect.rules
		fi
	fi

	if ! use bash-completion; then
		rm -rf "${ED}"/usr/share/bash-completion
	fi
	if ! use dracut; then
		rm -rf "${ED}"/usr/lib/dracut
	fi
	if ! use systemd; then
		rm -rf "${ED}"/usr/lib/systemd
	fi
	if ! use zsh-completion; then
		rm -rf "${ED}"/usr/share/zsh
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
