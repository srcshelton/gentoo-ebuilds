# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit eapi9-ver linux-info systemd toolchain-funcs multilib-minimal

DESCRIPTION="Hardware Monitoring user-space utilities"
HOMEPAGE="https://hwmon.wiki.kernel.org/ https://github.com/lm-sensors/lm-sensors"

if [[ "${PV}" =~ .*_p[[:digit:]]{8}.* ]] ; then
	COMMIT="5c3ba50f806dea27c3b1e368966191c735459111"
	SRC_URI="https://github.com/hramrach/${PN}/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${COMMIT}"
else
	SRC_URI="https://github.com/hramrach/lm-sensors/archive/V$(ver_rs 1- -).tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-$(ver_rs 1- -)"
fi

LICENSE="GPL-2+ LGPL-2.1"

# SUBSLOT based on SONAME of libsensors.so
SLOT="0/5.0.0"

KEYWORDS="~alpha amd64 arm arm64 ~loong ~mips ppc ppc64 ~riscv sparc x86 ~amd64-linux ~x86-linux"
IUSE="contrib selinux sensord static-libs systemd test"

COMMON_DEPS="
	sensord? (
		net-analyzer/rrdtool
		virtual/logger
	)"

BDEPEND="
	test? (
		dev-perl/Test-Cmd
	)
"
RDEPEND="${COMMON_DEPS}
	dev-lang/perl
	selinux? ( sec-policy/selinux-sensord )"

DEPEND="${COMMON_DEPS}
	app-alternatives/yacc
	app-alternatives/lex"
RESTRICT="!test? ( test )"

CONFIG_CHECK="~HWMON ~I2C_CHARDEV ~I2C"
WARNING_HWMON="${PN} requires CONFIG_HWMON to be enabled for use."
WARNING_I2C_CHARDEV="sensors-detect requires CONFIG_I2C_CHARDEV to be enabled."
WARNING_I2C="${PN} requires CONFIG_I2C to be enabled for most sensors."

PATCHES=(
	"${FILESDIR}"/${PN}-3.5.0-sensors-detect-gentoo.patch
	"${FILESDIR}"/${PN}-3.6.2-no-valgrind-tests.patch
)

DOCS=( CHANGES CONTRIBUTORS INSTALL README )
DOCS+=( doc/{donations,fancontrol.txt,fan-divisors,libsensors-API.txt,progs,temperature-sensors,vid} )

src_prepare() {
	default

	if [[ -n "${COMMIT}" ]]; then
		local _version="${PV%_*}+git_${COMMIT}"

		sed -i \
			-e "s:LM_VERSION.*:LM_VERSION \"${_version}\":" \
			version.h || \
			die "Failed to update version.h"

		sed -i \
			-e "s/^\$revision = '.*/\$revision = '${_version}';/" \
			-e "/^\$revision =~ s.*/d" \
			prog/detect/sensors-detect || \
			die "Failed to set revision in prog/detect/sensors-detect"

		sed -i \
			-e "s/^echo \"# pwmconfig revision.*/echo \"# pwmconfig revision ${_version}\"/" \
			-e "/^REVISION=.*/d" \
			-e "/^REVDATE=.*/d" \
			-e "s:^PIDFILE=\".*:PIDFILE=\"/var/run/fancontrol.pid\":" \
			prog/pwm/pwmconfig || \
			die "Failed to adjust prog/pwm/pwmconfig"
	else
		sed -i \
			-e "s:^PIDFILE=\".*:PIDFILE=\"/var/run/fancontrol.pid\":" \
			prog/pwm/pwmconfig || \
			die "Failed to adjust PIDFILE in prog/pwm/pwmconfig"
	fi

	# Respect LDFLAGS
	sed -i -e 's/\$(LIBDIR)$/\$(LIBDIR) \$(LDFLAGS)/g' Makefile || \
		die "Failed to sed in LDFLAGS"

	sed -i \
		-e "s:^PIDFILE=\".*:PIDFILE=\"/var/run/fancontrol.pid\":" \
		prog/pwm/fancontrol || \
		die "Failed to adjust PIDFILE of prog/pwm/fancontrol"

	# Don't use EnvironmentFile in systemd unit
	sed -i \
		-e '/^EnvironmentFile=/d' \
		-e '/^Exec.*modprobe.*/d' \
		prog/init/lm_sensors.service || \
		die "Failed to remove EnvironmentFile from systemd unit file"

	if ! use static-libs; then
		sed -i -e '/^BUILD_STATIC_LIB/d' Makefile || \
			die "Failed to disable static building"
	fi

	# Don't show outdated user instructions
	sed -i -e '/^	@echo "\*\*\* /d' Makefile || \
		die "Failed to remove outdated user instructions"

	multilib_copy_sources
}

multilib_src_configure() {
	default

	if multilib_is_native_abi && use sensord; then
		# sensord requires net-analyzer/rrdtool which doesn't have real multilib
		# support. To prevent errors like
		#
		#   skipping incompatible /usr/lib/librrd.so when searching for -lrrd
		#   cannot find -lrrd
		#
		# we only build sensord when we are building for profile's native ABI
		# (it doesn't affect libsensors.so).
		sed -i -e 's:^#\(PROG_EXTRA.*\):\1:' Makefile || \
			die "Failed to enable building of sensord"
	fi
}

multilib_src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		LD="$(tc-getLD)" \
		AR="$(tc-getAR)"
}

multilib_src_install() {
	# We need to set CC and friends again here to avoid recompilation for cross
	# bug #799851
	emake \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		LD="$(tc-getLD)" \
		AR="$(tc-getAR)" \
		DESTDIR="${ED}" \
		PREFIX="/usr" \
		MANDIR="/usr/share/man" \
		ETCDIR="/etc" \
		LIBDIR="/usr/$(get_libdir)" \
		install
}

multilib_src_install_all() {
	newinitd "${FILESDIR}"/lm_sensors.initd lm_sensors
	newconfd "${FILESDIR}"/lm_sensors.confd lm_sensors
	use systemd && systemd_dounit prog/init/lm_sensors.service

	newinitd "${FILESDIR}"/fancontrol.initd fancontrol
	newconfd "${FILESDIR}"/fancontrol.confd fancontrol
	use systemd && systemd_newunit "${FILESDIR}"/fancontrol.service-r1 fancontrol.service

	if use sensord; then
		newconfd "${FILESDIR}"/sensord.confd sensord
		newinitd "${FILESDIR}"/sensord.initd sensord
		use systemd && systemd_newunit "${FILESDIR}"/sensord.service-r1 sensord.service
	fi

	einstalldocs

	docinto developers
	dodoc doc/developers/applications

	if use contrib; then
		insinto /usr/share/lm_sensors
		doins -r "${S}"/configs
	fi
}

pkg_postinst() {
	local _new_loader='3.4.0_p20160725'
	if ver_replacing -lt "${_new_loader}"; then
		# This is an upgrade which requires migration

		elog ""
		elog "Since version 3.4.0_p20160725 ${PN} no longer loads modules on its own"
		elog "instead it is using \"modules-load\" services provided by OpenRC or systemd."
		elog ""
		elog "To migrate your configuration you have 2 options:"
		elog ""
		elog "  a) Re-create a new configuration using \"/usr/sbin/sensors-detect\""
		elog ""
		elog "  b) Copy existing \"modules_<n>\", \"HWMON_MODULES\" or \"BUS_MODULES\""
		elog "     variables from \"/etc/conf.d/lm_modules\" to"
		elog "     \"/etc/modules-load.d/lm_sensors.conf\" and adjust format."
		elog ""
		elog "     For details see https://wiki.gentoo.org/wiki/Systemd#Automatic_module_loading"
		elog ""
		elog "     Important: Don't forget to migrate your module's argument"
		elog "                (modules_<name>_args variable) if your are not already"
		elog "                using \"/etc/modprobe.d\" (which is recommended)."
	fi

	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		# New installation

		elog ""
		elog "Please run \`/usr/sbin/sensors-detect' in order to setup"
		elog "\"/etc/modules-load.d/lm_sensors.conf\"."
		elog ""
		elog "You might want to add lm_sensors to your default runlevel to make"
		elog "sure the sensors get initialized on the next startup."
		elog ""
		elog "Be warned, the probing of hardware in your system performed by"
		elog "sensors-detect could freeze your system."
	fi
}
