# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit fcaps go-module prefix systemd

DESCRIPTION="Flexible DNS proxy, with support for encrypted DNS protocols"
HOMEPAGE="https://github.com/DNSCrypt/dnscrypt-proxy"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/DNSCrypt/dnscrypt-proxy.git"
	inherit git-r3
else
	SRC_URI="https://github.com/DNSCrypt/dnscrypt-proxy/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm arm64 ppc64 x86"
fi

LICENSE="Apache-2.0 BSD ISC MIT MPL-2.0"
SLOT="0"
IUSE="systemd"

RDEPEND="
	acct-group/dnscrypt-proxy
	acct-user/dnscrypt-proxy
"

FILECAPS=( cap_net_bind_service+ep usr/sbin/dnscrypt-proxy )

PATCHES=(
	"${FILESDIR}"/${PN}-2.1.11-config-full-paths.patch
)

src_compile() {
	pushd "${PN}" >/dev/null || die
	ego build -v -x -mod=readonly -mod=vendor
	popd >/dev/null || die
}

src_test() {
	cd "${PN}" || die
	ego test -mod=vendor
}

src_install() {
	pushd "${PN}" >/dev/null || die

	dosbin dnscrypt-proxy

	eprefixify example-dnscrypt-proxy.toml
	insinto /etc/dnscrypt-proxy
	newins example-dnscrypt-proxy.toml dnscrypt-proxy.toml
	doins example-{allowed,blocked}-{ips.txt,names.txt}
	doins example-{cloaking-rules.txt,forwarding-rules.txt}

	popd >/dev/null || die

	insinto /usr/share/dnscrypt-proxy
	doins -r "utils/generate-domains-blocklist/."

	newinitd "${FILESDIR}"/dnscrypt-proxy.initd dnscrypt-proxy
	newconfd "${FILESDIR}"/dnscrypt-proxy.confd dnscrypt-proxy

	if use systemd; then
		systemd_newunit "${FILESDIR}"/dnscrypt-proxy.service dnscrypt-proxy.service
		systemd_newunit "${FILESDIR}"/dnscrypt-proxy.socket dnscrypt-proxy.socket
	fi

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/dnscrypt-proxy.logrotate dnscrypt-proxy

	einstalldocs
}

pkg_postinst() {
	fcaps_pkg_postinst

	if ! use filecaps; then
		ewarn "'filecaps' USE flag is disabled"
		ewarn "${PN} will fail to listen on port 53"
		ewarn "please do one the following:"
		ewarn "1) re-enable 'filecaps'"
		ewarn "2) change port to > 1024"
		ewarn "3) configure to run ${PN} as root (not recommended)"
		ewarn
	fi

	if systemd_is_booted || has_version sys-apps/systemd; then
		elog "Using systemd socket activation may cause issues with speed"
		elog "latency and reliability of ${PN} and is discouraged by upstream"
		elog "Existing installations advised to disable 'dnscrypt-proxy.socket'"
		elog "It is disabled by default for new installations"
		elog "check "$(systemd_get_systemunitdir)/${PN}.service" for details"
		elog

	fi

	elog "After starting the service you will need to update your"
	elog "${EROOT}/etc/resolv.conf and replace your current set of resolvers"
	elog "with:"
	elog
	elog "nameserver 127.0.0.1"
	elog
	elog "Also see https://github.com/DNSCrypt/${PN}/wiki"
}
