# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit cmake llvm.org python-any-r1

DESCRIPTION="Polyhedral optimizations for LLVM"
HOMEPAGE="https://polly.llvm.org/"

LICENSE="Apache-2.0-with-LLVM-exceptions MIT UoI-NCSA"
SLOT="${LLVM_MAJOR}/${LLVM_SOABI}"
KEYWORDS="amd64 arm arm64 ~loong ~mips ppc ppc64 ~riscv ~sparc x86"
IUSE="debug test"
RESTRICT="!test? ( test )"

DEPEND="
	~llvm-core/llvm-${PV}:${LLVM_MAJOR}=[debug=]
"
RDEPEND="${DEPEND}"
BDEPEND="
	test? (
		$(python_gen_any_dep 'dev-python/lit[${PYTHON_USEDEP}]')
	)
"

LLVM_COMPONENTS=( polly cmake )
llvm.org_set_globals

python_check_deps() {
	python_has_version "dev-python/lit[${PYTHON_USEDEP}]"
}

pkg_setup() {
	use test && python-any-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/llvm/${LLVM_MAJOR}"
		-DLLVM_ROOT="${ESYSROOT}/usr/lib/llvm/${LLVM_MAJOR}"
	)
	use test && mycmakeargs+=(
		-DLLVM_EXTERNAL_LIT="${EPREFIX}/usr/bin/lit"
		-DLLVM_LIT_ARGS="$(get_lit_flags)"
		-DPython3_EXECUTABLE="${PYTHON}"
	)
	cmake_src_configure
}

src_test() {
	local -x LIT_PRESERVES_TMP=1
	cmake_build check-polly
}

pkg_postinst() {
	pkg_config

	elog "To use the clang plugin add the following flag:"
	elog "  \"-fplugin=LLVMPolly.so\""
	elog "Then pass polly args via, e.g.:"
	elog "  \"-mllvm -polly\""
}

pkg_config() {
	local best="$( best_version "${CATEGORY}/${PN}" )"
	local file=''

	if [[ -n "${best}" ]] && [[ "${CATEGORY}/${PF}" != "${best}" ]]; then
		einfo "Not updating library directory, latest version is '${best}'" \
			"(this is '${CATEGORY}/${PF}')"

		return 0
	fi

	for file in \
			libPolly.so \
			libPolly.so.${LLVM_SOABI} \
			libPollyISL.so
	do
		if ! [ -e \
			"${EROOT}/usr/lib/llvm/${LLVM_MAJOR}/$(get_libdir)/${file}" \
			]
		then
			die "Couldn't find ${PN} shared-object '${file}' in path" \
				"'${EROOT}/usr/lib/llvm/${LLVM_MAJOR}/$(get_libdir)/'"
		fi

		find "${EROOT}/usr/$(get_libdir)" -name "libLLVM*.so*" -type l \
				-exec rm -v {} +
		ln -s "../lib/llvm/${LLVM_MAJOR}/$(get_libdir)/${file}" \
				"/usr/$(get_libdir)/" ||
			die "Failed to link '${file}' into '/usr/$(get_libdir)/': ${?}"
	done

	return 0
}
