# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{10..11} )
GO_OPTIONAL=1

inherit autotools fcaps flag-o-matic go-module linux-info python-single-r1 systemd toolchain-funcs

# cf. https://github.com/netdata/netdata/blob/v${PV}/packaging/go.d.version
GO_D_PLUGIN_PV="0.57.2"
GO_D_PLUGIN_PN="go.d.plugin"
GO_D_PLUGIN_P="${GO_D_PLUGIN_PN}-${GO_D_PLUGIN_PV}"

EGO_SUM=(
	"github.com/Azure/go-ansiterm v0.0.0-20210617225240-d185dfc1b5a1"
	"github.com/Azure/go-ansiterm v0.0.0-20210617225240-d185dfc1b5a1/go.mod"
	"github.com/BurntSushi/toml v0.3.1/go.mod"
	"github.com/DATA-DOG/go-sqlmock v1.5.0"
	"github.com/DATA-DOG/go-sqlmock v1.5.0/go.mod"
	"github.com/Masterminds/goutils v1.1.1"
	"github.com/Masterminds/goutils v1.1.1/go.mod"
	"github.com/Masterminds/semver/v3 v3.1.1/go.mod"
	"github.com/Masterminds/semver/v3 v3.2.0"
	"github.com/Masterminds/semver/v3 v3.2.0/go.mod"
	"github.com/Masterminds/sprig/v3 v3.2.3"
	"github.com/Masterminds/sprig/v3 v3.2.3/go.mod"
	"github.com/Microsoft/go-winio v0.5.1"
	"github.com/Microsoft/go-winio v0.5.1/go.mod"
	"github.com/Wing924/ltsv v0.3.1"
	"github.com/Wing924/ltsv v0.3.1/go.mod"
	"github.com/apparentlymart/go-cidr v1.1.0"
	"github.com/apparentlymart/go-cidr v1.1.0/go.mod"
	"github.com/araddon/dateparse v0.0.0-20210429162001-6b43995a97de"
	"github.com/araddon/dateparse v0.0.0-20210429162001-6b43995a97de/go.mod"
	"github.com/axiomhq/hyperloglog v0.0.0-20230201085229-3ddf4bad03dc"
	"github.com/axiomhq/hyperloglog v0.0.0-20230201085229-3ddf4bad03dc/go.mod"
	"github.com/blang/semver/v4 v4.0.0"
	"github.com/blang/semver/v4 v4.0.0/go.mod"
	"github.com/bmatcuk/doublestar/v4 v4.6.1"
	"github.com/bmatcuk/doublestar/v4 v4.6.1/go.mod"
	"github.com/cespare/xxhash/v2 v2.2.0"
	"github.com/cespare/xxhash/v2 v2.2.0/go.mod"
	"github.com/clbanning/rfile/v2 v2.0.0-20231024120205-ac3fca974b0e"
	"github.com/clbanning/rfile/v2 v2.0.0-20231024120205-ac3fca974b0e/go.mod"
	"github.com/cloudflare/cfssl v1.6.4"
	"github.com/cloudflare/cfssl v1.6.4/go.mod"
	"github.com/cockroachdb/apd v1.1.0"
	"github.com/cockroachdb/apd v1.1.0/go.mod"
	"github.com/coreos/go-systemd v0.0.0-20190321100706-95778dfbb74e/go.mod"
	"github.com/coreos/go-systemd v0.0.0-20190719114852-fd7a80b32e1f/go.mod"
	"github.com/coreos/go-systemd/v22 v22.5.0"
	"github.com/coreos/go-systemd/v22 v22.5.0/go.mod"
	"github.com/creack/pty v1.1.7/go.mod"
	"github.com/creack/pty v1.1.9/go.mod"
	"github.com/davecgh/go-spew v1.1.0/go.mod"
	"github.com/davecgh/go-spew v1.1.1"
	"github.com/davecgh/go-spew v1.1.1/go.mod"
	"github.com/dgryski/go-metro v0.0.0-20180109044635-280f6062b5bc"
	"github.com/dgryski/go-metro v0.0.0-20180109044635-280f6062b5bc/go.mod"
	"github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f"
	"github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f/go.mod"
	"github.com/docker/distribution v2.8.2+incompatible"
	"github.com/docker/distribution v2.8.2+incompatible/go.mod"
	"github.com/docker/docker v24.0.7+incompatible"
	"github.com/docker/docker v24.0.7+incompatible/go.mod"
	"github.com/docker/go-connections v0.4.0"
	"github.com/docker/go-connections v0.4.0/go.mod"
	"github.com/docker/go-units v0.4.0"
	"github.com/docker/go-units v0.4.0/go.mod"
	"github.com/emicklei/go-restful/v3 v3.9.0"
	"github.com/emicklei/go-restful/v3 v3.9.0/go.mod"
	"github.com/evanphx/json-patch v5.6.0+incompatible"
	"github.com/evanphx/json-patch v5.6.0+incompatible/go.mod"
	"github.com/facebook/time v0.0.0-20230914161634-c95c229720fd"
	"github.com/facebook/time v0.0.0-20230914161634-c95c229720fd/go.mod"
	"github.com/fsnotify/fsnotify v1.7.0"
	"github.com/fsnotify/fsnotify v1.7.0/go.mod"
	"github.com/go-kit/log v0.1.0/go.mod"
	"github.com/go-logfmt/logfmt v0.5.0/go.mod"
	"github.com/go-logr/logr v1.2.0/go.mod"
	"github.com/go-logr/logr v1.2.4"
	"github.com/go-logr/logr v1.2.4/go.mod"
	"github.com/go-openapi/jsonpointer v0.19.6"
	"github.com/go-openapi/jsonpointer v0.19.6/go.mod"
	"github.com/go-openapi/jsonreference v0.20.2"
	"github.com/go-openapi/jsonreference v0.20.2/go.mod"
	"github.com/go-openapi/swag v0.22.3"
	"github.com/go-openapi/swag v0.22.3/go.mod"
	"github.com/go-redis/redis/v8 v8.11.5"
	"github.com/go-redis/redis/v8 v8.11.5/go.mod"
	"github.com/go-sql-driver/mysql v1.7.1"
	"github.com/go-sql-driver/mysql v1.7.1/go.mod"
	"github.com/go-stack/stack v1.8.0/go.mod"
	"github.com/go-task/slim-sprig v0.0.0-20230315185526-52ccab3ef572"
	"github.com/go-task/slim-sprig v0.0.0-20230315185526-52ccab3ef572/go.mod"
	"github.com/godbus/dbus/v5 v5.0.4/go.mod"
	"github.com/godbus/dbus/v5 v5.1.0"
	"github.com/godbus/dbus/v5 v5.1.0/go.mod"
	"github.com/gofrs/flock v0.8.1"
	"github.com/gofrs/flock v0.8.1/go.mod"
	"github.com/gofrs/uuid v4.0.0+incompatible"
	"github.com/gofrs/uuid v4.0.0+incompatible/go.mod"
	"github.com/gogo/protobuf v1.3.2"
	"github.com/gogo/protobuf v1.3.2/go.mod"
	"github.com/golang/mock v1.6.0"
	"github.com/golang/mock v1.6.0/go.mod"
	"github.com/golang/protobuf v1.3.1/go.mod"
	"github.com/golang/protobuf v1.3.5/go.mod"
	"github.com/golang/protobuf v1.5.0/go.mod"
	"github.com/golang/protobuf v1.5.3"
	"github.com/golang/protobuf v1.5.3/go.mod"
	"github.com/golang/snappy v0.0.1/go.mod"
	"github.com/golang/snappy v0.0.4"
	"github.com/golang/snappy v0.0.4/go.mod"
	"github.com/google/certificate-transparency-go v1.1.4"
	"github.com/google/certificate-transparency-go v1.1.4/go.mod"
	"github.com/google/gnostic-models v0.6.8"
	"github.com/google/gnostic-models v0.6.8/go.mod"
	"github.com/google/go-cmp v0.5.2/go.mod"
	"github.com/google/go-cmp v0.5.5/go.mod"
	"github.com/google/go-cmp v0.6.0"
	"github.com/google/go-cmp v0.6.0/go.mod"
	"github.com/google/gofuzz v1.0.0/go.mod"
	"github.com/google/gofuzz v1.2.0"
	"github.com/google/gofuzz v1.2.0/go.mod"
	"github.com/google/pprof v0.0.0-20220520215854-d04f2422c8a1"
	"github.com/google/pprof v0.0.0-20220520215854-d04f2422c8a1/go.mod"
	"github.com/google/renameio v0.1.0/go.mod"
	"github.com/google/uuid v1.1.1/go.mod"
	"github.com/google/uuid v1.3.1"
	"github.com/google/uuid v1.3.1/go.mod"
	"github.com/gosnmp/gosnmp v1.37.0"
	"github.com/gosnmp/gosnmp v1.37.0/go.mod"
	"github.com/grafana/regexp v0.0.0-20220304095617-2e8d9baf4ac2"
	"github.com/grafana/regexp v0.0.0-20220304095617-2e8d9baf4ac2/go.mod"
	"github.com/huandu/xstrings v1.3.3"
	"github.com/huandu/xstrings v1.3.3/go.mod"
	"github.com/ilyam8/hashstructure v1.1.0"
	"github.com/ilyam8/hashstructure v1.1.0/go.mod"
	"github.com/imdario/mergo v0.3.11/go.mod"
	"github.com/imdario/mergo v0.3.12"
	"github.com/imdario/mergo v0.3.12/go.mod"
	"github.com/jackc/chunkreader v1.0.0/go.mod"
	"github.com/jackc/chunkreader/v2 v2.0.0/go.mod"
	"github.com/jackc/chunkreader/v2 v2.0.1"
	"github.com/jackc/chunkreader/v2 v2.0.1/go.mod"
	"github.com/jackc/pgconn v0.0.0-20190420214824-7e0022ef6ba3/go.mod"
	"github.com/jackc/pgconn v0.0.0-20190824142844-760dd75542eb/go.mod"
	"github.com/jackc/pgconn v0.0.0-20190831204454-2fabfa3c18b7/go.mod"
	"github.com/jackc/pgconn v1.8.0/go.mod"
	"github.com/jackc/pgconn v1.9.0/go.mod"
	"github.com/jackc/pgconn v1.9.1-0.20210724152538-d89c8390a530/go.mod"
	"github.com/jackc/pgconn v1.14.0"
	"github.com/jackc/pgconn v1.14.0/go.mod"
	"github.com/jackc/pgio v1.0.0"
	"github.com/jackc/pgio v1.0.0/go.mod"
	"github.com/jackc/pgmock v0.0.0-20190831213851-13a1b77aafa2/go.mod"
	"github.com/jackc/pgmock v0.0.0-20201204152224-4fe30f7445fd/go.mod"
	"github.com/jackc/pgmock v0.0.0-20210724152146-4ad1a8207f65"
	"github.com/jackc/pgmock v0.0.0-20210724152146-4ad1a8207f65/go.mod"
	"github.com/jackc/pgpassfile v1.0.0"
	"github.com/jackc/pgpassfile v1.0.0/go.mod"
	"github.com/jackc/pgproto3 v1.1.0/go.mod"
	"github.com/jackc/pgproto3/v2 v2.0.0-alpha1.0.20190420180111-c116219b62db/go.mod"
	"github.com/jackc/pgproto3/v2 v2.0.0-alpha1.0.20190609003834-432c2951c711/go.mod"
	"github.com/jackc/pgproto3/v2 v2.0.0-rc3/go.mod"
	"github.com/jackc/pgproto3/v2 v2.0.0-rc3.0.20190831210041-4c03ce451f29/go.mod"
	"github.com/jackc/pgproto3/v2 v2.0.6/go.mod"
	"github.com/jackc/pgproto3/v2 v2.1.1/go.mod"
	"github.com/jackc/pgproto3/v2 v2.3.2"
	"github.com/jackc/pgproto3/v2 v2.3.2/go.mod"
	"github.com/jackc/pgservicefile v0.0.0-20200714003250-2b9c44734f2b/go.mod"
	"github.com/jackc/pgservicefile v0.0.0-20221227161230-091c0ba34f0a"
	"github.com/jackc/pgservicefile v0.0.0-20221227161230-091c0ba34f0a/go.mod"
	"github.com/jackc/pgtype v0.0.0-20190421001408-4ed0de4755e0/go.mod"
	"github.com/jackc/pgtype v0.0.0-20190824184912-ab885b375b90/go.mod"
	"github.com/jackc/pgtype v0.0.0-20190828014616-a8802b16cc59/go.mod"
	"github.com/jackc/pgtype v1.8.1-0.20210724151600-32e20a603178/go.mod"
	"github.com/jackc/pgtype v1.14.0"
	"github.com/jackc/pgtype v1.14.0/go.mod"
	"github.com/jackc/pgx/v4 v4.0.0-20190420224344-cc3461e65d96/go.mod"
	"github.com/jackc/pgx/v4 v4.0.0-20190421002000-1b8f0016e912/go.mod"
	"github.com/jackc/pgx/v4 v4.0.0-pre1.0.20190824185557-6972a5742186/go.mod"
	"github.com/jackc/pgx/v4 v4.12.1-0.20210724153913-640aa07df17c/go.mod"
	"github.com/jackc/pgx/v4 v4.18.1"
	"github.com/jackc/pgx/v4 v4.18.1/go.mod"
	"github.com/jackc/puddle v0.0.0-20190413234325-e4ced69a3a2b/go.mod"
	"github.com/jackc/puddle v0.0.0-20190608224051-11cab39313c9/go.mod"
	"github.com/jackc/puddle v1.1.3/go.mod"
	"github.com/jackc/puddle v1.3.0/go.mod"
	"github.com/jessevdk/go-flags v1.5.0"
	"github.com/jessevdk/go-flags v1.5.0/go.mod"
	"github.com/josharian/intern v1.0.0"
	"github.com/josharian/intern v1.0.0/go.mod"
	"github.com/josharian/native v1.1.0"
	"github.com/josharian/native v1.1.0/go.mod"
	"github.com/json-iterator/go v1.1.12"
	"github.com/json-iterator/go v1.1.12/go.mod"
	"github.com/kisielk/errcheck v1.5.0/go.mod"
	"github.com/kisielk/gotool v1.0.0/go.mod"
	"github.com/klauspost/compress v1.13.6"
	"github.com/klauspost/compress v1.13.6/go.mod"
	"github.com/konsorten/go-windows-terminal-sequences v1.0.1/go.mod"
	"github.com/konsorten/go-windows-terminal-sequences v1.0.2/go.mod"
	"github.com/kr/pretty v0.1.0/go.mod"
	"github.com/kr/pretty v0.2.1/go.mod"
	"github.com/kr/pretty v0.3.1"
	"github.com/kr/pretty v0.3.1/go.mod"
	"github.com/kr/pty v1.1.1/go.mod"
	"github.com/kr/pty v1.1.8/go.mod"
	"github.com/kr/text v0.1.0/go.mod"
	"github.com/kr/text v0.2.0"
	"github.com/kr/text v0.2.0/go.mod"
	"github.com/lib/pq v1.0.0/go.mod"
	"github.com/lib/pq v1.1.0/go.mod"
	"github.com/lib/pq v1.2.0/go.mod"
	"github.com/lib/pq v1.10.2/go.mod"
	"github.com/lib/pq v1.10.9"
	"github.com/lib/pq v1.10.9/go.mod"
	"github.com/likexian/gokit v0.25.13"
	"github.com/likexian/gokit v0.25.13/go.mod"
	"github.com/likexian/whois v1.15.1"
	"github.com/likexian/whois v1.15.1/go.mod"
	"github.com/likexian/whois-parser v1.24.10"
	"github.com/likexian/whois-parser v1.24.10/go.mod"
	"github.com/lmittmann/tint v1.0.3"
	"github.com/lmittmann/tint v1.0.3/go.mod"
	"github.com/mailru/easyjson v0.7.7"
	"github.com/mailru/easyjson v0.7.7/go.mod"
	"github.com/mattn/go-colorable v0.1.1/go.mod"
	"github.com/mattn/go-colorable v0.1.6/go.mod"
	"github.com/mattn/go-isatty v0.0.5/go.mod"
	"github.com/mattn/go-isatty v0.0.7/go.mod"
	"github.com/mattn/go-isatty v0.0.12/go.mod"
	"github.com/mattn/go-isatty v0.0.20"
	"github.com/mattn/go-isatty v0.0.20/go.mod"
	"github.com/mattn/go-runewidth v0.0.10/go.mod"
	"github.com/mattn/go-xmlrpc v0.0.3"
	"github.com/mattn/go-xmlrpc v0.0.3/go.mod"
	"github.com/matttproud/golang_protobuf_extensions v1.0.2"
	"github.com/matttproud/golang_protobuf_extensions v1.0.2/go.mod"
	"github.com/mdlayher/genetlink v1.3.2"
	"github.com/mdlayher/genetlink v1.3.2/go.mod"
	"github.com/mdlayher/netlink v1.7.2"
	"github.com/mdlayher/netlink v1.7.2/go.mod"
	"github.com/mdlayher/socket v0.4.1"
	"github.com/mdlayher/socket v0.4.1/go.mod"
	"github.com/miekg/dns v1.1.57"
	"github.com/miekg/dns v1.1.57/go.mod"
	"github.com/mikioh/ipaddr v0.0.0-20190404000644-d465c8ab6721"
	"github.com/mikioh/ipaddr v0.0.0-20190404000644-d465c8ab6721/go.mod"
	"github.com/mitchellh/copystructure v1.0.0"
	"github.com/mitchellh/copystructure v1.0.0/go.mod"
	"github.com/mitchellh/go-homedir v1.1.0"
	"github.com/mitchellh/go-homedir v1.1.0/go.mod"
	"github.com/mitchellh/reflectwalk v1.0.0/go.mod"
	"github.com/mitchellh/reflectwalk v1.0.1"
	"github.com/mitchellh/reflectwalk v1.0.1/go.mod"
	"github.com/moby/term v0.0.0-20210619224110-3f7ff695adc6"
	"github.com/moby/term v0.0.0-20210619224110-3f7ff695adc6/go.mod"
	"github.com/modern-go/concurrent v0.0.0-20180228061459-e0a39a4cb421/go.mod"
	"github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd"
	"github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd/go.mod"
	"github.com/modern-go/reflect2 v1.0.2"
	"github.com/modern-go/reflect2 v1.0.2/go.mod"
	"github.com/montanaflynn/stats v0.0.0-20171201202039-1bf9dbcd8cbe"
	"github.com/montanaflynn/stats v0.0.0-20171201202039-1bf9dbcd8cbe/go.mod"
	"github.com/morikuni/aec v1.0.0"
	"github.com/morikuni/aec v1.0.0/go.mod"
	"github.com/muesli/cancelreader v0.2.2"
	"github.com/muesli/cancelreader v0.2.2/go.mod"
	"github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822"
	"github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822/go.mod"
	"github.com/nxadm/tail v1.4.8"
	"github.com/nxadm/tail v1.4.8/go.mod"
	"github.com/onsi/ginkgo v1.16.5"
	"github.com/onsi/ginkgo v1.16.5/go.mod"
	"github.com/onsi/ginkgo/v2 v2.9.4"
	"github.com/onsi/ginkgo/v2 v2.9.4/go.mod"
	"github.com/onsi/gomega v1.27.6"
	"github.com/onsi/gomega v1.27.6/go.mod"
	"github.com/opencontainers/go-digest v1.0.0"
	"github.com/opencontainers/go-digest v1.0.0/go.mod"
	"github.com/opencontainers/image-spec v1.0.2"
	"github.com/opencontainers/image-spec v1.0.2/go.mod"
	"github.com/pkg/errors v0.8.1/go.mod"
	"github.com/pkg/errors v0.9.1"
	"github.com/pkg/errors v0.9.1/go.mod"
	"github.com/pmezard/go-difflib v1.0.0"
	"github.com/pmezard/go-difflib v1.0.0/go.mod"
	"github.com/prometheus-community/pro-bing v0.3.0"
	"github.com/prometheus-community/pro-bing v0.3.0/go.mod"
	"github.com/prometheus/client_model v0.3.0"
	"github.com/prometheus/client_model v0.3.0/go.mod"
	"github.com/prometheus/common v0.37.0"
	"github.com/prometheus/common v0.37.0/go.mod"
	"github.com/prometheus/prometheus v0.36.2"
	"github.com/prometheus/prometheus v0.36.2/go.mod"
	"github.com/rivo/uniseg v0.1.0/go.mod"
	"github.com/rogpeppe/go-internal v1.3.0/go.mod"
	"github.com/rogpeppe/go-internal v1.10.0"
	"github.com/rogpeppe/go-internal v1.10.0/go.mod"
	"github.com/rs/xid v1.2.1/go.mod"
	"github.com/rs/zerolog v1.13.0/go.mod"
	"github.com/rs/zerolog v1.15.0/go.mod"
	"github.com/satori/go.uuid v1.2.0/go.mod"
	"github.com/scylladb/termtables v0.0.0-20191203121021-c4c0b6d42ff4/go.mod"
	"github.com/shopspring/decimal v0.0.0-20180709203117-cd690d0c9e24/go.mod"
	"github.com/shopspring/decimal v1.2.0"
	"github.com/shopspring/decimal v1.2.0/go.mod"
	"github.com/sirupsen/logrus v1.4.1/go.mod"
	"github.com/sirupsen/logrus v1.4.2/go.mod"
	"github.com/sirupsen/logrus v1.7.0/go.mod"
	"github.com/sirupsen/logrus v1.8.1"
	"github.com/sirupsen/logrus v1.8.1/go.mod"
	"github.com/spf13/cast v1.3.1"
	"github.com/spf13/cast v1.3.1/go.mod"
	"github.com/spf13/pflag v1.0.5"
	"github.com/spf13/pflag v1.0.5/go.mod"
	"github.com/stretchr/objx v0.1.0/go.mod"
	"github.com/stretchr/objx v0.1.1/go.mod"
	"github.com/stretchr/objx v0.2.0/go.mod"
	"github.com/stretchr/objx v0.4.0/go.mod"
	"github.com/stretchr/objx v0.5.0/go.mod"
	"github.com/stretchr/testify v1.2.2/go.mod"
	"github.com/stretchr/testify v1.3.0/go.mod"
	"github.com/stretchr/testify v1.4.0/go.mod"
	"github.com/stretchr/testify v1.5.1/go.mod"
	"github.com/stretchr/testify v1.7.0/go.mod"
	"github.com/stretchr/testify v1.7.1/go.mod"
	"github.com/stretchr/testify v1.8.0/go.mod"
	"github.com/stretchr/testify v1.8.1/go.mod"
	"github.com/stretchr/testify v1.8.4"
	"github.com/stretchr/testify v1.8.4/go.mod"
	"github.com/tomasen/fcgi_client v0.0.0-20180423082037-2bb3d819fd19"
	"github.com/tomasen/fcgi_client v0.0.0-20180423082037-2bb3d819fd19/go.mod"
	"github.com/valyala/fastjson v1.6.4"
	"github.com/valyala/fastjson v1.6.4/go.mod"
	"github.com/vmware/govmomi v0.33.1"
	"github.com/vmware/govmomi v0.33.1/go.mod"
	"github.com/xdg-go/pbkdf2 v1.0.0"
	"github.com/xdg-go/pbkdf2 v1.0.0/go.mod"
	"github.com/xdg-go/scram v1.1.2"
	"github.com/xdg-go/scram v1.1.2/go.mod"
	"github.com/xdg-go/stringprep v1.0.4"
	"github.com/xdg-go/stringprep v1.0.4/go.mod"
	"github.com/youmark/pkcs8 v0.0.0-20181117223130-1be2e3e5546d"
	"github.com/youmark/pkcs8 v0.0.0-20181117223130-1be2e3e5546d/go.mod"
	"github.com/yuin/goldmark v1.1.27/go.mod"
	"github.com/yuin/goldmark v1.2.1/go.mod"
	"github.com/yuin/goldmark v1.3.5/go.mod"
	"github.com/yuin/goldmark v1.4.13/go.mod"
	"github.com/zenazn/goji v0.9.0/go.mod"
	"go.mongodb.org/mongo-driver v1.13.0"
	"go.mongodb.org/mongo-driver v1.13.0/go.mod"
	"go.uber.org/atomic v1.3.2/go.mod"
	"go.uber.org/atomic v1.4.0/go.mod"
	"go.uber.org/atomic v1.5.0/go.mod"
	"go.uber.org/atomic v1.6.0/go.mod"
	"go.uber.org/multierr v1.1.0/go.mod"
	"go.uber.org/multierr v1.3.0/go.mod"
	"go.uber.org/multierr v1.5.0/go.mod"
	"go.uber.org/tools v0.0.0-20190618225709-2cfd321de3ee/go.mod"
	"go.uber.org/zap v1.9.1/go.mod"
	"go.uber.org/zap v1.10.0/go.mod"
	"go.uber.org/zap v1.13.0/go.mod"
	"golang.org/x/crypto v0.0.0-20190308221718-c2843e01d9a2/go.mod"
	"golang.org/x/crypto v0.0.0-20190411191339-88737f569e3a/go.mod"
	"golang.org/x/crypto v0.0.0-20190510104115-cbcb75029529/go.mod"
	"golang.org/x/crypto v0.0.0-20190820162420-60c769a6c586/go.mod"
	"golang.org/x/crypto v0.0.0-20191011191535-87dc89f01550/go.mod"
	"golang.org/x/crypto v0.0.0-20200622213623-75b288015ac9/go.mod"
	"golang.org/x/crypto v0.0.0-20201203163018-be400aefbc4c/go.mod"
	"golang.org/x/crypto v0.0.0-20210616213533-5ff15b29337e/go.mod"
	"golang.org/x/crypto v0.0.0-20210711020723-a769d52b0f97/go.mod"
	"golang.org/x/crypto v0.0.0-20210921155107-089bfa567519/go.mod"
	"golang.org/x/crypto v0.0.0-20220622213112-05595931fe9d/go.mod"
	"golang.org/x/crypto v0.3.0/go.mod"
	"golang.org/x/crypto v0.6.0/go.mod"
	"golang.org/x/crypto v0.16.0"
	"golang.org/x/crypto v0.16.0/go.mod"
	"golang.org/x/lint v0.0.0-20190930215403-16217165b5de/go.mod"
	"golang.org/x/mod v0.0.0-20190513183733-4bf6d317e70e/go.mod"
	"golang.org/x/mod v0.1.1-0.20191105210325-c90efee705ee/go.mod"
	"golang.org/x/mod v0.2.0/go.mod"
	"golang.org/x/mod v0.3.0/go.mod"
	"golang.org/x/mod v0.4.2/go.mod"
	"golang.org/x/mod v0.6.0-dev.0.20220419223038-86c51ed26bb4/go.mod"
	"golang.org/x/mod v0.13.0"
	"golang.org/x/mod v0.13.0/go.mod"
	"golang.org/x/net v0.0.0-20190311183353-d8887717615a/go.mod"
	"golang.org/x/net v0.0.0-20190404232315-eb5bcb51f2a3/go.mod"
	"golang.org/x/net v0.0.0-20190603091049-60506f45cf65/go.mod"
	"golang.org/x/net v0.0.0-20190620200207-3b0461eec859/go.mod"
	"golang.org/x/net v0.0.0-20190813141303-74dc4d7220e7/go.mod"
	"golang.org/x/net v0.0.0-20200226121028-0de0cce0169b/go.mod"
	"golang.org/x/net v0.0.0-20201021035429-f5854403a974/go.mod"
	"golang.org/x/net v0.0.0-20210226172049-e18ecbb05110/go.mod"
	"golang.org/x/net v0.0.0-20210405180319-a5a99cb37ef4/go.mod"
	"golang.org/x/net v0.0.0-20211112202133-69e39bad7dc2/go.mod"
	"golang.org/x/net v0.0.0-20220722155237-a158d28d115b/go.mod"
	"golang.org/x/net v0.2.0/go.mod"
	"golang.org/x/net v0.6.0/go.mod"
	"golang.org/x/net v0.19.0"
	"golang.org/x/net v0.19.0/go.mod"
	"golang.org/x/oauth2 v0.8.0"
	"golang.org/x/oauth2 v0.8.0/go.mod"
	"golang.org/x/sync v0.0.0-20190423024810-112230192c58/go.mod"
	"golang.org/x/sync v0.0.0-20190911185100-cd5d95a43a6e/go.mod"
	"golang.org/x/sync v0.0.0-20201020160332-67f06af15bc9/go.mod"
	"golang.org/x/sync v0.0.0-20210220032951-036812b2e83c/go.mod"
	"golang.org/x/sync v0.0.0-20220722155255-886fb9371eb4/go.mod"
	"golang.org/x/sync v0.4.0"
	"golang.org/x/sync v0.4.0/go.mod"
	"golang.org/x/sys v0.0.0-20180905080454-ebe1bf3edb33/go.mod"
	"golang.org/x/sys v0.0.0-20190215142949-d0b11bdaac8a/go.mod"
	"golang.org/x/sys v0.0.0-20190222072716-a9d3bda3a223/go.mod"
	"golang.org/x/sys v0.0.0-20190403152447-81d4e9dc473e/go.mod"
	"golang.org/x/sys v0.0.0-20190412213103-97732733099d/go.mod"
	"golang.org/x/sys v0.0.0-20190422165155-953cdadca894/go.mod"
	"golang.org/x/sys v0.0.0-20190813064441-fde4db37ae7a/go.mod"
	"golang.org/x/sys v0.0.0-20191026070338-33540a1f6037/go.mod"
	"golang.org/x/sys v0.0.0-20200116001909-b77594299b42/go.mod"
	"golang.org/x/sys v0.0.0-20200223170610-d5e6a3e2c0ae/go.mod"
	"golang.org/x/sys v0.0.0-20200930185726-fdedc70b468f/go.mod"
	"golang.org/x/sys v0.0.0-20201119102817-f84b799fce68/go.mod"
	"golang.org/x/sys v0.0.0-20210124154548-22da62e12c0c/go.mod"
	"golang.org/x/sys v0.0.0-20210320140829-1e4c9ba3b0c4/go.mod"
	"golang.org/x/sys v0.0.0-20210330210617-4fbd30eecc44/go.mod"
	"golang.org/x/sys v0.0.0-20210423082822-04245dca01da/go.mod"
	"golang.org/x/sys v0.0.0-20210510120138-977fb7262007/go.mod"
	"golang.org/x/sys v0.0.0-20210615035016-665e8c7367d1/go.mod"
	"golang.org/x/sys v0.0.0-20210616094352-59db8d763f22/go.mod"
	"golang.org/x/sys v0.0.0-20220520151302-bc2c85ada10a/go.mod"
	"golang.org/x/sys v0.0.0-20220722155257-8c9f86f7a55f/go.mod"
	"golang.org/x/sys v0.2.0/go.mod"
	"golang.org/x/sys v0.5.0/go.mod"
	"golang.org/x/sys v0.6.0/go.mod"
	"golang.org/x/sys v0.15.0"
	"golang.org/x/sys v0.15.0/go.mod"
	"golang.org/x/term v0.0.0-20201117132131-f5c789dd3221/go.mod"
	"golang.org/x/term v0.0.0-20201126162022-7de9c90e9dd1/go.mod"
	"golang.org/x/term v0.0.0-20210927222741-03fcf44c2211/go.mod"
	"golang.org/x/term v0.2.0/go.mod"
	"golang.org/x/term v0.5.0/go.mod"
	"golang.org/x/term v0.15.0"
	"golang.org/x/term v0.15.0/go.mod"
	"golang.org/x/text v0.3.0/go.mod"
	"golang.org/x/text v0.3.2/go.mod"
	"golang.org/x/text v0.3.3/go.mod"
	"golang.org/x/text v0.3.4/go.mod"
	"golang.org/x/text v0.3.6/go.mod"
	"golang.org/x/text v0.3.7/go.mod"
	"golang.org/x/text v0.3.8/go.mod"
	"golang.org/x/text v0.4.0/go.mod"
	"golang.org/x/text v0.7.0/go.mod"
	"golang.org/x/text v0.14.0"
	"golang.org/x/text v0.14.0/go.mod"
	"golang.org/x/time v0.3.0"
	"golang.org/x/time v0.3.0/go.mod"
	"golang.org/x/tools v0.0.0-20180917221912-90fa682c2a6e/go.mod"
	"golang.org/x/tools v0.0.0-20190311212946-11955173bddd/go.mod"
	"golang.org/x/tools v0.0.0-20190425163242-31fd60d6bfdc/go.mod"
	"golang.org/x/tools v0.0.0-20190621195816-6e04913cbbac/go.mod"
	"golang.org/x/tools v0.0.0-20190823170909-c4a336ef6a2f/go.mod"
	"golang.org/x/tools v0.0.0-20191029041327-9cc4af7d6b2c/go.mod"
	"golang.org/x/tools v0.0.0-20191029190741-b9c20aec41a5/go.mod"
	"golang.org/x/tools v0.0.0-20191119224855-298f0cb1881e/go.mod"
	"golang.org/x/tools v0.0.0-20200103221440-774c71fcf114/go.mod"
	"golang.org/x/tools v0.0.0-20200619180055-7c47624df98f/go.mod"
	"golang.org/x/tools v0.0.0-20210106214847-113979e3529a/go.mod"
	"golang.org/x/tools v0.1.1/go.mod"
	"golang.org/x/tools v0.1.12/go.mod"
	"golang.org/x/tools v0.14.0"
	"golang.org/x/tools v0.14.0/go.mod"
	"golang.org/x/xerrors v0.0.0-20190410155217-1f06c39b4373/go.mod"
	"golang.org/x/xerrors v0.0.0-20190510150013-5403a72a6aaf/go.mod"
	"golang.org/x/xerrors v0.0.0-20190513163551-3ee3066db522/go.mod"
	"golang.org/x/xerrors v0.0.0-20190717185122-a985d3407aa7/go.mod"
	"golang.org/x/xerrors v0.0.0-20191011141410-1b5146add898/go.mod"
	"golang.org/x/xerrors v0.0.0-20191204190536-9bdfabe68543/go.mod"
	"golang.org/x/xerrors v0.0.0-20200804184101-5ec99f83aff1/go.mod"
	"golang.org/x/xerrors v0.0.0-20220907171357-04be3eba64a2"
	"golang.org/x/xerrors v0.0.0-20220907171357-04be3eba64a2/go.mod"
	"golang.zx2c4.com/wireguard v0.0.0-20230325221338-052af4a8072b"
	"golang.zx2c4.com/wireguard v0.0.0-20230325221338-052af4a8072b/go.mod"
	"golang.zx2c4.com/wireguard/wgctrl v0.0.0-20220504211119-3d4a969bb56b"
	"golang.zx2c4.com/wireguard/wgctrl v0.0.0-20220504211119-3d4a969bb56b/go.mod"
	"google.golang.org/appengine v1.6.7"
	"google.golang.org/appengine v1.6.7/go.mod"
	"google.golang.org/protobuf v1.26.0-rc.1/go.mod"
	"google.golang.org/protobuf v1.26.0/go.mod"
	"google.golang.org/protobuf v1.31.0"
	"google.golang.org/protobuf v1.31.0/go.mod"
	"gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405/go.mod"
	"gopkg.in/check.v1 v1.0.0-20180628173108-788fd7840127/go.mod"
	"gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c"
	"gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c/go.mod"
	"gopkg.in/errgo.v2 v2.1.0/go.mod"
	"gopkg.in/inconshreveable/log15.v2 v2.0.0-20180818164646-67afb5ed74ec/go.mod"
	"gopkg.in/inf.v0 v0.9.1"
	"gopkg.in/inf.v0 v0.9.1/go.mod"
	"gopkg.in/ini.v1 v1.67.0"
	"gopkg.in/ini.v1 v1.67.0/go.mod"
	"gopkg.in/tomb.v1 v1.0.0-20141024135613-dd632973f1e7"
	"gopkg.in/tomb.v1 v1.0.0-20141024135613-dd632973f1e7/go.mod"
	"gopkg.in/yaml.v2 v2.2.2/go.mod"
	"gopkg.in/yaml.v2 v2.2.8/go.mod"
	"gopkg.in/yaml.v2 v2.3.0/go.mod"
	"gopkg.in/yaml.v2 v2.4.0"
	"gopkg.in/yaml.v2 v2.4.0/go.mod"
	"gopkg.in/yaml.v3 v3.0.0-20200313102051-9f266ea9e77c/go.mod"
	"gopkg.in/yaml.v3 v3.0.1"
	"gopkg.in/yaml.v3 v3.0.1/go.mod"
	"gotest.tools/v3 v3.0.3"
	"gotest.tools/v3 v3.0.3/go.mod"
	"honnef.co/go/tools v0.0.1-2019.2.3/go.mod"
	"k8s.io/api v0.28.4"
	"k8s.io/api v0.28.4/go.mod"
	"k8s.io/apimachinery v0.28.4"
	"k8s.io/apimachinery v0.28.4/go.mod"
	"k8s.io/client-go v0.28.4"
	"k8s.io/client-go v0.28.4/go.mod"
	"k8s.io/klog/v2 v2.100.1"
	"k8s.io/klog/v2 v2.100.1/go.mod"
	"k8s.io/kube-openapi v0.0.0-20230717233707-2695361300d9"
	"k8s.io/kube-openapi v0.0.0-20230717233707-2695361300d9/go.mod"
	"k8s.io/utils v0.0.0-20230406110748-d93618cff8a2"
	"k8s.io/utils v0.0.0-20230406110748-d93618cff8a2/go.mod"
	"layeh.com/radius v0.0.0-20190322222518-890bc1058917"
	"layeh.com/radius v0.0.0-20190322222518-890bc1058917/go.mod"
	"sigs.k8s.io/json v0.0.0-20221116044647-bc3834ca7abd"
	"sigs.k8s.io/json v0.0.0-20221116044647-bc3834ca7abd/go.mod"
	"sigs.k8s.io/structured-merge-diff/v4 v4.2.3"
	"sigs.k8s.io/structured-merge-diff/v4 v4.2.3/go.mod"
	"sigs.k8s.io/yaml v1.3.0"
	"sigs.k8s.io/yaml v1.3.0/go.mod"
)

go-module_set_globals

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
	inherit git-r3
else
	SRC_URI="
		https://github.com/netdata/${PN}/releases/download/v${PV}/${PN}-v${PV}.tar.gz -> ${P}.tar.gz
		go? (
			https://github.com/netdata/${GO_D_PLUGIN_PN}/archive/refs/tags/v${GO_D_PLUGIN_PV}.tar.gz -> ${GO_D_PLUGIN_PN}-v${GO_D_PLUGIN_PV}.tar.gz
			${EGO_SUM_SRC_URI}
		)"
	S="${WORKDIR}/${PN}-v${PV}"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv ~x86"
	GO_D_PLUGIN_S="${WORKDIR}/${GO_D_PLUGIN_P}"
	RESTRICT="mirror"
fi

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata
	https://github.com/netdata/go.d.plugin
	https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD"
SLOT="0"
IUSE="bind cloud +compression cpu_flags_x86_sse2 cups +dbengine dhcp dovecot +go ipmi +jsonc mongodb mysql nfacct nodejs nvme podman postgres prometheus +python sensors systemd tor xen"
REQUIRED_USE="
	bind? ( go )
	dhcp? ( go )
	dovecot? ( python )
	mysql? ( go )
	nvme? ( go )
	python? ( ${PYTHON_REQUIRED_USE} )
	sensors? ( python )
	tor? ( python )"

# Most unconditional dependencies are for plugins.d/charts.d.plugin:
RDEPEND="
	acct-group/netdata
	acct-user/netdata[podman?]
	app-alternatives/awk
	app-misc/jq
	>=app-shells/bash-4:0
	dev-libs/libuv:=
	dev-libs/libyaml
	|| (
		net-analyzer/openbsd-netcat
		net-analyzer/netcat6
		net-analyzer/netcat
	)
	net-analyzer/tcpdump
	net-analyzer/traceroute
	net-libs/libwebsockets
	net-misc/curl
	net-misc/wget
	sys-apps/util-linux
	sys-libs/libcap
	sys-libs/zlib
	cloud? ( dev-libs/protobuf:= )
	cups? ( net-print/cups )
	dbengine? (
		app-arch/lz4:=
		dev-libs/judy
		dev-libs/openssl:=
	)
	dhcp? (
		acct-group/dhcp
		acct-user/dhcp
	)
	dovecot? (
		acct-group/dovecot
		acct-group/dovenull
		acct-user/dovecot
	)
	ipmi? ( sys-libs/freeipmi )
	jsonc? ( dev-libs/json-c:= )
	mongodb? ( dev-libs/mongo-c-driver )
	mysql? (
		acct-group/mysql
		acct-user/mysql
	)
	bind? (
		acct-group/named
		net-dns/bind
	)
	nfacct? (
		net-firewall/nfacct
		net-libs/libmnl:=
		net-libs/libnetfilter_acct
	)
	nodejs? ( net-libs/nodejs )
	nvme? (
		app-admin/sudo
		sys-apps/nvme-cli[json]
	)
	podman? (
		app-containers/podman
	)
	prometheus? (
		app-arch/snappy:=
		dev-libs/protobuf:=
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep 'dev-python/pyyaml[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/dnspython[${PYTHON_USEDEP}]')
		mysql? ( $(python_gen_cond_dep 'dev-python/mysqlclient[${PYTHON_USEDEP}]') )
		postgres? ( $(python_gen_cond_dep 'dev-python/psycopg:2[${PYTHON_USEDEP}]') )
		tor? ( $(python_gen_cond_dep 'net-libs/stem[${PYTHON_USEDEP}]') )
	)
	sensors? ( sys-apps/lm-sensors )
	xen? (
		app-emulation/xen-tools
		dev-libs/yajl
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig"
BDEPEND="
	sys-apps/sed
	go? ( >=dev-lang/go-1.21 )"

FILECAPS=(
	'cap_dac_read_search,cap_sys_ptrace+ep'
		'usr/libexec/netdata/plugins.d/apps.plugin'
		'usr/libexec/netdata/plugins.d/debugfs.plugin'
)

PATCHES=(
	"${FILESDIR}/${P}-dbengine.patch"
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
	linux-info_pkg_setup
}

src_unpack() {
	local -x GO_MODULE_SOURCE_DIR="${WORKDIR}/${GO_D_PLUGIN_P}"

	if use go; then
		go-module_src_unpack
	else
		default
	fi
}

src_prepare() {
	default

	# go.d.plugin uses /usr/lib/netdata, whereas netdata itself uses
	# /usr/lib64/netdata (on amd64 platforms) :(
	if use go; then
		pushd "${GO_D_PLUGIN_S}" >/dev/null
		#eapply "${FILESDIR}/${PN}-go-mod-badhash.patch"
		sed -e "/[/]usr[/]lib[/]netdata[/]/s|/lib/|/$(get_libdir)/|" \
			-i Dockerfile.dev cmd/godplugin/main.go examples/simple/main.go ||
				die "go.d.plugin library path update failed: ${?}"
		popd >/dev/null
	fi
	# /etc/netdata/edit_config also uses /usr/lib/netdata...
	sed -e "/[/]usr[/]lib[/]netdata[/]/s|/lib/|/$(get_libdir)/|" \
		-i system/edit-config ||
			die "edit-config library path update failed: ${?}"

	eautoreconf
}

src_configure() {
	if use ppc64; then
		# bundled dlib does not support vsx on big-endian
		# https://github.com/davisking/dlib/issues/397
		[[ $(tc-endian) == big ]] && append-flags -mno-vsx
	fi

	# --enable-lto only appends -flto
	econf \
		--localstatedir="${EPREFIX}"/var \
		--with-user=netdata \
		--without-bundled-protobuf \
		$(use_enable cloud) \
		$(use_enable jsonc) \
		$(use_enable cups plugin-cups) \
		$(use_enable dbengine) \
		$(use_enable nfacct plugin-nfacct) \
		$(use_enable ipmi plugin-freeipmi) \
		--disable-exporting-kinesis \
		--disable-lto \
		$(use_enable mongodb exporting-mongodb) \
		$(use_enable prometheus exporting-prometheus-remote-write) \
		$(use_enable xen plugin-xenstat) \
		$(use_enable cpu_flags_x86_sse2 x86-sse)
}

src_compile() {
	emake clean
	default

	if use go; then
		local -x TRAVIS_TAG="v${GO_D_PLUGIN_PV}"
		pushd "${GO_D_PLUGIN_S}" >/dev/null
		emake clean build
		popd >/dev/null
	fi
}

src_test() {
	if use go; then
		pushd "${GO_D_PLUGIN_S}" >/dev/null
		ego test ./... -race -cover -covermode=atomic
		popd >/dev/null
	fi
}

src_install() {
	local dir=''

	default

	if use go; then
		pushd "${GO_D_PLUGIN_S}" >/dev/null

		einstalldocs

		exeinto /usr/libexec/netdata/plugins.d
		newexe bin/godplugin go.d.plugin
		insinto /usr/$(get_libdir)/netdata/conf.d
		doins -r config/go.d

		popd >/dev/null
	fi

	# Remove unneeded .keep files
	find "${ED}" -name ".keep" -delete || die

	insinto /etc/cron.d
	doins "${ED}"/usr/$(get_libdir)/netdata/system/cron/netdata-updater-daily

	if use nvme; then
		echo 'netdata ALL=(root) NOPASSWD: /usr/sbin/nvme' > "${T}"/nvme
		insinto /etc/sudoers.d
		doins "${T}"/nvme
	fi

	#rm -r "${ED}"/usr/share/netdata/web/old
	rm \
		"${ED}"/usr/libexec/netdata/charts.d/README.md \
		"${ED}"/usr/libexec/netdata/node.d/README.md \
		"${ED}"/usr/libexec/netdata/plugins.d/README.md

	if ! use nodejs; then
		rm -r "${ED}"/usr/libexec/netdata/node.d
		rm "${ED}"/usr/libexec/netdata/plugins.d/node.d.plugin
	fi

	rm -r \
		"${ED}"/usr/$(get_libdir)/netdata/system

	# netdata includes 'web root owner' settings, but ignores them and
	# fails to serve its pages if netdata:netdata isn't the owner :(
	#fowners -Rc netdata:netdata /usr/share/netdata/web ||
	#	die "Failed settings owners: ${?}"

	rmdir -p "${ED}"/var/log "${ED}"/var/cache 2>/dev/null

	for dir in log/netdata lib/netdata/registry $(usex cloud 'lib/netdata/cloud.d' ''); do
		keepdir "/var/${dir}" || die
		fowners -Rc netdata:netdata "/var/${dir}" || die
	done
	fowners -Rc netdata:netdata /var/lib/netdata || die

	fowners -Rc root:netdata /usr/share/netdata || die

	#newinitd system/openrc/init.d/netdata ${PN}
	#newconfd system/openrc/conf.d/netdata ${PN}
	newinitd "${FILESDIR}/${PN}.initd-r1" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"
	if use systemd; then
		systemd_dounit system/systemd/netdata.service
		systemd_dounit system/systemd/netdata-updater.service
		systemd_dounit system/systemd/netdata-updater.timer
	fi
	insinto /etc/netdata
	doins system/netdata.conf

	echo "CONFIG_PROTECT=\"${EPREFIX}/usr/libexec/netdata/conf.d\"" > \
		"${T}"/99netdata
	doenvd "${T}"/99netdata
}

pkg_postinst() {
	fcaps_pkg_postinst

	if use nfacct ; then
		fcaps 'cap_net_admin' 'usr/libexec/netdata/plugins.d/nfacct.plugin'
	fi

	if use xen ; then
		fcaps 'cap_dac_override' 'usr/libexec/netdata/plugins.d/xenstat.plugin'
	fi

	if use ipmi ; then
	    fcaps 'cap_dac_override' 'usr/libexec/netdata/plugins.d/freeipmi.plugin'
	fi
}

# vi: set diffopt=filler,iwhite:
