#!/usr/bin/env bash
# Focused native build only: no vmlinux, Debian packages or installation.
set -euo pipefail

fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
[[ $# == 2 ]] || fail "usage: $0 <6.18.57|6.18.58> <new-evidence-directory>"
version=$1
case $version in
	6.18.57|6.18.58) ;;
	*) fail "unsupported release: $version" ;;
esac
[[ $(uname -s) == Linux && $(uname -m) == aarch64 ]] || fail 'native Linux aarch64 required'
[[ -z ${CROSS_COMPILE:-}${LLVM:-}${KCFLAGS:-}${KCPPFLAGS:-}${KBUILD_MODPOST_WARN:-} ]] ||
	fail 'unset cross-compiler, LLVM, extra flags and modpost overrides'
jobs=${CIX_USB_JOBS:-2}
[[ $jobs =~ ^[1-4]$ ]] || fail 'CIX_USB_JOBS must be between 1 and 4'
for tool in gcc ld ar nm readelf make python3 curl patch sha256sum sha512sum b2sum flex bison bc; do
	command -v "$tool" >/dev/null || fail "missing tool: $tool"
done
[[ $(gcc -dumpmachine) == aarch64*-linux-gnu* ]] || fail 'native ARM64 GCC required'
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)
cd "$repo"
[[ ! -e $2 ]] || fail 'evidence directory must be new (never overwrite a receipt)'
mkdir -p -- "$2"
evidence=$(cd -- "$2" && pwd -P)
exec > >(tee "$evidence/run.log") 2>&1
# Receipt is outside disposable work, including on failure. Default /tmp is
# acceptable only for reconstructible source and compiler intermediates.
scratch=''
stage=preflight
finish() {
	local status=$?
	trap - EXIT
	{
		printf '\n%s: %s (exit %s; last stage: %s)\n' "$version" \
			"$([[ $status == 0 ]] && echo PASS || echo FAIL)" "$status" "$stage"
		printf 'Final .ko/modpost: NOT RUN (matching whole-kernel exports unavailable).\n'
		printf 'Runtime: NOT RUN; qualify the two power-loss observations on hardware.\n'
	} >> "$evidence/summary.txt"
	[[ -z $scratch ]] || rm -rf -- "$scratch"
	df -h "$evidence" >> "$evidence/summary.txt"
	cat "$evidence/summary.txt"
	if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
		cat "$evidence/summary.txt" >> "$GITHUB_STEP_SUMMARY"
	fi
	exit "$status"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Budget 10 GiB peak, retaining at least 10 GiB on the work filesystem.
work_parent=${CIX_USB_WORK_PARENT:-${TMPDIR:-/tmp}}
[[ -d $work_parent ]] || fail 'work parent must exist'
df -h "$work_parent" "$evidence" > "$evidence/summary.txt"
free_kib=$(df -Pk "$work_parent" | awk 'END {print $4}')
((free_kib >= 20 * 1024 * 1024)) || fail 'need 20 GiB free before source preparation'
scratch=$(mktemp -d "${work_parent%/}/cix-usb-${version}.XXXXXXXX")
source_dir=$scratch/source
{
	uname -a
	gcc --version
	ld --version
	make --version
	git rev-parse HEAD
	git status --short
	printf 'jobs=%s; scratch=%s; helper defaults: radxa-menu on; AML compilation off\n' "$jobs" "$scratch"
} > "$evidence/environment.txt"
sha256sum "sys-kernel/cix-sources/cix-sources-${version}.ebuild" \
	sys-kernel/cix-sources/Manifest \
	.github/scripts/cix-sources/create-patched-kernel.sh \
	.github/scripts/cix-sources/qualify-usb-arm64.sh \
	.github/workflows/cix-usb-arm64.yml > "$evidence/inputs.sha256"
# Keep downloads until their hashes have been recorded, then remove with work.
stage=preparation
bash .github/scripts/cix-sources/create-patched-kernel.sh \
	--work-dir "$scratch/prepare" --distdir "$scratch/distfiles" \
	--patch-log "$evidence/patch-order.tsv" \
	"sys-kernel/cix-sources/cix-sources-${version}.ebuild" "$source_dir" \
	2>&1 | tee "$evidence/prepare.log"
sha256sum "$scratch"/distfiles/* > "$evidence/distfiles.sha256"
# All applied patches and replacement identities are in patch-order.tsv.
# Retain hashes of effective USB sources, Kconfig and Makefiles as well.
(cd "$source_dir"; find drivers/usb/cdns3 drivers/phy/cix -type f -print0 |
	LC_ALL=C sort -z | xargs -0 sha256sum) > "$evidence/effective-usb.sha256"
python3 - "$evidence/patch-order.tsv" <<'PY'
import csv
import sys
with open(sys.argv[1]) as stream:
    rows = list(csv.DictReader(stream, delimiter='\t'))
name = '60020-usb-cdnsp-fix-resume-order-and-v2-marker.patch'
indices = [i for i, row in enumerate(rows) if row['basename'] == name]
if len(indices) != 1 or indices[0] == 0 or not rows[indices[0]-1]['basename'].startswith('60010-'):
    raise SystemExit('60020 missing, duplicated, or not immediately after 60010')
PY

for profile in builtin-host module-dual; do
	stage=$profile
	result=$evidence/$profile
	build=$scratch/build-$profile
	mkdir -p "$result" "$build"
	mode=y
	gadget=n
	[[ $profile != module-dual ]] || { mode=m; gadget=m; }
	# USB stays built-in in the modular case. USB=m unconditionally adds
	# cdns3.o in this tree's Makefile, even with USB_CDNS3=n.
	cat > "$result/requested.config" <<CONFIG
CONFIG_64BIT=y
CONFIG_ARM64=y
CONFIG_ARCH_CIX=y
CONFIG_MODULES=y
CONFIG_EXPERT=y
CONFIG_EFI=y
CONFIG_ACPI=y
CONFIG_OF=y
CONFIG_PM=y
CONFIG_SUSPEND=y
CONFIG_PM_SLEEP=y
CONFIG_COMMON_CLK=y
CONFIG_RESET_CONTROLLER=y
CONFIG_MFD_SYSCON=y
CONFIG_USB_SUPPORT=y
CONFIG_USB=y
CONFIG_USB_COMMON=y
CONFIG_USB_XHCI_HCD=$mode
CONFIG_USB_XHCI_PLATFORM=$mode
CONFIG_USB_CDNS_SUPPORT=$mode
CONFIG_USB_CDNSP=$mode
CONFIG_USB_CDNSP_SKY1=$mode
CONFIG_USB_CDNSP_HOST=y
CONFIG_USB_CDNS_HOST=y
CONFIG_USB_GADGET=$gadget
CONFIG_USB_CDNSP_GADGET=$([[ $gadget == m ]] && echo y || echo n)
CONFIG_USB_ROLE_SWITCH=$mode
CONFIG_GENERIC_PHY=y
CONFIG_PHY_CIX_USBDP=$mode
CONFIG_WERROR=y
# CONFIG_USB_CDNS3 is not set
# CONFIG_USB_CDNSP_PCI is not set
# CONFIG_USB_PCI is not set
# CONFIG_TYPEC is not set
# CONFIG_TRACING is not set
CONFIG
	kmake=(make -C "$source_dir" O="$build" ARCH=arm64 CC=gcc HOSTCC=gcc LD=ld HOSTLD=ld AR=ar NM=nm OBJCOPY=objcopy OBJDUMP=objdump READELF=readelf STRIP=strip)
	{
		set -x
		KCONFIG_ALLCONFIG="$result/requested.config" "${kmake[@]}" allnoconfig
		"${kmake[@]}" olddefconfig
	} > "$result/config.log" 2>&1
	cp "$build/.config" "$result/resolved.config"
	python3 - "$result" <<'PY' | tee "$result/config-verification.txt"
from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
def read(path):
    result = {}
    for line in path.read_text().splitlines():
        if line.startswith('CONFIG_'):
            key, value = line.split('=', 1)
            result[key] = value
        elif match := re.fullmatch(r'# (CONFIG_\w+) is not set', line):
            result[match[1]] = 'n'
    return result
wanted = read(root / 'requested.config')
actual = read(root / 'resolved.config')
for key, value in wanted.items():
    # Kconfig may omit invisible disabled symbols, but must not drop any
    # requested enabled symbol. Missing is equivalent to n only for n.
    found = actual.get(key, 'n')
    print(f'{key}: requested={value} resolved={found}')
    if found != value:
        raise SystemExit(f'{key}: expected {value}, got {found}')
PY
	# Directory targets run normal in-tree Kbuild, compiling all constituents
	# and linking module composites, without invoking final modpost/vmlinux.
	targets=(drivers/usb/cdns3/ drivers/usb/common/ drivers/usb/core/
		drivers/usb/host/ drivers/usb/roles/ drivers/phy/cix/
		drivers/phy/phy-core.o drivers/mfd/syscon.o)
	[[ $gadget != m ]] || targets+=(drivers/usb/gadget/udc/)
	{
		set -x
		"${kmake[@]}" -j"$jobs" prepare modules_prepare
		"${kmake[@]}" -j"$jobs" W=1 "${targets[@]}"
	} 2>&1 | tee "$result/build.log"
	# Inspect outputs chosen by Kconfig/Makefiles, never force the three .o
	# targets independently (that could hide a missing Kconfig dependency).
	expected=(drivers/usb/cdns3/cdnsp-plat.o drivers/usb/cdns3/core.o
		drivers/usb/cdns3/drd.o drivers/usb/cdns3/host.o
		drivers/usb/cdns3/cdnsp-sky1.o drivers/usb/host/xhci.o
		drivers/usb/host/xhci-plat.o drivers/usb/core/usb.o
		drivers/usb/common/common.o drivers/usb/roles/class.o
		drivers/phy/cix/phy-cix-usbdp.o drivers/phy/phy-core.o drivers/mfd/syscon.o)
	if [[ $gadget == m ]]; then
		expected+=(drivers/usb/cdns3/cdnsp-ring.o drivers/usb/cdns3/cdnsp-gadget.o
			drivers/usb/cdns3/cdnsp-mem.o drivers/usb/cdns3/cdnsp-ep0.o
			drivers/usb/gadget/udc/core.o drivers/usb/gadget/udc/udc-core.o
			drivers/usb/cdns3/cdns-usb-common.o
			drivers/usb/cdns3/cdnsp.o)
		cp "$build/drivers/usb/cdns3/modules.order" "$result/modules.order"
		for module in cdns-usb-common cdnsp cdnsp-sky1; do
			grep -Fx "drivers/usb/cdns3/$module.o" "$result/modules.order" >/dev/null ||
				fail "missing module target: $module"
			cp "$build/drivers/usb/cdns3/$module.mod" "$result/"
		done
	else
		ar t "$build/drivers/usb/cdns3/built-in.a" > "$result/archive-members.txt"
		for member in core drd host cdnsp-plat cdnsp-sky1; do
			grep -E "(^|/)$member.o$" "$result/archive-members.txt" >/dev/null ||
				fail "missing built-in archive member: $member"
		done
	fi
	for object in "${expected[@]}"; do
		[[ -s $build/$object ]] || fail "omitted object: $object"
		readelf -h "$build/$object" | grep -q 'Machine:.*AArch64' || fail "not ARM64: $object"
		(cd "$build"; sha256sum "$object") >> "$result/objects.sha256"
	done
	# These global definitions are inside CONFIG_PM_SLEEP; require actual
	# resume code as well as the containing translation units.
	nm --defined-only "$build/drivers/usb/cdns3/core.o" | grep -q ' T cdns_resume$' || fail 'cdns_resume omitted'
	nm --defined-only "$build/drivers/usb/cdns3/drd.o" | grep -q ' T cdns_power_is_lost$' || fail 'marker reader omitted'
	# Check subsystem-local symbol closure against real compiled definitions.
	# Generic kernel APIs still require a complete kernel's export table;
	# this check deliberately does not manufacture one or downgrade modpost.
	python3 - "$build" <<'PYCODE' | tee "$result/usb-symbols.txt"
from pathlib import Path
import subprocess
import sys
root = Path(sys.argv[1])
objects = sorted((root / 'drivers/usb').rglob('*.o'))
objects += sorted((root / 'drivers/phy').rglob('*.o'))
objects += [root / 'drivers/mfd/syscon.o']
def symbols(path, flag):
    text = subprocess.check_output(['nm', flag, str(path)], text=True)
    return {line.split()[-1] for line in text.splitlines() if line.split()}
defined = set()
for path in objects:
    # Global definitions only: local static names cannot resolve imports.
    text = subprocess.check_output(['nm', '-g', '--defined-only', str(path)], text=True)
    defined.update(line.split()[-1] for line in text.splitlines() if line.split())
imports = set()
for path in (root / 'drivers/usb/cdns3').glob('*.o'):
    imports.update(symbols(path, '-u'))
prefixes = ('cdns_', 'cdns3_', 'cdnsp_', 'usb_', '__usb_', 'xhci_', 'phy_', 'syscon_')
relevant = {name for name in imports if name.startswith(prefixes)}
for name in sorted(relevant):
    print(f'{name}: {"resolved" if name in defined else "MISSING"}')
missing = relevant - defined
if missing:
    raise SystemExit('unresolved USB/PHY/syscon dependencies: ' + ', '.join(sorted(missing)))
PYCODE
	sha256sum "$result/requested.config" "$result/resolved.config" > "$result/config.sha256"
	printf '%s %s: PASS (ARM64 objects and Kbuild archive/composite links)\n' "$version" "$profile" >> "$evidence/summary.txt"
	# Keep concise evidence, not regenerable objects, across profiles.
	rm -rf -- "$build"
done
