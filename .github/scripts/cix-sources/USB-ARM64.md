# Focused CIX ARM64 USB compilation

`cix-usb-arm64.yml` is already registered on `master` and remains manual-only.
One native `ubuntu-24.04-arm` job compiles 6.18.57, 6.18.58 and 7.2.12
sequentially with GCC, two workers, `CONFIG_WERROR=y` and `W=1`. Each release
has fresh built-in host and modular dual-role configurations. No full kernel,
packages, installation or hardware tests are performed.

The four 6.18 configurations passed native ARM64 compilation, including Kbuild
archive/composite links, in [run 40482020611](https://github.com/srcshelton/gentoo-ebuilds/actions/runs/40482020611)
at `dbc33e01596a64e0d2ed3dfa05a873188a041e6b`. Final `.ko`/modpost and runtime
were not tested. The helper and this document were recovered from that commit:
they were absent at the Phase 2E checkout HEAD,
`9d3fbe91ec2b262226c5b2675b0ff8dd607cce14` (`ci/register-cix-usb-arm64`).

**7.2 ARM64 compilation: NOT RUN.** Phase 2E runs on macOS ARM64 without a
supported native Linux ARM64 compiler. Static checks and complete source
preparation do not qualify compilation. The 6.18 configuration logic is retained.

## Complete source preparation

The helper uses `create-patched-kernel.sh`, each current ebuild's complete
effective stack and Manifest verification: radxa-menu enabled, AML compilation
disabled, no user patches. It records preparation logs, checkout status,
input/archive/effective-source hashes and ordered patch identities separately
under `usb-evidence/<release>/`. It requires exactly one release-appropriate
60020 immediately after 60010, failing before compilation otherwise.

| Input | 6.18.57 | 6.18.58 | 7.2.12 |
| --- | --- | --- | --- |
| Upstream archive | linux-6.18.tar.xz | linux-6.18.tar.xz | linux-7.2.tar.xz |
| Genpatches base + extras | 6.18-65 | 6.18-66 | 7.2-13 |
| CIX pin | bc078a383042a6c14b05c56e12390e422f893088 | same | same |
| Prepared stack with 60020 | 224 patches, position 151 | 225 patches, position 152 | 179 patches, position 100 |

Phase 2E independently prepared the complete current 7.2.12 stack successfully.
Its patch identities/order match the Phase 2D `final-stack.tsv`; 60020 occurs
once at position 100, directly after 60010. No patch, ebuild, Manifest, vendor
pin, substitution or exclusion was changed by Phase 2E.

**Current checkout prerequisite:** its two 6.18 ebuilds do not enable their
60020, and that patch is absent. The successful run's 6.18.57 thermal patch
selection also differs. A reviewable test branch must contain the validated
6.18 inputs from `dbc33e01596a64e0d2ed3dfa05a873188a041e6b` and the Phase 2D
7.2 pilot inputs before dispatch. This task leaves those inputs untouched;
dispatching the present checkout would fail the 6.18 preparation assertions.
The workflow continues to 7.2 and reports an overall failure if either 6.18 fails.

## Kconfig and expected objects

The 7.2 mapping was derived from the freshly prepared source's Cadence and PHY
Kconfig/Makefiles, not from renamed 6.18 symbols. Each profile requests
`allnoconfig` with `KCONFIG_ALLCONFIG`, runs `olddefconfig`, and asserts every
requested enabled and disabled symbol. Missing enabled symbols fail.

| Symbol | Built-in host | Modular dual-role |
| --- | --- | --- |
| USB / USB_COMMON | y | y |
| USB_CDNS_SUPPORT | y | m |
| 6.18: USB_CDNSP / USB_CDNSP_SKY1 | y | m |
| 7.2: USB_CDNS3 / USB_CDNS3_SKY1 | y | m |
| USB_XHCI_HCD / USB_XHCI_PLATFORM | y | m |
| 6.18: USB_CDNSP_HOST / USB_CDNS_HOST | y | y |
| 7.2: USB_CDNS3_HOST | y | y |
| USB_GADGET | n | m |
| 6.18: USB_CDNSP_GADGET | n | y |
| 7.2: USB_CDNS3_GADGET | n | y |
| USB_ROLE_SWITCH / PHY_CIX_USBDP | y | m |
| ARCH_CIX / ACPI / OF / EFI / MODULES / EXPERT | y | y |
| COMMON_CLK / RESET_CONTROLLER / MFD_SYSCON / GENERIC_PHY | y | y |
| 64BIT / ARM64 / PM / SUSPEND / PM_SLEEP / WERROR | y | y |
| USB_PCI / USB_CDNSP_PCI / TYPEC / TRACING | n | n |
| 6.18: USB_CDNS3 | n | n |
| 7.2: USB_CDNS3_PCI_WRAP | n | n |

7.2 has no USB_CDNSP, USB_CDNSP_SKY1, USB_CDNSP_HOST,
USB_CDNSP_GADGET or USB_CDNS_HOST configuration symbols. Its HOST/GADGET
switches are bools inside USB_CDNS3; USB=y satisfies the host dependency,
and USB_GADGET=m equals USB_CDNS3=m for dual-role. CDNS_SUPPORT requires
USB_SUPPORT/HAS_DMA and USB or GADGET, selecting role switch and xHCI platform.
Sky1 requires ARCH_CIX (or COMPILE_TEST), ACPI or OF, clocks, resets and syscon;
it selects the CIX PHY. The PHY selects GENERIC_PHY/REGMAP and permits TYPEC=n.
USB=y also retains the successful 6.18 workaround for its USB=m Makefile behavior.

7.2 built-in Cadence archive members must include `core.o`, `drd.o`,
`cdns3-plat.o`, `host.o` and `cdns3-sky1.o`. In dual-role, `cdns.o` must link
exactly `core.o`, `drd.o`, `cdns3-plat.o`, `host.o`, `cdns3-gadget.o`,
`cdns3-ep0.o`, `cdnsp-ring.o`, `cdnsp-gadget.o`, `cdnsp-mem.o` and `cdnsp-ep0.o`.
Both gadget implementations are included for runtime controller detection.
`cdns3-sky1.o` is a separate module. Tracing and PCI wrappers are disabled.
The helper checks `modules.order`, `.mod` constituent membership and the
actual linked composite object; built-ins use `ar t` membership.

6.18 retains `cdnsp-plat.o`, `cdnsp-sky1.o`, `core.o`, `drd.o`, `host.o`;
its module composites are `cdns-usb-common.o` and `cdnsp.o`, with only the
four CDNSP gadget constituents in dual-role.

Both releases also require AArch64 `xhci.o`, `xhci-plat.o`, USB core `usb.o`,
USB common `common.o`, role-switch `class.o`, `phy-cix-usbdp.o`, `phy-core.o`
and `syscon.o`. Dual-role additionally requires UDC `core.o` and linked
`udc-core.o`. Directory targets let Kbuild select constituents; individual
Cadence object targets are never forced to bypass configuration.

Actual `cdns_resume` and `cdns_power_is_lost` definitions are required.
7.2 also requires the platform system-resume callback and references to both
common recovery functions, retaining PM-path symbol evidence. USB/PHY/syscon
imports must resolve against compiled global subsystem definitions. This
cannot prove generic kernel API/export closure.

## Execution, receipts and limits

Final `.ko`/modpost is **NOT RUN**: `modules_prepare` supplies no matching
whole-kernel export table. There are no fake exports, warning suppressions or
modpost overrides. Preparation, config and build failures keep logs; successful
receipts include requested/resolved configs, hashes, module/archive membership
and symbol checks. Artifacts retain evidence for 14 days. 7.2 also retains its
effective Cadence Kconfig/Makefile. Each release has its own evidence directory.

Preflight requires 20 GiB free: a conservative 10 GiB peak budget and 10 GiB
remaining. Only one release/profile builds at a time; source/downloads/objects
are removed on exit, including failure. No caches or containers are created.
Store local receipts outside temporary storage. `CIX_USB_WORK_PARENT` selects
an existing work filesystem; `CIX_USB_JOBS` retains its existing 1–4 range,
with the workflow fixed at two. Native Linux aarch64 GCC is required.

## Local Phase 2E validation

Passed: complete 7.2 preparation/179-row stack comparison; Bash syntax;
ShellCheck; all four embedded Python blocks; all six profile generators;
byte-identical 6.18 requested configs versus the successful helper; negative
config, composite-member and patch-order cases; actual 7.2 Makefile member
selection; YAML parsing, workflow structure and embedded shell syntax;
`git diff --check`; inventory tests (3) and external-input tests (11).
Synthetic config-verifier tests are not `olddefconfig` results. Actionlint was
unavailable. No actual Linux Kconfig resolution or ARM64 compilation ran.
The owned 1.8 GiB generated source tree was removed after preserving compact
preparation, source-definition and validation evidence under
`.agent-work/01a17d02-6236-7740-8f39-10f5c1af7ec1-usb-2e/`.
No new caches, worktrees, containers or outstanding jobs remain.

## Review and dispatch commands (not executed)

Use a reviewable test branch containing the source prerequisites above. Do not
register another workflow or change `master`. Only these three Phase 2E files
belong in the tooling commit; review the Phase 2D source changes separately.

```sh
# On the prepared test branch, for example codex/cix-usb-arm64-7.2:
git add .github/scripts/cix-sources/qualify-usb-arm64.sh \
  .github/scripts/cix-sources/USB-ARM64.md \
  .github/workflows/cix-usb-arm64.yml
git diff --cached --check
git diff --cached
# After review and separate publication authorization:
git commit -m 'ci: extend CIX ARM64 USB smoke test to 7.2.12 [skip ci]'
git push -u origin codex/cix-usb-arm64-7.2
gh workflow run cix-usb-arm64.yml --repo srcshelton/gentoo-ebuilds \
  --ref codex/cix-usb-arm64-7.2
gh run list --repo srcshelton/gentoo-ebuilds \
  --workflow cix-usb-arm64.yml --branch codex/cix-usb-arm64-7.2
gh run watch RUN_ID --repo srcshelton/gentoo-ebuilds --exit-status
gh run download RUN_ID --repo srcshelton/gentoo-ebuilds \
  --dir .agent-work/usb-arm64-ci-RUN_ID
```

`[skip ci]` avoids automatic package workflows on publication; explicit manual
dispatch still runs. On an existing native Linux ARM64 host, run the helper
with `<release> <new-persistent-evidence-directory>` for each release above.
Use fresh evidence directories on retries.

## Qualification boundary

Hardware runtime remains separate, including both power-loss marker reads
around wrapper restoration/reset, failed recovery followed by retry, host,
gadget and idle roles, runtime/system PM and s2idle versus deep sleep. Source
and compilation evidence cannot settle the marker register's reset/retention
semantics. No driver rewrite, full build, DMA350, AUDSS or 7.3 work is included.
