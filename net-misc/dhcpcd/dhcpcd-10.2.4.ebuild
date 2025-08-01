# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature systemd toolchain-funcs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NetworkConfiguration/dhcpcd.git"
else
	MY_P="${P/_alpha/-alpha}"
	MY_P="${MY_P/_beta/-beta}"
	MY_P="${MY_P/_rc/-rc}"
	SRC_URI="https://github.com/NetworkConfiguration/dhcpcd/releases/download/v${PV}/${MY_P}.tar.xz"
	S="${WORKDIR}/${MY_P}"

	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux"
fi

DESCRIPTION="A fully featured, yet light weight RFC2131 compliant DHCP client"
HOMEPAGE="https://github.com/NetworkConfiguration/dhcpcd/ https://roy.marples.name/projects/dhcpcd/"

LICENSE="BSD-2 BSD ISC MIT"
SLOT="0"
IUSE="debug +embedded ipv6 privsep systemd +udev"

DEPEND="
	app-crypt/libmd
	udev? ( virtual/udev )
"
RDEPEND="
	${DEPEND}
	privsep? (
		acct-group/dhcpcd
		acct-user/dhcpcd
	)
"

QA_CONFIG_IMPL_DECL_SKIP=(
	# These don't exist on Linux/glibc (bug #900264)
	memset_explicit
	memset_s
	setproctitle
	strtoi
	consttime_memequal
	SHA256_Init
	hmac
	timingsafe_bcmp
	# These may exist on some glibc versions, but the checks fail due to
	# -Werror / undefined reference no matter what. bug #924825
	arc4random
	arc4random_uniform
)

PATCHES=(
	"${FILESDIR}"/${PN}-10.0.6-fix-lib-check.patch
)

src_configure() {
	local myeconfargs=(
		--dbdir="${EPREFIX%/}/var/lib/dhcpcd"
		--libexecdir="${EPREFIX%/}/lib/dhcpcd"
		--localstatedir="${EPREFIX%/}/var"
		--prefix="${EPREFIX}"
		--with-hook=ntp.conf
		$(use_enable debug)
		$(use_enable embedded)
		$(use_enable ipv6)
		$(use_enable privsep)
		$(usex elibc_glibc '--with-hook=yp.conf' '')
		--rundir="${EPREFIX%/}/var/run/dhcpcd"
		$(usex privsep '--privsepuser=dhcpcd' '')
		$(usex udev '' '--without-dev --without-udev')
		CC="$(tc-getCC)"
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default
	keepdir /var/lib/dhcpcd
	newinitd "${FILESDIR}"/dhcpcd.initd-r1 dhcpcd
	use systemd && systemd_newunit "${FILESDIR}"/dhcpcd.service-r1 dhcpcd.service
}

pkg_postinst() {
	local dbdir="${EROOT%/}"/var/lib/dhcpcd old_files=()

	local old_old_duid="${EROOT%/}"/var/lib/dhcpcd/dhcpcd.duid
	local old_duid="${EROOT%/}"/etc/dhcpcd.duid
	local new_duid="${dbdir}"/duid
	if [[ -e "${old_old_duid}" ]] ; then
		# Upgrade the duid file to the new format if needed
		if ! grep -q '..:..:..:..:..:..' "${old_old_duid}"; then
			sed -i -e 's/\(..\)/\1:/g; s/:$//g' "${old_old_duid}"
		fi

		# Move the duid to /etc, a more sensible location
		if [[ ! -e "${old_duid}" ]] ; then
			cp -p "${old_old_duid}" "${new_duid}"
		fi
		old_files+=( "${old_old_duid}" )
	fi

	# dhcpcd-7 moves the files out of /etc
	if [[ -e "${old_duid}" ]] ; then
		if [[ ! -e "${new_duid}" ]] ; then
			cp -p "${old_duid}" "${new_duid}"
		fi
		old_files+=( "${old_duid}" )
	fi
	local old_secret="${EROOT%/}"/etc/dhcpcd.secret
	local new_secret="${dbdir}"/secret
	if [[ -e "${old_secret}" ]] ; then
		if [[ ! -e "${new_secret}" ]] ; then
			cp -p "${old_secret}" "${new_secret}"
		fi
		old_files+=( "${old_secret}" )
	fi

	# dhcpcd-7 renames some files in /var/lib/dhcpcd
	local old_rdm="${dbdir}"/dhcpcd-rdm.monotonic
	local new_rdm="${dbdir}"/rdm_monotonic
	if [[ -e "${old_rdm}" ]] ; then
		if [[ ! -e "${new_rdm}" ]] ; then
			cp -p "${old_rdm}" "${new_rdm}"
		fi
		old_files+=( "${old_rdm}" )
	fi
	local lease=
	for lease in "${dbdir}"/dhcpcd-*.lease*; do
		[[ -f "${lease}" ]] || continue
		old_files+=( "${lease}" )
		local new_lease=$(basename "${lease}" | sed -e "s/dhcpcd-//")
		[[ -e "${dbdir}/${new_lease}" ]] && continue
		cp "${lease}" "${dbdir}/${new_lease}"
	done

	# Warn about removing stale files
	if [[ -n "${old_files[@]}" ]] ; then
		elog
		elog "dhcpcd-7 has copied dhcpcd.duid and dhcpcd.secret from"
		elog "${EROOT%/}/etc to ${dbdir}"
		elog "and copied leases in ${dbdir} to new files with the dhcpcd-"
		elog "prefix dropped."
		elog
		elog "You should remove these files if you don't plan on reverting"
		elog "to an older version:"
		local old_file=
		for old_file in ${old_files[@]}; do
			elog "	${old_file}"
		done
	fi

	if [ -z "${REPLACING_VERSIONS}" ]; then
		elog
		elog "dhcpcd has zeroconf support active by default."
		elog "This means it will always obtain an IP address even if no"
		elog "DHCP server can be contacted, which will break any existing"
		elog "failover support you may have configured in your net configuration."
		elog "This behaviour can be controlled with the noipv4ll configuration"
		elog "file option or the -L command line switch."
		elog "See the dhcpcd and dhcpcd.conf man pages for more details."

		elog
		elog "Dhcpcd has duid enabled by default, and this may cause issues"
		elog "with some dhcp servers. For more information, see"
		elog "https://bugs.gentoo.org/show_bug.cgi?id=477356"
	fi

	optfeature "lookup-hostname hook" net-dns/bind
}
