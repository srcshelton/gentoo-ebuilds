# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic toolchain-funcs

DESCRIPTION="Report on flag-o-matic flag filters"
IUSE="clang"

IDEPEND="clang? (
		llvm-core/clang
		llvm-runtimes/clang-runtime
	)"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64 arm x86"

pkg_setup() {
	local flag='' value='' old='' new=''
	local -i changed=0

	if use clang || tc-is-clang ; then
		if ! tc-is-clang; then
			CC='clang'
			CXX='clang++'
			# clang can be used with (gold,) GNU/bfd, lld, mold linkers... but
			# we can't use tc-ld-is-<linker>() if we're not already configured
			# for clang so we need to figure out that '-fuse-ld=' parameter is
			# present in clang's LDFLAGS.  However, this may not be explictly
			# included as the defaults in
			# /etc/clang/${LLVM_MAJOR}/gentoo-runtimes.cfg or
			# /etc/clang/gentoo-runtimes.cfg otherwise will be used if not
			# specified.
			if value="$( grep -ow '-fuse-ld=[^\s]\+' <<<"${_LLVM_LDFLAGS}" )"
			then
				LD="${value}"
			#elif 
			fi
			tc-export CC CXX LD
		fi

		ewarn "Using LLVM flags ..."
		echo

		for flag in C CXX LD; do
			if ! set | grep -q -- "^_LLVM_${flag}FLAGS="; then
				ewarn "make.conf does not set '_LLVM_${flag}FLAGS'"
				continue
			elif [[ -z "$( eval "echo \${_LLVM_${flag}FLAGS}" )" ]]; then
				ewarn "'_LLVM_${flag}FLAGS' is empty"
				continue
			fi

			value="$( eval "echo \${_LLVM_${flag}FLAGS}" )"
			if [[ -n "${value:-}" ]]; then
				einfo "Populating clang ${flag}FLAGS from _LLVM_${flag}FLAGS ('${value}') ..."
				eval "export ${flag}FLAGS=\"${value}\""
			fi
			unset value
		done
	fi

	echo

	for flag in CFLAGS CXXFLAGS LDFLAGS; do
		einfo "Initial ${flag} is '${!flag}'"
		eval "export old_${flag}='${!flag}'"
	done

	strip-unsupported-flags

	echo

	for flag in CFLAGS CXXFLAGS LDFLAGS; do
		einfo "Filtered ${flag} is '${!flag}'"
		eval "export new_${flag}='${!flag}'"
	done

	for flag in CFLAGS CXXFLAGS LDFLAGS; do
		eval "old=\"\${old_${flag}}\""
		eval "new=\"\${new_${flag}}\""
		if ! [[ "${old:-}" == "${new:-}" ]]; then
			if ! diff -q <( xargs -rn 1 <<<"${old:-}" ) <( xargs -rn 1 <<<"${new:-}" ) >/dev/null 2>&1; then
				changed=1
				echo
				ewarn "${flag} differs:"
				diff -u <( xargs -rn 1 <<<"${old:-}" ) <( xargs -rn 1 <<<"${new:-}" ) | grep '^--[^-]' | sed 's/^-//' | xargs -rn 1 ewarn "  "
			fi
		fi
	done

	if ! (( changed )); then
		echo
		einfo "No flags filtered"
	fi

	echo

	return 1
}

src_unpack() {
	return 1
}
