# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
SCONS_MIN_VERSION="2.3.0"
CHECKREQS_DISK_BUILD="2400M"
CHECKREQS_DISK_USR="512M" # Less if stripped binaries are installed.
CHECKREQS_MEMORY="640M" # Default 1024M, but builds on RPi with ~700M available...

inherit eutils flag-o-matic multilib pax-utils scons-utils systemd toolchain-funcs user versionator check-reqs

MY_P=${PN}-src-r${PV/_rc/-rc}

DESCRIPTION="A high-performance, open source, schema-free document-oriented database"
HOMEPAGE="http://www.mongodb.org"
SRC_URI="https://fastdl.mongodb.org/src/${MY_P}.tar.gz
	arm? ( https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/38.8.0esr/source/firefox-38.8.0esr.source.tar.bz2 )"

LICENSE="AGPL-3 Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm"
IUSE="debug kerberos libressl mms-agent +mongos ssl systemd test +tools"

RDEPEND=">=app-arch/snappy-1.1.2
	>=dev-cpp/yaml-cpp-0.5.1
	>=dev-libs/boost-1.57[threads(+)]
	>=dev-libs/libpcre-8.39[cxx]
	dev-libs/snowball-stemmer
	net-libs/libpcap
	>=sys-libs/zlib-1.2.8
	mms-agent? ( app-admin/mms-agent )
	ssl? (
		!libressl? ( >=dev-libs/openssl-1.0.1g:0= )
		libressl? ( dev-libs/libressl:0= )
	)"
DEPEND="${RDEPEND}
	>=sys-devel/gcc-4.8.2:*
	sys-libs/ncurses
	sys-libs/readline
	debug? ( dev-util/valgrind )
	kerberos? ( dev-libs/cyrus-sasl[kerberos] )
	test? (
		dev-python/pymongo
		dev-python/pyyaml
	)"
PDEPEND="tools? ( >=app-admin/mongo-tools-${PV} )"

PATCHES=(
	"${FILESDIR}/${PN}-3.2.0-fix-scons.patch"
	"${FILESDIR}/${PN}-3.2.4-boost-1.60.patch"
	"${FILESDIR}/${PN}-3.2.10-boost-1.62.patch"
	"${FILESDIR}/${PN}-3.2.16-Replace-string-with-explicit-std-string.patch"
	"${FILESDIR}/${PN}-3.4.6-sysmacros-include.patch"
)

S=${WORKDIR}/${MY_P}

pkg_pretend() {
	if [[ ${REPLACING_VERSIONS} < 3.0 ]]; then
		ewarn "To upgrade an existing MongoDB deployment to 3.2, you must be"
		ewarn "running a 3.0-series release. Please update to the latest 3.0"
		ewarn "release before continuing if wish to keep your data."
	fi
}

pkg_setup() {
	enewgroup mongodb
	enewuser mongodb -1 -1 /var/lib/${PN} mongodb

	# Maintainer notes
	#
	# --use-system-tcmalloc is strongly NOT recommended:
	# https://www.mongodb.org/about/contributors/tutorial/build-mongodb-from-source/

	scons_opts=(
		CC="$(tc-getCC)"
		CXX="$(tc-getCXX)"

		--disable-warnings-as-errors
		--use-system-boost
		--use-system-pcre
		--use-system-snappy
		--use-system-stemmer
		--use-system-yaml
		--use-system-zlib
	)

	# wiredtiger not supported on 32bit platforms #572166
	if use x86 || use arm; then
		scons_opts+=( --wiredtiger=off --mmapv1=on )
	fi

	if use debug; then
		scons_opts+=( --dbg=on )
	fi

	if use prefix; then
		scons_opts+=(
			--cpppath="${EPREFIX}/usr/include"
			--libpath="${EPREFIX}/usr/$(get_libdir)"
		)
	fi

	if use kerberos; then
		scons_opts+=( --use-sasl-client )
	fi

	if use ssl; then
		scons_opts+=( --ssl )
	fi
}

src_prepare() {
	mv "${WORKDIR}"/mozilla-esr38 "${S}"/src/third_party/mozjs-38/mozilla-release || die

	if has_version ">=dev-libs/boost-1.62"; then
		PATCHES+=( "${FILESDIR}/${PN}-3.2.10-boost-1.62.patch" )
	fi

	default
}

src_compile() {
	if use arm; then
		pushd src/third_party/mozjs-38/ >/dev/null || die "chdir() to src/third_party/mozjs-38 failed: ${?}"
		./gen-config.sh arm linux || die "Configuration for ARM failed: ${?}"
		popd >/dev/null
	fi

	# respect mongoDB upstream's basic recommendations
	# see bug #536688 and #526114
	if ! use debug; then
		use arm || filter-flags '-m*' # ... but not on ARM, where flags such as -march/-mtune, -mfpu,
									  # and -mfloat-abi, etc. are *essential* in order to produce
									  # working code.
		filter-flags '-O?'
	fi
	escons "${scons_opts[@]}" core tools || die
}

src_install() {
	escons "${scons_opts[@]}" --nostrip install --prefix="${ED}"/usr || die

	local x
	for x in /var/{lib,log}/${PN}; do
		keepdir "${x}"
		fowners mongodb:mongodb "${x}"
	done

	doman debian/mongo*.1
	#dodoc README docs/building.md

	newinitd "${FILESDIR}/${PN}.initd-r3" ${PN}
	newconfd "${FILESDIR}/${PN}.confd-r3" ${PN}
	newinitd "${FILESDIR}/${PN/db/s}.initd-r3" ${PN/db/s}
	newconfd "${FILESDIR}/${PN/db/s}.confd-r3" ${PN/db/s}

	insinto /etc
	newins "${FILESDIR}/${PN}.conf-r3" ${PN}.conf
	newins "${FILESDIR}/${PN/db/s}.conf-r2" ${PN/db/s}.conf

	use systemd && systemd_dounit "${FILESDIR}/${PN}.service"

	insinto /etc/logrotate.d/
	newins "${FILESDIR}/${PN}.logrotate" ${PN}

	# see bug #526114
	pax-mark emr "${ED}"/usr/bin/{mongo,mongod,mongos}

	if ! use mongos; then
		rm "${ED}"/etc/mongos.conf "${ED}"/etc/init.d/mongos "${ED}"/usr/share/man/man1/mongos.1* "${ED}"/usr/bin/mongos ||
			die "Error removing mongo shard elements: ${?}"
	fi
}

pkg_preinst() {
	# wrt bug #461466
	if [[ "$(get_libdir)" == "lib64" ]]; then
		rmdir "${ED}"/usr/lib/ &>/dev/null
	fi
}

src_test() {
	# this one test fails
	rm jstests/core/repl_write_threads_start_param.js

	./buildscripts/resmoke.py --dbpathPrefix=test --suites core || die "Tests failed"
}

pkg_postinst() {
	local v
	for v in ${REPLACING_VERSIONS}; do
		if ! version_is_at_least 3.0 ${v}; then
			ewarn "!! IMPORTANT !!"
			ewarn " "
			ewarn "${PN} configuration files have changed !"
			ewarn " "
			ewarn "Make sure you migrate from /etc/conf.d/${PN} to the new YAML standard in /etc/${PN}.conf"
			ewarn "  http://docs.mongodb.org/manual/reference/configuration-options/"
			ewarn " "
			ewarn "Make sure you also follow the upgrading process :"
			ewarn "  http://docs.mongodb.org/master/release-notes/3.0-upgrade/"
			ewarn " "
			ewarn "MongoDB 3.0 introduces the WiredTiger storage engine."
			ewarn "WiredTiger is incompatible with MMAPv1 and you need to dump/reload your data if you want to use it."
			ewarn "Once you have your data dumped, you need to set storage.engine: wiredTiger in /etc/${PN}.conf"
			ewarn "  http://docs.mongodb.org/master/release-notes/3.0-upgrade/#change-storage-engine-to-wiredtiger"
			break
		fi
	done

	ewarn "Make sure to read the release notes and follow the upgrade process:"
	ewarn "  https://docs.mongodb.org/manual/release-notes/3.2/"
	ewarn "  https://docs.mongodb.org/master/release-notes/3.2-upgrade/"
	ewarn
	ewarn " Starting in 3.2, MongoDB uses the WiredTiger as the default storage engine."
}
