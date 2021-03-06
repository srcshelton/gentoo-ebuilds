# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

JAVA_PKG_IUSE="doc examples source"

inherit autotools flag-o-matic java-pkg-2 java-ant-2

DESCRIPTION="Tools to allow Java programs to run as UNIX daemons"
SRC_URI="mirror://apache/commons/daemon/source/${P}-src.tar.gz"
HOMEPAGE="http://commons.apache.org/daemon/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ppc64 x86 ~amd64-linux ~x86-linux ~x86-solaris"
IUSE="kernel_linux"

CDEPEND="kernel_linux? ( sys-libs/libcap )"

DEPEND="
	${CDEPEND}
	>=virtual/jdk-1.6
	>=dev-java/java-config-2
	source? ( app-arch/zip )"

RDEPEND="
	${CDEPEND}
	>=virtual/jre-1.6"

S="${WORKDIR}/${P}-src"

java_prepare() {
	cd "${S}/src/native/unix" || die
	sed -i "s/powerpc/powerpc|powerpc64/g" support/apsupport.m4 || die
	eautoconf
}

src_configure() {
	use kernel_linux && append-cppflags -I$( java-config-2 -g JAVA_HOME )/include/linux
	java-ant-2_src_configure
	cd "${S}/src/native/unix" || die
	default
}

src_compile() {
	java-pkg-2_src_compile
	cd "${S}/src/native/unix" || die
	default
}

src_install() {
	dobin src/native/unix/jsvc
	java-pkg_newjar dist/*.jar

	dodoc README RELEASE-NOTES.txt *.html src/native/unix/CHANGES.txt
	use doc && java-pkg_dohtml -r dist/docs/*
	use examples && java-pkg_doexamples src/samples
	use source && java-pkg_dosrc src/main/java/*
}
