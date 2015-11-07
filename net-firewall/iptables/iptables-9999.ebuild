# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: ef4eb78c92d7f88400535ae1a4077879110157f0 $

EAPI="5"

# Force users doing their own patches to install their own tools
AUTOTOOLS_AUTO_DEPEND=no

inherit autotools eutils git-r3 multilib systemd toolchain-funcs

DESCRIPTION="Linux kernel (3.13+) firewall, NAT and packet mangling tools, with nftables compatibility"
HOMEPAGE="http://www.netfilter.org/projects/nftables/"

LICENSE="GPL-2"
# Subslot tracks libxtables as that's the one other packages generally link
# against and iptables changes.  Will have to revisit if other sonames change.
SLOT="0/10"
KEYWORDS="~alpha ~amd64 arm ~arm64 hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="conntrack ipv6 netlink pcap static-libs systemd xlate"

REPO="iptables"
EGIT_REPO_URI="git://git.netfilter.org/${REPO}.git"
EGIT_BRANCH="$( usex xlate 'xlate2' 'master' )"
#EGIT_COMMIT="${COMMIT}"

RDEPEND="
	conntrack? ( net-libs/libnetfilter_conntrack )
	netlink? ( net-libs/libnfnetlink )
	pcap? ( net-libs/libpcap )
"
DEPEND="${RDEPEND}
	virtual/os-headers
	virtual/pkgconfig
	=net-libs/libnftnl-9999
"

src_prepare() {
	# use the saner headers from the kernel
	rm -f include/linux/{kernel,types}.h

	eautoreconf

	epatch "${FILESDIR}"/${PN}-1.4.21-configure.patch #557586
	epatch "${FILESDIR}"/${PN}-1.4.21-static-connlabel-config.patch #558234

	# Only run autotools if user patched something
	epatch_user && eautoreconf || elibtoolize
}

src_configure() {
	# Some libs use $(AR) rather than libtool to build #444282
	tc-export AR

	# Hack around struct mismatches between userland & kernel for some ABIs. #472388
	use amd64 && [[ ${ABI} == "x32" ]] && append-flags -fpack-struct

	sed -i \
		-e "/nfnetlink=[01]/s:=[01]:=$(usex netlink 1 0):" \
		-e "/nfconntrack=[01]/s:=[01]:=$(usex conntrack 1 0):" \
		configure || die

	econf \
		--sbindir="${EPREFIX}/sbin" \
		--libexecdir="${EPREFIX}/$(get_libdir)" \
		--enable-devel \
		--enable-shared \
		--enable-libipq \
		--enable-nfsynproxy \
		$(use_enable pcap bpf-compiler) \
		$(use_enable static-libs static) \
		$(use_enable ipv6)
}

src_compile() {
	emake V=1
}

src_install() {
	default
	dodoc INCOMPATIBILITIES iptables/iptables.xslt

	# all the iptables binaries are in /sbin, so might as well
	# put these small files in with them
	into /
	dosbin iptables/iptables-apply
	dosym iptables-apply /sbin/ip6tables-apply
	doman iptables/iptables-apply.8

	insinto /usr/include
	doins include/iptables.h $(use ipv6 && echo include/ip6tables.h)
	insinto /usr/include/iptables
	doins include/iptables/internal.h

	keepdir /var/lib/iptables
	newinitd "${FILESDIR}"/${PN}.init iptables
	newconfd "${FILESDIR}"/${PN}-1.4.13.confd iptables
	if use ipv6 ; then
		keepdir /var/lib/ip6tables
		newinitd "${FILESDIR}"/${PN}.init ip6tables
		newconfd "${FILESDIR}"/ip6tables-1.4.13.confd ip6tables
	fi

	if use systemd; then
		systemd_dounit "${FILESDIR}"/systemd/iptables{,-{re,}store}.service
		if use ipv6 ; then
			systemd_dounit "${FILESDIR}"/systemd/ip6tables{,-{re,}store}.service
		fi
	fi

	# Move important libs to /lib #332175
	gen_usr_ldscript -a ip{4,6}tc iptc xtables

	prune_libtool_files --all
}
