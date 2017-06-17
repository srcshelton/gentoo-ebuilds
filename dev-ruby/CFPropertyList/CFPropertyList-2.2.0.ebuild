# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
USE_RUBY="ruby21"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="Read, write and manipulate both binary and XML property lists"
HOMEPAGE="https://github.com/ckruse/CFPropertyList"
SRC_URI="${HOMEPAGE}/archive/cfpropertylist-${PV/\.0}.zip"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

ruby_add_bdepend "
	>=dev-ruby/rake-0.7.0"

src_prepare() { 
	MY_S="${WORKDIR}"/all/"${PN}-cfpropertylist-${PV/\.0}"

	for ver in ${USE_RUBY}; do 
		mkdir "${WORKDIR}/$ver" 
		cp -prl "${MY_S}" "${WORKDIR}/$ver/${RUBY_S}" 
	done 
}
