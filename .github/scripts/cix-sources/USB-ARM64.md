# Focused CIX ARM64 USB compilation

`cix-usb-arm64.yml` is manual-only. One native `ubuntu-24.04-arm` job runs
6.18.57 and 6.18.58 sequentially with GCC and two make workers. Each release
has two fresh out-of-tree configurations; no full kernel or packages are built.

**Initial implementation qualification: compilation NOT RUN.** Shell, embedded
Python and workflow syntax were checked on macOS. No Linux toolchain image was
available locally; Docker had no images/containers. Source preparation results
come from the retained USB pilot and subsequent 6.18.57 compatibility receipt,
not a new preparation/build run.

## Inputs and configuration

The helper runs `create-patched-kernel.sh` with its unchanged default policy:
radxa-menu enabled, no AML compilation, no user patches. It uses each ebuild's
complete genpatches/vendor/replacement/exclusion/post-vendor stack, with Manifest
verification. It does not substitute a vendor-only source tree.

| Input | 6.18.57 | 6.18.58 |
| --- | --- | --- |
| Upstream archive | linux-6.18.tar.xz | linux-6.18.tar.xz |
| Gentoo genpatches base + extras | 6.18-65 | 6.18-66 |
| CIX pin | bc078a383042a6c14b05c56e12390e422f893088 | same |
| Existing complete preparation receipt | 224 patches, 60020 at 151 | 225 patches, 60020 at 152 |

Shared 60020 SHA-256:
`41b9720a9460fae45fbeedeb6a0f17008a95c1cf0aa3c88a0bb774bae968a60a`.
The runtime receipt records checkout revision/status, ebuild/Manifest/helper/
workflow hashes, archive hashes, complete ordered patch identities, effective
Cadence/PHY source hashes, requested and resolved configs and object hashes.
A config identity is only qualified after the real Kconfig run passes.

Each profile starts with `KCONFIG_ALLCONFIG=requested.config make allnoconfig`,
then `make olddefconfig`. Every requested enabled symbol must remain exactly
y/m as requested; missing/disabled drivers fail. Disabled symbols are also
checked. `CONFIG_WERROR=y` and `W=1` are used without warning suppressions.

| Symbol | builtin-host | module-dual |
| --- | --- | --- |
| USB | y | y |
| USB_CDNS_SUPPORT / USB_CDNSP / USB_CDNSP_SKY1 | y | m |
| USB_XHCI_HCD / USB_XHCI_PLATFORM | y | m |
| USB_CDNSP_HOST / USB_CDNS_HOST | y | y |
| USB_GADGET | n | m |
| USB_CDNSP_GADGET | n | y |
| USB_ROLE_SWITCH / PHY_CIX_USBDP | y | m |
| ARCH_CIX / ACPI / OF / EFI | y | y |
| COMMON_CLK / RESET_CONTROLLER / MFD_SYSCON / GENERIC_PHY | y | y |
| PM / SUSPEND / PM_SLEEP / MODULES / WERROR | y | y |
| USB_CDNS3 / USB_CDNSP_PCI / USB_PCI / TYPEC / TRACING | n | n |

The effective CDNSP host Kconfig permits USB=y in both cases. Gadget=m equals
CDNSP=m, satisfying its explicit dependency. Sky1's ARCH_CIX, ACPI/OF, clock,
reset and syscon dependencies are included; its selected CIX USB/DP PHY is
compiled. USB=y in the module case avoids this tree's unconditional cdns3.o
module addition when USB=m. No unrelated board profile is enabled.

The effective Cadence Makefile maps `core.o + drd.o + host.o` into
`cdns-usb-common`, `cdnsp-plat.o` into `cdnsp`, and adds ring/gadget/mem/ep0
objects with CDNSP_GADGET=y. Sky1 adds `cdnsp-sky1.o`. The helper builds the
whole selected directory and asserts these constituent objects, their AArch64
ELF identity, built-in archive membership or module-order entries, and actual
`cdns_resume` / `cdns_power_is_lost` definitions (requiring PM_SLEEP).

It also compiles USB common/core, xHCI host/platform, role switch, CIX and
generic PHY, syscon, and modular gadget UDC objects. A symbol check requires
Cadence's USB/PHY/syscon imports to have compiled global definitions. This is
a bounded subsystem check, not proof of every generic kernel API/export.

## Link scope and retained results

In-tree directory targets perform normal Kbuild composite module-object links
(`cdns-usb-common.o`, `cdnsp.o`, UDC core, etc.). Built-ins are checked in
`built-in.a`. Final `.ko`/modpost is **NOT RUN**: Linux's
`scripts/Makefile.modpost` requires matching `vmlinux.o` (or a matching complete
export table for external modules). `modules_prepare` does not supply it.
Building a whole kernel merely to supply it would exceed this check's scope.
No fake exports or `KBUILD_MODPOST_WARN` workaround is used.

Receipts retain full failure logs, requested/resolved configs, hashes and
membership/symbol summaries for 14 days in the Actions artifact. Build commands
are traced in config/build logs. Source, downloads and objects are disposable
and removed by an EXIT/INT/TERM trap. Each profile's objects are removed before
the next; each release's source is removed before the next release. Abrupt
SIGKILL cannot run traps; the hosted runner is disposable.

Preflight requires 20 GiB free on the work filesystem: a conservative 10 GiB
peak budget plus 10 GiB remaining. No caches or containers are created. Local
receipts must be written outside temporary storage and kept until reviewed.

## Manual execution after separate publication authorization

Nothing has been committed, pushed, dispatched or uploaded by this task.
Review only the intended files before staging. From the overlay root, a future
publication sequence is:

```sh
git switch -c codex/cix-usb-arm64
git add .github/workflows/cix-usb-arm64.yml \
  .github/scripts/cix-sources/qualify-usb-arm64.sh \
  .github/scripts/cix-sources/USB-ARM64.md \
  sys-kernel/cix-sources/cix-sources-6.18.57.ebuild \
  sys-kernel/cix-sources/cix-sources-6.18.58.ebuild \
  sys-kernel/cix-sources/Manifest \
  sys-kernel/cix-sources/files/6.18.x/60020-usb-cdnsp-fix-resume-order-and-v2-marker.patch
git diff --cached --check
git diff --cached --stat
# Inspect the staged diff and preserve unrelated work.
git commit -m 'Qualify audited CIX 6.18 USB compilation [skip ci]'
git push -u origin codex/cix-usb-arm64
```

`[skip ci]` is needed here because existing package workflows also match these
script/ebuild paths. It skips push/PR events and does not suppress an explicit
manual dispatch. See [GitHub skip instructions](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs).

**First-run prerequisite:** GitHub requires a new dispatch workflow on the
default branch before manual dispatch is available. Have the small workflow
and helper reviewed and installed there through a separately authorized
change (also avoiding automatic package builds). Publishing only the feature
branch does not satisfy that prerequisite. Then select the feature branch:

```sh
gh workflow run cix-usb-arm64.yml --repo srcshelton/gentoo-ebuilds \
  --ref codex/cix-usb-arm64
gh run list --repo srcshelton/gentoo-ebuilds \
  --workflow cix-usb-arm64.yml --branch codex/cix-usb-arm64
# Use the returned run ID:
gh run watch RUN_ID --repo srcshelton/gentoo-ebuilds --exit-status
gh run download RUN_ID --repo srcshelton/gentoo-ebuilds \
  --dir .agent-work/usb-arm64-ci-RUN_ID
```

See [GitHub manual workflow execution](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)
for the default-branch requirement and `--ref` behavior.

On an existing native Linux ARM64 machine with the workflow's apt dependencies,
the equivalent commands, from the checkout root, are:

```sh
bash .github/scripts/cix-sources/qualify-usb-arm64.sh \
  6.18.57 "$PWD/.agent-work/usb-arm64-local/6.18.57"
bash .github/scripts/cix-sources/qualify-usb-arm64.sh \
  6.18.58 "$PWD/.agent-work/usb-arm64-local/6.18.58"
```

Use new evidence directories on retries. `CIX_USB_WORK_PARENT` can select an
existing filesystem with sufficient headroom; `CIX_USB_JOBS` accepts 1–4.
The helper rejects non-Linux/non-aarch64 and cross/LLVM/extra compiler flags.

## Runtime qualification remains separate

On genuinely lost power, verify both marker observations: after platform wake
and again inside `cdns_resume()` after platform restoration, PHY reinit and
power-on. Restoration must not make the second read report retained power
before lost-power role recovery. The reviewed Sky1 restore path performs resets
and controller programming without an explicit software marker re-arm; hardware
reset side effects remain unproven. Capture both observations and the recovery
path under separately authorized host/gadget/idle and role-change testing.

No concrete new static defect was established. The implementation of 60020 is
unchanged. Compilation and the existing 34 host contract cases cannot resolve
this runtime uncertainty. Distinguish s2idle from actual supported S3/STR.
