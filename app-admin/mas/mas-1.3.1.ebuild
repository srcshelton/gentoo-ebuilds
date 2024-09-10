# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A simple command-line interface for the Mac App Store"
HOMEPAGE="https://github.com/mas-cli/mas/"
SRC_URI="https://github.com/mas-cli/mas/archive/v1.3.1.tar.gz -> mas-1.3.1.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="x64-macos"

pkg_setup() {
	type -pf "xcodebuild" >/dev/null 2>&1 || die "Xcode is required in order to build ${PN}"
}

src_compile() {
	# Requires 'xcpretty'...
	#script/build || die "'build' script failed: ${?}"

	xcodebuild -project "mas-cli.xcodeproj" -scheme "mas-cli" -configuration "Release" clean build ||
		die "Compilation of 'mas-cli' via \`xcodebuild\` failed: ${?}"
}

src_install() {
	dodoc "README.md"
	dosbin "build/mas" || die "'mas' binary not found ${?}"
}
