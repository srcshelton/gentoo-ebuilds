EAPI=2

MODULE_AUTHOR=MVZ
inherit perl-module

DESCRIPTION="Read Outlook .msg files"

SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris"
IUSE=""

RDEPEND="
	dev-perl/Email-LocalDelivery
	dev-perl/Email-MIME
	dev-perl/IO-All
	dev-perl/OLE-StorageLite
	virtual/perl-Getopt-Long
	virtual/perl-Module-Build
	virtual/perl-PodParser
	"
DEPEND="${RDEPEND}"

SRC_TEST=do
