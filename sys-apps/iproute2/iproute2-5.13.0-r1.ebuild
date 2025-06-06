# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic multilib toolchain-funcs

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://git.kernel.org/pub/scm/linux/kernel/git/shemminger/iproute2.git"
	inherit git-r3
else
	SRC_URI="https://www.kernel.org/pub/linux/utils/net/${PN}/${P}.tar.xz"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
fi

DESCRIPTION="kernel routing and traffic control utilities"
HOMEPAGE="https://wiki.linuxfoundation.org/networking/iproute2"

LICENSE="GPL-2"
SLOT="0"
IUSE="atm berkdb bpf caps elf +iptables ipv6 libbsd minimal selinux"

# We could make libmnl optional, but it's tiny, so eh
RDEPEND="
	!net-misc/arpd
	!minimal? ( net-libs/libmnl:= )
	atm? ( net-dialup/linux-atm )
	berkdb? ( sys-libs/db:= )
	bpf? ( dev-libs/libbpf:= )
	caps? ( sys-libs/libcap )
	elf? ( virtual/libelf:= )
	iptables? ( >=net-firewall/iptables-1.4.20:= )
	libbsd? ( dev-libs/libbsd )
	selinux? ( sys-libs/libselinux )
"
# We require newer linux-headers for ipset support #549948 and some defines #553876
DEPEND="
	${RDEPEND}
	virtual/os-headers:31600
"
BDEPEND="
	app-arch/xz-utils
	>=sys-devel/bison-2.4
	sys-devel/flex
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-3.1.0-mtu.patch #291907
	"${FILESDIR}"/${PN}-5.12.0-configure-nomagic.patch # bug 643722
	#"${FILESDIR}"/${PN}-5.1.0-portability.patch
	"${FILESDIR}"/${PN}-5.7.0-mix-signal.h-include.patch
)

src_prepare() {
	if ! use ipv6 ; then
		PATCHES+=(
			"${FILESDIR}"/${PN}-4.20.0-no-ipv6.patch #326849
		)
	fi

	default

	# Fix version if necessary
	local versionfile="include/version.h"
	if [[ "${PV}" != 9999 ]] && ! grep -Fq "${PV}" ${versionfile} ; then
		einfo "Fixing version string"
		sed "s@\"[[:digit:]\.]\+\"@\"${PV}\"@" \
			-i ${versionfile} || die
	fi

	# echo -n is not POSIX compliant
	sed 's@echo -n@printf@' -i configure || die

	sed -i \
		-e '/^CC :\?=/d' \
		-e "/^LIBDIR/s:=.*:=/$(get_libdir):" \
		-e "s|-O2|${CFLAGS} ${CPPFLAGS}|" \
		-e "/^HOSTCC/s:=.*:= $(tc-getBUILD_CC):" \
		-e "/^DBM_INCLUDE/s:=.*:=${T}:" \
		Makefile || die

	# build against system headers
	rm -r include/netinet || die #include/linux include/ip{,6}tables{,_common}.h include/libiptc
	sed -i 's:TCPI_OPT_ECN_SEEN:16:' misc/ss.c || die

	if use minimal ; then
		sed -i -e '/^SUBDIRS=/s:=.*:=lib tc ip:' Makefile || die
	fi
}

src_configure() {
	tc-export AR CC PKG_CONFIG

	# This sure is ugly.  Should probably move into toolchain-funcs at some point.
	local setns
	pushd "${T}" >/dev/null
	printf '#include <sched.h>\nint main(){return setns(0, 0);}\n' > test.c
	${CC} ${CFLAGS} ${CPPFLAGS} -D_GNU_SOURCE ${LDFLAGS} test.c >&/dev/null && setns=y || setns=n
	echo 'int main(){return 0;}' > test.c
	${CC} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} test.c -lresolv >&/dev/null || sed -i '/^LDLIBS/s:-lresolv::' "${S}"/Makefile
	popd >/dev/null

	# run "configure" script first which will create "config.mk"...
	LIBBPF_FORCE="$(usex bpf on off)" \
	econf

	# ...now switch on/off requested features via USE flags
	# this is only useful if the test did not set other things, per bug #643722
	cat <<-EOF >> config.mk
	TC_CONFIG_ATM := $(usex atm y n)
	TC_CONFIG_XT  := $(usex iptables y n)
	TC_CONFIG_NO_XT := $(usex iptables n y)
	# We've locked in recent enough kernel headers #549948
	TC_CONFIG_IPSET := y
	HAVE_BERKELEY_DB := $(usex berkdb y n)
	HAVE_CAP      := $(usex caps y n)
	HAVE_MNL      := $(usex minimal n y)
	HAVE_ELF      := $(usex elf y n)
	HAVE_SELINUX  := $(usex selinux y n)
	IP_CONFIG_SETNS := ${setns}
	# Use correct iptables dir, #144265 #293709
	IPT_LIB_DIR   := $(use iptables && ${PKG_CONFIG} xtables --variable=xtlibdir)
	HAVE_LIBBSD   := $(usex libbsd y n)
	EOF
}

src_compile() {
	emake V=1 NETNS_RUN_DIR=/var/run/netns
}

src_install() {
	if use minimal ; then
		into /
		dosbin tc/tc
		dobin ip/ip
		return 0
	fi

	emake \
		DESTDIR="${D}" \
		PREFIX="${EPREFIX}/usr" \
		LIBDIR="${EPREFIX}"/$(get_libdir) \
		SBINDIR="${EPREFIX}"/sbin \
		CONFDIR="${EPREFIX}"/etc/iproute2 \
		DOCDIR="${EPREFIX}"/usr/share/doc/${PF} \
		MANDIR="${EPREFIX}"/usr/share/man \
		ARPDDIR="${EPREFIX}"/var/lib/arpd \
		install

	dodir /bin
	mv "${ED}"/{s,}bin/ip || die #330115

	dolib.a lib/libnetlink.a
	insinto /usr/include
	doins include/libnetlink.h
	# This local header pulls in a lot of linux headers it
	# doesn't directly need.  Delete this header that requires
	# linux-headers-3.8 until that goes stable.  #467716
	sed -i '/linux\/netconf.h/d' "${ED}"/usr/include/libnetlink.h || die

	if use berkdb ; then
		keepdir /var/lib/arpd
		# bug 47482, arpd doesn't need to be in /sbin
		dodir /usr/bin
		mv "${ED}"/sbin/arpd "${ED}"/usr/bin/ || die
	elif [[ -d "${ED}"/var/lib/arpd ]]; then
		rmdir --ignore-fail-on-non-empty -p "${ED}"/var/lib/arpd || die
	fi
}
