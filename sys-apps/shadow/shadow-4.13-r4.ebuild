# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/sergehallyn.asc
inherit libtool pam usr-ldscript verify-sig

DESCRIPTION="Utilities to deal with user accounts"
HOMEPAGE="https://github.com/shadow-maint/shadow"
SRC_URI="https://github.com/shadow-maint/shadow/releases/download/${PV}/${P}.tar.xz
	verify-sig? ( https://github.com/shadow-maint/shadow/releases/download/${PV}/${P}.tar.xz.asc )"

LICENSE="BSD GPL-2"
# Subslot is for libsubid's SONAME.
SLOT="0/4"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="acl audit bcrypt cracklib nls pam selinux skey split-usr -su xattr"
# Taken from the man/Makefile.am file.
LANGS=( cs da de es fi fr hu id it ja ko pl pt_BR ru sv tr zh_CN zh_TW )

REQUIRED_USE="?? ( cracklib pam )"

COMMON_DEPEND="
	virtual/libcrypt:=
	acl? ( sys-apps/acl:= )
	audit? ( >=sys-process/audit-2.6:= )
	cracklib? ( >=sys-libs/cracklib-2.7-r3:= )
	nls? ( virtual/libintl )
	pam? ( sys-libs/pam:= )
	skey? ( sys-auth/skey:= )
	selinux? (
		>=sys-libs/libselinux-1.28:=
		sys-libs/libsemanage:=
	)
	xattr? ( sys-apps/attr:= )
"
DEPEND="
	${COMMON_DEPEND}
	virtual/os-headers:41400
"
RDEPEND="
	${COMMON_DEPEND}
	!<sys-apps/man-pages-5.11-r1
	!=sys-apps/man-pages-5.12-r0
	!=sys-apps/man-pages-5.12-r1
	nls? (
		!<app-i18n/man-pages-it-5.06-r1
		!<app-i18n/man-pages-ja-20180315-r1
		!<app-i18n/man-pages-ru-5.03.2390.2390.20191017-r1
	)
	pam? ( >=sys-auth/pambase-20150213 )
	su? ( !sys-apps/util-linux[su(-)] )
"
BDEPEND="
	app-arch/xz-utils
	sys-devel/gettext
	verify-sig? ( sec-keys/openpgp-keys-sergehallyn )
"

PATCHES=(
	"${FILESDIR}"/${P}-configure-clang16.patch
	"${FILESDIR}"/${P}-CVE-2023-29383.patch
	"${FILESDIR}"/${P}-usermod-prefix-gid.patch
	"${FILESDIR}"/${P}-password-leak.patch
)

src_prepare() {
	default

	elibtoolize
}

src_configure() {
	local myeconfargs=(
		--disable-account-tools-setuid
		--disable-static
		--with-btrfs
		--without-group-name-max-length
		--without-tcb
		$(use_enable nls)
		$(use_with acl)
		$(use_with audit)
		$(use_with bcrypt)
		$(use_with cracklib libcrack)
		$(use_with elibc_glibc nscd)
		$(use_with pam libpam)
		$(use_with selinux)
		$(use_with skey)
		$(use_with su)
		$(use_with xattr attr)
	)

	econf "${myeconfargs[@]}"

	if use nls ; then
		local l langs="po" # These are the pot files.
		for l in ${LANGS[*]} ; do
			has ${l} ${LINGUAS-${l}} && langs+=" ${l}"
		done
		sed -i "/^SUBDIRS = /s:=.*:= ${langs}:" man/Makefile || die
	fi
}

set_login_opt() {
	local comment="" opt=${1} val=${2}
	if [[ -z ${val} ]]; then
		comment="#"
		sed -i \
			-e "/^${opt}\>/s:^:#:" \
			"${ED}"/etc/login.defs || die
	else
		sed -i -r \
			-e "/^#?${opt}\>/s:.*:${opt} ${val}:" \
			"${ED}"/etc/login.defs
	fi
	local res=$(grep "^${comment}${opt}\>" "${ED}"/etc/login.defs)
	einfo "${res:-Unable to find ${opt} in /etc/login.defs}"
}

src_install() {
	emake DESTDIR="${D}" suidperms=4711 install

	# 4.9 regression: https://github.com/shadow-maint/shadow/issues/389
	emake DESTDIR="${D}" -C man install

	find "${ED}" -name '*.la' -type f -delete || die

	insinto /etc
	if ! use pam ; then
		insopts -m0600
		doins etc/login.access etc/limits
	fi

	# needed for 'useradd -D'
	insinto /etc/default
	insopts -m0600
	doins "${FILESDIR}"/default/useradd

	if use split-usr ; then
		# move passwd to / to help recover broken systems #64441
		# We cannot simply remove this or else net-misc/scponly
		# and other tools will break because of hardcoded 'passwd'
		# location
		dodir /bin
		mv "${ED}"/usr/bin/passwd "${ED}"/bin/ || die
		dosym ../../bin/passwd /usr/bin/passwd

		# By default, /bin/getsubids depends on /usr/lib64/libsubid.so.4 - we
		# could move the binary to /usr/bin, but it's probably safer to move
		# the library to the root filesystem...
		gen_usr_ldscript -a subid
	fi

	cd "${S}" || die
	insinto /etc
	insopts -m0644
	newins etc/login.defs login.defs

	set_login_opt CREATE_HOME yes
	if ! use pam ; then
		set_login_opt MAIL_CHECK_ENAB no
		set_login_opt SU_WHEEL_ONLY yes
		set_login_opt CRACKLIB_DICTPATH /usr/lib/cracklib_dict
		set_login_opt LOGIN_RETRIES 3
		set_login_opt ENCRYPT_METHOD SHA512
		set_login_opt CONSOLE
	else
		dopamd "${FILESDIR}"/pam.d-include/shadow

		for x in chsh chfn ; do
			newpamd "${FILESDIR}"/pam.d-include/passwd ${x}
		done

		for x in chpasswd newusers ; do
			newpamd "${FILESDIR}"/pam.d-include/chpasswd ${x}
		done

		newpamd "${FILESDIR}"/pam.d-include/shadow-r1 groupmems

		# Comment out login.defs options that pam hates
		local opt sed_args=()
		for opt in \
			CHFN_AUTH \
			CONSOLE \
			CRACKLIB_DICTPATH \
			ENV_HZ \
			ENVIRON_FILE \
			FAILLOG_ENAB \
			FTMP_FILE \
			LASTLOG_ENAB \
			MAIL_CHECK_ENAB \
			MOTD_FILE \
			NOLOGINS_FILE \
			OBSCURE_CHECKS_ENAB \
			PASS_ALWAYS_WARN \
			PASS_CHANGE_TRIES \
			PASS_MIN_LEN \
			PORTTIME_CHECKS_ENAB \
			QUOTAS_ENAB \
			SU_WHEEL_ONLY
		do
			set_login_opt ${opt}
			sed_args+=( -e "/^#${opt}\>/b pamnote" )
		done
		sed -i "${sed_args[@]}" \
			-e 'b exit' \
			-e ': pamnote; i# NOTE: This setting should be configured via /etc/pam.d/ and not in this file.' \
			-e ': exit' \
			"${ED}"/etc/login.defs || die

		# Remove manpages that pam will install for us
		# and/or don't apply when using pam
		find "${ED}"/usr/share/man -type f \
			'(' -name 'limits.5*' -o -name 'suauth.5*' ')' \
			-delete

		# Remove pam.d files provided by pambase.
		rm "${ED}"/etc/pam.d/{login,passwd} || die
		if use su ; then
			rm "${ED}"/etc/pam.d/su || die
		fi
	fi

	# Remove manpages that are handled by other packages
	find "${ED}"/usr/share/man -type f \
		'(' -name id.1 -o -name getspnam.3 ')' \
		-delete || die

	if ! use su ; then
		find "${ED}"/usr/share/man -type f -name su.1 -delete || die
	fi

	cd "${S}" || die
	dodoc ChangeLog NEWS TODO
	newdoc README README.download
	cd doc || die
	dodoc HOWTO README* WISHLIST *.txt

	if use elibc_musl; then
		QA_CONFIG_IMPL_DECL_SKIP+=( sgetsgent )
	fi
}

pkg_preinst() {
	rm -f "${EROOT}"/etc/pam.d/system-auth.new \
		"${EROOT}/etc/login.defs.new"
}

pkg_postinst() {
	# Missing entries from /etc/passwd can cause odd system blips.
	# See bug #829872.
	if ! pwck -r -q -R "${EROOT:-/}" &>/dev/null ; then
		ewarn "Running 'pwck' returned errors. Please run it manually to fix any errors."
	fi

	# Enable shadow groups.
	if [[ ! -f "${EROOT}"/etc/gshadow ]] ; then
		if grpck -r -R "${EROOT:-/}" 2>/dev/null ; then
			grpconv -R "${EROOT:-/}"
		else
			ewarn "Running 'grpck' returned errors. Please run it by hand, and then"
			ewarn "run 'grpconv' afterwards!"
		fi
	fi

	[[ ! -f "${EROOT}"/etc/subgid ]] &&
		touch "${EROOT}"/etc/subgid
	[[ ! -f "${EROOT}"/etc/subuid ]] &&
		touch "${EROOT}"/etc/subuid

	einfo "The 'adduser' symlink to 'useradd' has been dropped."
}
