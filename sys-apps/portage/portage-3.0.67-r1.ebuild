# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( pypy3_11 python3_{11..13} )
PYTHON_REQ_USE='bzip2(+),threads(+)'
TMPFILES_OPTIONAL=1

inherit linux-info meson python-r1 tmpfiles

DESCRIPTION="The package management and distribution system for Gentoo"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:Portage"

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="
		https://anongit.gentoo.org/git/proj/portage.git
		https://github.com/gentoo/portage.git
	"
	inherit git-r3
else
	SRC_URI="https://gitweb.gentoo.org/proj/portage.git/snapshot/${P}.tar.bz2"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
fi

LICENSE="GPL-2"
SLOT="0"
# 'dedupdebug' and 'installsources' are optional portage FEATURES with
# additional dependencies...
IUSE="apidoc build dedupdebug doc gentoo-dev installsources +ipc +native-extensions +rsync-verify selinux test +trust-helper xattr"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="!test? ( test )"

BDEPEND="
	${PYTHON_DEPS}
	>=app-arch/tar-1.27
	>=dev-build/meson-1.3.0-r1
	>=sys-apps/sed-4.0.5
	sys-devel/patch
	!build? ( $(python_gen_impl_dep 'ssl(+)') )
	apidoc? (
		dev-python/sphinx[${PYTHON_USEDEP}]
		dev-python/sphinx-epytext[${PYTHON_USEDEP}]
	)
	dedupdebug? (
		sys-devel/dwz
	)
	doc? (
		~app-text/docbook-xml-dtd-4.4
		app-text/xmlto
	)
	installsources? (
		dev-util/debugedit
	)
	test? (
		dev-python/pytest-xdist[${PYTHON_USEDEP}]
		dev-vcs/git
	)
"
# Require sandbox-2.2 for bug #288863.
# For whirlpool hash, require python[ssl] (bug #425046).
RDEPEND="
	${PYTHON_DEPS}
	acct-user/portage
	>=app-arch/tar-1.27
	app-arch/zstd
	>=app-misc/pax-utils-0.1.17
	dev-lang/python-exec:2
	>=sys-apps/baselayout-2.9
	>=sys-apps/findutils-4.9
	!build? (
		>=app-admin/eselect-1.2
		trust-helper? ( app-portage/getuto )
		>=app-shells/bash-5.0:0
		>=sec-keys/openpgp-keys-gentoo-release-20240703
		>=sys-apps/sed-4.0.5
		rsync-verify? (
			>=app-crypt/gnupg-2.2.4-r2[ssl(-)]
			>=app-portage/gemato-14.5[${PYTHON_USEDEP}]
		)
	)
	elibc_glibc? ( >=sys-apps/sandbox-2.2 )
	elibc_musl? ( >=sys-apps/sandbox-2.2 )
	kernel_linux? ( sys-apps/util-linux )
	selinux? ( >=sys-libs/libselinux-2.0.94[python,${PYTHON_USEDEP}] )
	xattr? ( kernel_linux? (
		>=sys-apps/install-xattr-0.3
	) )
"
# coreutils-6.4 rdep is for date format in emerge-webrsync #164532
# NOTE: FEATURES=installsources requires debugedit and rsync
PDEPEND="
	!build? (
		>=net-misc/rsync-2.6.4
		>=sys-apps/coreutils-6.4
		>=sys-apps/file-5.44-r3
	)
"

PATCHES=(
	"${FILESDIR}/${PN}-3.0.67-nicer-depend-phase-output.patch"

	# Unclear whether these (AI-generated) patches are working at all :(
	"${FILESDIR}/${PN}-3.0.67-show-binpkg-size.patch"
	#"${FILESDIR}/${PN}-3.0.67-relaxed-deps.patch"
)

pkg_pretend() {
	local CONFIG_CHECK="~IPC_NS ~PID_NS ~NET_NS ~UTS_NS"

	check_extra_config
}

src_prepare() {
	default

	if use prefix-guest; then
		sed -e "s|^\(main-repo = \).*|\\1gentoo_prefix|" \
			-e "s|^\\[gentoo\\]|[gentoo_prefix]|" \
			-e "s|^\(sync-uri = \).*|\\1rsync://rsync.prefix.bitzolder.nl/gentoo-portage-prefix|" \
			-i cnf/repos.conf || die "sed failed"
	fi
}

src_configure() {
	local code_only=false
	python_foreach_impl my_src_configure
}

my_src_configure() {
	local emesonargs=(
		-Dcode-only=${code_only}
		-Deprefix="${EPREFIX}"
		-Dportage-bindir="${EPREFIX}/usr/lib/portage/${EPYTHON}"
		-Ddocdir="${EPREFIX}/usr/share/doc/${PF}"
		$(meson_use doc)
		$(meson_use apidoc)
		$(meson_use gentoo-dev)
		$(meson_use ipc)
		$(meson_use xattr)
	)

	if use native-extensions && [[ "${EPYTHON}" != "pypy3"* ]] ; then
		emesonargs+=( -Dnative-extensions=true )
	else
		emesonargs+=( -Dnative-extensions=false )
	fi

	if use build; then
		emesonargs+=( -Drsync-verify=false )
	else
		emesonargs+=( $(meson_use rsync-verify) )
	fi

	meson_src_configure
	code_only=true
}

src_compile() {
	python_foreach_impl meson_src_compile
}

src_test() {
	local EPYTEST_XDIST=1
	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
	python_foreach_impl epytest
}

src_install() {
	python_foreach_impl my_src_install
	dotmpfiles "${FILESDIR}"/portage-{ccache,tmpdir}.conf

	local scripts
	mapfile -t scripts < <(awk '/^#!.*python/ {print FILENAME} {nextfile}' "${ED}"/usr/{bin,sbin}/* || die)
	python_replicate_script "${scripts[@]}"
}

my_src_install() {
	local pydirs=(
		"${D}$(python_get_sitedir)"
		"${ED}/usr/lib/portage/${EPYTHON}"
	)

	meson_src_install
	python_fix_shebang "${pydirs[@]}"
	python_optimize "${pydirs[@]}"
}

pkg_preinst() {
	if ! use build && [[ -z ${ROOT} ]]; then
		python_setup
		local sitedir=$(python_get_sitedir)
		[[ -d ${D}${sitedir} ]] || die "${D}${sitedir}: No such directory"
		env -u DISTDIR \
			-u PORTAGE_OVERRIDE_EPREFIX \
			-u PORTAGE_REPOSITORIES \
			-u PORTDIR \
			-u PORTDIR_OVERLAY \
			PYTHONPATH="${D}${sitedir}${PYTHONPATH:+:${PYTHONPATH}}" \
			ED="${ED}" \
			"${PYTHON}" -m portage._compat_upgrade.default_locations || die

		env -u BINPKG_COMPRESS -u PORTAGE_REPOSITORIES \
			PYTHONPATH="${D}${sitedir}${PYTHONPATH:+:${PYTHONPATH}}" \
			ED="${ED}" \
			"${PYTHON}" -m portage._compat_upgrade.binpkg_compression || die

		env -u FEATURES -u PORTAGE_REPOSITORIES \
			PYTHONPATH="${D}${sitedir}${PYTHONPATH:+:${PYTHONPATH}}" \
			ED="${ED}" \
			"${PYTHON}" -m portage._compat_upgrade.binpkg_multi_instance || die

		env -u BINPKG_FORMAT \
			PYTHONPATH="${D}${sitedir}${PYTHONPATH:+:${PYTHONPATH}}" \
			ED="${ED}" \
			"${PYTHON}" -m portage._compat_upgrade.binpkg_format || die
	fi

	# elog dir must exist to avoid logrotate error for bug #415911.
	# This code runs in preinst in order to bypass the mapping of
	# portage:portage to root:root which happens after src_install.
	keepdir /var/log/portage/elog
	# This is allowed to fail if the user/group are invalid for prefix users.
	if chown portage:portage "${ED}"/var/log/portage{,/elog} 2>/dev/null ; then
		chmod g+s,ug+rwx "${ED}"/var/log/portage{,/elog}
	fi

	if has_version "<${CATEGORY}/${PN}-2.3.77"; then
		elog "The emerge --autounmask option is now disabled by default, except for"
		elog "portions of behavior which are controlled by the --autounmask-use and"
		elog "--autounmask-license options. For backward compatibility, previous"
		elog "behavior of --autounmask=y and --autounmask=n is entirely preserved."
		elog "Users can get the old behavior simply by adding --autounmask to the"
		elog "make.conf EMERGE_DEFAULT_OPTS variable. For the rationale for this"
		elog "change, see https://bugs.gentoo.org/658648."
	fi
}

pkg_postinst() {
	# Warn about obsolete "enotice" script, bug #867010
	local bashrc=${EROOT}/etc/portage/profile/profile.bashrc
	if [[ -e ${bashrc} ]] && grep -q enotice "${bashrc}"; then
		eerror "Obsolete 'enotice' script detected!"
		eerror "Please remove this from ${bashrc} to avoid problems."
		eerror "See bug 867010 for more details."
	fi

	if ! use trust-helper; then
		ewarn "The 'trust-helper' USE-flag has not been set, and therefore you must"
		ewarn "add the following to '/etc/portage/make.conf':"
		ewarn
		ewarn "  PORTAGE_TRUST_HELPER=true"
		ewarn
		ewarn "... if ever using the --getbinpkg or --getbinpkgonly portage options"
	fi
}
