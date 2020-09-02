# Copyright 2019-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

inherit autotools python-any-r1

#libocispec_commit='69a096a965ae47c5a83832b87e1d0a5178ca0b30'
#imagespec_commit='79b036d80240ae530a8de15e1d21c7ab9292c693'
#runtimespec_commit='2086147713ebe64cd12681960914e81eadbbe1d9'

DESCRIPTION="A fast and low-memory footprint OCI Container Runtime fully written in C"
HOMEPAGE="https://github.com/containers/crun"
SRC_URI="https://github.com/containers/${PN}/releases/download/${PV}/${P}.tar.gz
	https://github.com/containers/${PN}/raw/${PV}/libcrun.lds"
##SRC_URI="https://github.com/containers/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz
##	https://github.com/containers/libocispec/archive/${libocispec_commit}.tar.gz -> ${P}-libocispec.tar.gz
##	https://github.com/opencontainers/image-spec/archive/${imagespec_commit}.tar.gz -> ${P}-libocispec-imagespec.tar.gz
##	https://github.com/opencontainers/runtime-spec/archive/${runtimespec_commit}.tar.gz -> ${P}-libocispec-runtimespec.tar.gz"
#EGIT_REPO_URI="https://github.com/containers/crun.git"
#EGIT_COMMIT="88886aef25302adfd40a9335372bbc2b970c8ae5" # 0.14.1
#RESTRICT="mirror"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="bpf +caps criu man seccomp static-libs systemd"

COMMON_DEPEND="
	dev-libs/yajl
	caps? ( sys-libs/libcap )
	seccomp? ( sys-libs/libseccomp )
	systemd? ( sys-apps/systemd:= )
"
RDEPEND="${COMMON_DEPEND}"
DEPEND="
	${COMMON_DEPEND}
	virtual/pkgconfig
	dev-util/gperf
	sys-devel/gettext
	sys-devel/libtool"
BDEPEND="
	${PYTHON_DEPS}
	man? ( dev-go/go-md2man )
"

# the crun test suite is comprehensive to the extent that tests will fail
# within a sandbox environment, due to the nature of the privileges
# required to create linux "containers".
RESTRICT="test"

DOCS=( README.md )

src_unpack() {
	# dont' try to unpack the .lds file
	A=( ${A[@]/libcrun.lds} )
	unpack ${A}
}

src_prepare() {
	default
	eautoreconf
	cp -v ${DISTDIR}/libcrun.lds ${S}/ || die "libcrun.lds could not be copied"
}

src_configure() {
	local myeconfargs=(
		$(use_enable criu) \
		$(use_enable bpf) \
		$(use_enable caps) \
		$(use_enable seccomp) \
		$(use_enable systemd) \
		$(usex static-libs '--enabled-shared  --enabled-static' '--enable-shared --disable-static' '' '')
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
