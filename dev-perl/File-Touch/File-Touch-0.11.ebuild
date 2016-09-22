# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Proc-Daemon/Proc-Daemon-0.140.0.ebuild,v 1.5 2012/03/02 21:38:44 ranger Exp $

EAPI=5

MODULE_AUTHOR=NEILB
MODULE_VERSION=0.11
inherit perl-module

DESCRIPTION="File::Touch - update file access and modification times, optionally creating files if needed"

SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE="test"

SRC_TEST="do"
