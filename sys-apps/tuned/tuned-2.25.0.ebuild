# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

inherit optfeature python-single-r1 tmpfiles xdg-utils

DESCRIPTION="Daemon for monitoring and adaptive tuning of system devices"
HOMEPAGE="https://github.com/redhat-performance/tuned"
SRC_URI="https://github.com/redhat-performance/tuned/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

IUSE="bash-completion +dbus gtk ppd +tmpfiles +server systemd-boot"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	server? ( dbus )
	"

DEPEND="
	${PYTHON_DEPS}
	ppd? (
		$(python_gen_cond_dep '
			dev-python/pyinotify[${PYTHON_USEDEP}]
		')
	)
	server? (
		$(python_gen_cond_dep '
			dev-python/configobj[${PYTHON_USEDEP}]
			dev-python/decorator[${PYTHON_USEDEP}]
			dev-python/pyudev[${PYTHON_USEDEP}]
		')
	)
	$(python_gen_cond_dep '
		dev-python/dbus-python[${PYTHON_USEDEP}]
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		dev-python/python-linux-procfs[${PYTHON_USEDEP}]
	')"

RDEPEND="
	${DEPEND}
	dbus? ( sys-apps/dbus )
	gtk? ( x11-libs/gtk+[introspection] )
	ppd? ( !sys-power/power-profiles-daemon )
	server? (
		app-emulation/virt-what
		dev-debug/systemtap
		sys-apps/ethtool
		sys-power/powertop
	)
	"

RESTRICT="test"

src_prepare() {
	default

	use bash-completion ||
		sed -i \
			-e '/BASH_COMPLETIONS/d' \
				Makefile || die
	use gtk ||
		sed -i \
			-e '/\/applications/d' \
			-e '/\/ui\//d' \
				Makefile || die
	use systemd-boot ||
		sed -i \
			-e '/KERNELINSTALLHOOKDIR/d' \
				Makefile || die
	sed -i \
		-e "/^PYTHON/s:/usr/bin/python3:${EPREFIX}/usr/bin/${EPYTHON}:" \
		-e "/^export DOCDIR/s/$/&\-\$(VERSION)/g" \
		-e "/\$(DESTDIR)\/run\/tuned/d" \
		-e "/\$(DESTDIR)\/var\/lib\/tuned/d" \
		-e "/\$(DESTDIR)\/var\/log\/tuned/d" \
			Makefile || die
	sed -i \
		-e '/STORAGE/s:=/run/:=/var/run:' \
			functions || die
	sed -i \
		-e '/sysctl/s:/run/sysctl\.d:/lib/sysctl\.d:' \
			man/tuned-main.conf.5 tuned/plugins/plugin_sysctl.py || die
	sed -i \
		-e '/PID/s:/run/tuned:/var/run/tuned:' \
			man/tuned.8 || die
	sed -i \
		-e '/sock/s:/run/tuned:/var/run/tuned:' \
			tests/beakerlib/Expose-TuneD-API-to-the-Unix-Domain-Socket/runtest.sh \
				tuned/exports/unix_socket_exporter.py || die
	sed -i \
		-e '/PID_FILE/s:/run/tuned:/var/run/tuned:' \
			tests/beakerlib/bz1798183-RFE-support-post-loaded-profile/runtest.sh || die
	sed -i \
		-e '/sysctl/s:/run/sysctl\.d:/lib/sysctl\.d:' \
		-e '/sock/s:/run/tuned:/var/run/tuned:' \
			tuned-main.conf || die
	sed -i \
		-e 's:/run/tuned:/var/run/tuned:' \
			tuned.service tuned.spec tuned.tmpfiles || die
	sed -i \
		-e '/_FILE/s:/run/tuned:/var/run/tuned:' \
		-e '/CFG_DEF_UNIX_SOCKET_PATH/s:/run/tuned:/var/run/tuned:' \
			tuned/consts.py || die

	cp "${FILESDIR}/${PN}.initd" "${T}"/
	use dbus ||
		sed -i "${T}/${PN}.initd" \
			-e '/command_args/s:-d :-d --no-dbus :' \
			-e '/need dbus$/s:need:use:'
}

src_install() {
	default

	rm \
			"${ED%/}/usr/share/doc/${P}/AUTHORS" \
			"${ED%/}/usr/share/doc/${P}/COPYING" \
			"${ED%/}/usr/share/doc/${P}/README.NFV" \
			"${ED%/}/usr/share/doc/${P}/TODO" ||
		die

	if ! use dbus; then
		rm -r "${ED%/}/usr/share/polkit-1" "${ED%/}/usr/share/dbus-1" || die
	fi

	if use ppd; then
		emake DESTDIR="${D}" install-ppd
	else
		rm "${ED%/}/etc/tuned/ppd_base_profile" || die
	fi

	if ! use gtk; then
		rm "${ED%/}/usr/sbin/tuned-gui" || die
		rm "${ED%/}/usr/share/man/man8/tuned-gui.8" || die
		rm -r "${ED%/}/usr/share/icons" || die
	fi

	if ! use server; then
		rm -r "${ED%/}/usr/lib/tuned" || die
		rm \
				"${ED%/}/usr/share/man/man8/varnetload.8" \
				"${ED%/}/usr/share/man/man8/tuned.8" \
				"${ED%/}/usr/share/man/man8/scomes.8" \
				"${ED%/}/usr/share/man/man8/netdevstat.8" \
				"${ED%/}/usr/share/man/man8/diskdevstat.8" ||
			die
		rm \
				"${ED%/}/usr/sbin/varnetload" \
				"${ED%/}/usr/sbin/tuned" \
				"${ED%/}/usr/sbin/scomes" \
				"${ED%/}/usr/sbin/netdevstat" \
				"${ED%/}/usr/sbin/diskdevstat" ||
			die
		rm -r "${ED%/}/usr/bin" "${ED%/}/usr/libexec" || die
		rm -r "${ED%/}/etc/modprobe.d" "${ED%/}/etc/grub.d" || die
	fi

	use server && newinitd "${T}/${PN}.initd" "${PN}"
	python_fix_shebang "${D}"
	python_optimize
}

pkg_postinst() {
	use tmpfiles && tmpfiles_process "${PN}.conf"
	xdg_icon_cache_update

	if use server; then
		optfeature_header
		optfeature "Optimize for power saving by spinning-down rotational disks" sys-apps/hdparm
		optfeature "Get hardware info" sys-apps/dmidecode
		optfeature "Optimize network txqueuelen" sys-apps/iproute2
	fi
}
