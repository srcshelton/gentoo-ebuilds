# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
USE_RUBY="ruby21"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.md"

RUBY_FAKEGEM_TASK_TEST="spec:prepare_fixtures"

inherit ruby-fakegem

DESCRIPTION="Guard::RSpec automatically run your specs"
HOMEPAGE="http://rubygems.org/gems/guard-rspec/"

LICENSE="freedist"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

ruby_add_bdepend "
	>=dev-ruby/bundler-1.1"

ruby_add_rdepend "
	>=dev-ruby/rspec-2.11"
# guard and guard-rspec depend on each other
#	>=dev-ruby/guard-1.1
