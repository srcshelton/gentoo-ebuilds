# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="Linux-${PN^^}-${PV}"

# Avoid QA warnings
# Can reconsider w/ EAPI 8 and IDEPEND, bug #810979
TMPFILES_OPTIONAL=1

inherit db-use fcaps flag-o-matic meson-multilib toolchain-funcs usr-ldscript

DESCRIPTION="Linux-PAM (Pluggable Authentication Modules)"
HOMEPAGE="https://github.com/linux-pam/linux-pam"

if [[ ${PV} == *_p* ]] ; then
	PAM_COMMIT="e634a3a9be9484ada6e93970dfaf0f055ca17332"
	SRC_URI="
		https://github.com/linux-pam/linux-pam/archive/${PAM_COMMIT}.tar.gz -> ${P}.gh.tar.gz
	"
	S="${WORKDIR}/linux-${PN}-${PAM_COMMIT}"
else
	VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/strace.asc
	inherit verify-sig

	SRC_URI="
		https://github.com/linux-pam/linux-pam/releases/download/v${PV}/${MY_P}.tar.xz
		verify-sig? ( https://github.com/linux-pam/linux-pam/releases/download/v${PV}/${MY_P}.tar.xz.asc )
	"
	S="${WORKDIR}/${MY_P}"

	BDEPEND="verify-sig? ( sec-keys/openpgp-keys-strace )"
fi

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux"
# Avoid pam[systemd] -> systemd -> pam circular dependency...
IUSE="audit berkdb debug elogind examples nis nls pam-systemd selinux +tmpfiles"
REQUIRED_USE="?? ( elogind pam-systemd )"

# meson.build specifically checks for bison and then byacc
# also requires xsltproc
#
# Something appears to be (more) broken in sys-apps/portage-3.0.67 - as with
# util-linux-2.40.2, the *DEPENDS dependencies from inherited classes are being
# ignored, leading to build failures :(
#
# Manually adding 'dev-build/ninja' to work-around this...
#
BDEPEND+="
	>=dev-build/ninja-1.8.2

	|| ( sys-devel/bison dev-util/byacc )
	app-text/docbook-xsl-ns-stylesheets
	dev-libs/libxslt
	sys-devel/flex
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"
DEPEND="
	virtual/libcrypt:=[${MULTILIB_USEDEP}]
	>=virtual/libintl-0-r1[${MULTILIB_USEDEP}]
	audit? ( >=sys-process/audit-2.2.2[${MULTILIB_USEDEP}] )
	berkdb? ( >=sys-libs/db-4.8.30-r1:=[${MULTILIB_USEDEP}] )
	!berkdb? ( sys-libs/gdbm:=[${MULTILIB_USEDEP}] )
	elogind? ( >=sys-auth/elogind-254 )
	selinux? ( >=sys-libs/libselinux-2.2.2-r4[${MULTILIB_USEDEP}] )
	pam-systemd? ( >=sys-apps/systemd-254:= )
	nis? (
		net-libs/libnsl:=[${MULTILIB_USEDEP}]
		>=net-libs/libtirpc-0.2.4-r2:=[${MULTILIB_USEDEP}]
	)
"
RDEPEND="${DEPEND}"
PDEPEND=">=sys-auth/pambase-20200616"

QA_XLINK_ALLOWED=(
	lib64/security/pam_userdb.so
	libx32/security/pam_userdb.so
	lib32/security/pam_userdb.so
	lib/security/pam_userdb.so
)

src_configure() {
	# meson.build sets -Wl,--fatal-warnings and with e.g. mold, we get:
	#  cannot assign version `global` to symbol `pam_sm_open_session`: symbol not found
	append-ldflags $(test-flags-CCLD -Wl,--undefined-version)

	# Do not let user's BROWSER setting mess us up, bug #549684
	unset BROWSER

	meson-multilib_src_configure
}

multilib_src_configure() {
	local machine_file="${T}/meson.${CHOST}.${ABI}.ini.local"
	# Workaround for docbook5 not being packaged (bug #913087#c4)
	# It's only used for validation of output, so stub it out.
	# Also, stub out elinks+w3m which are only used for an index.
	cat >> "${machine_file}" <<-EOF || die
		[binaries]
		xmlcatalog='true'
		xmllint='true'
		elinks='true'
		w3m='true'
	EOF

	local emesonargs=()

	if tc-is-cross-compiler; then
		emesonargs+=( --cross-file "${machine_file}" )
	else
		emesonargs+=( --native-file "${machine_file}" )
	fi

	emesonargs+=(
		$(meson_feature audit)
		$(meson_native_use_bool examples)
		$(meson_use debug pam-debug)
		$(meson_feature nis)
		$(meson_feature nls i18n)
		$(meson_feature selinux)

		-Disadir='.'
		-Dxml-catalog="${BROOT}"/etc/xml/catalog
		-Dsbindir="${EPREFIX}"/sbin
		-Dsecuredir="${EPREFIX}"/$(get_libdir)/security
		-Ddocdir="${EPREFIX}"/usr/share/doc/${PF}
		-Dhtmldir="${EPREFIX}"/usr/share/doc/${PF}/html
		-Dpdfdir="${EPREFIX}"/usr/share/doc/${PF}/pdf

		$(meson_native_enabled docs)

		-Dpam_unix=enabled

		# TODO: wire this up now it's more useful as of 1.5.3 (bug #931117)
		-Deconf=disabled

		# TODO: lastlog is enabled again for now by us as elogind support
		# wasn't available at first. Even then, disabling lastlog will
		# probably need a news item.
		$(meson_native_use_feature pam-systemd logind)
		$(meson_native_use_feature elogind)
		$(meson_feature !elibc_musl pam_lastlog)
	)

	if use berkdb; then
		local dbver
		dbver="$(db_findver sys-libs/db)" ||
			die "could not find db version"
		local -x CPPFLAGS="${CPPFLAGS} -I$(db_includedir "${dbver}")"
		emesonargs+=(
			-Ddb=db
			-Ddb-uniquename="-${dbver}"
		)
	else
		emesonargs+=(
			-Ddb=gdbm
		)
	fi

	meson_src_configure
}

multilib_src_install() {
	meson_install "${_meson_args[@]}"

	if use split-usr; then
		ebegin "Relocating libraries 'pam', 'pam_misc', and 'pamc' to root filesystem"
		gen_usr_ldscript -a pam pam_misc pamc
		eend ${?} "gen_usr_ldscript() failed: ${?}" || die
		#ls -l "${ED}/$(get_libdir)/"
		#ls -l "${ED}/usr/$(get_libdir)/"
	fi
}

multilib_src_install_all() {
	find "${ED}" -type f -name '*.la' -delete || die

	# tmpfiles.eclass is impossible to use because
	# there is the pam -> tmpfiles -> systemd -> pam dependency loop
	if use tmpfiles; then
		dodir /usr/lib/tmpfiles.d

		cat ->> "${ED}"/usr/lib/tmpfiles.d/${CATEGORY}-${PN}.conf <<-_EOF_
			d /var/run/faillock 0755 root root
		_EOF_
		use selinux && cat ->> "${ED}"/usr/lib/tmpfiles.d/${CATEGORY}-${PN}-selinux.conf <<-_EOF_
			d /var/run/sepermit 0755 root root
		_EOF_
	fi
}

pkg_postinst() {
	ewarn "Some software with pre-loaded PAM libraries might experience"
	ewarn "warnings or failures related to missing symbols and/or versions"
	ewarn "after any update. While unfortunate this is a limit of the"
	ewarn "implementation of PAM and the software, and it requires you to"
	ewarn "restart the software manually after the update."
	ewarn
	ewarn "You can get a list of such software running a command such as:"
	ewarn "  lsof / | grep -E -i 'del.*libpam\\.so'"
	ewarn
	ewarn "Alternatively, simply reboot your system."

	if use split-usr && use berkdb; then
		ewarn
		ewarn "PAM rules which make use of 'pam_userdb.so' may fail until the"
		ewarn "/usr filesystem is mounted, as /lib64/security/pam_userdb.so"
		ewarn "links to /usr/lib64/libdb-5.2.so, which cannot be relocated"
		ewarn "without causing constant preserved-library warnings."
	fi

	# The pam_unix module needs to check the password of the user which requires
	# read access to /etc/shadow only.
	fcaps -m u+s cap_dac_override sbin/unix_chkpwd
}

# vi: set diffopt=filler,iwhite:
