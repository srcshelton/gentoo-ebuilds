# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic linux-info systemd

DESCRIPTION="Reliability, Availability and Serviceability logging tool"
HOMEPAGE="https://github.com/mchehab/rasdaemon"
SRC_URI="https://github.com/mchehab/rasdaemon/releases/download/v${PV}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ~ppc64 x86"
IUSE="experimental extlog sqlite systemd"
REQUIRED_USE="
	extlog? ( experimental )
	sqlite? ( experimental )
"

DEPEND="
	sqlite? ( dev-db/sqlite )
	elibc_musl? ( sys-libs/argp-standalone )
"
RDEPEND="
	${DEPEND}
	sqlite? (
		dev-perl/DBI
		dev-perl/DBD-SQLite
	)
	sys-apps/dmidecode
"
BDEPEND="sys-devel/gettext"

pkg_setup() {
	if kernel_is ge 6 1 0; then
		warn "Please upgrade to ${CATEGORY}/${P} in order to provide support for linux-6.1.0 and above"
	fi

	linux-info_pkg_setup
	local CONFIG_CHECK="~DEBUG_FS"
	use extlog && CONFIG_CHECK="${CONFIG_CHECK} ~ACPI_EXTLOG"
	check_extra_config
}

src_prepare() {
	default

	sed -i \
		-e 's|/etc/sysconfig/rasdaemon|/etc/ras/rasdaemon|g' \
			man/rasdaemon.1.in \
			misc/rasdaemon.env

	# Add missing newline at end of file...
	echo >> misc/rasdaemon.env

	cp "${FILESDIR}"/rasdaemon.confd "${T}"/
	if ! use sqlite; then
		sed -i \
			-e 's|--record||' \
				"${T}/rasdaemon.confd"
	fi
}

src_configure() {
	#  --enable-sqlite3        enable storing data at SQL lite database (currently experimental)
	#  --enable-aer            enable PCIe AER events (currently experimental)
	#  --enable-non-standard   enable NON_STANDARD events (currently experimental)
	#  --enable-arm            enable ARM events (currently experimental)
	#  --enable-mce            enable MCE events (currently experimental)
	#  --enable-extlog         enable EXTLOG events (currently experimental)
	#  --enable-devlink        enable devlink health events (currently experimental)
	#  --enable-diskerror      enable disk I/O error events (currently experimental)
	#  --enable-memory-failure enable memory failure events (currently experimental)
	#  --enable-abrt-report    enable report event to ABRT (currently experimental)
	#  --enable-hisi-ns-decode enable HISI_NS_DECODE events (currently experimental)
	#  --enable-amp-ns-decode  enable AMP_NS_DECODE events (currently experimental)
	#  --enable-memory-ce-pfa  enable memory Corrected Error predictive failure analysis
	#  --enable-cpu-fault-isolation
	#                          enable cpu online fault isolation
	local myconfargs=(
		--enable-memory-ce-pfa
		--enable-cpu-fault-isolation
		--includedir="/usr/include/${PN}"
		--localstatedir=/var
		--with-sysconfdefdir=/etc/ras
	)
	if use experimental; then
		myconfargs+=( # <- Syntax
			$(use_enable sqlite sqlite3)
			--enable-aer
			--enable-non-standard
			--enable-arm
			--enable-mce
			$(use_enable extlog)
			--enable-devlink
			--enable-diskerror
			--enable-memory-failure
			--enable-abrt-report
			--enable-hisi-ns-decode
			--enable-amp-ns-decode
		)
	fi

	use elibc_musl && append-libs -largp

	econf "${myconfargs[@]}"
}

src_install() {
	default

	keepdir "/var/lib/${PN}"

	use systemd && systemd_dounit misc/*.service

	newinitd "${FILESDIR}/rasdaemon.openrc-r2" rasdaemon
	newinitd "${FILESDIR}/ras-mc-ctl.openrc-r1" ras-mc-ctl
	newconfd "${T}"/rasdaemon.confd rasdaemon

	fperms 0640 /etc/ras/rasdaemon
}
