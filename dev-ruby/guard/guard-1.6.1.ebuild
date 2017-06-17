# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
USE_RUBY="ruby21"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="
	README.md
	CHANGELOG.md
	CONTRIBUTING.md"

RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="Guard is a command line tool to easily handle events on file system modifications"
HOMEPAGE="https://github.com/guard/guard"

LICENSE="freedist"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

ruby_add_bdepend "
	dev-ruby/bundler
	>=dev-ruby/guard-rspec-2.3.0
	>=dev-ruby/rspec-2.12.0"

ruby_add_rdepend "
	>=dev-ruby/listen-0.6.0
	>=dev-ruby/lumberjack-1.0.2
	>=dev-ruby/pry-0.9.10
	>=dev-ruby/thor-0.14.6"
