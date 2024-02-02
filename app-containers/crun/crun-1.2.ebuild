# Copyright 2019-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..10} )

inherit autotools python-any-r1

DESCRIPTION="A fast and low-memory footprint OCI Container Runtime fully written in C"
HOMEPAGE="https://github.com/containers/crun"
SRC_URI="https://github.com/containers/${PN}/releases/download/${PV}/${P}.tar.gz"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64"
IUSE="+bpf +caps criu man +seccomp static-libs systemd"

COMMON_DEPEND="
	>=dev-libs/yajl-2.0.0
	caps? ( sys-libs/libcap )
	criu? ( >=sys-process/criu-3.15 )
	seccomp? ( sys-libs/libseccomp )
	systemd? ( sys-apps/systemd:= )
"
DEPEND="
	${COMMON_DEPEND}
	dev-util/gperf
	sys-devel/gettext
	dev-build/libtool
	virtual/os-headers
	virtual/pkgconfig
"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	man? ( dev-go/go-md2man )
	sys-apps/sed
"

# the crun test suite is comprehensive to the extent that tests will fail
# within a sandbox environment, due to the nature of the privileges
# required to create linux "containers".
RESTRICT="test"

PATCHES=( "${FILESDIR}"/${PN}-1.0-run.patch )

DOCS=( README.md )

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
	emake -C libocispec
	emake crun
	if use man ; then
		emake generate-man
	fi
}

src_install() {
	emake "DESTDIR=${D}" install-exec
	if use man ; then
		emake "DESTDIR=${D}" install-man
	fi

	einstalldocs
}
