# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit autotools eutils flag-o-matic toolchain-funcs user

# Oh god, this is horrible :(
NDPI_PN="nDPI"
NDPI_PV="2.2"
NDPI_P="${NDPI_PN}-${NDPI_PV}"
LUAJIT="LuaJIT-2.1.0-beta3"

DESCRIPTION="Network traffic analyzer with web interface"
HOMEPAGE="http://www.ntop.org/"
# Use (updated) stable branch rather than release tag...
SRC_URI="https://github.com/ntop/${PN}/archive/${PV}-stable.zip -> ${P}.zip
	https://github.com/ntop/${NDPI_PN}/archive/${NDPI_PV}-stable.zip -> ${NDPI_P}-stable.zip"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	!net-libs/nDPI
	dev-db/sqlite:3
	dev-python/pyzmq
	dev-libs/json-c:=
	dev-libs/geoip
	dev-libs/glib:2
	dev-libs/hiredis
	dev-libs/libsodium:=
	dev-libs/libxml2
	net-analyzer/rrdtool
	net-libs/libpcap
	net-misc/curl
	virtual/libmysqlclient"
RDEPEND="${DEPEND}
	dev-db/redis"

PATCHES=(
	"${FILESDIR}"/${PN}-3.2-gentoo.patch
	"${FILESDIR}"/${PN}-3.2-mysqltool.patch
	"${FILESDIR}"/${PN}-3.2-luajit.patch
	"${FILESDIR}"/${PN}-3.2-remove-pool-limits.patch
)

S="${WORKDIR}/${P}-stable"

pkg_setup() {
	if has_version net-libs/nDPI; then
		eerror "Due to the enormous brokenness of the ${PN} source, it is not"
		eerror "possible to build ${PN} if nDPI is present in any way on the"
		eerror "system, even though ${PN} requires nDPI to operate."
		eerror
		eerror "Please completely remove net-libs/nDPI *before* attempting to"
		eerror "install ${PN}."
		die "net-libs/nDPI cannot be installed"
	fi
}

src_prepare() {

	# I'm not crazy - my mother had me tested...
	#
	# ntopng has always used nDPI - and in version 3.0 and before, this was
	# easy: you install the nDPI library, then you install ntopng.
	# In version 3.2 of ntopng, however, this had been FUBAR :(
	# ntopng will fail to compile if any version of nDPI is present on the
	# system at build-time.  However, the nDPI sources (which version is never
	# specified, but 2.0 fails... it seems that 2.2 is a potential candidate?)
	# must be present alongside the ntopng sources, and the ntopng build
	# process requires include files from nDPI which are never installed if
	# nDPI is built separately.
	# Furthermore, nDPI must be configured and built before ntopng can be
	# configured, which means that we have to do it in src_prepare (which is
	# marginally less unpleasant than re-doing ntopng configuration during its
	# src_compile phase, when nDPI can have been compiled in the correct step).
	# To summarise, the ntopng developers have inextricably linked two separate
	# products without actually declaring a dependency or specifying what code
	# versions are required, and have made the building of their product
	# require the successful build of the external code, but in a way which
	# fails if the external code is correctly installed.
	# This does not inspire confidence... :(

	pushd "${S}"/../"${NDPI_P}"-stable >/dev/null || die

	ebegin "Preparing nDPI ${NDPI_PV} source"

	# We love well-maintained source repos...
	[[ -e lib ]] && rm lib

	# Let's not sink to this level of craziness...
	#./autogen.sh

	# ... but instead try to sort it out ourselves:
	NDPI_MAJOR="${PV%.*}"
	NDPI_MINOR="${PV#*.}"
	NDPI_PATCH="0"
	[[ "${PVR}" == *-r* ]] && NDPI_PATCH="${PVR#*-r}"
	NDPI_VERSION_SHORT="${NDPI_MAJOR}.${NDPI_MINOR}.${NDPI_PATCH}"

	ebegin "Generating configure.ac ..."
	sed -e "s/@NDPI_MAJOR@/${NDPI_MAJOR}/g" \
		-e "s/@NDPI_MINOR@/${NDPI_MINOR}/g" \
		-e "s/@NDPI_PATCH@/${NDPI_PATCH}/g" \
		-e "s/@NDPI_VERSION_SHORT@/${NDPI_VERSION_SHORT}/g" \
		configure.seed > configure.ac ||
	eend ${?}  "Version substitution failed: ${?}" || die

	# Now let's let Portage do its thing ...
	S="${WORKDIR}/${NDPI_P}-stable" PATCHES="" default
	eautoreconf || die "eautoreconf failed: ${?}"
	NDPI_HOME=../"${NDPI_P}"-stable econf

	eend ${?} "nDPI preparation failed: ${?}" || die

	# Ogodogodogodogod :(
	ebegin "Building nDPI ${NDPI_PV} source"
	emake
	eend ${?} "nDPI build failed" || die

	popd >/dev/null || die

	pushd "${S}"/third-party/"${LUAJIT}"/src >/dev/null || die

	# ... and there's more.
	ebegin "Preparing ${LUAJIT} source"
	sed -e '/^CCOPT/s/ -O2 / /' \
		-i Makefile
	eend ${?} "LuaJIT preparation failed: ${?}" || die
	ebegin "Building ${LUAJIT} source"
	emake \
		Q= \
		PREFIX="${EPREFIX}/usr" \
		MULTILIB="$(get_libdir)" \
		DESTDIR="${D}" \
		HOST_CC="$(tc-getBUILD_CC)" \
		STATIC_CC="$(tc-getCC)" \
		DYNAMIC_CC="$(tc-getCC) -fPIC" \
		TARGET_LD="$(tc-getCC)" \
		TARGET_AR="$(tc-getAR) rcus" \
		TARGET_STRIP="true" \
		INSTALL_LIB="${ED%/}/usr/$(get_libdir)"
	eend ${?} "LuaJIT build failed: ${?}" || die

	popd >/dev/null || die

	sed -e "s/@VERSION@/${PV}/g;s/@SHORT_VERSION@/${PV}/g" < "${S}/configure.seed" > "${S}/configure.ac" || die

	default

	eautoreconf
}

src_configure() {
	# ntopng can't find its own included source packages :(
	append-cppflags -Ithird-party/LuaJIT-2.1.0-beta3/src

	export NDPI_HOME=../"${NDPI_P}"-stable
	default
}

src_install() {
	SHARE_NTOPNG_DIR="${EPREFIX}/usr/share/${PN}"
	dodir ${SHARE_NTOPNG_DIR}
	insinto ${SHARE_NTOPNG_DIR}
	doins -r httpdocs
	doins -r scripts

	dodir ${SHARE_NTOPNG_DIR}/third-party
	insinto ${SHARE_NTOPNG_DIR}/third-party
	doins -r third-party/i18n.lua-master
	doins -r third-party/lua-resty-template-master

	exeinto /usr/sbin
	doexe ${PN}

	doman ${PN}.8

	newinitd "${FILESDIR}/ntopng.init.d" ntopng
	newconfd "${FILESDIR}/ntopng.conf.d" ntopng

	dodir "/var/lib/ntopng"
	fowners ntopng "${EPREFIX}/var/lib/ntopng"
}

pkg_setup() {
	enewuser ntopng
}

pkg_postinst() {
	elog "ntopng default credentials are user='admin' password='admin'"
}
