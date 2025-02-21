# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module
DESCRIPTION="Terminal UI frontend for Podman"
HOMEPAGE="https://github.com/containers/podman-tui"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/containers/podman-tui.git"
else
	SRC_URI="https://github.com/containers/podman-tui/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="Apache-2.0 BSD-2 BSD MIT MPL-2.0"
SLOT="0"
RESTRICT="test"

src_prepare() {
	default

	# Fix '/var/run' path...
	grep -R -e '/run[^cent.]' -e 'run/' "${S}" |
			grep -v \
					-e "github.com[^ '\"]\+/run" \
					-e "golangci-lint\.run" \
					-e "https\?://[^ '\"]\+/run" \
					-e 'bin/run' \
					-e 'runscript' \
					-e 'var/run' \
					-e '//.*/run' |
			cut -d':' -f 1 |
			xargs -rI'{}' \
				sed -i '{}' \
					-e 's:/run:/var/run:g' ||
		die "sed failed: ${?}"
}

src_compile() {
	# parse tags from Makefile & make them comma-seperated as space-seperated list is deprecated
	local BUILDTAGS=$(grep 'BUILDTAGS :=' Makefile | awk -F\" '{ print $2; }' | sed -e 's| |,|g;')
	ego build -tags "${BUILDTAGS}"
}

src_install() {
	dobin "${PN}"
	einstalldocs
}
