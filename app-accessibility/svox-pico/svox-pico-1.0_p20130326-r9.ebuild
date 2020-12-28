# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools eutils

MYPV="${PV/_p/+git}"
[[ "${PR}" == "r0" ]] && MYPR="" || MYPR="${PR}"

DESCRIPTION="SVOX Pico non-free TTS, from Android"
SRC_URI="http://http.debian.net/debian/pool/non-free/s/svox/svox_${MYPV}.orig.tar.gz
	http://http.debian.net/debian/pool/non-free/s/svox/svox_${MYPV}${PR:+-${PR#r}}.debian.tar.xz"
RESTRICT="nomirror"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

DEPEND="sys-apps/help2man
	dev-libs/popt
	sys-devel/libtool"

WANT_AUTOMAKE="1.11"

# svox-pico-1.0_p20130326-r5 -> svox-1.0+git20130326
S="${WORKDIR}"/"${PN%-pico}-${MYPV}"

src_prepare() {
	local patch

	default

	cd "${S}"

	while read -r patch; do
		eapply ../debian/patches/"${patch}" || die "Debian patch '${patch}' application failed: ${?}"
	done < <( sed 's/#.*$//' "${WORKDIR}"/debian/patches/series | grep -v '^\s*$' )

	mv pico/* . && rmdir pico

	chmod 755 autogen.sh && ./autogen.sh || die "Package-provided autogen.sh failed: ${?}"

	eautoreconf

	help2man --name 'Small Footprint TTS' --version-string ' ' --no-info pico2wave > pico2wave.1
}

src_install() {
	default

	doman pico2wave.1
}
