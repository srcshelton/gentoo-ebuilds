# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic linux-info tmpfiles udev multilib-minimal

DESCRIPTION="TCG Trusted Platform Module 2.0 Software Stack"
HOMEPAGE="https://github.com/tpm2-software/tpm2-tss"
SRC_URI="https://github.com/tpm2-software/${PN}/releases/download/${PV}/${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0/4"
KEYWORDS="amd64 arm arm64 ~loong ppc64 ~riscv x86"
IUSE="doc +fapi mbedtls +openssl +policy static-libs systemd test +tmpfiles udev"
RESTRICT="!test? ( test )"

REQUIRED_USE="
	^^ ( mbedtls openssl )
	fapi? ( openssl !mbedtls )
	policy? ( openssl !mbedtls )
"

RDEPEND="
	acct-group/tss
	acct-user/tss
	sys-apps/util-linux:=[${MULTILIB_USEDEP}]
	fapi? (
		dev-libs/json-c:=[${MULTILIB_USEDEP}]
		>=net-misc/curl-7.80.0[${MULTILIB_USEDEP}]
	)
	mbedtls? ( net-libs/mbedtls:=[${MULTILIB_USEDEP}] )
	openssl? ( dev-libs/openssl:=[${MULTILIB_USEDEP}] )
"

DEPEND="
	${RDEPEND}
	test? ( app-crypt/swtpm
		dev-libs/uthash
		dev-util/cmocka
		fapi? ( >=net-misc/curl-7.80.0 ) )
"

BDEPEND="
	sys-apps/acl
	virtual/pkgconfig
	doc? ( app-text/doxygen )
"

PATCHES=(
	"${FILESDIR}/${PN}-4.0.2-Dont-install-files-into-run.patch"
)

pkg_setup() {
	local CONFIG_CHECK="~TCG_TPM"
	linux-info_pkg_setup
	kernel_is ge 4 12 0 || ewarn "At least kernel 4.12.0 is required"
}

src_prepare() {
	default
	eautoreconf
}

multilib_src_configure() {
	# Fails with inlining
	filter-flags -fno-semantic-interposition
	append-flags -fsemantic-interposition
	# tests fail with LTO enabbled. See bug 865275 and 865279
	filter-lto

	local myconf=(
		--localstatedir=/var
		$(multilib_native_use_enable doc doxygen-doc)
		$(use_enable fapi)
		$(use_enable policy)
		$(use_enable static-libs static)
		$(multilib_native_use_enable test unit)
		$(multilib_native_use_enable test integration)
		$(multilib_native_use_enable test self-generated-certificate)
		--disable-tcti-libtpms
		--disable-tcti-spi-ltt2go
		--disable-tcti-spi-ftdi
		--disable-tcti-i2c-ftdi
		--disable-defaultflags
		--disable-weakcrypto
		--with-crypto="$(usex mbedtls mbed ossl)"
		--with-runstatedir=/var/run
		--with-udevrulesdir="$(get_udevdir)/rules.d"
		--with-udevrulesprefix=60-
		--without-sysusersdir
		--with-tmpfilesdir="/usr/lib/tmpfiles.d"
	)

	ECONF_SOURCE=${S} econf "${myconf[@]}"
}

multilib_src_install() {
	default
	keepdir /var/lib/tpm2-tss/system/keystore

	if ! use udev; then
		rm "${ED}$(get_udevdir)"/rules.d/60-*
		rmdir -p "${ED}$(get_udevdir)"/rules.d 2>/dev/null
	fi
	if ! use tmpfiles; then
		rm -rf "${ED}"/usr/lib/tmpfiles.d
		rmdir -p "${ED}"/usr/lib 2>/dev/null
	fi
	if ! use systemd; then
		rm -rf "${ED}"/usr/lib/sysusers.d
		rmdir -p "${ED}"/usr/lib 2>/dev/null
	fi

	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process tpm2-tss-fapi.conf
	use !udev || udev_reload
}

pkg_postrm() {
	use !udev || udev_reload
}
