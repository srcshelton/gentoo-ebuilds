# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic linux-info

DESCRIPTION="A Thread Stall Detector"
HOMEPAGE="https://gitlab.com/rt-linux-tools/stalld"
SRC_URI="https://gitlab.com/rt-linux-tools/${PN}/-/archive/v${PV}/${PN}-v${PV}.tar.bz2"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~loong x86"
IUSE="bpf"

RDEPEND="app-shells/bash"
# USE='multilib' is needed on amd64 as all eBPF code is 32-bit
DEPEND="
	bpf? (
		dev-libs/libbpf
		dev-util/bpftool
		sys-devel/clang[llvm_targets_bpf]
		amd64? ( sys-libs/glibc[multilib] )
	)
	virtual/linux-sources
	|| ( >=sys-kernel/linux-headers-5.8 >=sys-kernel/raspberrypi-headers-5.8 )
"

pkg_setup() {
	local CONFIG_CHECK="SCHED_DEBUG"
	use bpf && CONFIG_CHECK+=" DEBUG_INFO_BTF"

	local ERROR_SCHED_DEBUG="Kernel option 'CONFIG_SCHED_DEBUG' *must* be enabled for stalld to operate"
	local ERROR_DEBUG_INFO_BTF="Kernel option 'CONFIG_DEBUG_INFO_BTF' *must* be enabled for stalld to compile"

	linux-info_pkg_setup
}

S="${WORKDIR}/${PN}-v${PV}"

src_prepare() {
	# As of (unreleased) v1.19.6 and 1.19.7 (versioned as 1.19.6),
	# 'make install' rebuilds stalld :(
	#
	einfo "Patching Makefile ..."
	sed \
				-e "/^DOCDIR/ s|/stalld$|/stalld-${PV}|" \
				-e '/^FILES/ s| gpl-2.0.txt||' \
				-e '/^install: stalld/ s| stalld||' \
				-e '/LICDIR/ d' \
				-e '/\s:=\(\s\|$\)/ s|:=|?=|' \
				-e '/\smake\s/ s|make|$(MAKE)|' \
				-i Makefile ||
		die "sed failed: ${?}"

	einfo "Patching systemd/stalld.conf ..."
	sed \
				-e 's|/run/|/var/run/|' \
				-e 's/^# ex: /# e.g.: /' \
				-e '/^[A-Z]\+=$/ s/^/#/' \
				-e 's/LOGONLY/LOGGING/' \
			systemd/stalld.conf > "${T}"/stalld.conf ||
		die "sed failed: ${?}"

	# VERSION pre-processor directive isn't being expanded?
	einfo "Patching src/stalld.c ..."
	sed \
				-e "s|VERSION|\"${PV%.0}\"|g" \
				-i src/stalld.c ||
		die "sed failed: ${?}"

	default
}

src_compile() {
	emake MTUNE= USE_BPF=$(usex bpf '1' '0') || die "emake failed"
}

src_install() {
	default

	dodir /usr/sbin
	mv "${ED}"/usr/bin/stalld "${ED}"/usr/sbin/ ||
		die "Binary move failed: ${?}"

	newsbin scripts/throttlectl.sh stalld-throttlectl.sh

	newinitd "${FILESDIR}"/stalld.init stalld
	newconfd "${T}"/stalld.conf stalld
}
