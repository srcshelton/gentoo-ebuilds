# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

USE_RUBY="ruby19"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.markdown"

inherit ruby-fakegem

DESCRIPTION="An IRB alternative and runtime developer console"
HOMEPAGE="http://pry.github.com/"
IUSE=""
SLOT="0"

LICENSE="MIT"
KEYWORDS="amd64 ~ppc64 x86"

ruby_add_rdepend ">=dev-ruby/coderay-1.0.5
	>=dev-ruby/slop-3.3.1
	>=dev-ruby/method_source-0.8
	!!dev-python/pry"

ruby_add_bdepend "test? (
	>=dev-ruby/bacon-1.2.0
	>=dev-ruby/open4-1.3.0
	>=dev-ruby/rake-0.9
	>=dev-ruby/guard-1.3.2
	>=dev-ruby/mocha-0.13.1
	>=dev-ruby/bond-0.4.2
)"

all_ruby_prepare() {
	# Make version dependencies more lenient to avoid problems with
	# compatible upgrades.
	sed -i -e 's/~> 1.0.5/>= 1.0.5/'    \
		-e 's/~> 3.3.1/>= 3.3.1/'    \
		-e 's/~> 0.8/>= 0.8/'    \
		pry.gemspec || die
}

each_ruby_test() {
	${RUBY} -S bacon -Itest -a -q || die
}
