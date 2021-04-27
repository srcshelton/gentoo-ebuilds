# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit python-any-r1 toolchain-funcs

DESCRIPTION="Easy hugepage access"
HOMEPAGE="https://github.com/libhugetlbfs/libhugetlbfs"
SRC_URI="https://github.com/libhugetlbfs/libhugetlbfs/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~s390 ~x86"
IUSE="abi_x86_x32 static-libs test"
RESTRICT="!test? ( test )"

DEPEND="test? ( ${PYTHON_DEPS} )"
RDEPEND="acct-group/hugetlb"

PATCHES=(
	"${FILESDIR}"/${PN}-2.6-fixup-testsuite.patch
)

src_prepare() {
	default
	sed -i \
		-e '/^PREFIX/s:/local::' \
		-e '1iBUILDTYPE = NATIVEONLY' \
		-e '1iV = 1' \
		-e '/gzip.*MANDIR/d' \
		-e "/^LIB\(32\)/s:=.*:= $(get_libdir):" \
		-e '/^CC\(32\|64\)/s:=.*:= $(CC):' \
		-e 's@^\(ARCH\) ?=@\1 =@' \
		Makefile || die "sed failed"
	if [ "$(get_libdir)" == "lib64" ]; then
		sed -i \
			-e "/^LIB\(32\)/s:=.*:= lib32:" \
				Makefile
	fi

	# Tarballs from github don't have the version set.
	# https://github.com/libhugetlbfs/libhugetlbfs/issues/7
	[[ -f version ]] || echo "${PV}" > version
}

src_compile() {
	local -i fix32=0

	tc-export AR

	if use elibc_glibc; then
		if use abi_x86_x32 || [[ "$( uname -m )" == "x86_64" && "$( getconf LONG_BIT )" != "64" ]]; then
			fix32=1
		fi
	fi
	if (( fix32 )); then
		linux32 emake CC="$(tc-getCC)" libs tools
	else
		emake CC="$(tc-getCC)" libs tools
	fi
}

src_install() {
	local -i fix32=0

	#default -> default_src_install -> __eapi6_src_install
	if use elibc_glibc; then
		if use abi_x86_x32 || [[ "$( uname -m )" == "x86_64" && "$( getconf LONG_BIT )" != "64" ]]; then
			fix32=1
		fi
	fi
	if [[ -f makefile || -f Makefile || -f GNUmakefile ]]; then
		if (( fix32 )); then
			linux32 emake DESTDIR="${D}" install
		else
			emake DESTDIR="${D}" install
		fi
	fi
	einstalldocs
	# End __eapi6_src_install

	use static-libs || rm -f "${ED}"/usr/$(get_libdir)/*.a

	# libhugetlbfs Makefile makes bad assumptions about how manpages are compressed :(
	#  image//usr/share/man/man3/:
	#  lrwxrwxrwx 1 root root   19 free_huge_pages.3.gz -> get_huge_pages.3.gz
	#  lrwxrwxrwx 1 root root   24 free_hugepage_region.3.gz -> get_hugepage_region.3.gz
	#  -r--r--r-- 1 root root 2309 get_huge_pages.3
	#  -r--r--r-- 1 root root 2875 get_hugepage_region.3
	#  -r--r--r-- 1 root root 1558 gethugepagesize.3
	#  -r--r--r-- 1 root root 2218 gethugepagesizes.3
	#  -r--r--r-- 1 root root 2189 getpagesizes.3
	#  -r--r--r-- 1 root root 1630 hugetlbfs_find_path.3
	#  lrwxrwxrwx 1 root root   24 hugetlbfs_find_path_for_size.3.gz -> hugetlbfs_find_path.3.gz
	#  -r--r--r-- 1 root root 1466 hugetlbfs_test_path.3
	#  -r--r--r-- 1 root root 1808 hugetlbfs_unlinked_fd.3
	#  lrwxrwxrwx 1 root root   26 hugetlbfs_unlinked_fd_for_size.3.gz -> hugetlbfs_unlinked_fd.3.gz
	local f=''
	for f in free_huge_pages free_hugepage_region; do
		if [[ -L "${ED%/}"/usr/share/man/man3/"${f}".3.gz ]]; then
			rm "${ED%/}"/usr/share/man/man3/"${f}".3.gz
			ln -s "${f/free_/get_}".3 "${ED%/}"/usr/share/man/man3/"${f}".3
		fi
	done
	for f in hugetlbfs_find_path_for_size hugetlbfs_unlinked_fd_for_size; do
		if [[ -L "${ED%/}"/usr/share/man/man3/"${f}".3.gz ]]; then
			rm "${ED%/}"/usr/share/man/man3/"${f}".3.gz
			ln -s "${f/_for_size}".3 "${ED%/}"/usr/share/man/man3/"${f}".3
		fi
	done
}

src_test_alloc_one() {
	hugeadm="${1}"
	sign="${2}"
	pagesize="${3}"
	pagecount="${4}"
	${hugeadm} \
		--pool-pages-max ${pagesize}:${sign}${pagecount} \
	&& \
	${hugeadm} \
		--pool-pages-min ${pagesize}:${sign}${pagecount}
	return $?
}

# die is NOT allowed in this src_test block after the marked point, so that we
# can clean up memory allocation. You'll leak at LEAST 64MiB per run otherwise.
src_test() {
	[[ ${UID} -eq 0 ]] || die "Need FEATURES=-userpriv to run this testsuite"
	einfo "Building testsuite"
	emake -j1 tests || die "Failed to build tests"

	local hugeadm='obj/hugeadm'
	local allocated=''
	local rc=0
	# the testcases need 64MiB per pagesize.
	local MIN_HUGEPAGE_RAM=$((64*1024*1024))

	einfo "Planning allocation"
	local PAGESIZES="$(${hugeadm} --page-sizes-all)"

	# Need to do this before we can create the mountpoints.
	local pagesize pagecount
	for pagesize in ${PAGESIZES} ; do
		# The kernel depends on the location :-(
		mkdir -p /var/lib/hugetlbfs/pagesize-${pagesize}
		addwrite /var/lib/hugetlbfs/pagesize-${pagesize}
	done
	addwrite /proc/sys/vm/
	addwrite /proc/sys/kernel/shmall
	addwrite /proc/sys/kernel/shmmax
	addwrite /proc/sys/kernel/shmmni

	einfo "Checking HugeTLB mountpoints"
	${hugeadm} --create-mounts || die "Failed to set up hugetlb mountpoints."

	# -----------------------------------------------------
	# --------- die is unsafe after this point. -----------
	# -----------------------------------------------------

	einfo "Starting allocation"
	for pagesize in ${PAGESIZES} ; do
		pagecount=$((${MIN_HUGEPAGE_RAM}/${pagesize}))
		einfo "  ${pagecount} @ ${pagesize}"
		addwrite /var/lib/hugetlbfs/pagesize-${pagesize}
		src_test_alloc_one "${hugeadm}" "+" "${pagesize}" "${pagecount}"
		rc=$?
		if [[ ${rc} -eq 0 ]]; then
			allocated="${allocated} ${pagesize}:${pagecount}"
		else
			eerror "Failed to add ${pagecount} pages of size ${pagesize}"
		fi
	done

	einfo "Allocation status"
	${hugeadm} --pool-list

	if [[ -n "${allocated}" ]]; then
		# All our allocations worked, so time to run.
		einfo "Starting tests"
		cd "${S}"/tests || die
		local TESTOPTS="-t func"
		case ${ARCH} in
			amd64|ppc64)
				TESTOPTS="${TESTOPTS} -b 64"
				;;
			x86)
				TESTOPTS="${TESTOPTS} -b 32"
				;;
		esac
		# This needs a bit of work to give a nice exit code still.
		./run_tests.py ${TESTOPTS}
		rc=$?
	else
		eerror "Failed to make HugeTLB allocations."
		rc=1
	fi

	einfo "Cleaning up memory"
	cd "${S}" || die
	# Cleanup memory allocation
	for alloc in ${allocated} ; do
		pagesize="${alloc/:*}"
		pagecount="${alloc/*:}"
		einfo "  ${pagecount} @ ${pagesize}"
		src_test_alloc_one "${hugeadm}" "-" "${pagesize}" "${pagecount}"
	done

	# ---------------------------------------------------------
	# --------- die is safe again after this point. -----------
	# ---------------------------------------------------------

	return ${rc}
}

pkg_postinst() {
	elog "For details of how to configure HugeTLBfs, please see"
	elog "    https://wiki.debian.org/Hugepages#Enabling_HugeTlbPage"
	elog
	elog "A 'hugetlb' group with UIG=30 has been created for this purpose"
	elog
	elog "To fully enable hugetlb support, changes are required to:"
	elog "    /etc/groups"
	elog "    /etc/sysctl.conf"
	elog "    /etc/security/limits.conf"
	elog "    /etc/fstab"
	elog
	elog "dev-db/redis warns against the presence of hugetlb"
}
