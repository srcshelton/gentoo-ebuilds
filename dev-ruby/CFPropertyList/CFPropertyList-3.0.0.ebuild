# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
USE_RUBY="ruby24 ruby25 ruby26 ruby27 ruby30"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="Read, write and manipulate both binary and XML property lists"
HOMEPAGE="https://github.com/ckruse/CFPropertyList"
SRC_URI="${HOMEPAGE}/archive/cfpropertylist-${PV}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

ruby_add_bdepend "
	>=dev-ruby/rake-0.7.0"

src_prepare() {
	MY_S="${WORKDIR}"/all/"${PN}-cfpropertylist-${PV}"

	for ver in ${USE_RUBY}; do 
		mkdir "${WORKDIR}/$ver" 
		cp -prl "${MY_S}" "${WORKDIR}/$ver/${RUBY_S}" 
	done

	default
}
