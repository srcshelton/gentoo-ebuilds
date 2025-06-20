# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: kernel-2.eclass
# @MAINTAINER:
# Gentoo Kernel project <kernel@gentoo.org>
# @AUTHOR:
# John Mylchreest <johnm@gentoo.org>
# Mike Pagano <mpagano@gentoo.org>
# <so many, many others, please add yourself>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: Eclass for kernel packages
# @DESCRIPTION:
# This is the kernel.eclass rewrite for a clean base regarding the 2.6
# series of kernel with back-compatibility for 2.4
# Please direct your bugs to the current eclass maintainer :)
# added functionality:
# unipatch		- a flexible, singular method to extract, add and remove patches.

# @ECLASS_VARIABLE: CTARGET
# @INTERNAL
# @DESCRIPTION:
# Utilized for 32-bit userland on ppc64.

# @ECLASS_VARIABLE: CKV
# @DEFAULT_UNSET
# @DESCRIPTION:
# Used as a comparison kernel version, which is used when
# PV doesn't reflect the genuine kernel version.
# This gets set to the portage style versioning. ie:
# CKV=2.6.11_rc4

# @ECLASS_VARIABLE: EXTRAVERSION
# @DEFAULT_UNSET
# @DESCRIPTION:
# The additional version appended to OKV (-gentoo/-gentoo-r1)

# @ECLASS_VARIABLE: H_SUPPORTEDARCH
# @DEFAULT_UNSET
# @DESCRIPTION:
# this should be a space separated list of ARCH's which
# can be supported by the headers ebuild

# @ECLASS_VARIABLE: K_BASE_VER
# @DEFAULT_UNSET
# @DESCRIPTION:
# for git-sources, declare the base version this patch is
# based off of.

# @ECLASS_VARIABLE: K_DEBLOB_AVAILABLE
# @DEFAULT_UNSET
# @DESCRIPTION:
# A value of "0" will disable all of the optional deblob
# code. If empty, will be set to "1" if deblobbing is
# possible. Test ONLY for "1".

# @ECLASS_VARIABLE: K_DEBLOB_TAG
# @DEFAULT_UNSET
# @DESCRIPTION:
# This will be the version of deblob script. It's a upstream SVN tag
# such asw -gnu or -gnu1.

# @ECLASS_VARIABLE: K_DEFCONFIG
# @DEFAULT_UNSET
# @DESCRIPTION:
# Allow specifying a different defconfig target.
# If length zero, defaults to "defconfig".

# @ECLASS_VARIABLE: K_EXP_GENPATCHES_PULL
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, we pull "experimental" regardless of the USE FLAG
# but expect the ebuild maintainer to use K_EXP_GENPATCHES_LIST.

# @ECLASS_VARIABLE: K_EXP_GENPATCHES_NOUSE
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, no USE flag will be provided for "experimental";
# as a result the user cannot choose to apply those patches.

# @ECLASS_VARIABLE: K_EXP_GENPATCHES_LIST
# @DEFAULT_UNSET
# @DESCRIPTION:
# A list of patches to pick from "experimental" to apply when
# the USE flag is unset and K_EXP_GENPATCHES_PULL is set.

# @ECLASS_VARIABLE: K_EXTRAEINFO
# @DEFAULT_UNSET
# @DESCRIPTION:
# this is a new-line separated list of einfo displays in
# postinst and can be used to carry additional postinst
# messages

# @ECLASS_VARIABLE: K_EXTRAELOG
# @DEFAULT_UNSET
# @DESCRIPTION:
# same as K_EXTRAEINFO except using elog instead of einfo

# @ECLASS_VARIABLE: K_EXTRAEWARN
# @DEFAULT_UNSET
# @DESCRIPTION:
# same as K_EXTRAEINFO except using ewarn instead of einfo

# @ECLASS_VARIABLE: K_FROM_GIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, this variable signals that the kernel sources derives
# from a git tree and special handling will be applied so that
# any patches that are applied will actually apply.

# @ECLASS_VARIABLE: K_GENPATCHES_VER
# @DEFAULT_UNSET
# @DESCRIPTION:
# The version of the genpatches tarball(s) to apply.
# A value of "5" would apply genpatches-2.6.12-5 to
# my-sources-2.6.12.ebuild

# @ECLASS_VARIABLE: K_LONGTERM
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, the eclass will search for the kernel source
# in the long term directories on the upstream servers
# as the location has been changed by upstream

# @ECLASS_VARIABLE: K_NODRYRUN
# @DEFAULT_UNSET
# @DESCRIPTION:
# if this is set then patch --dry-run will not
# be run. Certain patches will fail with this parameter
# See bug #507656

# @ECLASS_VARIABLE: K_NOSETEXTRAVERSION
# @DEFAULT_UNSET
# @DESCRIPTION:
# if this is set then EXTRAVERSION will not be
# automatically set within the kernel Makefile

# @ECLASS_VARIABLE: K_NOUSENAME
# @DEFAULT_UNSET
# @DESCRIPTION:
# if this is set then EXTRAVERSION will not include the
# first part of ${PN} in EXTRAVERSION

# @ECLASS_VARIABLE: K_NOUSEPR
# @DEFAULT_UNSET
# @DESCRIPTION:
# if this is set then EXTRAVERSION will not include the
# anything based on ${PR}.

# @ECLASS_VARIABLE: K_PREDEBLOBBED
# @DEFAULT_UNSET
# @DESCRIPTION:
# This kernel was already deblobbed elsewhere.
# If false, either optional deblobbing will be available
# or the license will note the inclusion of linux-firmware code.

# @ECLASS_VARIABLE: K_PREPATCHED
# @DEFAULT_UNSET
# @DESCRIPTION:
# if the patchset is prepatched (ie: pf-sources,
# zen-sources etc) it will use PR (ie: -r5) as the
# patchset version for and not use it as a true package
# revision

# @ECLASS_VARIABLE: K_SECURITY_UNSUPPORTED
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, this kernel is unsupported by Gentoo Security
# to the current eclass maintainer :)

# @ECLASS_VARIABLE: K_SYMLINK
# @DEFAULT_UNSET
# @DESCRIPTION:
# if this is set, then forcibly create symlink anyway

# @ECLASS_VARIABLE: K_USEPV
# @DEFAULT_UNSET
# @DESCRIPTION:
# When setting the EXTRAVERSION variable, it should
# add PV to the end.
# this is useful for things like wolk. IE:
# EXTRAVERSION would be something like : -wolk-4.19-r1

# @ECLASS_VARIABLE: K_WANT_GENPATCHES
# @DEFAULT_UNSET
# @DESCRIPTION:
# Apply genpatches to kernel source. Provide any
# combination of "base", "extras" or "experimental".

# @ECLASS_VARIABLE: KERNEL_URI
# @DEFAULT_UNSET
# @DESCRIPTION:
# Upstream kernel src URI

# @ECLASS_VARIABLE: KV
# @DEFAULT_UNSET
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Kernel Version (2.6.0-gentoo/2.6.0-test11-gentoo-r1)

# @ECLASS_VARIABLE: KV_FULL
# @DEFAULT_UNSET
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Kernel full version

# @ECLASS_VARIABLE: KV_MAJOR
# @DEFAULT_UNSET
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Kernel major version from <KV_MAJOR>.<KV_MINOR>.<KV_PATCH

# @ECLASS_VARIABLE: KV_MINOR
# @DEFAULT_UNSET
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Kernel minor version from <KV_MAJOR>.<KV_MINOR>.<KV_PATCH

# @ECLASS_VARIABLE: KV_PATCH
# @DEFAULT_UNSET
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Kernel patch version from <KV_MAJOR>.<KV_MINOR>.<KV_PATCH

# @ECLASS_VARIABLE: LINUX_HOSTCFLAGS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Default cflags if not already set

# @ECLASS_VARIABLE: OKV
# @DEFAULT_UNSET
# @DESCRIPTION:
# Original Kernel Version (2.6.0/2.6.0-test11)

# @ECLASS_VARIABLE: RELEASE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Representative of the kernel release tag (-rc3/-git3)

# @ECLASS_VARIABLE: RELEASETYPE
# @DEFAULT_UNSET
# @DESCRIPTION:
# The same as RELEASE but with its numerics stripped (-rc/-git)

# @ECLASS_VARIABLE: UNIPATCH_DOCS
# @DEFAULT_UNSET
# @DESCRIPTION:
# space delimemeted list of docs to be installed to
# the doc dir

# @ECLASS_VARIABLE: UNIPATCH_EXCLUDE
# @DEFAULT_UNSET
# @DESCRIPTION:
# An addition var to support exclusion based completely
# on "<passedstring>*" and not "<passedno#>_*"
# this should _NOT_ be used from the ebuild as this is
# reserved for end users passing excludes from the cli

# @ECLASS_VARIABLE: UNIPATCH_LIST
# @DEFAULT_UNSET
# @DESCRIPTION:
# space delimetered list of patches to be applied to the kernel

# @ECLASS_VARIABLE: UNIPATCH_LIST_DEFAULT
# @INTERNAL
# @DESCRIPTION:
# Upstream kernel patch archive

# @ECLASS_VARIABLE: UNIPATCH_LIST_GENPATCHES
# @INTERNAL
# @DESCRIPTION:
# List of genpatches archives to apply to the kernel

# @ECLASS_VARIABLE: UNIPATCH_STRICTORDER
# @DEFAULT_UNSET
# @DESCRIPTION:
# if this is set places patches into directories of
# order, so they are applied in the order passed
# Changing any other variable in this eclass is not supported; you can request
# for additional variables to be added by contacting the current maintainer.
# If you do change them, there is a chance that we will not fix resulting bugs;
# that of course does not mean we're not willing to help.

# Added by Daniel Ostrow <dostrow@gentoo.org>
# This is an ugly hack to get around an issue with a 32-bit userland on ppc64.
# I will remove it when I come up with something more reasonable.
# Alfred Persson Forsberg <cat@catcream.org>
# Moved this above inherit as crossdev.eclass uses CHOST internally.
[[ ${PROFILE_ARCH} == ppc64 ]] && CHOST="powerpc64-${CHOST#*-}"

inherit crossdev estack multiprocessing optfeature toolchain-funcs

case ${EAPI} in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

HOMEPAGE="https://www.kernel.org/ https://wiki.gentoo.org/wiki/Kernel ${HOMEPAGE}"
: "${LICENSE:="GPL-2"}"

if [[ "${CATEGORY}" == 'sys-kernel' ]]; then
	# No need to run scanelf/strip on kernel sources/headers (bug #134453).
	RESTRICT="binchecks strip"
fi

# set LINUX_HOSTCFLAGS if not already set
: "${LINUX_HOSTCFLAGS:="-Wall -Wstrict-prototypes -Os -fomit-frame-pointer -I${S}/include"}"

# @FUNCTION: debug-print-kernel2-variables
# @USAGE:
# @DESCRIPTION:
# this function exists only to help debug kernel-2.eclass
# if you are adding new functionality in, put a call to it
# at the start of src_unpack, or during SRC_URI/dep generation.

debug-print-kernel2-variables() {
	for v in PVR CKV OKV KV KV_FULL KV_MAJOR KV_MINOR KV_PATCH RELEASETYPE \
			RELEASE UNIPATCH_LIST_DEFAULT UNIPATCH_LIST_GENPATCHES \
			UNIPATCH_LIST S KERNEL_URI K_WANT_GENPATCHES ; do
		debug-print "${v}: ${!v}"
	done
}

# @FUNCTION: handle_genpatches
# @USAGE: [--set-unipatch-list]
# @DESCRIPTION:
# add genpatches to list of patches to apply if wanted

handle_genpatches() {
	local tarball want_unipatch_list
	[[ -z ${K_WANT_GENPATCHES} || -z ${K_GENPATCHES_VER} ]] && return 1

	if [[ -n ${1} ]]; then
		# set UNIPATCH_LIST_GENPATCHES only on explicit request
		# since that requires 'use' call which can be used only in phase
		# functions, while the function is also called in global scope
		if [[ ${1} == --set-unipatch-list ]]; then
			want_unipatch_list=1
		else
			die "Usage: ${FUNCNAME} [--set-unipatch-list]"
		fi
	fi

	debug-print "Inside handle_genpatches"
	local OKV_ARRAY
	IFS="." read -r -a OKV_ARRAY <<<"${OKV}"

	# for > 3.0 kernels, handle genpatches tarball name
	# genpatches for 3.0 and 3.0.1 might be named
	# genpatches-3.0-1.base.tar.xz and genpatches-3.0-2.base.tar.xz
	# respectively.  Handle this.

	for i in ${K_WANT_GENPATCHES} ; do
		if [[ ${KV_MAJOR} -ge 3 ]]; then
			if [[ ${#OKV_ARRAY[@]} -ge 3 ]]; then
				tarball="genpatches-${KV_MAJOR}.${KV_MINOR}-${K_GENPATCHES_VER}.${i}.tar.xz"
			else
				tarball="genpatches-${KV_MAJOR}.${KV_PATCH}-${K_GENPATCHES_VER}.${i}.tar.xz"
			fi
		else
			tarball="genpatches-${OKV}-${K_GENPATCHES_VER}.${i}.tar.xz"
		fi

		local use_cond_start="" use_cond_end=""

		if [[ ${i} == experimental && -z ${K_EXP_GENPATCHES_PULL} && -z ${K_EXP_GENPATCHES_NOUSE} ]]; then
			use_cond_start="experimental? ( "
			use_cond_end=" )"

			if [[ -n ${want_unipatch_list} ]] && use experimental; then
				UNIPATCH_LIST_GENPATCHES+=" ${DISTDIR}/${tarball}"
				debug-print "genpatches tarball: ${tarball}"
			fi
		elif [[ -n ${want_unipatch_list} ]]; then
			UNIPATCH_LIST_GENPATCHES+=" ${DISTDIR}/${tarball}"
			debug-print "genpatches tarball: ${tarball}"
		fi
		GENPATCHES_URI+=" ${use_cond_start}$(echo https://dev.gentoo.org/~{alicef,mpagano}/dist/genpatches/${tarball})${use_cond_end}"
	done
}

# @FUNCTION: detect_version
# @USAGE:
# @DESCRIPTION:
# this function will detect and set
# - OKV: Original Kernel Version (2.6.0/2.6.0-test11)
# - KV: Kernel Version (2.6.0-gentoo/2.6.0-test11-gentoo-r1)
# - EXTRAVERSION: The additional version appended to OKV (-gentoo/-gentoo-r1)
detect_version() {
	# We've already run, so nothing to do here.
	[[ -n ${KV_FULL} ]] && return 0

	# CKV is used as a comparison kernel version, which is used when
	# PV doesn't reflect the genuine kernel version.
	# this gets set to the portage style versioning. ie:
	#   CKV=2.6.11_rc4
	CKV=${CKV:-${PV}}
	OKV=${OKV:-${CKV}}
	OKV=${OKV/_beta/-test}
	OKV=${OKV/_rc/-rc}
	OKV=${OKV/-r*}
	OKV=${OKV/_p*}

	KV_MAJOR=$(ver_cut 1 ${OKV})
	# handle if OKV is X.Y or X.Y.Z (e.g. 3.0 or 3.0.1)
	local OKV_ARRAY
	IFS="." read -r -a OKV_ARRAY <<<"${OKV}"

	# if KV_MAJOR >= 3, then we have no more KV_MINOR
	#if [[ ${KV_MAJOR} -lt 3 ]]; then
	if [[ ${#OKV_ARRAY[@]} -ge 3 ]]; then
		KV_MINOR=$(ver_cut 2 ${OKV})
		KV_PATCH=$(ver_cut 3 ${OKV})
		if [[ ${KV_MAJOR}${KV_MINOR}${KV_PATCH} -ge 269 ]]; then
			KV_EXTRA=$(ver_cut 4- ${OKV})
			KV_EXTRA=${KV_EXTRA/[-_]*}
		else
			KV_PATCH=$(ver_cut 3- ${OKV})
		fi
	else
		KV_PATCH=$(ver_cut 2 ${OKV})
		KV_EXTRA=$(ver_cut 3- ${OKV})
		KV_EXTRA=${KV_EXTRA/[-_]*}
	fi

	debug-print "KV_EXTRA is ${KV_EXTRA}"

	KV_PATCH=${KV_PATCH/[-_]*}

	local v n=0 missing
	#if [[ ${KV_MAJOR} -lt 3 ]]; then
	if [[ ${#OKV_ARRAY[@]} -ge 3 ]]; then
		for v in CKV OKV KV_{MAJOR,MINOR,PATCH} ; do
			[[ -z ${!v} ]] && n=1 && missing="${missing}${v} ";
		done
	else
		for v in CKV OKV KV_{MAJOR,PATCH} ; do
			[[ -z ${!v} ]] && n=1 && missing="${missing}${v} ";
		done
	fi

	[[ ${n} -eq 1 ]] && \
		eerror "Missing variables: ${missing}" && \
		die "Failed to extract kernel version (try explicit CKV in ebuild)!"
	unset v n missing

#	if [[ ${KV_MAJOR} -ge 3 ]]; then
	if [[ ${#OKV_ARRAY[@]} -lt 3 ]]; then
		KV_PATCH_ARR=(${KV_PATCH//\./ })

		# at this point 031412, Linus is putting all 3.x kernels in a
		# 3.x directory, may need to revisit when 4.x is released
		KERNEL_BASE_URI="https://www.kernel.org/pub/linux/kernel/v${KV_MAJOR}.x"

		[[ -n ${K_LONGTERM} ]] &&
			KERNEL_BASE_URI="${KERNEL_BASE_URI}/longterm/v${KV_MAJOR}.${KV_PATCH_ARR}"
	else
		#KERNEL_BASE_URI="https://www.kernel.org/pub/linux/kernel/v${KV_MAJOR}.0"
		#KERNEL_BASE_URI="https://www.kernel.org/pub/linux/kernel/v${KV_MAJOR}.${KV_MINOR}"
		if [[ ${KV_MAJOR} -ge 3 ]]; then
			KERNEL_BASE_URI="https://www.kernel.org/pub/linux/kernel/v${KV_MAJOR}.x"
		else
			KERNEL_BASE_URI="https://www.kernel.org/pub/linux/kernel/v${KV_MAJOR}.${KV_MINOR}"
		fi

		[[ -n ${K_LONGTERM} ]] &&
			#KERNEL_BASE_URI="${KERNEL_BASE_URI}/longterm"
			KERNEL_BASE_URI="${KERNEL_BASE_URI}/longterm/v${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}"
	fi

	debug-print "KERNEL_BASE_URI is ${KERNEL_BASE_URI}"

	if [[ ${#OKV_ARRAY[@]} -ge 3 && ${KV_MAJOR} -ge 3 ]]; then
		# handle non genpatch using sources correctly
		if [[ -z ${K_WANT_GENPATCHES} && -z ${K_GENPATCHES_VER} && ${KV_PATCH} -gt 0 ]]; then
			KERNEL_URI="${KERNEL_BASE_URI}/patch-${OKV}.xz"
			UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${CKV}.xz"
		fi
		KERNEL_URI="${KERNEL_URI} ${KERNEL_BASE_URI}/linux-${KV_MAJOR}.${KV_MINOR}.tar.xz"
	else
		KERNEL_URI="${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
	fi

	RELEASE=${CKV/${OKV}}
	RELEASE=${RELEASE/_beta}
	RELEASE=${RELEASE/_rc/-rc}
	RELEASE=${RELEASE/_pre/-pre}
	# We cannot trivially call kernel_is here, because it calls us to detect the
	# version
	#kernel_is ge 2 6 && RELEASE=${RELEASE/-pre/-git}
	(( KV_MAJOR * 1000 + ${KV_MINOR:-0} >= 2006 )) && RELEASE=${RELEASE/-pre/-git}
	RELEASETYPE=${RELEASE//[0-9]}

	# Now we know that RELEASE is the -rc/-git
	# and RELEASETYPE is the same but with its numerics stripped
	# we can work on better sorting EXTRAVERSION.
	# first of all, we add the release
	EXTRAVERSION="${RELEASE}"
	debug-print "0 EXTRAVERSION:${EXTRAVERSION}"
	[[ -n ${KV_EXTRA} && ${KV_MAJOR} -lt 3 ]] && EXTRAVERSION=".${KV_EXTRA}${EXTRAVERSION}"

	debug-print "1 EXTRAVERSION:${EXTRAVERSION}"
	if [[ -n ${K_NOUSEPR} ]]; then
		# Don't add anything based on PR to EXTRAVERSION
		debug-print "1.0 EXTRAVERSION:${EXTRAVERSION}"
	elif [[ -n ${K_PREPATCHED} ]]; then
		debug-print "1.1 EXTRAVERSION:${EXTRAVERSION}"
		EXTRAVERSION="${EXTRAVERSION}-${PN/-*}${PR/r}"
	elif [[ ${ETYPE} = sources ]]; then
		debug-print "1.2 EXTRAVERSION:${EXTRAVERSION}"
		# For some sources we want to use the PV in the extra version
		# This is because upstream releases with a completely different
		# versioning scheme.
		case ${PN/-*} in
		     wolk) K_USEPV=1;;
		  vserver) K_USEPV=1;;
		esac

		[[ -z ${K_NOUSENAME} ]] && EXTRAVERSION="${EXTRAVERSION}-${PN/-*}"
		[[ -n ${K_USEPV} ]]     && EXTRAVERSION="${EXTRAVERSION}-${PV//_/-}"
		[[ -n ${PR//r0} ]] && EXTRAVERSION="${EXTRAVERSION}-${PR}"
	fi
	debug-print "2 EXTRAVERSION:${EXTRAVERSION}"

	# The only messing around which should actually effect this is for KV_EXTRA
	# since this has to limit OKV to MAJ.MIN.PAT and strip EXTRA off else
	# KV_FULL evaluates to MAJ.MIN.PAT.EXT.EXT after EXTRAVERSION

	if [[ -n ${KV_EXTRA} ]]; then
		if [[ -n ${KV_MINOR} ]]; then
			OKV="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}"
		else
			OKV="${KV_MAJOR}.${KV_PATCH}"
		fi
		KERNEL_URI="${KERNEL_BASE_URI}/patch-${CKV}.xz
					${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
		UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${CKV}.xz"
	fi

	# We need to set this using OKV, but we need to set it before we do any
	# messing around with OKV based on RELEASETYPE
	KV_FULL=${OKV}${EXTRAVERSION}

	# we will set this for backwards compatibility.
	S="${WORKDIR}"/linux-${KV_FULL}
	KV=${KV_FULL}

	# -rc-git pulls can be achieved by specifying CKV
	# for example:
	#   CKV="2.6.11_rc3_pre2"
	# will pull:
	#   linux-2.6.10.tar.xz & patch-2.6.11-rc3.xz & patch-2.6.11-rc3-git2.xz

	if [[ ${KV_MAJOR}${KV_MINOR} -eq 26 ]]; then

		if [[ ${RELEASETYPE} == -rc || ${RELEASETYPE} == -pre ]]; then
			OKV="${KV_MAJOR}.${KV_MINOR}.$((${KV_PATCH} - 1))"
			KERNEL_URI="${KERNEL_BASE_URI}/testing/patch-${CKV//_/-}.xz
						${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
			UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${CKV//_/-}.xz"
		fi

		if [[ ${RELEASETYPE} == -git ]]; then
			KERNEL_URI="${KERNEL_BASE_URI}/snapshots/patch-${OKV}${RELEASE}.xz
						${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
			UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${OKV}${RELEASE}.xz"
		fi

		if [[ ${RELEASETYPE} == -rc-git ]]; then
			OKV="${KV_MAJOR}.${KV_MINOR}.$((${KV_PATCH} - 1))"
			KERNEL_URI="${KERNEL_BASE_URI}/snapshots/patch-${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${RELEASE}.xz
						${KERNEL_BASE_URI}/testing/patch-${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${RELEASE/-git*}.xz
						${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"

			UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${RELEASE/-git*}.xz ${DISTDIR}/patch-${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${RELEASE}.xz"
		fi
	else
		KV_PATCH_ARR=(${KV_PATCH//\./ })

		# the different majorminor versions have different patch start versions
		OKV_DICT=(["2"]="${KV_MAJOR}.$((${KV_PATCH_ARR} - 1))" ["3"]="2.6.39" ["4"]="3.19")

		if [[ ${RELEASETYPE} == -rc || ${RELEASETYPE} == -pre ]]; then

			OKV=${K_BASE_VER:-${OKV_DICT["${KV_MAJOR}"]}}

			# as of 12/5/2017, the rc patch is no longer offered as a compressed
			# file, and no longer is it mirrored on kernel.org
			if ver_test "${KV_MAJOR}.${KV_PATCH}" -ge "4.12"; then
				KERNEL_URI="https://git.kernel.org/torvalds/p/v${KV_FULL}/v${OKV} -> patch-${KV_FULL}.patch
							${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
				UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${CKV//_/-}.patch"
			else
				KERNEL_URI="${KERNEL_BASE_URI}/testing/patch-${CKV//_/-}.xz
							${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
				UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${CKV//_/-}.xz"
			fi
		fi

		if [[ ${RELEASETYPE} == -git ]]; then
			KERNEL_URI="${KERNEL_BASE_URI}/snapshots/patch-${OKV}${RELEASE}.xz
						${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
			UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${OKV}${RELEASE}.xz"
		fi

		if [[ ${RELEASETYPE} == -rc-git ]]; then
			OKV=${K_BASE_VER:-${OKV_DICT["${KV_MAJOR}"]}}
			KERNEL_URI="${KERNEL_BASE_URI}/snapshots/patch-${KV_MAJOR}.${KV_PATCH}${RELEASE}.xz
						${KERNEL_BASE_URI}/testing/patch-${KV_MAJOR}.${KV_PATCH}${RELEASE/-git*}.xz
						${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"

			UNIPATCH_LIST_DEFAULT="${DISTDIR}/patch-${KV_MAJOR}.${KV_PATCH}${RELEASE/-git*}.xz ${DISTDIR}/patch-${KV_MAJOR}.${KV_PATCH}${RELEASE}.xz"
		fi
	fi

	debug-print-kernel2-variables

	handle_genpatches
}

# @FUNCTION: kernel_is
# @USAGE: <conditional version | version>
# @DESCRIPTION:
# user for comparing kernel versions
# or just identifying a version
# e.g kernel_is 2 4
# e.g kernel_is ge 4.8.11
# Note: duplicated in linux-info.eclass
kernel_is() {
	# ALL of these should be set before we can safely continue this function.
	# some of the sources have in the past had only one set.
	local v n=0
	for v in OKV KV_{MAJOR,MINOR,PATCH} ; do [[ -z ${!v} ]] && n=1 ; done
	[[ ${n} -eq 1 ]] && detect_version

	# Now we can continue
	local operator

	case ${1#-} in
	  lt) operator="-lt"; shift;;
	  gt) operator="-gt"; shift;;
	  le) operator="-le"; shift;;
	  ge) operator="-ge"; shift;;
	  eq) operator="-eq"; shift;;
	   *) operator="-eq";;
	esac
	[[ $# -gt 3 ]] && die "Error in ${ECLASS}_${FUNCNAME}(): too many parameters"

	ver_test \
		"${KV_MAJOR:-0}.${KV_MINOR:-0}.${KV_PATCH:-0}" \
		"${operator}" \
		"${1:-${KV_MAJOR:-0}}.${2:-${KV_MINOR:-0}}.${3:-${KV_PATCH:-0}}"
}

# Capture the sources type and set DEPENDs
if [[ "${ETYPE}" == 'sources' ]]; then
	SLOT=${SLOT:=${PVR}}

	if ! [[ "${CATEGORY}" == 'sys-kernel' ]]; then
		DESCRIPTION="Sources using code from the Linux Kernel"

	else
		RDEPEND="!build? (
			app-alternatives/cpio
			dev-lang/perl
			app-alternatives/bc
			dev-build/make
			sys-devel/bison
			sys-devel/flex
			>=sys-libs/ncurses-5.2
			virtual/libelf
			virtual/pkgconfig
		)"

		DESCRIPTION="Sources based on the Linux Kernel"
		IUSE="symlink build"
	fi

	# Bug #266157, deblob for libre support
	if [[ -z ${K_PREDEBLOBBED} ]]; then
		if [[ ${K_DEBLOB_AVAILABLE} == 1 ]]; then
			IUSE="${IUSE} deblob"

			# Reflect that kernels contain firmware blobs unless otherwise
			# stripped. Starting with version 4.14, the whole firmware
			# tree has been dropped from the kernel.
			kernel_is lt 4 14 &&
				LICENSE+=" !deblob? ( linux-fw-redistributable all-rights-reserved )"

			if [[ -n KV_MINOR ]]; then
				DEBLOB_PV="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}"
			else
				DEBLOB_PV="${KV_MAJOR}.${KV_PATCH}"
			fi

			if [[ ${KV_MAJOR} -ge 3 ]]; then
				DEBLOB_PV="${KV_MAJOR}.${KV_MINOR}"
			fi

			# deblob svn tag, default is -gnu, to change, use K_DEBLOB_TAG in ebuild
			K_DEBLOB_TAG=${K_DEBLOB_TAG:--gnu}
			DEBLOB_A="deblob-${DEBLOB_PV}"
			DEBLOB_CHECK_A="deblob-check-${DEBLOB_PV}"
			DEBLOB_HOMEPAGE="https://www.fsfla.org/svn/fsfla/software/linux-libre/releases/tags/"
			DEBLOB_URI_PATH="${DEBLOB_PV}${K_DEBLOB_TAG}"
			DEBLOB_CHECK_URI="${DEBLOB_HOMEPAGE}/${DEBLOB_URI_PATH}/deblob-check -> ${DEBLOB_CHECK_A}"
			DEBLOB_URI="${DEBLOB_HOMEPAGE}/${DEBLOB_URI_PATH}/${DEBLOB_A}"
			HOMEPAGE="${HOMEPAGE} ${DEBLOB_HOMEPAGE}"

			KERNEL_URI="${KERNEL_URI}
				deblob? (
					${DEBLOB_URI}
					${DEBLOB_CHECK_URI}
				)"
		elif kernel_is lt 4 14; then
			# Deblobbing is not available, so just mark kernels older
			# than 4.14 as tainted with non-libre materials.
			LICENSE+=" linux-fw-redistributable all-rights-reserved"
		fi
	fi

elif [[ ${ETYPE} == headers ]]; then
	DESCRIPTION="Linux system headers"
	IUSE="headers-only"

	# Since we should NOT honour KBUILD_OUTPUT in headers
	# lets unset it here.
	unset KBUILD_OUTPUT

	SLOT="0"
fi

# Cross-compile support functions

# @FUNCTION: kernel_header_destdir
# @USAGE:
# @DESCRIPTION:
# return header destination directory
kernel_header_destdir() {
	[[ ${CTARGET} == ${CHOST} ]] \
		&& echo /usr/include \
		|| echo /usr/${CTARGET}/usr/include
}

# @FUNCTION: cross_pre_c_headers
# @USAGE:
# @DESCRIPTION:
# set use if necessary for cross compile support
cross_pre_c_headers() {
	use headers-only && [[ ${CHOST} != ${CTARGET} ]]
}

# @FUNCTION: env_setup_kernel_makeopts
# @USAGE:
# @DESCRIPTION:
# Set the toolchain variables, as well as ARCH and CROSS_COMPILE when
# cross-compiling.

env_setup_kernel_makeopts() {
	# Kernel ARCH != portage ARCH
	export KARCH=$(tc-arch-kernel)

	# When cross-compiling, we need to set the ARCH/CROSS_COMPILE
	# variables properly or bad things happen !
	KERNEL_MAKEOPTS=( ARCH="${KARCH}" )
	if [[ ${CTARGET} != ${CHOST} ]] && ! cross_pre_c_headers; then
		KERNEL_MAKEOPTS+=( CROSS_COMPILE="${CTARGET}-" )
	elif type -p ${CHOST}-ar >/dev/null; then
		KERNEL_MAKEOPTS+=( CROSS_COMPILE="${CHOST}-" )
	fi
	KERNEL_MAKEOPTS+=(
		HOSTCC="$(tc-getBUILD_CC)"
		CC="$(tc-getCC)"
		LD="$(tc-getLD)"
		AR="$(tc-getAR)"
		NM="$(tc-getNM)"
		OBJCOPY="$(tc-getOBJCOPY)"
		READELF="$(tc-getREADELF)"
		STRIP="$(tc-getSTRIP)"
	)
	export KERNEL_MAKEOPTS
}

# @FUNCTION: universal_unpack
# @USAGE:
# @DESCRIPTION:
# unpack kernel sources

universal_unpack() {
	debug-print "Inside universal_unpack"

	local OKV_ARRAY
	IFS="." read -r -a OKV_ARRAY <<<"${OKV}"

	cd "${WORKDIR}" || die
	if [[ ${#OKV_ARRAY[@]} -ge 3 && ${KV_MAJOR} -ge 3 ]]; then
		unpack linux-${KV_MAJOR}.${KV_MINOR}.tar.xz
	else
		unpack linux-${OKV}.tar.xz
	fi

	if [[ -d linux ]]; then
		debug-print "Moving linux to linux-${KV_FULL}"
		mv linux linux-${KV_FULL} \
			|| die "Unable to move source tree to ${KV_FULL}."
	elif [[ ${OKV} != ${KV_FULL} ]]; then
		if [[ ${#OKV_ARRAY[@]} -ge 3 && ${KV_MAJOR} -ge 3 ]] &&
			[[ ${ETYPE} = sources ]]; then
			debug-print "moving linux-${KV_MAJOR}.${KV_MINOR} to linux-${KV_FULL} "
			mv linux-${KV_MAJOR}.${KV_MINOR} linux-${KV_FULL} \
				|| die "Unable to move source tree to ${KV_FULL}."
		else
			debug-print "moving linux-${OKV} to linux-${KV_FULL} "
			mv linux-${OKV} linux-${KV_FULL} \
				|| die "Unable to move source tree to ${KV_FULL}."
		fi
	elif [[ ${#OKV_ARRAY[@]} -ge 3 && ${KV_MAJOR} -ge 3 ]]; then
		mv linux-${KV_MAJOR}.${KV_MINOR} linux-${KV_FULL} \
			|| die "Unable to move source tree to ${KV_FULL}."
	fi
	cd "${S}" || die

	# remove all backup files
	find . -iname "*~" -exec rm {} \; 2>/dev/null

}

# @FUNCTION: unpack_set_extraversion
# @USAGE:
# @DESCRIPTION:
# handle EXTRAVERSION

unpack_set_extraversion() {
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" "${S}"/Makefile || die
}

# @FUNCTION: unpack_fix_install_path
# @USAGE:
# @DESCRIPTION:
# Should be done after patches have been applied
# Otherwise patches that modify the same area of Makefile will fail

unpack_fix_install_path() {
	sed -i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' "${S}"/Makefile || die
}

# install functions

# @FUNCTION: install_universal
# @USAGE:
# @DESCRIPTION:
# Fix permissions in tarball

install_universal() {
	chown -R 0:0 "${WORKDIR}"/* &>/dev/null
	chmod -R a+r-w+X,u+w "${WORKDIR}"/*
}

# @FUNCTION: install_headers
# @USAGE:
# @DESCRIPTION:
# Install headers

install_headers() {
	local ddir=$(kernel_header_destdir)

	env_setup_kernel_makeopts
	emake headers_install INSTALL_HDR_PATH="${ED}"${ddir}/.. "${KERNEL_MAKEOPTS[@]}"

	# let other packages install some of these headers
	rm -rf "${ED}"${ddir}/scsi || die #glibc/uclibc/etc...
	return 0
}

# @FUNCTION: install_sources
# @USAGE:
# @DESCRIPTION:
# Install sources

install_sources() {
	local file

	cd "${S}" || die
	dodir /usr/src
	einfo ">>> Copying sources ..."

	file="$(find "${WORKDIR}" -iname "docs" -type d)"
	if [[ -n ${file} ]]; then
		for file in $(find ${file} -type f); do
			echo "${file//*docs\/}" >> "${S}"/patches.txt
			echo "===================================================" >> "${S}"/patches.txt
			cat ${file} >> "${S}"/patches.txt
			echo "===================================================" >> "${S}"/patches.txt
			echo "" >> "${S}"/patches.txt
		done
	fi

	cp -R "${WORKDIR}"/linux* "${ED}"/usr/src || die

	if [[ -n ${UNIPATCH_DOCS} ]]; then
		for i in ${UNIPATCH_DOCS}; do
			dodoc "${T}"/${i}
		done
	fi
}

# @FUNCTION: preinst_headers
# @USAGE:
# @DESCRIPTION:
# Headers preinst steps

preinst_headers() {
	local ddir=$(kernel_header_destdir)
	[[ -L ${EPREFIX}${ddir}/linux ]] && { rm "${EPREFIX}"${ddir}/linux || die; }
	[[ -L ${EPREFIX}${ddir}/asm ]] && { rm "${EPREFIX}"${ddir}/asm || die; }
}

# @FUNCTION: postinst_sources
# @USAGE:
# @DESCRIPTION:
# Sources post installation function.
# see inline comments

postinst_sources() {
	# if we have USE=symlink, then force K_SYMLINK=1
	use symlink && K_SYMLINK=1

	# We do support security on a deblobbed kernel, bug #555878.
	# If some particular kernel version doesn't have security
	# supported because of USE=deblob or otherwise, one can still
	# set K_SECURITY_UNSUPPORTED on a per ebuild basis.
	#[[ ${K_DEBLOB_AVAILABLE} == 1 ]] && \
	#	use deblob && \
	#	K_SECURITY_UNSUPPORTED=deblob

	# if we are to forcibly symlink, delete it if it already exists first.
	if [[ ${K_SYMLINK} -gt 0 ]]; then
		if [[ -e ${EROOT}/usr/src/linux && ! -L ${EROOT}/usr/src/linux ]] ; then
			die "${EROOT}/usr/src/linux exists and is not a symlink"
		fi

		ln -snf linux-${KV_FULL} "${EROOT}"/usr/src/linux || die
	fi

	# Don't forget to make directory for sysfs
	[[ ! -d ${EROOT}/sys ]] && kernel_is 2 6 && { mkdir "${EROOT}"/sys || die ; }

	elog "If you are upgrading from a previous kernel, you may be interested"
	elog "in the following document:"
	elog "  - General upgrade guide: https://wiki.gentoo.org/wiki/Kernel/Upgrade"

	# if K_EXTRAEINFO is set then lets display it now
	if [[ -n ${K_EXTRAEINFO} ]]; then
		echo ${K_EXTRAEINFO} | fmt |
		while read -s ELINE; do einfo "${ELINE}"; done
	fi

	# if K_EXTRAELOG is set then lets display it now
	if [[ -n ${K_EXTRAELOG} ]]; then
		echo ${K_EXTRAELOG} | fmt |
		while read -s ELINE; do elog "${ELINE}"; done
	fi

	# if K_EXTRAEWARN is set then lets display it now
	if [[ -n ${K_EXTRAEWARN} ]]; then
		echo ${K_EXTRAEWARN} | fmt |
		while read -s ELINE; do ewarn "${ELINE}"; done
	fi

	# optionally display security unsupported message
	#  Start with why
	if [[ -n ${K_SECURITY_UNSUPPORTED} ]]; then
		ewarn "${PN} is UNSUPPORTED by Gentoo Security."
	fi
	#  And now the general message.
	if [[ -n ${K_SECURITY_UNSUPPORTED} ]]; then
		ewarn "This means that it is likely to be vulnerable to recent security issues."
		ewarn "Upstream kernel developers recommend always running the latest "
		ewarn "release of any current long term supported Linux kernel version."
		ewarn "To see a list of these versions, their most current release and "
		ewarn "long term support status, please go to https://www.kernel.org ."
		ewarn "For specific information on why this kernel is unsupported, please read:"
		ewarn "https://wiki.gentoo.org/wiki/Project:Kernel_Security"
	fi

	# warn sparc users that they need to do cross-compiling with >= 2.6.25(bug #214765)
	KV_MAJOR=$(ver_cut 1 ${OKV})
	KV_MINOR=$(ver_cut 2 ${OKV})
	KV_PATCH=$(ver_cut 3 ${OKV})
	if [[ $(tc-arch) = sparc ]]; then
		if [[ $(gcc-major-version) -lt 4 && $(gcc-minor-version) -lt 4 ]]; then
			if [[ ${KV_MAJOR} -ge 3 ]] || ver_test ${KV_MAJOR}.${KV_MINOR}.${KV_PATCH} -gt 2.6.24; then
				elog "NOTE: Since 2.6.25 the kernel Makefile has changed in a way that"
				elog "you now need to do"
				elog "  make CROSS_COMPILE=sparc64-unknown-linux-gnu-"
				elog "instead of just"
				elog "  make"
				elog "to compile the kernel. For more information please browse to"
				elog "https://bugs.gentoo.org/show_bug.cgi?id=214765"
			fi
		fi
	fi

	optfeature "versioned kernel image installation and optionally automating tasks such as generating an initramfs or unified kernel image" \
		"sys-kernel/installkernel"
}

# pkg_setup functions

# @FUNCTION: setup_headers
# @USAGE:
# @DESCRIPTION:
# Determine if ${PN} supports arch

setup_headers() {
	[[ -z ${H_SUPPORTEDARCH} ]] && H_SUPPORTEDARCH=${PN/-*/}
	for i in ${H_SUPPORTEDARCH}; do
		[[ $(tc-arch) == ${i} ]] && H_ACCEPT_ARCH="yes"
	done

	if [[ ${H_ACCEPT_ARCH} != yes ]]; then
		eerror "This version of ${PN} does not support $(tc-arch)."
		eerror "Please merge the appropriate sources, in most cases"
		eerror "(but not all) this will be called $(tc-arch)-headers."
		die "Package unsupported for $(tc-arch)"
	fi
}

# @FUNCTION: unipatch
# @USAGE: <list of patches to apply>
# @DESCRIPTION:
# Universal function that will apply patches to source

unipatch() {
	local i x y z extension PIPE_CMD UNIPATCH_DROP KPATCH_DIR PATCH_DEPTH ELINE
	local STRICT_COUNT PATCH_LEVEL myLC_ALL myLANG

	# set to a standard locale to ensure sorts are ordered properly.
	myLC_ALL="${LC_ALL}"
	myLANG="${LANG}"
	LC_ALL="C"
	LANG=""

	[[ -z ${KPATCH_DIR} ]] && KPATCH_DIR="${WORKDIR}/patches/"
	[[ ! -d ${KPATCH_DIR} ]] && mkdir -p ${KPATCH_DIR}

	# We're gonna need it when doing patches with a predefined patchlevel
	eshopts_push -s extglob

	# This function will unpack all passed tarballs, add any passed patches,
	# and remove any passed patchnumbers
	# usage can be either via an env var or by params
	# although due to the nature we pass this within this eclass
	# it shall be by param only.
	# -z "${UNIPATCH_LIST}" ] && UNIPATCH_LIST="${@}"
	UNIPATCH_LIST="${@}"

	#unpack any passed tarballs
	for i in ${UNIPATCH_LIST}; do
		if echo ${i} | grep -qs -e "\.tar" -e "\.tbz" -e "\.tgz"; then
			if [[ -n ${UNIPATCH_STRICTORDER} ]]; then
				unset z
				STRICT_COUNT=$((10#${STRICT_COUNT:=0} + 1))
				for((y=0; y<$((6 - ${#STRICT_COUNT})); y++));
					do z="${z}0";
				done
				PATCH_ORDER="${z}${STRICT_COUNT}"

				mkdir -p "${KPATCH_DIR}/${PATCH_ORDER}"
				pushd "${KPATCH_DIR}/${PATCH_ORDER}" >/dev/null || die
				unpack ${i##*/}
				popd >/dev/null || die
			else
				pushd "${KPATCH_DIR}" >/dev/null || die
				unpack ${i##*/}
				popd >/dev/null || die
			fi

			[[ ${i} == *:* ]] && elog ">>> Strict patch levels not currently supported for tarballed patchsets"
		else
			extension=${i/*./}
			extension=${extension/:*/}
			PIPE_CMD=""
			case ${extension} in
				     xz) PIPE_CMD="xz -T$(makeopts_jobs) -dc";;
				   lzma) PIPE_CMD="lzma -dc";;
				    bz2) PIPE_CMD="bzip2 -dc";;
				 patch*) PIPE_CMD="cat";;
				   diff) PIPE_CMD="cat";;
				 gz|Z|z) PIPE_CMD="gzip -dc";;
				ZIP|zip) PIPE_CMD="unzip -p";;
				      *) UNIPATCH_DROP="${UNIPATCH_DROP} ${i/:*/}";;
			esac

			PATCH_LEVEL=${i/*([^:])?(:)}
			i=${i/:*/}
			x=${i/*\//}
			x=${x/\.${extension}/}

			if [[ -n ${PIPE_CMD} ]]; then
				if [[ ! -r ${i} ]]; then
					eerror "FATAL: unable to locate:"
					eerror "${i}"
					eerror "for read-only. The file either has incorrect permissions"
					eerror "or does not exist."
					die Unable to locate ${i}
				fi

				if [[ -n ${UNIPATCH_STRICTORDER} ]]; then
					unset z
					STRICT_COUNT=$((10#${STRICT_COUNT:=0} + 1))
					for((y=0; y<$((6 - ${#STRICT_COUNT})); y++));
						do z="${z}0";
					done
					PATCH_ORDER="${z}${STRICT_COUNT}"

					mkdir -p ${KPATCH_DIR}/${PATCH_ORDER}/
					$(${PIPE_CMD} ${i} > ${KPATCH_DIR}/${PATCH_ORDER}/${x}.patch${PATCH_LEVEL}) || die "uncompressing patch failed"
				else
					$(${PIPE_CMD} ${i} > ${KPATCH_DIR}/${x}.patch${PATCH_LEVEL}) || die "uncompressing patch failed"
				fi
			fi
		fi

		# If experimental was not chosen by the user, drop experimental patches not in K_EXP_GENPATCHES_LIST.
		if [[ ${i} == *genpatches-*.experimental.* && -n ${K_EXP_GENPATCHES_PULL} ]]; then
			if [[ -z ${K_EXP_GENPATCHES_NOUSE} ]] && use experimental; then
				continue
			fi

			local j
			for j in ${KPATCH_DIR}/*/50*_*.patch*; do
				for k in ${K_EXP_GENPATCHES_LIST} ; do
					[[ $(basename ${j}) == ${k}* ]] && continue 2
				done
				UNIPATCH_DROP+=" $(basename ${j})"
			done
		else
			UNIPATCH_LIST_GENPATCHES+=" ${DISTDIR}/${tarball}"
			debug-print "genpatches tarball: ${tarball}"

			local GCC_MAJOR_VER=$(gcc-major-version)
			local GCC_MINOR_VER=$(gcc-minor-version)

			# this section should be the target state to handle the cpu opt
			# patch for kernels > 4.19.189, 5.4.115, 5.10.33 and 5.11.17,
			# 5.12.0 and gcc >= 9  The patch now handles the
			# gcc version enabled on the system through the Kconfig file as
			# 'depends'. The legacy section can hopefully be retired in the future
			# Note the patch for 4.19-5.8 version are the same and the patch for
			# 5.8+ version is the same
			# eventually we can remove everything except the gcc ver <9 check
			# based on stablization, time, kernel removals or a combo of all three
			if ( kernel_is eq 4 19 && kernel_is gt 4 19 189 ) ||
				( kernel_is eq 5 4 && kernel_is gt 5 4 115 ) ||
				( kernel_is eq 5 10 && kernel_is gt 5 10 33 ) ||
				( kernel_is eq 5 11 && kernel_is gt 5 11 17 ) ||
				( kernel_is eq 5 12 && kernel_is gt 5 12 0 ) ||
				( kernel_is ge 5 13); then
				UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc.patch"
				UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
				UNIPATCH_DROP+=" 5011_enable-cpu-optimizations-for-gcc8.patch"
				UNIPATCH_DROP+=" 5012_enable-cpu-optimizations-for-gcc91.patch"
				UNIPATCH_DROP+=" 5013_enable-cpu-optimizations-for-gcc10.patch"
				if [[ ${GCC_MAJOR_VER} -lt 9 ]] && ! tc-is-clang; then
					UNIPATCH_DROP+=" 5010_enable-cpu-optimizations-universal.patch"
				fi
				# this legacy section should be targeted for removal
				# optimization patch for gcc < 8.X and kernel > 4.13 and <  4.19
			elif kernel_is ge 4 13; then
				UNIPATCH_DROP+=" 5010_enable-cpu-optimizations-universal.patch"
				if [[ ${GCC_MAJOR_VER} -lt 8 && ${GCC_MAJOR_VER} -gt 4 ]]; then
					UNIPATCH_DROP+=" 5011_enable-cpu-optimizations-for-gcc8.patch"
					UNIPATCH_DROP+=" 5012_enable-cpu-optimizations-for-gcc91.patch"
					UNIPATCH_DROP+=" 5013_enable-cpu-optimizations-for-gcc10.patch"
				# optimization patch for gcc >= 8 and kernel ge 4.13
				elif [[ ${GCC_MAJOR_VER} -eq 8 ]]; then
					# support old kernels for a period. For now, remove as all gcc versions required are masked
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc.patch"
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
					UNIPATCH_DROP+=" 5012_enable-cpu-optimizations-for-gcc91.patch"
					UNIPATCH_DROP+=" 5013_enable-cpu-optimizations-for-gcc10.patch"
				elif [[ ${GCC_MAJOR_VER} -eq 9 && ${GCC_MINOR_VER} -ge 1 ]]; then
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc.patch"
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
					UNIPATCH_DROP+=" 5011_enable-cpu-optimizations-for-gcc8.patch"
					UNIPATCH_DROP+=" 5013_enable-cpu-optimizations-for-gcc10.patch"
				elif [[ ${GCC_MAJOR_VER} -eq 10 && ${GCC_MINOR_VER} -ge 1 ]]; then
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc.patch"
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
					UNIPATCH_DROP+=" 5011_enable-cpu-optimizations-for-gcc8.patch"
					UNIPATCH_DROP+=" 5012_enable-cpu-optimizations-for-gcc91.patch"
				else
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc.patch"
					UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
					UNIPATCH_DROP+=" 5011_enable-cpu-optimizations-for-gcc8.patch"
					UNIPATCH_DROP+=" 5012_enable-cpu-optimizations-for-gcc91.patch"
					UNIPATCH_DROP+=" 5013_enable-cpu-optimizations-for-gcc10.patch"
				fi
			else
				UNIPATCH_DROP+=" 5010_enable-cpu-optimizations-universal.patch"
				UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc.patch"
				UNIPATCH_DROP+=" 5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
				UNIPATCH_DROP+=" 5011_enable-cpu-optimizations-for-gcc8.patch"
				UNIPATCH_DROP+=" 5012_enable-cpu-optimizations-for-gcc91.patch"
				UNIPATCH_DROP+=" 5013_enable-cpu-optimizations-for-gcc10.patch"
			fi
		fi
	done

	# Populate KPATCH_DIRS so we know where to look to remove the excludes
	x=${KPATCH_DIR}
	KPATCH_DIR=""
	for i in $(find ${x} -type d | sort -n); do
		KPATCH_DIR="${KPATCH_DIR} ${i}"
	done

	# So now lets get rid of the patch numbers we want to exclude
	UNIPATCH_DROP="${UNIPATCH_EXCLUDE} ${UNIPATCH_DROP}"
	for i in ${UNIPATCH_DROP}; do
		ebegin "Excluding Patch #${i}"
		for x in ${KPATCH_DIR}; do rm -f ${x}/${i}* 2>/dev/null; done
		eend $?
	done

	# and now, finally, we patch it :)
	for x in ${KPATCH_DIR}; do
		for i in $(find ${x} -maxdepth 1 -iname "*.patch*" -or -iname "*.diff*" | sort -n); do
			STDERR_T="${T}/${i/*\//}"
			STDERR_T="${STDERR_T/.patch*/.err}"

			[[ -z ${i/*.patch*/} ]] && PATCH_DEPTH=${i/*.patch/}
			#[[ -z ${i/*.diff*/} ]]  && PATCH_DEPTH=${i/*.diff/}

			if [[ -z ${PATCH_DEPTH} ]]; then PATCH_DEPTH=0; fi

			####################################################################
			# IMPORTANT: This code is to support kernels which cannot be       #
			# tested with the --dry-run parameter                              #
			#                                                                  #
			# These patches contain a removal of a symlink, followed by        #
			# addition of a file with the same name as the symlink in the      #
			# same location; this causes the dry-run to fail, see bug #507656. #
			#                                                                  #
			# https://bugs.gentoo.org/507656                                   #
			####################################################################
			if [[ -n ${K_NODRYRUN} ]]; then
				ebegin "Applying ${i/*\//} (-p1)"
				patch -p1 --no-backup-if-mismatch -f < ${i} >> ${STDERR_T}
				if [[ $? -le 2 ]]; then
					eend 0
					rm ${STDERR_T} || die
				else
					eend 1
					eerror "Failed to apply patch ${i/*\//}"
					eerror "Please attach ${STDERR_T} to any bug you may post."
					eshopts_pop
					die "Failed to apply ${i/*\//} on patch depth 1."
				fi
			fi
			####################################################################

			while [[ ${PATCH_DEPTH} -lt 5 && -z ${K_NODRYRUN} ]]; do
				echo "Attempting Dry-run:" >> ${STDERR_T}
				echo "cmd: patch -p${PATCH_DEPTH} --no-backup-if-mismatch --dry-run -f < ${i}" >> ${STDERR_T}
				echo "=======================================================" >> ${STDERR_T}
				patch -p${PATCH_DEPTH} --no-backup-if-mismatch --dry-run -f < ${i} >> ${STDERR_T}
				if [[ $? -eq 0 ]]; then
					ebegin "Applying ${i/*\//} (-p${PATCH_DEPTH})"
					echo "Attempting patch:" > ${STDERR_T}
					echo "cmd: patch -p${PATCH_DEPTH} --no-backup-if-mismatch -f < ${i}" >> ${STDERR_T}
					echo "=======================================================" >> ${STDERR_T}
					patch -p${PATCH_DEPTH} --no-backup-if-mismatch -f < ${i} >> ${STDERR_T}
					if [[ $? -eq 0 ]]; then
						eend 0
						rm ${STDERR_T} || die
						break
					else
						eend 1
						eerror "Failed to apply patch ${i/*\//}"
						eerror "Please attach ${STDERR_T} to any bug you may post."
						eshopts_pop
						die "Failed to apply ${i/*\//} on patch depth ${PATCH_DEPTH}."
					fi
				else
					PATCH_DEPTH=$((${PATCH_DEPTH} + 1))
				fi
			done
			if [[ ${PATCH_DEPTH} -eq 5 ]]; then
				eerror "Failed to dry-run patch ${i/*\//}"
				eerror "Please attach ${STDERR_T} to any bug you may post."
				eshopts_pop
				die "Unable to dry-run patch on any patch depth lower than 5."
			fi
		done
	done

	# When genpatches is used, we want to install 0000_README which documents
	# the patches that were used; such that the user can see them, bug #301478.
	if [[ ! -z ${K_WANT_GENPATCHES} ]]; then
		UNIPATCH_DOCS="${UNIPATCH_DOCS} 0000_README"
	fi

	# When files listed in UNIPATCH_DOCS are found in KPATCH_DIR's, we copy it
	# to the temporary directory and remember them in UNIPATCH_DOCS to install
	# them during the install phase.
	local tmp
	for x in ${KPATCH_DIR}; do
		for i in ${UNIPATCH_DOCS}; do
			if [[ -f ${x}/${i} ]]; then
				tmp="${tmp} ${i}"
				cp -f "${x}/${i}" "${T}"/ || die
			fi
		done
	done
	UNIPATCH_DOCS="${tmp}"

	# clean up  KPATCH_DIR's - fixes bug #53610
	for x in ${KPATCH_DIR}; do rm -Rf ${x}; done

	LC_ALL="${myLC_ALL}"
	LANG="${myLANG}"
	eshopts_pop
}

# @FUNCTION: getfilevar
# @USAGE: <variable> <configfile>
# @DESCRIPTION:
# pulled from linux-info

getfilevar() {
	local basefname basedname xarch=$(tc-arch-kernel)

	if [[ -z ${1} && ! -f ${2} ]]; then
		eerror "getfilevar requires 2 variables, with the second a valid file."
		eerror "   getfilevar <VARIABLE> <CONFIGFILE>"
	else
		basefname=$(basename ${2})
		basedname=$(dirname ${2})
		unset ARCH

		echo -e "include ${basefname}\ne:\n\t@echo \$(${1})" |
			make -C "${basedname}" -s -f - e 2>/dev/null

		ARCH=${xarch}
	fi
}

# @FUNCTION: detect_arch
# @USAGE:
# @DESCRIPTION:
# This function sets ARCH_URI and ARCH_PATCH
# with the necessary info for the arch specific compatibility
# patchsets.

detect_arch() {
	local ALL_ARCH LOOP_ARCH LOOP_ARCH_L COMPAT_URI i TC_ARCH_KERNEL

	# COMPAT_URI is the contents of ${ARCH}_URI
	# ARCH_URI is the URI for all the ${ARCH}_URI patches
	# ARCH_PATCH is ARCH_URI broken into files for UNIPATCH

	ARCH_URI=""
	ARCH_PATCH=""
	TC_ARCH_KERNEL=""
	ALL_ARCH="ALPHA AMD64 ARM HPPA IA64 M68K MIPS PPC PPC64 S390 SH SPARC X86"

	for LOOP_ARCH in ${ALL_ARCH}; do
		COMPAT_URI="${LOOP_ARCH}_URI"
		COMPAT_URI="${!COMPAT_URI}"

		declare -l LOOP_ARCH_L=${LOOP_ARCH}

		[[ -n ${COMPAT_URI} ]] && \
			ARCH_URI="${ARCH_URI} ${LOOP_ARCH_L}? ( ${COMPAT_URI} )"

		declare -u TC_ARCH_KERNEL=$(tc-arch-kernel)
		if [[ ${LOOP_ARCH} == ${TC_ARCH_KERNEL} ]]; then
			for i in ${COMPAT_URI}; do
				ARCH_PATCH="${ARCH_PATCH} ${DISTDIR}/${i/*\//}"
			done
		fi

	done
}

# @FUNCTION: headers___fix
# @USAGE:
# @DESCRIPTION:
# Voodoo to partially fix broken upstream headers.
# note: do not put inline/asm/volatile together (breaks "inline asm volatile")

headers___fix() {
	sed -i \
		-e '/^\#define.*_TYPES_H/{:loop n; bloop}' \
		-e 's:\<\([us]\(8\|16\|32\|64\)\)\>:__\1:g' \
		-e "s/\([[:space:]]\)inline\([[:space:](]\)/\1__inline__\2/g" \
		-e "s/\([[:space:]]\)asm\([[:space:](]\)/\1__asm__\2/g" \
		-e "s/\([[:space:]]\)volatile\([[:space:](]\)/\1__volatile__\2/g" \
		"$@"
}

# @FUNCTION: kernel-2_src_unpack
# @USAGE:
# @DESCRIPTION:
# unpack sources, handle genpatches, deblob

kernel-2_src_unpack() {
	universal_unpack
	debug-print "Doing unipatch"

	# request UNIPATCH_LIST_GENPATCHES in phase since it calls 'use'
	handle_genpatches --set-unipatch-list
	[[ -n ${UNIPATCH_LIST} || -n ${UNIPATCH_LIST_DEFAULT} || -n ${UNIPATCH_LIST_GENPATCHES} ]] && \
		unipatch "${UNIPATCH_LIST_DEFAULT} ${UNIPATCH_LIST_GENPATCHES} ${UNIPATCH_LIST}"

	debug-print "Doing premake"

	# allow ebuilds to massage the source tree after patching but before
	# we run misc `make` functions below
	if [[ $(type -t kernel-2_hook_premake) == "function" ]]; then
		ewarn "The function name: kernel-2_hook_premake is being deprecated and"
		ewarn "being changed to:  kernel-2_insert_premake to comply with pms policy."
		ewarn "See bug #843686 "
		ewarn "The call to the old function name will be removed on or about July 1st, 2022 "
		ewarn "Please update your ebuild before this date."
		kernel-2_hook_premake
	else
		[[ $(type -t kernel-2_insert_premake) == "function" ]] && kernel-2_insert_premake
	fi

	debug-print "Doing unpack_set_extraversion"

	[[ -z ${K_NOSETEXTRAVERSION} ]] && unpack_set_extraversion
	unpack_fix_install_path

	# Setup KERNEL_MAKEOPTS and cd into sourcetree.
	env_setup_kernel_makeopts
	cd "${S}" || die

	if [[ ${K_DEBLOB_AVAILABLE} == 1 ]] && use deblob; then
		cp "${DISTDIR}/${DEBLOB_A}" "${T}" || die "cp ${DEBLOB_A} failed"
		cp "${DISTDIR}/${DEBLOB_CHECK_A}" "${T}/deblob-check" || die "cp ${DEBLOB_CHECK_A} failed"
		chmod +x "${T}/${DEBLOB_A}" "${T}/deblob-check" || die "chmod deblob scripts failed"
	fi

	# fix a problem on ppc where TOUT writes to /usr/src/linux breaking sandbox
	# only do this for kernel < 2.6.27 since this file does not exist in later
	# kernels
	if [[ -n ${KV_MINOR} ]] && ver_test ${KV_MAJOR}.${KV_MINOR}.${KV_PATCH} -lt 2.6.27; then
		sed -i \
			-e 's|TOUT      := .tmp_gas_check|TOUT  := $(T).tmp_gas_check|' \
			"${S}"/arch/ppc/Makefile
	else
		sed -i \
			-e 's|TOUT      := .tmp_gas_check|TOUT  := $(T).tmp_gas_check|' \
			"${S}"/arch/powerpc/Makefile
	fi
}

# @FUNCTION: kernel-2_src_prepare
# @USAGE:
# @DESCRIPTION:
# Apply any user patches

kernel-2_src_prepare() {
	debug-print "Applying any user patches"
	eapply_user
}

# @FUNCTION: kernel-2_src_compile
# @USAGE:
# @DESCRIPTION:
# conpile headers or run deblob script

kernel-2_src_compile() {
	cd "${S}" || die

	if [[ ${K_DEBLOB_AVAILABLE} == 1 ]] && use deblob; then
		einfo ">>> Patching deblob script for forcing awk ..."
		sed -i '/check="\/bin\/sh $check"/a \  check="$check --use-awk"' \
			"${T}/${DEBLOB_A}" || die "Failed to patch ${DEBLOB_A}"
		einfo ">>> Running deblob script ..."
		sh "${T}/${DEBLOB_A}" --force || die "Deblob script failed to run!!!"
	fi
}

# @FUNCTION: kernel-2_src_test
# @USAGE:
# @DESCRIPTION:
# if you leave it to the default src_test, it will run make to
# find whether test/check targets are present; since "make test"
# actually produces a few support files, they are installed even
# though the package is binchecks-restricted.
#
# Avoid this altogether by making the function moot.
kernel-2_src_test() { :; }

# @FUNCTION: kernel-2_pkg_preinst
# @DESCRIPTION:
# if ETYPE = headers, call preinst_headers

kernel-2_pkg_preinst() {
	[[ ${ETYPE} == headers ]] && preinst_headers
}

# @FUNCTION: kernel-2_src_install
# @USAGE:
# @DESCRIPTION:
# Install headers or sources dependent on ETYPE

kernel-2_src_install() {
	install_universal
	[[ ${ETYPE} == headers ]] && install_headers
	[[ ${ETYPE} == sources ]] && install_sources
}

# @FUNCTION: kernel-2_pkg_postinst
# @USAGE:
# @DESCRIPTION:
# call postinst_sources for ETYPE = sources

kernel-2_pkg_postinst() {
	[[ ${ETYPE} == sources ]] && postinst_sources
}

# @FUNCTION: kernel-2_pkg_setup
# @USAGE:
# @DESCRIPTION:
# check for supported kernel version, die if ETYPE is unknown, call setup_headers
# if necessary

kernel-2_pkg_setup() {
	if [[ "${CATEGORY}" == 'sys-kernel' ]]; then
		ABI="${KERNEL_ABI}"
	fi
	if [[ ${ETYPE} != sources && ${ETYPE} != headers ]]; then
		eerror "Unknown ETYPE=\"${ETYPE}\", must be \"sources\" or \"headers\""
		die "Unknown ETYPE=\"${ETYPE}\", must be \"sources\" or \"headers\""
	fi

	[[ ${ETYPE} == headers ]] && setup_headers
	[[ ${ETYPE} == sources ]] && einfo ">>> Preparing to unpack ..."
}

# @FUNCTION: kernel-2_pkg_postrm
# @USAGE:
# @DESCRIPTION:
# Notify the user that after a depclean, there may be sources
# left behind that need to be manually cleaned

kernel-2_pkg_postrm() {
	# This warning only makes sense for kernel sources.
	[[ ${ETYPE} == headers ]] && return 0

	# If there isn't anything left behind, then don't complain.
	[[ -e ${EROOT}/usr/src/linux-${KV_FULL} ]] || return 0
	ewarn "Note: Even though you have successfully unmerged "
	ewarn "your kernel package, directories in kernel source location: "
	ewarn "${EROOT}/usr/src/linux-${KV_FULL}"
	ewarn "with modified files will remain behind. By design, package managers"
	ewarn "will not remove these modified files and the directories they reside in."
	ewarn "For more detailed kernel removal instructions, please see: "
	ewarn "https://wiki.gentoo.org/wiki/Kernel/Removal"
}

EXPORT_FUNCTIONS src_{unpack,prepare,compile,install,test} \
	pkg_{setup,preinst,postinst,postrm}
