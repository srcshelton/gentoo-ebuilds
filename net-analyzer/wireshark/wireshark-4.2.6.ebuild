# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LUA_COMPAT=( lua5-{1..2} )
# TODO: check cmake/modules/UseAsn2Wrs.cmake for 3.12
PYTHON_COMPAT=( python3_{10..13} )

inherit cmake fcaps flag-o-matic lua-single python-any-r1 qmake-utils

DESCRIPTION="Network protocol analyzer (sniffer)"
HOMEPAGE="https://www.wireshark.org/"

if [[ ${PV} == *9999* ]] ; then
	EGIT_REPO_URI="https://gitlab.com/wireshark/wireshark"
	inherit git-r3
else
	VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/wireshark.asc
	inherit verify-sig

	SRC_URI="https://www.wireshark.org/download/src/all-versions/${P/_/}.tar.xz
		verify-sig? ( https://www.wireshark.org/download/SIGNATURES-${PV}.txt -> ${P}-signatures.txt )"
	S="${WORKDIR}/${P/_/}"

	if [[ ${PV} != *_rc* ]] ; then
		KEYWORDS="amd64 arm arm64 ~hppa ~loong ~ppc64 ~riscv x86"
	fi

	BDEPEND="verify-sig? ( sec-keys/openpgp-keys-wireshark )"
fi

LICENSE="GPL-2"
SLOT="0/${PV}"
IUSE="androiddump bcg729 brotli +capinfos +captype ciscodump crypt +dftest doc dpauxmon +dumpcap +editcap -gui http2 http3 ilbc kerberos libxml2 lua lz4 maxminddb +mergecap +minizip +netlink opus +pcap +plugins qt6 +randpkt +randpktdump +reordercap sbc sdjournal selinux +sharkd smi snappy spandsp sshdump ssl test +text2pcap tfshark +tshark +udpdump wifi zlib +zstd"

REQUIRED_USE="
	lua? ( ${LUA_REQUIRED_USE} )
	ssl? ( crypt )
"

RESTRICT="!test? ( test )"

# bug #753062 for speexdsp
COMMON_DEPEND="
	acct-group/pcap
	>=dev-libs/glib-2.50.0:2
	dev-libs/libpcre2
	>=net-dns/c-ares-1.13.0:=
	media-libs/speexdsp
	bcg729? ( media-libs/bcg729 )
	brotli? ( app-arch/brotli:= )
	ciscodump? ( >=net-libs/libssh-0.6:= )
	crypt? ( >=dev-libs/libgcrypt-1.8.0:= )
	filecaps? ( sys-libs/libcap )
	http2? ( >=net-libs/nghttp2-1.11.0:= )
	http3? ( net-libs/nghttp3 )
	ilbc? ( media-libs/libilbc:= )
	kerberos? ( virtual/krb5 )
	libxml2? ( dev-libs/libxml2 )
	lua? ( ${LUA_DEPS} )
	lz4? ( app-arch/lz4:= )
	maxminddb? ( dev-libs/libmaxminddb:= )
	minizip? ( sys-libs/zlib[minizip] )
	netlink? ( dev-libs/libnl:3 )
	opus? ( media-libs/opus )
	pcap? ( net-libs/libpcap )
	gui? (
		x11-misc/xdg-utils
		qt6? (
			dev-qt/qtbase:6[concurrent,dbus,gui,widgets]
			dev-qt/qt5compat:6
			dev-qt/qtmultimedia:6
		)
		!qt6? (
			dev-qt/qtcore:5
			dev-qt/qtconcurrent:5
			dev-qt/qtgui:5
			dev-qt/qtmultimedia:5
			dev-qt/qtprintsupport:5
			dev-qt/qtwidgets:5
		)
	)
	sbc? ( media-libs/sbc )
	sdjournal? ( sys-apps/systemd:= )
	smi? ( net-libs/libsmi )
	snappy? ( app-arch/snappy:= )
	spandsp? ( media-libs/spandsp:= )
	sshdump? ( >=net-libs/libssh-0.6:= )
	ssl? ( >=net-libs/gnutls-3.5.8:= )
	wifi? ( >=net-libs/libssh-0.6:= )
	zlib? ( sys-libs/zlib )
	zstd? ( app-arch/zstd:= )
"
DEPEND="
	${COMMON_DEPEND}
	gui? (
		!qt6? (
			dev-qt/qtdeclarative:5
		)
	)
"
# TODO: 4.0.0_rc1 release notes say:
# "Perl is no longer required to build Wireshark, but may be required to build some source code files and run code analysis checks."
BDEPEND="
	${BDEPEND}
	${PYTHON_DEPS}
	dev-lang/perl
	app-alternatives/lex
	sys-devel/gettext
	virtual/pkgconfig
	doc? (
		app-text/doxygen
		dev-ruby/asciidoctor
		dev-libs/libxslt
	)
	gui? (
		qt6? (
			dev-qt/qttools:6[linguist]
		)
		!qt6? (
			dev-qt/linguist-tools:5
		)
	)
	test? (
		$(python_gen_any_dep '
			dev-python/pytest[${PYTHON_USEDEP}]
			dev-python/pytest-xdist[${PYTHON_USEDEP}]
		')
	)
"
RDEPEND="
	${COMMON_DEPEND}
	gui? ( virtual/freedesktop-icon-theme )
	selinux? ( sec-policy/selinux-wireshark )
"

python_check_deps() {
	use test || return 0

	python_has_version -b "dev-python/pytest[${PYTHON_USEDEP}]" &&
		python_has_version -b "dev-python/pytest-xdist[${PYTHON_USEDEP}]"
}

pkg_setup() {
	use lua && lua-single_pkg_setup

	python-any-r1_pkg_setup
}

src_unpack() {
	if [[ ${PV} == *9999* ]] ; then
		git-r3_src_unpack
	else
		if use verify-sig ; then
			cd "${DISTDIR}" || die
			verify-sig_verify_signed_checksums \
				${P}-signatures.txt \
				openssl-dgst \
				${P}.tar.xz
			cd "${WORKDIR}" || die
		fi

		default
	fi
}

src_configure() {
	local mycmakeargs

	python_setup

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

	if use gui ; then
		append-cxxflags -fPIC -DPIC
	fi

	# Using '-isysroot' to use the macOS SDK fails due to stub libraries and
	# missing headers...
	sed -e '/SDKFLAGS="-isysroot $SDKPATH"/d' \
		-i tools/macos-setup.sh \
		|| die "Could not remove sysroot/SDK injection from macOS setup script: ${?}"

	# crashes at runtime
	# https://bugs.gentoo.org/754021
	filter-lto

	mycmakeargs+=(
		-DPython3_EXECUTABLE="${PYTHON}"
		-DCMAKE_DISABLE_FIND_PACKAGE_{Asciidoctor,DOXYGEN}=$(usex !doc)

		# Force bundled lemon (bug 933119)
		-DLEMON_EXECUTABLE=

		-DRPMBUILD_EXECUTABLE=
		-DGIT_EXECUTABLE=
		-DENABLE_CCACHE=OFF

		$(use androiddump && use pcap && echo -DEXTCAP_ANDROIDDUMP_LIBPCAP=yes)
		$(usex gui LRELEASE=$(qt5_get_bindir)/lrelease '')
		$(usex gui MOC=$(qt5_get_bindir)/moc '')
		$(usex gui RCC=$(qt5_get_bindir)/rcc '')
		$(usex gui UIC=$(qt5_get_bindir)/uic '')

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

		-DBUILD_wireshark=$(usex gui)
		-DUSE_qt6=$(usex qt6)

		-DENABLE_WERROR=OFF
		-DENABLE_BCG729=$(usex bcg729)
		-DENABLE_BROTLI=$(usex brotli)
		-DENABLE_CAP=$(usex filecaps caps)
		-DENABLE_GNUTLS=$(usex ssl)
		-DENABLE_ILBC=$(usex ilbc)
		-DENABLE_KERBEROS=$(usex kerberos)
		-DENABLE_LIBXML2=$(usex libxml2)
		# only appends -flto
		-DENABLE_LTO=OFF
		-DENABLE_LUA=$(usex lua)
		-DLUA_FIND_VERSIONS="${ELUA#lua}"
		-DENABLE_LZ4=$(usex lz4)
		-DENABLE_MINIZIP=$(usex minizip)
		-DENABLE_NETLINK=$(usex netlink)
		-DENABLE_NGHTTP2=$(usex http2)
		-DENABLE_NGHTTP3=$(usex http3)
		-DENABLE_OPUS=$(usex opus)
		-DENABLE_PCAP=$(usex pcap)
		-DENABLE_PLUGINS=$(usex plugins)
		-DENABLE_PLUGIN_IFDEMO=OFF
		-DENABLE_SBC=$(usex sbc)
		-DENABLE_SMI=$(usex smi)
		-DENABLE_SNAPPY=$(usex snappy)
		-DENABLE_SPANDSP=$(usex spandsp)
		-DBUILD_wifidump=$(usex wifi)
		-DENABLE_ZLIB=$(usex zlib)
		-DENABLE_ZSTD=$(usex zstd)
	)

	cmake_src_configure

	# Remove any remaining macOS SDK usage...
	find . -name Makefile -exec sed -e 's/ -isysroot [^ ]\+ / /g' -i {} +
}

src_test() {
	cmake_build test-programs

	# https://www.wireshark.org/docs/wsdg_html_chunked/ChTestsRunPytest.html
	epytest \
		--disable-capture \
		--skip-missing-programs=all \
		--program-path "${BUILD_DIR}"/run
}

src_install() {
	# bug #928577
	# https://gitlab.com/wireshark/wireshark/-/commit/fe7bfdf6caac9204ab5f34eeba7b0f4a0314d3cd
	cmake_src_install install-headers

	# FAQ is not required as is installed from help/faq.txt
	dodoc AUTHORS ChangeLog NEWS README* doc/randpkt.txt doc/README*

	# install headers
	insinto /usr/include/wireshark
	doins "${BUILD_DIR}"/config.h

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

	if use gui ; then
		local s

		for s in 16 32 48 64 128 256 512 1024 ; do
			insinto /usr/share/icons/hicolor/${s}x${s}/apps
			newins resources/icons/wsicon${s}.png wireshark.png
		done

		for s in 16 24 32 48 64 128 256 ; do
			insinto /usr/share/icons/hicolor/${s}x${s}/mimetypes
			newins resources/icons//WiresharkDoc-${s}.png application-vnd.tcpdump.pcap.png
		done
	fi

	if [[ -d "${ED}"/usr/share/appdata ]] ; then
		rm -r "${ED}"/usr/share/appdata || die
	fi
}

pkg_postinst() {
	# Removed to prevent IDEPEND dependency on dev-util/desktop-file-utils
	#use gui && xdg_pkg_postinst

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
