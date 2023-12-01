# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..11} )

inherit python-any-r1

DESCRIPTION="A fast and low-memory footprint OCI Container Runtime fully written in C"
HOMEPAGE="https://github.com/containers/crun"
SRC_URI="https://github.com/containers/${PN}/releases/download/${PV}/${P}.tar.xz"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv"
IUSE="+bpf +caps criu man +seccomp selinux static-libs systemd"
RESTRICT="mirror"

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
	sys-devel/libtool
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

src_prepare() {
	default

	sed -ri \
		-e 's|([=B*])/run|\1/var/run|' \
		src/libcrun/status.c \
		crun.1 \
		crun.1.md \
	|| die "'/run' replacement failed: ${?}"
}

src_configure() {
	local myeconfargs=(
		--cache-file="${S}"/config.cache
		$(use_enable bpf)
		$(use_enable caps)
		$(use_enable criu)
		$(use_enable seccomp)
		$(use_enable systemd)
		$(usex static-libs '--enable-shared --enable-static' '--enable-shared --disable-static')
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

# the crun test suite is comprehensive to the extent that tests will fail
# within a sandbox environment, due to the nature of the privileges
# required to create linux "containers".
# due to this we disable most of the core test suite by unsetting PYTHON_TESTS
src_test() {
	emake check PYTHON_TESTS=
}

src_install() {
	emake "DESTDIR=${D}" install-exec
	if use man ; then
		emake "DESTDIR=${D}" install-man
	fi

	einstalldocs

	einfo "Cleaning up .la files"
	find "${ED}" -name '*.la' -delete || die
}
