# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

LUA_COMPAT=( lua5-{1..2} )
PYTHON_COMPAT=( python3_{8..10} )

inherit cmake fcaps flag-o-matic lua-single python-any-r1 qmake-utils xdg-utils

DESCRIPTION="A network protocol analyzer formerly known as ethereal"
HOMEPAGE="https://www.wireshark.org/"

if [[ ${PV} == *9999* ]] ; then
	EGIT_REPO_URI="https://gitlab.com/wireshark/wireshark"
	inherit git-r3
else
	SRC_URI="https://www.wireshark.org/download/src/all-versions/${P/_/}.tar.xz"
	S="${WORKDIR}/${P/_/}"

	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~ppc64 ~riscv x86"
fi

LICENSE="GPL-2"
SLOT="0/${PV}"
IUSE="androiddump bcg729 brotli +capinfos +captype ciscodump crypt +dftest doc dpauxmon +dumpcap +editcap http2 ilbc kerberos libxml2 lto lua lz4 maxminddb +mergecap +minizip +netlink opus +pcap plugin-ifdemo +plugins +qt5 +randpkt +randpktdump +reordercap sbc sdjournal selinux +sharkd smi snappy spandsp sshdump ssl test +text2pcap tfshark +tshark +udpdump zlib +zstd"

REQUIRED_USE="lua? ( ${LUA_REQUIRED_USE} )
	plugin-ifdemo? ( plugins )
	ssl? ( crypt )"

RESTRICT="!test? ( test )"

# bug #753062 for speexdsp
CDEPEND="acct-group/pcap
	>=dev-libs/glib-2.38:2
	>=net-dns/c-ares-1.5:=
	media-libs/speexdsp
	bcg729? ( media-libs/bcg729 )
	brotli? ( app-arch/brotli:= )
	ciscodump? ( >=net-libs/libssh-0.6 )
	crypt? ( dev-libs/libgcrypt:= )
	filecaps? ( sys-libs/libcap )
	http2? ( net-libs/nghttp2:= )
	ilbc? ( media-libs/libilbc )
	kerberos? ( virtual/krb5 )
	libxml2? ( dev-libs/libxml2 )
	lua? ( ${LUA_DEPS} )
	lz4? ( app-arch/lz4:= )
	maxminddb? ( dev-libs/libmaxminddb:= )
	minizip? ( sys-libs/zlib[minizip] )
	netlink? ( dev-libs/libnl:3 )
	opus? ( media-libs/opus )
	pcap? ( net-libs/libpcap )
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtmultimedia:5
		dev-qt/qtprintsupport:5
		dev-qt/qtwidgets:5
		x11-misc/xdg-utils
	)
	sbc? ( media-libs/sbc )
	sdjournal? ( sys-apps/systemd )
	smi? ( net-libs/libsmi )
	snappy? ( app-arch/snappy )
	spandsp? ( media-libs/spandsp )
	sshdump? ( >=net-libs/libssh-0.6 )
	ssl? ( net-libs/gnutls:= )
	zlib? ( sys-libs/zlib )
	zstd? ( app-arch/zstd:= )"
DEPEND="${CDEPEND}"
BDEPEND="${PYTHON_DEPS}
	dev-lang/perl
	sys-devel/bison
	sys-devel/flex
	sys-devel/gettext
	virtual/pkgconfig
	doc? (
		app-doc/doxygen
		dev-ruby/asciidoctor
	)
	qt5? (
		dev-qt/linguist-tools:5
	)
	test? (
		dev-python/pytest
		dev-python/pytest-xdist
	)"
RDEPEND="${CDEPEND}
	qt5? ( virtual/freedesktop-icon-theme )
	selinux? ( sec-policy/selinux-wireshark )"

PATCHES=(
	"${FILESDIR}"/${PN}-2.6.0-redhat.patch
	"${FILESDIR}"/${PN}-3.4.2-cmake-lua-version.patch
	"${FILESDIR}"/${P}-fix-build-no-zlib.patch
)

pkg_setup() {
	use lua && lua-single_pkg_setup
}

src_configure() {
	local mycmakeargs

	# Workaround bug #213705. If krb5-config --libs has -lcrypto then pass
	# --with-ssl to ./configure. (Mimics code from acinclude.m4).
	if use kerberos ; then
		case $(krb5-config --libs) in
			*-lcrypto*)
				ewarn "Kerberos was built with ssl support: linkage with openssl is enabled."
				ewarn "Note there are annoying license incompatibilities between the OpenSSL"
				ewarn "license and the GPL, so do your check before distributing such package."
				mycmakeargs+=( -DENABLE_GNUTLS=$(usex ssl) )
				;;
		esac
	fi

	if use qt5 ; then
		export QT_MIN_VERSION=5.3.0
		append-cxxflags -fPIC -DPIC
	fi

	# Using '-isysroot' to use the macOS SDK fails due to stub libraries and
	# missing headers...
	sed -e '/SDKFLAGS="-isysroot $SDKPATH"/d' \
		-i tools/macos-setup.sh \
		|| die "Could not remove sysroot/SDK injection from macOS setup script: ${?}"

	python_setup

	mycmakeargs+=(
		-DCMAKE_DISABLE_FIND_PACKAGE_{Asciidoctor,DOXYGEN}=$(usex !doc)
		$(use androiddump && use pcap && echo -DEXTCAP_ANDROIDDUMP_LIBPCAP=yes)
		$(usex qt5 LRELEASE=$(qt5_get_bindir)/lrelease '')
		$(usex qt5 MOC=$(qt5_get_bindir)/moc '')
		$(usex qt5 RCC=$(qt5_get_bindir)/rcc '')
		$(usex qt5 UIC=$(qt5_get_bindir)/uic '')
		-DBUILD_androiddump=$(usex androiddump)
		-DBUILD_capinfos=$(usex capinfos)
		-DBUILD_captype=$(usex captype)
		-DBUILD_ciscodump=$(usex ciscodump)
		-DBUILD_dftest=$(usex dftest)
		-DBUILD_dpauxmon=$(usex dpauxmon)
		-DBUILD_dumpcap=$(usex dumpcap)
		-DBUILD_editcap=$(usex editcap)
		-DBUILD_gcrypt=$(usex crypt)
		-DBUILD_mergecap=$(usex mergecap)
		-DBUILD_mmdbresolve=$(usex maxminddb)
		-DBUILD_randpkt=$(usex randpkt)
		-DBUILD_randpktdump=$(usex randpktdump)
		-DBUILD_reordercap=$(usex reordercap)
		-DBUILD_sdjournal=$(usex sdjournal)
		-DBUILD_sharkd=$(usex sharkd)
		-DBUILD_sshdump=$(usex sshdump)
		-DBUILD_text2pcap=$(usex text2pcap)
		-DBUILD_tfshark=$(usex tfshark)
		-DBUILD_tshark=$(usex tshark)
		-DBUILD_udpdump=$(usex udpdump)
		-DBUILD_wireshark=$(usex qt5)
		-DDISABLE_WERROR=yes
		-DENABLE_BCG729=$(usex bcg729)
		-DENABLE_BROTLI=$(usex brotli)
		-DENABLE_CAP=$(usex filecaps caps)
		-DENABLE_GNUTLS=$(usex ssl)
		-DENABLE_ILBC=$(usex ilbc)
		-DENABLE_KERBEROS=$(usex kerberos)
		-DENABLE_LIBXML2=$(usex libxml2)
		-DENABLE_LTO=$(usex lto)
		-DENABLE_LUA=$(usex lua)
		-DENABLE_LZ4=$(usex lz4)
		-DENABLE_MINIZIP=$(usex minizip)
		-DENABLE_NETLINK=$(usex netlink)
		-DENABLE_NGHTTP2=$(usex http2)
		-DENABLE_OPUS=$(usex opus)
		-DENABLE_PCAP=$(usex pcap)
		-DENABLE_PLUGINS=$(usex plugins)
		-DENABLE_PLUGIN_IFDEMO=$(usex plugin-ifdemo)
		-DENABLE_SBC=$(usex sbc)
		-DENABLE_SMI=$(usex smi)
		-DENABLE_SNAPPY=$(usex snappy)
		-DENABLE_SPANDSP=$(usex spandsp)
		-DENABLE_ZLIB=$(usex zlib)
		-DENABLE_ZSTD=$(usex zstd)
	)

	cmake_src_configure

	# Remove any remaining macOS SDK usage...
	find . -name Makefile -exec sed -e 's/ -isysroot [^ ]\+ / /g' -i {} +
}

src_test() {
	cmake_build test-programs

	myctestargs=(
		--disable-capture
		--skip-missing-programs=all
		--verbose

		# Skip known failing tests
		# extcaps needs a bunch of external programs
		-E "(suite_extcaps)"
		#-E "(suite_decryption|suite_extcaps|suite_nameres)"
	)

	cmake_src_test
}

src_install() {
	cmake_src_install

	# FAQ is not required as is installed from help/faq.txt
	dodoc AUTHORS ChangeLog NEWS README* doc/randpkt.txt doc/README*

	# install headers
	insinto /usr/include/wireshark
	doins ws_diag_control.h ws_symbol_export.h \
		"${BUILD_DIR}"/config.h

	# If trying to remove this, try build e.g. libvirt first!
	# At last check, Fedora is still doing this too.
	local dir dirs=(
		epan
		epan/crypt
		epan/dfilter
		epan/dissectors
		epan/ftypes
		wiretap
		wsutil
		wsutil/wmem
	)

	for dir in "${dirs[@]}" ; do
		insinto /usr/include/wireshark/${dir}
		doins ${dir}/*.h
	done

	if use qt5 ; then
		local s

		for s in 16 32 48 64 128 256 512 1024 ; do
			insinto /usr/share/icons/hicolor/${s}x${s}/apps
			newins image/wsicon${s}.png wireshark.png
		done

		for s in 16 24 32 48 64 128 256 ; do
			insinto /usr/share/icons/hicolor/${s}x${s}/mimetypes
			newins image/WiresharkDoc-${s}.png application-vnd.tcpdump.pcap.png
		done
	fi

	if [[ -d "${ED}"/usr/share/appdata ]] ; then
		rm -r "${ED}"/usr/share/appdata || die
	fi
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update

	# Add group for users allowed to sniff.
	chgrp pcap "${EROOT}"/usr/bin/dumpcap

	if use dumpcap && use pcap ; then
		fcaps -o 0 -g pcap -m 4710 -M 0710 \
			cap_dac_read_search,cap_net_raw,cap_net_admin \
			"${EROOT}"/usr/bin/dumpcap
	fi

	ewarn "NOTE: To capture traffic with wireshark as normal user you have to"
	ewarn "add yourself to the pcap group. This security measure ensures"
	ewarn "that only trusted users are allowed to sniff your traffic."
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}