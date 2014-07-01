EAPI=5

MODULE_AUTHOR=MVZ
inherit perl-module

DESCRIPTION="Read Outlook .msg files"

SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris"
IUSE=""

RDEPEND="virtual/perl-PodParser
	virtual/perl-Getopt-Long
	dev-perl/Email-LocalDelivery
	dev-perl/IO-All
	dev-perl/OLE-StorageLite
	dev-perl/Email-MIME
	"
DEPEND="${RDEPEND}"

SRC_TEST=do
