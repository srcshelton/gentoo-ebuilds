# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit prefix readme.gentoo-r1

DESCRIPTION="Scripts to support compressed swap devices or ramdisks with zRAM"
HOMEPAGE="https://github.com/vaeth/zram-init/"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/vaeth/${PN}.git"
else
	SRC_URI="https://github.com/vaeth/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 ~arm arm64 ppc ppc64 ~riscv x86"
fi

LICENSE="GPL-2"
SLOT="0"
RESTRICT="binchecks strip test"
IUSE="systemd zsh-completion"

BDEPEND="sys-devel/gettext"

RDEPEND="
	>=app-shells/push-2.0
	virtual/libintl
	|| ( sys-apps/openrc sys-apps/systemd )
"

DISABLE_AUTOFORMATTING=true
DOC_CONTENTS="\
To use zram-init, activate it in your kernel and add it to the default
runlevel:
	rc-update add zram-init default
If you use systemd enable zram_swap, zram_tmp, and/or zram_var_tmp with
systemctl. You might need to modify the following file depending on the number
of devices that you want to create:
	/etc/modprobe.d/zram.conf.
If you use the \$TMPDIR as zram device with OpenRC, you should add zram-init to
the boot runlevel:
	rc-update add zram-init boot
Still for the same case, you should add in the OpenRC configuration file for
the services using \$TMPDIR the following line:
	rc_need=\"zram-init\""

src_prepare() {
	default

	hprefixify man/"${PN}".8

	hprefixify -e "s%(}|:)(/(usr/)?sbin)%\1${EPREFIX}\2%g" \
		sbin/"${PN}".in

	hprefixify -e "s%( |=)(/tmp)%\1${EPREFIX}\2%g" \
		systemd/system/* \
		openrc/*/*
}

src_compile() {
	emake \
		MODIFY_SHEBANG=FALSE \
		PREFIX="${EPREFIX}/usr" \
		SYSTEMD=$(usex systemd TRUE FALSE) \
		ZSH_COMPLETION=$(usex zsh-completion TRUE FALSE)
}

src_install() {
	einstalldocs
	readme.gentoo_create_doc

	emake \
			BINDIR="${ED}/sbin" \
			DESTDIR="${ED}" \
			PREFIX="/usr" \
			SYSCONFDIR="/etc" \
			SYSTEMDDIR="${ED}/lib/systemd/system" \
		install
}

pkg_postinst() {
	readme.gentoo_print_elog
}
