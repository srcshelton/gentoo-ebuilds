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
DEPEND="
	bpf? (
		dev-libs/libbpf
		dev-util/bpftool
		llvm-core/clang[llvm_targets_BPF]
	)
	virtual/linux-sources
	virtual/os-headers:50800
"

S="${WORKDIR}/${PN}-v${PV}"

pkg_setup() {
	# Validate setup if package will be merged...
	#
	# Only three options are provided here - 'buildonly', 'binary' and 'source'
	#
	# 'binary' only applies when deploying a pre-built package whilst
	# 'buildonly' only applies if we're not deploying the package immediately
	# once built.  So the check below has to be against 'binary' and we'll work
	# with the assumption that host deployments will all be from pre-built
	# packages.
	#
	#if [[ "${MERGE_TYPE}" == 'binary' ]]; then

	# Update:
	#
	# In general, most checks should be non-fatal. The only time fatal checks
	# should be used is for building kernel modules or cases that a compile
	# will fail without the option.
	#
	# Dealing with the lack of granulairty in linux-info_pkg_setup checks was
	# getting to be a PITA, so let's make these requirements explicitly
	# non-fatal...
	#
		local CONFIG_CHECK="~SCHED_DEBUG"
		use bpf && CONFIG_CHECK+=" ~DEBUG_INFO_BTF"

		local WARNING_SCHED_DEBUG="Kernel option 'CONFIG_SCHED_DEBUG' *must* be enabled for stalld to operate"
		local WARNING_DEBUG_INFO_BTF="Kernel option 'CONFIG_DEBUG_INFO_BTF' *must* be enabled for stalld to compile"

		linux-info_pkg_setup
	#fi
}

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
