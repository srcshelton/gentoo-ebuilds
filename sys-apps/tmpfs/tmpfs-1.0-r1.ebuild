# Copyright (c) 2010-2015 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Mirror segments of a filesystem to a memory-based backing store"
HOMEPAGE="https://github.com/srcshelton/tmpfs"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 mips ppc x86"
IUSE="+examples"

RDEPEND="sys-process/lsof"

S="${WORKDIR}"

QA_RUN_ALLOWED="/etc/conf.d/tmpfs"

src_install() {
	newconfd "${FILESDIR}"/"${PN}".conf "${PN}"
	newinitd "${FILESDIR}"/"${PN}".init "${PN}"

	exeinto /etc/local.d/
	doexe "${FILESDIR}"/"${PN}".stop

	if use examples; then
		dodir /mnt/ram
		dosym tmpfs /etc/init.d/tmpfs.ram
	fi
}

pkg_postinst() {
	einfo "A sample configuration file has been deployed to /etc/conf.d/"
	einfo "which will mount a ram-backed filesystem to /var/.mem"
	einfo

	if use examples; then
		einfo "The directory /mnt/ram has been created and /etc/init.d/tmpfs.ram"
		einfo "has been created.  In order to make use of this, perform the"
		einfo "following actions:"
		einfo
		einfo "    sudo rc-update add tmpfs.ram boot"
		einfo "    sudo /etc/init.d/tmpfs.ram start"
		einfo
		einfo "... and then relocate items beneath /var/ to /var/.mem/ and"
		einfo "symlink them back to their original locations, e.g.:"
		einfo
		einfo "    /var/tmp -> .mem/tmp"
		einfo "    /var/cache -> .mem/cache"
		einfo "    /var/lib/portage -> ../.mem/lib/portage"
		einfo
		einfo "Data stored in the memory-backed filesystem will then be"
		einfo "restored to disk on shutdown."
		einfo
		einfo "To commit changes to disk without rebooting, run:"
		einfo
		einfo "    /etc/init.d/tmpfs.ram commit"
		einfo
		ewarn "Please review /etc/conf.d/tmpfs before making any changes."
	else
		ewarn "If you wish to have a sample configuruation deployed, please"
		ewarn "re-build with the 'examples' USE-flag enabled."
		ewarn
		ewarn "Please review /etc/conf.d/tmpfs before making any changes."
	fi
}
