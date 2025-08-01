# Copyright 2019-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit libtool python-any-r1

DESCRIPTION="A fast and low-memory footprint OCI Container Runtime fully written in C"
HOMEPAGE="https://github.com/containers/crun"

if [[ "$PV" == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/${PN}.git"
else
	SRC_URI="https://github.com/containers/${PN}/releases/download/${PV}/${P}.tar.gz"
	KEYWORDS="amd64 ~arm arm64 ~loong ppc64 ~riscv"
	RESTRICT="mirror"
fi

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
IUSE="+bpf +caps criu man +seccomp selinux static-libs systemd"

COMMON_DEPEND="
	>=dev-libs/yajl-2.0.0:=
	dev-libs/libgcrypt:=
	caps? ( sys-libs/libcap )
	criu? ( >=sys-process/criu-3.15 )
	systemd? ( sys-apps/systemd:= )
"
DEPEND="
	${COMMON_DEPEND}
	dev-util/gperf
	sys-devel/gettext
	dev-build/libtool
	sys-libs/libseccomp
	virtual/os-headers
"
RDEPEND="${COMMON_DEPEND}
	seccomp? ( sys-libs/libseccomp )
	selinux? ( sec-policy/selinux-container )"
BDEPEND="
	${PYTHON_DEPS}
	man? ( dev-go/go-md2man )
	app-shells/bash
	sys-apps/sed
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}/${PN}-1.0-run.patch"
)

#src_prepare() {
#	default
#
#	sed -ri \
#		-e 's|([=B*])/run|\1/var/run|' \
#		src/libcrun/status.c \
#		crun.1 \
#		crun.1.md \
#	|| die "'/run' replacement failed: ${?}"
#}

src_prepare() {
	default
	elibtoolize
}

src_configure() {
	local myeconfargs=(
		#--cache-file="${S}"/config.cache
		$(use_enable bpf)
		$(use_enable caps)
		$(use_enable criu)
		$(use_enable seccomp)
		$(use_enable systemd)
		--enable-shared
		$(use_enable static-libs static)
		--disable-embedded-yajl
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	emake git-version.h
	emake -C libocispec
	emake crun
	if use man ; then
		emake generate-man
	fi
}

src_test() {
	emake check-TESTS -C libocispec

	# the crun test suite is comprehensive to the extent that tests will fail
	# within a sandbox environment, due to the nature of the privileges
	# required to create linux "containers".
	local supported_tests=(
		"tests/tests_libcrun_utils"
		"tests/tests_libcrun_errors"
		"tests/tests_libcrun_intelrdt"
	)
	emake check-TESTS TESTS="${supported_tests[*]}"
}

src_install() {
	emake "DESTDIR=${D}" install-exec
	if use man ; then
		emake "DESTDIR=${D}" install-man
	fi

	einstalldocs

	find "${ED}" -name '*.la' -type f -delete || die
}
