# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ETYPE="sources"
K_NOUSENAME=1
inherit autotools kernel-2

# Most recent changes:
#
#   e7cd4b8
#
# (added 29th October 2024 against Linux-6.12-rc5)

DESCRIPTION="Userspace utilities for a general USB device sharing system over IP networks"
HOMEPAGE="https://www.kernel.org/"
SRC_URI="${KERNEL_URI}"
S="${WORKDIR}/linux-${PV}/tools/usb/${PN}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="doc tcpd"

RDEPEND="
	>=dev-libs/glib-2.6
	sys-apps/hwdata
	virtual/libudev
	tcpd? ( sys-apps/tcp-wrappers )"
DEPEND="${RDEPEND}
	virtual/os-headers:31700"
BDEPEND="virtual/pkgconfig"

src_unpack() {
	tar xJf "${DISTDIR}"/${A} linux-${PV}/tools/usb/${PN} || die
}

src_prepare() {
	default
	# remove -Werror from build, bug #545398
	sed -i 's/-Werror[^ ]* //g' configure.ac || die

	eautoreconf
}

src_configure() {
	if [[ -z "${ABI:-}" ]]; then
		die "Upstream kernel-2.eclass unsets 'ABI', breaking any non-kernel" \
			"packages inheriting this eclass :("
	fi

	econf \
		$(usev !tcpd --without-tcp-wrappers) \
		--with-usbids-dir="${EPREFIX}"/usr/share/hwdata
}

src_install() {
	default

	dodoc "${WORKDIR}"/linux-"${PV}"/tools/usb/"${PN}"/README
	use doc && dodoc  "${WORKDIR}"/linux-"${PV}"/drivers/usb/usbip/usbip_protocol.txt

	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	elog "In order to use USB/IP you must enable USBIP_VHCI_HCD in the client"
	elog "machine's kernel config, and USBIP_HOST on the server where the device(s)"
	elog "to share are attached."
}
