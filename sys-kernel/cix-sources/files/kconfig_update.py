#!/usr/bin/env python3
"""Generate CIX/Radxa Orion board-profile artifacts.

Default behavior emits a git-style patch suitable for `patch -p1`.
It adds:
  - Radxa Orion board identity options below `ARCH_CIX` in
    `arch/arm64/Kconfig.platforms`
  - `source "drivers/platform/arm64/Kconfig.radxa"`
  - a new `drivers/platform/arm64/Kconfig.radxa`

It can also emit a conservative `.config` fragment for O6/O6N ACPI/DT
profiles or emit/apply a unified diff for an existing `.config`. Source-tree
inspection always uses `--kernel-tree`, so it cleanly supports separate
read-only source trees and out-of-tree `make O=...` build directories.
"""

from __future__ import annotations

import argparse
import difflib
import re
import sys
import textwrap
from pathlib import Path


VENDOR_SYMBOLS = (
    "CIX_MBOX",
    "CLK_SKY1_ACPI",
    "CIX_ACPI_RESOURCE_LOOKUP",
    "CIX_ACPI_PCIE_SCAN",
    "CIX_ACPI_USB_SCAN",
    "CIX_ACPI_GPU_SCAN",
    "SKY1_PDC",
    "DRM_CIX",
    "DRM_CIX_VIRTUAL",
    "DRM_LINLONDP",
    "DRM_TRILIN_DPSUB",
    "SND_HDA_CIX_IPBLOQ",
    "SND_SOC_CIX",
    "SND_SOC_CDNS_I2S_MC",
    "SND_SOC_SKY1_SOUND_CARD",
    "CIX_DSP",
    "CIX_DSP_RPROC",
    "VIDEO_CIX_ARMCB_ISP",
    "TYPEC_RTS5453",
    "USB_CDNSP",
    "USB_CDNSP_SKY1",
    "PHY_CIX_PCIE",
    "PHY_CIX_USB2",
    "PHY_CIX_USB3",
    "PHY_CIX_USBDP",
    "SENSORS_CIX_FAN",
    "CIX_SKY1_REBOOT_REASON",
    "R8126",
)

PATCH_ONLY_DISABLED_SYMBOLS = (
    "EC_ACER_ASPIRE1",
    "EC_HUAWEI_GAOKUN",
    "EC_LENOVO_YOGA_C630",
    "EC_LENOVO_THINKPAD_T14S",
    "I2C_HID_ACPI",
)

ACPI_COMMON_DISABLED_SYMBOLS = (
    "ACPI_AC",
    "ACPI_BATTERY",
    "ACPI_DOCK",
    "ACPI_EC",
    "ACPI_EC_DEBUGFS",
    "ACPI_HOTPLUG_MEMORY",
    "ARM64_ACPI_PARKING_PROTOCOL",
    "KEYBOARD_ATKBD",
    "MOUSE_PS2",
    "PARPORT",
    "PCIEAER",
    "PCIEAER_INJECT",
    "PCIE_ECRC",
    "SERIAL_8250",
    "SERIAL_8250_CONSOLE",
    "SERIAL_8250_PNP",
    "SERIO",
    "SERIO_I8042",
)

ACPI_DT_IDLE_DISABLED_SYMBOLS = (
    # ACPI CPU idle uses ACPI _LPI via the ACPI processor driver and PSCI
    # firmware calls; the PSCI cpuidle driver itself consumes DT idle-state
    # descriptions and is not meaningful for ACPI-only Orion profiles.
    "ARM_PSCI_CPUIDLE",
    "ARM_PSCI_CPUIDLE_DOMAIN",
    "DT_IDLE_STATES",
    "DT_IDLE_GENPD",
)

ACPI_FIRMWARE_ABSENT_DISABLED_SYMBOLS = (
    # Current O6/O6N firmware does not expose ACPI slot _SUN descriptors, a
    # BGRT boot-logo table, APEI/HED error-reporting tables/devices, AGDI,
    # NFIT/NVDIMM, PRMT, ACPI video/backlight, or ACPI PMIC operation regions.
    # Keep these opt-in rather than carrying inert modules in ACPI profiles.
    "ACPI_AGDI",
    "ACPI_APEI",
    "ACPI_APEI_EINJ",
    "ACPI_APEI_EINJ_CXL",
    "ACPI_APEI_ERST_DEBUG",
    "ACPI_APEI_GHES",
    "ACPI_APEI_MEMORY_FAILURE",
    "ACPI_APEI_PCIEAER",
    "ACPI_APEI_SEA",
    "ACPI_BGRT",
    "ACPI_HED",
    "ACPI_NFIT",
    "BTT",
    "BLK_DEV_PMEM",
    "LIBNVDIMM",
    "ND_BTT",
    "NVDIMM_DAX",
    "NVDIMM_KEYS",
    "NVDIMM_KMSAN",
    "NVDIMM_PFN",
    "NVDIMM_SECURITY_TEST",
    "NVDIMM_TEST_BUILD",
    "OF_PMEM",
    "ACPI_PCI_SLOT",
    "ACPI_PRMT",
    "ACPI_VIDEO",
    "BXT_WC_PMIC_OPREGION",
    "BYTCRC_PMIC_OPREGION",
    "CHTCRC_PMIC_OPREGION",
    "CHT_DC_TI_PMIC_OPREGION",
    "CHT_WC_PMIC_OPREGION",
    "PMIC_OPREGION",
    "TPS68470_PMIC_OPREGION",
    "XPOWER_PMIC_OPREGION",
)

ACPI_CHROME_EC_DISABLED_SYMBOLS = (
    # The old CIX 6.6 vendor stack carried a CIX_EC/Chrome-EC-derived path, but
    # current Radxa O6/O6N ACPI firmware exposes EC functionality through ACPI
    # EC0/HWMN/CIXHA024 methods rather than a ChromeOS EC device.
    "CHROME_PLATFORMS",
    "CHROMEOS_ACPI",
    "CHROMEOS_LAPTOP",
    "CHROMEOS_OF_HW_PROBER",
    "CHROMEOS_PSTORE",
    "CHROMEOS_TBMC",
    "CROS_EC",
    "CROS_EC_CHARDEV",
    "CROS_EC_DEBUGFS",
    "CROS_EC_I2C",
    "CROS_EC_ISHTP",
    "CROS_EC_LIGHTBAR",
    "CROS_EC_LPC",
    "CROS_EC_PROTO",
    "CROS_EC_RPMSG",
    "CROS_EC_SENSORHUB",
    "CROS_EC_SPI",
    "CROS_EC_SYSFS",
    "CROS_EC_TYPEC",
    "CROS_EC_TYPEC_ALTMODES",
    "CROS_EC_UART",
    "CROS_EC_UCSI",
    "CROS_EC_VBC",
    "CROS_EC_WATCHDOG",
    "CROS_HPS_I2C",
    "CROS_KBD_LED_BACKLIGHT",
    "CROS_TYPEC_SWITCH",
    "CROS_USBPD_LOGGER",
    "CROS_USBPD_NOTIFY",
    "MFD_CROS_EC_DEV",
    "SENSORS_CROS_EC",
)

ACPI_SCPI_DISABLED_SYMBOLS = (
    # Orion ACPI firmware uses SCMI, not legacy Arm SCPI.
    "ARM_SCPI_CPUFREQ",
    "ARM_SCPI_POWER_DOMAIN",
    "ARM_SCPI_PROTOCOL",
    "COMMON_CLK_SCPI",
    "SENSORS_ARM_SCPI",
)

ACPI_UPSTREAM_DISABLED_SYMBOLS = (
    "I2C_CADENCE",
    # The generic PCI power-control driver expects DT regulator descriptions
    # for slots/endpoints; current Orion ACPI firmware does not provide an
    # equivalent binding.
    "PCI_PWRCTRL_GENERIC",
)

ACPI_VENDOR_DISABLED_SYMBOLS = (
    "SND_SOC_CDNS_I2S_SC",
    "DRM_CIX_COMPONENT_BIND_BYPASSED",
    "TRILIN_DP_HDCP_VALIDATION",
    "PCI_SKY1",
    "PCI_SKY1_HOST",
    "PCI_SKY1_HOST_CIX",
    "PCIE_CADENCE_PLAT_HOST",
)

VENDOR_ENGINEERING_DISABLED_SYMBOLS = (
    # CIX DST/RDR/blackbox/DSM and exception-monitoring options are
    # engineering diagnostics, EVB bring-up, or test hooks rather than
    # production Radxa Orion platform support. Keep them disabled in generated
    # board profiles unless a developer deliberately carries an out-of-tree
    # enablement policy.
    "CIX_DST",
    "CIX_EC_EXCEPTION_DRIVER",
    "KERNELDUMP_RESERVED_DESC",
    "PLAT_AP_HOOK",
    "PLAT_BBOX",
    "PLAT_BBOX_TEST",
    "PLAT_BOOT_POSTCODE",
    "PLAT_BOOT_TIME",
    "PLAT_CACHE_EXCEPTION_MONITOR",
    "PLAT_CACHE_EXCEPTION_MONITOR_TEST",
    "PLAT_DDR_EXCEPTION_COLLECT",
    "PLAT_DDR_EXCEPTION_DETECT",
    "PLAT_DSM",
    "PLAT_DSM_TEST",
    "PLAT_FDLEAK",
    "PLAT_HW_BREAKPOINT",
    "PLAT_IDM_DETECT",
    "PLAT_KERNELDUMP",
    "PLAT_LOGGER",
    "PLAT_MNTNDUMP",
    "PLAT_PRINTK_EXT",
    "PLAT_REBOOT_REASON",
    "PLAT_SDEI_EXCEPTIONS",
    "PLAT_SDEI_EXCEPTIONS_TEST",
    "PLAT_SKY1_AUDIO_TIMEOUT",
    "PLAT_SKY1_RCSU_GASKET_ERROR",
    "PLAT_SKY1_SE_PM_CRASH",
    "PLAT_TEE_EXCEPTIONS",
    "PLAT_TFA_TRACE",
    "PLAT_TZC400_DETECT",
    "PLAT_WAKEUP_SOURCE",
    "PM_EXCEPTION_DRIVER",
    "PM_EXCEPTION_PROTOCOL",
    "PM_EXCP_DSM_DRIVER",
    "RTC_DRV_RX8900",
    "SKY1_GPT_TIMER",
    "SKY1_REBOOT_REASON",
    "VIDEO_LINLON_FTRACE",
    "VIDEO_LINLON_PRINT_FILE",
)

ACPI_USB_MODEL_DISABLED_SYMBOLS = (
    "USB_GADGET",
    "USB_CDNSP_GADGET",
)

ALL_PROFILE_DISABLED_SYMBOLS = (
    # Radxa Orion O6 firmware leaves the CIX OPN field zero in current
    # testing, so keep the SoC-info reporter opt-in rather than a preset.
    "CIX_SKY1_SOCINFO",
    "DRM_CIX_VIRTUAL",
    "DRM_CIX_COMPONENT_BIND_BYPASSED",
    "TRILIN_DP_HDCP_VALIDATION",
)

# Keep this as a tuple so ACPI stub-FDT-specific disables can be added without
# changing the fragment/update machinery. The CIX display Kconfig symbols are
# ACPI-capable after the local 7.0 display fixes, so they are no longer pruned
# merely because CONFIG_OF is disabled.
OF_DISABLED_SYMBOLS: tuple[str, ...] = ()

PUBLIC_PROFILE_CHOICES = ("o6-acpi", "o6-dt", "o6n-acpi")
HIDDEN_PROFILE_CHOICES = ("o6n-dt",)
PROFILE_CHOICES = PUBLIC_PROFILE_CHOICES + HIDDEN_PROFILE_CHOICES
PROFILE_METAVAR = "{" + ",".join(PUBLIC_PROFILE_CHOICES) + "}"
PROFILE_BOARD_SYMBOLS = {
    "o6-acpi": "CIX_RADXA_ORION_O6",
    "o6-dt": "CIX_RADXA_ORION_O6",
    "o6n-acpi": "CIX_RADXA_ORION_O6N",
    "o6n-dt": "CIX_RADXA_ORION_O6N",
}
PROFILE_INTERFACE_SYMBOLS = {
    "o6-acpi": "CIX_RADXA_ORION_ACPI",
    "o6-dt": "CIX_RADXA_ORION_DT",
    "o6n-acpi": "CIX_RADXA_ORION_ACPI",
    "o6n-dt": "CIX_RADXA_ORION_DT",
}
DRIVER_PREFERENCE_CHOICES = ("module", "builtin")
NPU_ABI_CHOICES = ("r2p0", "r2p2")
KERNEL_VERSION_CHOICES = ("6.18", "6.19", "7.0", "7.1")
FIRMWARE_CHOICES = ("auto", "1.2", "1.3")
FIRMWARE_METAVAR = "{" + ",".join(FIRMWARE_CHOICES) + "}"
DMI_FIRMWARE_VERSION_PATHS = (
    Path("/sys/class/dmi/id/bios_version"),
    Path("/sys/class/dmi/id/product_version"),
    Path("/sys/class/dmi/id/board_version"),
)

SUPPORTED_COMMON = (
    ("EFI", "always"),
    ("SERIAL_AMBA_PL011", "always"),
    ("SERIAL_AMBA_PL011_CONSOLE", "always"),
    ("ARM_SMMU_V3", "always"),
    ("PM_OPP", "builtin"),
    ("RTC_CLASS", "always"),
    ("RTC_DRV_EFI", "prefer"),
    ("BLK_DEV_NVME", "always"),
    ("TEE", "prefer"),
    ("OPTEE", "prefer"),
    ("USB_XHCI_HCD", "prefer"),
    ("USB_XHCI_PLATFORM", "prefer"),
)

SUPPORTED_ACPI_ONLY = (
    ("ACPI_PROCESSOR", "builtin"),
    ("ACPI_BUTTON", "prefer"),
    ("ACPI_FAN", "prefer"),
    ("ACPI_THERMAL", "prefer"),
)

SUPPORTED_DT_ONLY = (
    ("RTC_DRV_HYM8563", "prefer"),
)

SUPPORTED_VENDOR_ACPI_COMMON = (
    ("TYPEC", "always"),
    ("TYPEC_RTS5453", "prefer"),
    ("FW_LOADER_COMPRESS", "always"),
    ("FW_LOADER_COMPRESS_XZ", "always"),
    ("PHY_CIX_USBDP", "always"),
    ("MAILBOX", "builtin"),
    ("ARM_SCMI_PROTOCOL", "builtin"),
    ("ARM_SCMI_TRANSPORT_MAILBOX", "builtin"),
    ("ARM_SCMI_PERF_DOMAIN", "prefer"),
    ("ARM_SCMI_POWER_DOMAIN", "builtin"),
    ("CIX_MBOX", "builtin"),
    ("SKY1_PDC", "prefer"),
    ("I2C_CADENCE", "prefer"),
    ("GPIO_CADENCE", "builtin"),
    ("ARM_DMA350", "prefer"),
    ("COMMON_CLK_SCMI", "builtin"),
    ("CLK_SKY1_ACPI", "builtin"),
    ("CIX_ACPI_RESOURCE_LOOKUP", "always"),
    ("CIX_ACPI_PCIE_SCAN", "always"),
    ("CIX_ACPI_USB_SCAN", "always"),
    ("CIX_ACPI_GPU_SCAN", "always"),
    ("CIX_BUS_PERF", "prefer"),
    ("CIX_SKY1_REBOOT_REASON", "prefer"),
    ("CIX_DDR_LP", "prefer"),
    ("CIX_THERMAL", "prefer"),
    ("CIX_CPU_IPA", "prefer"),
    ("ARMCHINA_NPU", "prefer"),
    ("ARMCHINA_NPU_ARCH_V3", "always"),
    ("ARMCHINA_NPU_ARCH_V3_2", "always"),
    ("ARMCHINA_NPU_SOC_SKY1", "always"),
    ("VIDEO_CIX_ARMCB_ISP", "prefer"),
    ("DRM_PANTHOR", "prefer"),
    ("DRM_CIX", "prefer"),
    ("DRM_LINLONDP", "prefer"),
    ("DRM_TRILIN_DPSUB", "prefer"),
)

SUPPORTED_VENDOR_ACPI_O6 = (
    # Orion O6 exposes the EC/HWMN fan-control path and HDA/audio hardware
    # through the firmware paths exercised by the local table upgrades.
    ("SENSORS_CIX_FAN", "prefer"),
    ("SND_HDA_CIX_IPBLOQ", "prefer"),
    ("SND_SOC_CIX", "prefer"),
    ("SND_SOC_CDNS_I2S_MC", "prefer"),
    ("SND_SOC_SKY1_SOUND_CARD", "prefer"),
)

SUPPORTED_VENDOR_ACPI_O6N = (
    # Public O6N hardware documentation and the captured stock ACPI/dmesg data
    # show active CIX/Cadence USB and PCIe PHY devices. Unlike O6, O6N is not
    # documented as having the EC chip or 3.5mm audio path used by the O6 fan
    # and HDA presets.
    ("USB_CDNS_SUPPORT", "prefer"),
    ("USB_CDNSP", "prefer"),
    ("USB_CDNSP_HOST", "always"),
    ("USB_CDNSP_SKY1", "prefer"),
    ("PHY_CIX_PCIE", "always"),
    ("PHY_CIX_USB2", "always"),
    ("PHY_CIX_USB3", "always"),
)

SUPPORTED_VENDOR_DT_COMMON = (
    ("TYPEC", "always"),
    ("TYPEC_RTS5453", "prefer"),
    ("USB_CDNS_SUPPORT", "prefer"),
    ("USB_CDNSP", "prefer"),
    ("USB_CDNSP_HOST", "always"),
    ("USB_GADGET", "prefer"),
    ("USB_CDNSP_GADGET", "prefer"),
    ("USB_CDNSP_SKY1", "prefer"),
    ("FW_LOADER_COMPRESS", "always"),
    ("FW_LOADER_COMPRESS_XZ", "always"),
    ("PM_OPP", "builtin"),
    ("ARM_SCMI_PROTOCOL", "builtin"),
    ("ARM_SCMI_TRANSPORT_MAILBOX", "builtin"),
    ("ARM_SCMI_PERF_DOMAIN", "prefer"),
    ("ARM_SCMI_POWER_DOMAIN", "builtin"),
    ("PHY_CIX_PCIE", "always"),
    ("PHY_CIX_USB2", "always"),
    ("PHY_CIX_USB3", "always"),
    ("PHY_CIX_USBDP", "always"),
    ("CIX_MBOX", "prefer"),
    ("SKY1_PDC", "prefer"),
    ("I2C_CADENCE", "prefer"),
    ("GPIO_CADENCE", "prefer"),
    ("ARM_DMA350", "prefer"),
    ("CIX_DDR_LP", "prefer"),
    ("CIX_THERMAL", "prefer"),
    ("CIX_CPU_IPA", "prefer"),
    ("ARMCHINA_NPU", "prefer"),
    ("ARMCHINA_NPU_ARCH_V3", "always"),
    ("ARMCHINA_NPU_ARCH_V3_2", "always"),
    ("ARMCHINA_NPU_SOC_SKY1", "always"),
    ("VIDEO_CIX_ARMCB_ISP", "prefer"),
    ("DRM_PANTHOR", "prefer"),
    ("DRM_CIX", "prefer"),
    ("DRM_LINLONDP", "prefer"),
    ("DRM_TRILIN_DPSUB", "prefer"),
)

SUPPORTED_VENDOR_DT_O6 = (
    ("SND_HDA_CIX_IPBLOQ", "prefer"),
    ("SND_SOC_CIX", "prefer"),
    ("SND_SOC_CDNS_I2S_MC", "prefer"),
    ("SND_SOC_SKY1_SOUND_CARD", "prefer"),
)

SUPPORTED_VENDOR_DT_O6N = (
    # The maintained O6N DT enables DP audio through the Sky1 sound-card and
    # Cadence I2S path, but it does not describe the O6 HDA controller path.
    ("SND_SOC_CIX", "prefer"),
    ("SND_SOC_CDNS_I2S_MC", "prefer"),
    ("SND_SOC_SKY1_SOUND_CARD", "prefer"),
)

KCONFIG_SYMBOL_RE = re.compile(r"^\s*(?:menu)?config\s+([A-Z0-9_]+)\s*$")
CONFIG_SET_RE = re.compile(r"^(CONFIG_[A-Z0-9_]+)=(y|m|n)$")
CONFIG_STRING_RE = re.compile(r'^(CONFIG_[A-Z0-9_]+)="(.*)"$')
CONFIG_VALUE_RE = re.compile(r"^(CONFIG_[A-Z0-9_]+)=([^\"].*)$")
CONFIG_UNSET_RE = re.compile(r"^# (CONFIG_[A-Z0-9_]+) is not set$")
RADXA_SOURCE_LINE = 'source "drivers/platform/arm64/Kconfig.radxa"\n'
INVOKED_BASENAME = Path(sys.argv[0]).name or Path(__file__).name

INITRAMFS_COMPRESSION_SYMBOLS = (
    "INITRAMFS_COMPRESSION_GZIP",
    "INITRAMFS_COMPRESSION_BZIP2",
    "INITRAMFS_COMPRESSION_LZMA",
    "INITRAMFS_COMPRESSION_XZ",
    "INITRAMFS_COMPRESSION_LZO",
    "INITRAMFS_COMPRESSION_LZ4",
    "INITRAMFS_COMPRESSION_ZSTD",
)

ACPI_TABLE_UPGRADE_CHOICES = ("ssdt", "dsdt")
ACPI_TABLE_UPGRADE_INITRAMFS_SOURCE_FORMATS = {
    "ssdt": "/usr/src/linux/cix-acpi-table-upgrade/{board}/{firmware}/initramfs.list",
    "dsdt": "/usr/src/linux/cix-acpi-table-upgrade/{board}/{firmware}/initramfs-dsdt.list",
}

KERNEL_MEMORY_DEBUG_ENABLED_SYMBOLS = (
    "DEBUG_KERNEL",
    "DEBUG_FS",
    "STACKTRACE",
    "KALLSYMS",
    "KPROBES",
    "KPROBE_EVENTS",
    "TRACING",
    "EVENT_TRACING",
    "FTRACE",
    "FUNCTION_TRACER",
    "DYNAMIC_FTRACE",
    "DMA_API_DEBUG",
    "DMA_API_DEBUG_SG",
    "DEBUG_SG",
    "IOMMU_DEBUGFS",
    "KFENCE",
    "PAGE_OWNER",
    "PAGE_POISONING",
    "DEBUG_PAGEALLOC",
    "SLUB_DEBUG",
    "SLUB_DEBUG_ON",
    "DEBUG_LIST",
    "DEBUG_VM",
    "UBSAN",
    "UBSAN_BOUNDS",
    "UBSAN_LOCAL_BOUNDS",
    "REFCOUNT_FULL",
    "HARDENED_USERCOPY",
    "INIT_ON_ALLOC_DEFAULT_ON",
    "INIT_ON_FREE_DEFAULT_ON",
)
KERNEL_MEMORY_DEBUG_KASAN_CHOICES = (
    "KASAN_HW_TAGS",
    "KASAN_SW_TAGS",
    "KASAN_GENERIC",
)

BUILD_HYGIENE_MINIMUMS = {
    # Clang can report harmless 1 KiB-class frames in generic crypto helpers;
    # keep CONFIG_WERROR usable without muting warning classes globally.
    "FRAME_WARN": 2048,
}


class KconfigHelpFormatter(argparse.RawDescriptionHelpFormatter):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("width", 78)
        kwargs.setdefault("max_help_position", 17)
        super().__init__(*args, **kwargs)

    def add_usage(self, usage, actions, groups, prefix=None):
        if prefix is None:
            prefix = "Usage: "
        return super().add_usage(usage, actions, groups, prefix)

    def _split_lines(self, text: str, width: int) -> list[str]:
        lines: list[str] = []
        for paragraph in text.splitlines():
            if not paragraph:
                lines.append("")
                continue
            lines.extend(textwrap.wrap(paragraph, width=width, break_on_hyphens=False))
        return lines


def option_help(description: str, default: str | None = None) -> str:
    if default is None:
        return description
    return f"{description}\nDefault: {default}"


def warn_ignored(parser: argparse.ArgumentParser, message: str) -> None:
    print(f"{parser.prog}: warning: {message}", file=sys.stderr)


def warn(parser: argparse.ArgumentParser, message: str) -> None:
    print(f"{parser.prog}: warning: {message}", file=sys.stderr)


def acpi_table_upgrade_board(profile: str) -> str:
    return profile.split("-", 1)[0]


def acpi_table_upgrade_has_dsdt_profile(profile: str, firmware: str) -> bool:
    board = acpi_table_upgrade_board(profile)
    return firmware == "1.2" or (board == "o6" and firmware == "1.3")


def default_acpi_table_upgrade_initramfs_source(
    profile: str, upgrade: str, firmware: str
) -> str:
    return ACPI_TABLE_UPGRADE_INITRAMFS_SOURCE_FORMATS[upgrade].format(
        board=acpi_table_upgrade_board(profile),
        firmware=firmware,
    )


def infer_firmware_profile() -> str | None:
    version_re = re.compile(r"(?<!\d)(1\.[23])(?:\.\d+)?(?!\d)")
    for path in DMI_FIRMWARE_VERSION_PATHS:
        try:
            value = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        match = version_re.search(value)
        if match:
            return match.group(1)
    return None


def parse_args() -> argparse.Namespace:
    usage = (
        "%(prog)s --mode patch [common options] [--kernel-version <VERSION>]\n"
        f"       %(prog)s --mode fragment --board-profile {PROFILE_METAVAR} "
        "[common options] [fragment/update options] [target_config]\n"
        f"       %(prog)s --mode update --board-profile {PROFILE_METAVAR} "
        "[common options] [fragment/update options] [update options] <target_config>"
    )
    description = "Generate CIX/Radxa Orion Kconfig source patches, '.config' fragments, or '.config' update diffs."
    epilog = textwrap.dedent(
        """
        Mode details:
          patch
            Print a patch for the kernel source tree. Use this when maintaining
            the kernel patch stack and you need to add or refresh the Radxa
            Orion board-profile Kconfig entries.

          fragment
            Print a '.config' fragment for '--board-profile'. Use this when you
            want config lines to merge with another tool or workflow.

          update
            Read a 'target_config' file, compute the requested '.config'
            changes, and print the unified diff that would make those changes.
            This is a dry run unless '--apply' is set.
        """
    ).strip()
    parser = argparse.ArgumentParser(
        usage=usage,
        description=description,
        epilog=epilog,
        formatter_class=KconfigHelpFormatter,
    )

    common = parser.add_argument_group("Common options")
    common.add_argument(
        "--mode",
        default="patch",
        metavar="{patch,fragment,update}",
        help=option_help(
            "Select the output mode. See Mode details below for what each "
            "mode does.",
            "patch",
        ),
    )
    common.add_argument(
        "--kernel-tree",
        type=Path,
        default=Path.cwd(),
        help=option_help(
            "Kernel source tree ('KERNEL_TREE') to inspect for Kconfig "
            "symbols. This is read only and may be separate from an 'O=' build "
            "directory or target '.config' file.",
            "current directory",
        ),
    )
    common.add_argument(
        "--cix-patches",
        choices=("auto", "yes", "no"),
        default="auto",
        help=option_help(
            "Whether the target tree already carries the CIX vendor driver "
            "stack. 'auto' scans 'KERNEL_TREE' for the presence of CIX patches; "
            "use 'yes'/'no' to force the result.",
            "auto",
        ),
    )
    common.add_argument(
        "--driver-preference",
        choices=DRIVER_PREFERENCE_CHOICES,
        default="module",
        help=option_help(
            "For newly-selected tristate hardware drivers, prefer modules "
            "where possible or prefer building them in. Existing 'y'/'m' "
            "tristates in a 'target_config' file are preserved by default, "
            "except for firmware-core symbols that must be built-in for ACPI "
            "boot ordering.",
            "module",
        ),
    )

    patch_options = parser.add_argument_group("'patch' options")
    patch_options.add_argument(
        "--kernel-version",
        choices=KERNEL_VERSION_CHOICES,
        help=option_help(
            "Override the kernel major.minor line used when generating "
            "source-tree patches. If omitted, the version is read from "
            "'KERNEL_TREE/Makefile'.",
            "auto",
        ),
    )

    config_modes = parser.add_argument_group("'fragment'/'update' options")
    config_modes.add_argument(
        "--board-profile",
        metavar=PROFILE_METAVAR,
        help=option_help(
            "Select the board/firmware profile used to generate '.config' "
            "symbols. Required.",
            "none",
        ),
    )
    config_modes.add_argument(
        "--firmware",
        choices=FIRMWARE_CHOICES,
        default="auto",
        metavar=FIRMWARE_METAVAR,
        help=option_help(
            "Select the Radxa firmware family used for ACPI table-upgrade "
            "profile paths. 'auto' attempts to infer the firmware family from "
            "local DMI/sysfs data and falls back to the 1.2 profile when it "
            "cannot infer a supported value.",
            "auto",
        ),
    )
    config_modes.add_argument(
        "--prune",
        action="store_true",
        help=option_help(
            "Scan a 'target_config' file and disable unsupported hardware "
            "configuration options. Requires a 'target_config' file when used "
            "with '--mode fragment'.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--rewrite-existing-driver-states",
        action="store_true",
        help=option_help(
            "If a 'target_config' file is supplied, rewrite existing tristate "
            "driver settings to match '--driver-preference' instead of "
            "preserving current 'y'/'m' values.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--with-tpm",
        action="store_true",
        help=option_help(
            "Treat optional TPM hardware as present when '--prune' decides "
            "which symbols to disable.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--npu-abi",
        choices=NPU_ABI_CHOICES,
        help=option_help(
            "Select the userspace ABI expected from the ArmChina NPU source "
            "tree. The helper verifies the source ABI and refuses to generate "
            "a configuration for a mismatched driver.",
            "r2p0",
        ),
    )
    config_modes.add_argument(
        "--acpi-table-upgrade",
        choices=ACPI_TABLE_UPGRADE_CHOICES,
        help=option_help(
            "For ACPI board profiles, enable either the lower-impact SSDT-only "
            "overlay set or the full DSDT and whole-table replacement profile.",
            "none",
        ),
    )
    config_modes.add_argument(
        "--acpi-table-upgrade-initramfs-source",
        metavar="PATH",
        help=option_help(
            "Override the 'CONFIG_INITRAMFS_SOURCE' value used with "
            "'--acpi-table-upgrade ssdt' or '--acpi-table-upgrade dsdt'. When "
            "omitted, the helper chooses the matching board-specific "
            "initramfs source list below the '/usr/src/linux' symlink.",
            "auto",
        ),
    )
    config_modes.add_argument(
        "--enable-kernel-memory-debug",
        action="store_true",
        help=option_help(
            "Enable a performance-impacting diagnostic profile for suspected "
            "kernel memory/DMA corruption. This turns on DMA API checking, "
            "page/slub poisoning, KASAN/KFENCE where available, and "
            "tracing/probe infrastructure.",
            "off",
        ),
    )

    update_mode = parser.add_argument_group("'update' options")
    update_mode.add_argument(
        "--apply",
        action="store_true",
        help=option_help(
            "After printing the unified diff, write a backup and overwrite "
            "the 'target_config' file. Without '--apply', 'update' is a dry "
            "run and only prints the patch.",
            "off",
        ),
    )

    inputs = parser.add_argument_group("Kernel configuration file")
    inputs.add_argument(
        "target_config",
        nargs="?",
        metavar="target_config",
        type=Path,
        help=option_help(
            "Existing '.config' path for 'fragment --prune' or 'update'. "
            "The script writes this file only when 'update --apply' is used.",
            "none",
        ),
    )

    args = parser.parse_args()
    if args.mode == "config-fragment":
        args.mode = "fragment"
    if args.mode not in ("patch", "fragment", "update"):
        parser.error(f"invalid '--mode {args.mode}'; expected 'patch', 'fragment', or 'update'")

    if args.mode == "patch":
        if args.board_profile:
            warn_ignored(parser, "'--board-profile' ignored in 'patch' mode")
            args.board_profile = None
        if args.firmware != "auto":
            warn_ignored(parser, "'--firmware' ignored in 'patch' mode")
            args.firmware = "auto"
        if args.prune:
            warn_ignored(parser, "'--prune' ignored in 'patch' mode")
            args.prune = False
        if args.rewrite_existing_driver_states:
            warn_ignored(parser, "'--rewrite-existing-driver-states' ignored in 'patch' mode")
            args.rewrite_existing_driver_states = False
        if args.with_tpm:
            warn_ignored(parser, "'--with-tpm' ignored in 'patch' mode")
            args.with_tpm = False
        if args.npu_abi is not None:
            warn_ignored(parser, "'--npu-abi' ignored in 'patch' mode")
            args.npu_abi = None
        if args.acpi_table_upgrade is not None:
            warn_ignored(parser, "'--acpi-table-upgrade' ignored in 'patch' mode")
            args.acpi_table_upgrade = None
        if args.acpi_table_upgrade_initramfs_source:
            warn_ignored(parser, "'--acpi-table-upgrade-initramfs-source' ignored in 'patch' mode")
            args.acpi_table_upgrade_initramfs_source = None
        if args.enable_kernel_memory_debug:
            warn_ignored(parser, "'--enable-kernel-memory-debug' ignored in 'patch' mode")
            args.enable_kernel_memory_debug = False
        if args.apply:
            warn_ignored(parser, "'--apply' ignored in 'patch' mode")
            args.apply = False
        if args.target_config:
            warn_ignored(parser, "'target_config' file ignored in 'patch' mode")
            args.target_config = None

    if args.mode in ("fragment", "update"):
        if args.kernel_version:
            warn_ignored(parser, f"'--kernel-version' ignored in '{args.mode}' mode")
            args.kernel_version = None
        if not args.board_profile:
            parser.error("'--board-profile' is required in 'fragment' and 'update' modes")
        if args.board_profile not in PROFILE_CHOICES:
            expected = ", ".join(PUBLIC_PROFILE_CHOICES)
            parser.error(
                f"invalid '--board-profile {args.board_profile}'; "
                f"expected one of: {expected}"
            )
        if args.with_tpm and not args.prune:
            parser.error("'--with-tpm' requires '--prune'")
        if args.npu_abi is None:
            args.npu_abi = "r2p0"
        if args.acpi_table_upgrade is not None and not args.board_profile.endswith("-acpi"):
            parser.error("'--acpi-table-upgrade' requires an ACPI board profile")
        if args.acpi_table_upgrade is None:
            if args.firmware != "auto":
                warn_ignored(parser, "'--firmware' ignored without '--acpi-table-upgrade'")
            args.firmware = "n/a"
        elif args.firmware == "auto":
            detected_firmware = infer_firmware_profile()
            if detected_firmware is None:
                warn(parser, "unable to infer '--firmware auto'; using firmware profile 1.2")
                args.firmware = "1.2"
            else:
                args.firmware = detected_firmware
        if args.acpi_table_upgrade == "dsdt" and not acpi_table_upgrade_has_dsdt_profile(
            args.board_profile, args.firmware
        ):
            parser.error(
                "'--acpi-table-upgrade dsdt' is not available for "
                f"'--board-profile {args.board_profile} --firmware {args.firmware}'"
            )
        if args.acpi_table_upgrade is None:
            if args.acpi_table_upgrade_initramfs_source:
                warn_ignored(parser, "'--acpi-table-upgrade-initramfs-source' ignored without '--acpi-table-upgrade'")
                args.acpi_table_upgrade_initramfs_source = None
        elif not args.acpi_table_upgrade_initramfs_source:
            args.acpi_table_upgrade_initramfs_source = (
                default_acpi_table_upgrade_initramfs_source(
                    args.board_profile, args.acpi_table_upgrade, args.firmware
                )
            )

    if args.mode == "fragment":
        if args.apply:
            warn_ignored(parser, "'--apply' ignored in 'fragment' mode")
            args.apply = False
        if args.target_config and not args.prune:
            warn_ignored(parser, "'target_config' file ignored in 'fragment' mode without '--prune'")
            args.target_config = None
        if args.rewrite_existing_driver_states and not args.target_config:
            warn_ignored(parser, "'--rewrite-existing-driver-states' ignored without a 'target_config' file")
            args.rewrite_existing_driver_states = False
        if args.prune and not args.target_config:
            parser.error("'--prune' in 'fragment' mode requires a 'target_config' file")

    if args.mode == "update" and not args.target_config:
        parser.error("'update' mode requires a 'target_config' file")

    return args



def detect_kernel_version(tree: Path) -> str:
    makefile = tree / "Makefile"
    try:
        lines = makefile.read_text(encoding="utf-8", errors="ignore").splitlines()
    except OSError as exc:
        raise SystemExit(f"error: unable to read kernel Makefile: {makefile}: {exc}") from exc

    values: dict[str, str] = {}
    for line in lines:
        match = re.match(r"^\s*(VERSION|PATCHLEVEL)\s*=\s*(\d+)\s*$", line)
        if match:
            values[match.group(1)] = match.group(2)

    if "VERSION" not in values or "PATCHLEVEL" not in values:
        raise SystemExit(
            f"error: unable to detect kernel version from {makefile}; "
            "use --kernel-version to override"
        )

    detected = f"{values['VERSION']}.{values['PATCHLEVEL']}"
    if detected not in KERNEL_VERSION_CHOICES:
        supported = ", ".join(KERNEL_VERSION_CHOICES)
        raise SystemExit(
            f"error: detected unsupported kernel version {detected} from {makefile}; "
            f"supported versions are {supported}; use --kernel-version to override"
        )
    return detected


def ensure_kernel_tree(tree: Path) -> tuple[Path, str, Path, str]:
    arm64_platforms_path = tree / "arch/arm64/Kconfig.platforms"
    arm64_platform_devices_path = tree / "drivers/platform/arm64/Kconfig"
    if not arm64_platforms_path.is_file():
        raise SystemExit(
            f"error: {tree} does not look like a kernel tree "
            f"(missing {arm64_platforms_path})"
        )
    if not arm64_platform_devices_path.is_file():
        raise SystemExit(
            f"error: {tree} does not look like a kernel tree "
            f"(missing {arm64_platform_devices_path})"
        )
    return (
        arm64_platforms_path,
        arm64_platforms_path.read_text(encoding="utf-8"),
        arm64_platform_devices_path,
        arm64_platform_devices_path.read_text(encoding="utf-8"),
    )


def scan_kconfig_symbols(tree: Path) -> set[str]:
    present: set[str] = set()
    for path in tree.rglob("Kconfig*"):
        if not path.is_file():
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for line in text.splitlines():
            match = KCONFIG_SYMBOL_RE.match(line)
            if match:
                present.add(match.group(1))
    return present


def detect_npu_abi(tree: Path) -> str | None:
    header = tree / "drivers/misc/armchina-npu/include/armchina_aipu.h"
    if not header.is_file():
        return None

    text = header.read_text(encoding="utf-8", errors="ignore")
    r2p2_markers = (
        "AIPU_ISA_VERSION_ZHOUYI_V3_2_0",
        "AIPU_ISA_VERSION_ZHOUYI_V3_2_1",
    )
    marker_count = sum(marker in text for marker in r2p2_markers)
    if marker_count:
        if marker_count != len(r2p2_markers):
            raise SystemExit(
                f"error: incomplete R2P2 NPU ABI markers in {header}"
            )
        return "r2p2"

    if re.search(r"\bAIPU_ISA_VERSION_ZHOUYI_V3_2\b", text):
        return "r2p0"

    raise SystemExit(f"error: unable to identify the ArmChina NPU ABI in {header}")


def validate_npu_abi(tree: Path, requested: str) -> str | None:
    detected = detect_npu_abi(tree)
    if detected is None or detected == requested:
        return detected

    use_action = "enable" if requested == "r2p2" else "disable"
    raise SystemExit(
        f"error: requested NPU ABI {requested}, but {tree} contains {detected}; "
        f"{use_action} USE=npu-r2p2-abi when reinstalling cix-sources-7.1.3, or "
        f"pass --npu-abi {detected} if that source ABI is intentional"
    )


def scan_kconfig_types(tree: Path) -> dict[str, str]:
    symbol_types: dict[str, str] = {}
    for path in tree.rglob("Kconfig*"):
        if not path.is_file():
            continue
        try:
            lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
        except OSError:
            continue

        current_symbol: str | None = None
        for line in lines:
            match = KCONFIG_SYMBOL_RE.match(line)
            if match:
                current_symbol = match.group(1)
                continue

            if current_symbol is None:
                continue

            stripped = line.strip()
            if stripped.startswith(("bool", "tristate", "string", "int", "hex")):
                symbol_types[current_symbol] = stripped.split()[0]
                current_symbol = None
                continue

            if stripped and not stripped.startswith(("#", "depends on", "select", "imply", "default", "help", "prompt")):
                current_symbol = None
    return symbol_types


def resolve_vendor_mode(tree: Path, mode: str) -> bool:
    if mode == "yes":
        return True
    if mode == "no":
        return False

    present = scan_kconfig_symbols(tree)
    found = sorted(symbol for symbol in VENDOR_SYMBOLS if symbol in present)
    if not found:
        return False

    missing = sorted(symbol for symbol in VENDOR_SYMBOLS if symbol not in present)
    if missing:
        missing_str = ", ".join(missing)
        found_str = ", ".join(found)
        raise SystemExit(
            "error: detected a partial CIX vendor tree; refusing to guess.\n"
            f"found: {found_str}\n"
            f"missing: {missing_str}\n"
            "rerun with --cix-patches yes or --cix-patches no"
        )
    return True


def insert_radxa_source_line(original: str) -> str:
    if RADXA_SOURCE_LINE in original:
        raise SystemExit(
            'error: drivers/platform/arm64/Kconfig already sources "Kconfig.radxa"'
        )

    marker = "endif # ARM64_PLATFORM_DEVICES\n"
    if marker in original:
        return original.replace(marker, marker + "\n" + RADXA_SOURCE_LINE, 1)

    if not original.endswith("\n"):
        original += "\n"
    return original + "\n" + RADXA_SOURCE_LINE


def insert_radxa_platform_menu(original: str) -> str:
    if "CIX_RADXA_ORION_O6" in original or "CIX_RADXA_ORION_O6N" in original:
        raise SystemExit(
            "error: arch/arm64/Kconfig.platforms already contains Radxa Orion "
            "board profile options"
        )

    match = re.search(r"^config ARCH_CIX\n", original, flags=re.MULTILINE)
    if not match:
        raise SystemExit("error: arch/arm64/Kconfig.platforms does not define ARCH_CIX")

    next_config = re.search(r"^config\s+\w+", original[match.end():], flags=re.MULTILINE)
    if not next_config:
        raise SystemExit("error: could not find insertion point after ARCH_CIX")

    insert_at = match.end() + next_config.start()
    before = original[:insert_at]
    after = original[insert_at:]
    return before + render_platform_radxa_menu() + after


def optional_default(active_symbol: str, driver_preference: str) -> str:
    if " " in active_symbol:
        active_symbol = f"({active_symbol})"
    if driver_preference == "builtin":
        return f"\tdefault y if {active_symbol}\n"
    return (
        f"\tdefault m if MODULES && {active_symbol}\n"
        f"\tdefault y if !MODULES && {active_symbol}\n"
    )


def render_template_block(block: str) -> str:
    block = block.rstrip()
    if not block:
        return ""
    return textwrap.indent(block, "        ")


def render_platform_radxa_menu() -> str:
    return textwrap.dedent(
        """\
        menu "Radxa Orion board profiles"
        	depends on ARCH_CIX

        config CIX_RADXA_ORION_O6
        	bool "Radxa Orion O6 board profile"
        	help
        	  Enable conservative Kconfig defaults for Radxa Orion O6
        	  systems. This only makes the matching driver preset buckets
        	  visible; the buckets use imply so normal dependency handling
        	  and user overrides are preserved.

        config CIX_RADXA_ORION_O6N
        	bool "Radxa Orion O6N board profile"
        	help
        	  Enable conservative Kconfig defaults for Radxa Orion O6N
        	  systems. O6N keeps common CIX P1 SoC support but has
        	  board-specific USB, PCIe, audio, and EC/fan-control defaults.

        choice
        	prompt "Radxa Orion firmware interface"
        	depends on (CIX_RADXA_ORION_O6 || CIX_RADXA_ORION_O6N) && (ACPI || OF)
        	default CIX_RADXA_ORION_ACPI if ACPI
        	default CIX_RADXA_ORION_DT if OF

        config CIX_RADXA_ORION_ACPI
        	bool "ACPI firmware interface"
        	depends on ACPI

        config CIX_RADXA_ORION_DT
        	bool "Device Tree firmware interface"
        	depends on OF

        endchoice

        endmenu

        """
    )


def render_kconfig_radxa(
    kernel_version: str,
    include_vendor: bool,
    driver_preference: str,
    available_symbols: set[str],
) -> str:
    profile_active = "(CIX_RADXA_ORION_O6 || CIX_RADXA_ORION_O6N)"
    ethernet_imply = render_ethernet_implies(available_symbols)
    cpu_ipa_imply = render_cpu_ipa_imply(available_symbols)
    fixed_regulator_select = ""
    if kernel_version == "7.1" and "REGULATOR_FIXED_VOLTAGE" in available_symbols:
        fixed_regulator_select = (
            "        \tselect REGULATOR_FIXED_VOLTAGE if REGULATOR && CIX_RADXA_ORION_ACPI\n"
        )
    accelerator_symbols = (
        "ARMCHINA_NPU",
        "ARMCHINA_NPU_ARCH_V3",
        "ARMCHINA_NPU_SOC_SKY1",
        "VIDEO_CIX_ARMCB_ISP",
    )
    accelerator_imply = "".join(
        f"\timply {symbol}\n"
        for symbol in accelerator_symbols
        if symbol in available_symbols
    )
    header = textwrap.dedent(
        f"""\
        # SPDX-License-Identifier: GPL-2.0-only
        #
        # Generated CIX/Radxa Orion board presets for Linux {kernel_version}.x.
        # Driver preference for tristates: {driver_preference}.
        # This menu is intentionally conservative and only covers the driver
        # groups we were able to justify from firmware analysis and the validated
        # vendor patch stack.

        menu "Radxa Orion hardware driver presets"
        \tdepends on ARM64_PLATFORM_DEVICES
        \tdepends on {profile_active}

        config CIX_RADXA_ESSENTIAL
        \tbool "Essential drivers"
        \tdepends on {profile_active}
        \tdefault y
        \timply SERIAL_AMBA_PL011
        \timply SERIAL_AMBA_PL011_CONSOLE
        \timply ARM_SMMU_V3
        \timply PM_OPP
        \timply BLK_DEV_NVME
        \timply ACPI_BUTTON if CIX_RADXA_ORION_ACPI
        \timply ACPI_FAN if CIX_RADXA_ORION_ACPI
        \timply ACPI_THERMAL if CIX_RADXA_ORION_ACPI
{fixed_regulator_select.rstrip()}
        \timply RTC_DRV_HYM8563 if CIX_RADXA_ORION_DT
        \thelp
        \t  Keep the smallest always-on set that is useful on current
        \t  Orion O6/O6N systems.

        menu "Optional drivers"
        \tdepends on {profile_active}

        config CIX_RADXA_OPTIONAL_IO
        \ttristate "Optional system bus / external I/O drivers"
{render_template_block(optional_default(profile_active, driver_preference))}
{render_template_block(ethernet_imply)}
        \timply TEE
        \timply OPTEE
        \timply USB_XHCI_HCD
        \timply USB_XHCI_PLATFORM
        \thelp
        \t  Enable the storage, networking, trusted execution, and USB
        \t  host drivers that are a reasonable default for Orion O6/O6N
        \t  systems.
        """
    )

    if not include_vendor:
        footer = textwrap.dedent(
            """\

            comment "Vendor-only display/audio/DSP buckets are omitted in an upstream-only tree"

            endmenu

        endmenu
            """
        )
        return header + footer

    accelerator_section = ""
    if accelerator_imply:
        accelerator_section = (
            "\n"
            "config CIX_RADXA_OPTIONAL_ACCELERATORS\n"
            "\ttristate \"Optional accelerator drivers\"\n"
            f"{optional_default(profile_active, driver_preference)}"
            f"{accelerator_imply}"
            "\thelp\n"
            "\t  Enable accelerator and media-processing drivers validated for\n"
            "\t  Orion O6/O6N, including the NPU and ISP paths when the vendor\n"
            "\t  driver stack provides them.\n"
        )
        accelerator_section = textwrap.indent(accelerator_section.rstrip("\n"), "        ")

    vendor_sections = textwrap.dedent(
        f"""\

        config CIX_RADXA_OPTIONAL_PLATFORM
        \ttristate "Optional platform bus / SoC glue drivers"
{render_template_block(optional_default(profile_active, driver_preference))}
        \timply TYPEC
        \timply TYPEC_RTS5453
        \timply CIX_DDR_LP
{render_template_block(cpu_ipa_imply)}
        \timply USB_CDNS_SUPPORT if CIX_RADXA_ORION_DT || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_ACPI)
        \timply USB_CDNSP if CIX_RADXA_ORION_DT || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_ACPI)
        \timply USB_CDNSP_HOST if CIX_RADXA_ORION_DT || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_ACPI)
        \timply USB_GADGET if CIX_RADXA_ORION_DT
        \timply USB_CDNSP_GADGET if CIX_RADXA_ORION_DT
        \timply USB_CDNSP_SKY1 if CIX_RADXA_ORION_DT || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_ACPI)
        \timply PHY_CIX_PCIE if CIX_RADXA_ORION_DT || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_ACPI)
        \timply PHY_CIX_USB2 if CIX_RADXA_ORION_DT || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_ACPI)
        \timply PHY_CIX_USB3 if CIX_RADXA_ORION_DT || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_ACPI)
        \tselect PHY_CIX_USBDP if TYPEC && (ACPI || OF)
        \timply SKY1_PDC
        \timply I2C_CADENCE
        \timply GPIO_CADENCE
        \timply ARM_DMA350
        \timply MAILBOX if CIX_RADXA_ORION_ACPI
        \timply ARM_SCMI_PROTOCOL if CIX_RADXA_ORION_ACPI
        \timply ARM_SCMI_TRANSPORT_MAILBOX if CIX_RADXA_ORION_ACPI
        \timply ARM_SCMI_PERF_DOMAIN if CIX_RADXA_ORION_ACPI
        \timply ARM_SCMI_POWER_DOMAIN if CIX_RADXA_ORION_ACPI
        \timply CIX_MBOX if CIX_RADXA_ORION_ACPI
        \timply COMMON_CLK_SCMI if CIX_RADXA_ORION_ACPI
        \timply CLK_SKY1_ACPI if CIX_RADXA_ORION_ACPI
        \timply CIX_ACPI_RESOURCE_LOOKUP if CIX_RADXA_ORION_ACPI
        \timply CIX_BUS_PERF if CIX_RADXA_ORION_ACPI
        \timply SENSORS_CIX_FAN if CIX_RADXA_ORION_O6 && CIX_RADXA_ORION_ACPI
        \timply CIX_SKY1_REBOOT_REASON if CIX_RADXA_ORION_ACPI
        \thelp
        \t  Enable the vendor Sky1 platform-resource plumbing used by
        \t  the CIX ACPI and DT driver stack. O6N additionally enables
        \t  the CIX/Cadence USB and PCIe PHY paths seen in its public
        \t  hardware description and stock ACPI logs. CIX_SKY1_SOCINFO is
        \t  intentionally not implied: tested Radxa Orion O6/O6N firmware
        \t  leaves the CIX OPN field zero, so that reporter is useful only
        \t  when selected deliberately for diagnostics.

        config CIX_RADXA_OPTIONAL_DISPLAY
        \ttristate "Optional display / GPU drivers"
{render_template_block(optional_default(profile_active, driver_preference))}
        \timply FW_LOADER_COMPRESS
        \timply FW_LOADER_COMPRESS_XZ
        \timply DRM_PANTHOR
        \timply DRM_CIX
        \timply DRM_LINLONDP
        \timply DRM_TRILIN_DPSUB
        \thelp
        \t  Enable the validated vendor display path for ACPI and DT.
        \t  Internal bring-up switches remain outside this preset.
{accelerator_section}

        config CIX_RADXA_OPTIONAL_AUDIO
        \ttristate "Optional audio drivers"
        \tdepends on CIX_RADXA_ORION_O6 || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_DT)
{render_template_block(optional_default("CIX_RADXA_ORION_O6 || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_DT)", driver_preference))}
        \timply SND_HDA_CIX_IPBLOQ if CIX_RADXA_ORION_O6
        \timply SND_SOC_CIX
        \timply SND_SOC_CDNS_I2S_MC
        \timply SND_SOC_SKY1_SOUND_CARD
        \thelp
        \t  Enable the vendor audio stack validated for Orion O6 and the
        \t  DP-audio-oriented DT sound-card path described by the maintained
        \t  O6N DTS. O6N ACPI leaves these drivers opt-in because the stock
        \t  ACPI card path has not been shown to bind successfully.

        config CIX_RADXA_EXPERIMENTAL_DSP
        \ttristate "Experimental DSP / SOF drivers"
        \tdepends on {profile_active}
        \tdefault n
        \timply CIX_DSP
        \timply CIX_DSP_RPROC
        \thelp
        \t  Leave this disabled unless you are intentionally working on
        \t  the vendor DSP / SOF enablement path.

        endmenu

        endmenu
        """
    )
    return header + vendor_sections


def parse_existing_config(path: Path) -> dict[str, str]:
    settings: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if match := CONFIG_SET_RE.match(raw_line):
            settings[match.group(1)] = match.group(2)
            continue
        if match := CONFIG_STRING_RE.match(raw_line):
            settings[match.group(1)] = f'"{match.group(2)}"'
            continue
        if match := CONFIG_VALUE_RE.match(raw_line):
            settings[match.group(1)] = match.group(2)
            continue
        if match := CONFIG_UNSET_RE.match(raw_line):
            settings[match.group(1)] = "n"
    return settings


def profile_is_acpi(profile: str) -> bool:
    return profile.endswith("-acpi")


def profile_is_o6(profile: str) -> bool:
    return profile.startswith("o6-")


def profile_is_o6n(profile: str) -> bool:
    return profile.startswith("o6n-")


def profile_config_symbol_updates(profile: str) -> tuple[tuple[str, str], ...]:
    board_symbol = PROFILE_BOARD_SYMBOLS[profile]
    interface_symbol = PROFILE_INTERFACE_SYMBOLS[profile]
    return (
        ("CIX_RADXA_ORION_O6", "y" if board_symbol == "CIX_RADXA_ORION_O6" else "n"),
        ("CIX_RADXA_ORION_O6N", "y" if board_symbol == "CIX_RADXA_ORION_O6N" else "n"),
        ("CIX_RADXA_ORION_ACPI", "y" if interface_symbol == "CIX_RADXA_ORION_ACPI" else "n"),
        ("CIX_RADXA_ORION_DT", "y" if interface_symbol == "CIX_RADXA_ORION_DT" else "n"),
    )


def preferred_ethernet_symbol(profile: str, available_symbols: set[str]) -> str:
    if profile_is_o6(profile) and "R8126" in available_symbols:
        return "R8126"
    return "R8169"


def render_ethernet_implies(available_symbols: set[str]) -> str:
    lines: list[str] = []
    if "R8126" in available_symbols:
        lines.append("\timply R8126 if CIX_RADXA_ORION_O6")
    elif "R8169" in available_symbols:
        lines.append("\timply R8169 if CIX_RADXA_ORION_O6")
    if "R8169" in available_symbols:
        lines.append("\timply R8169 if CIX_RADXA_ORION_O6N")
    return "\n".join(lines) + ("\n" if lines else "")


def render_cpu_ipa_imply(available_symbols: set[str]) -> str:
    if "CIX_THERMAL" in available_symbols:
        return "\timply CIX_THERMAL\n"
    if "CIX_CPU_IPA" in available_symbols:
        return "\timply CIX_CPU_IPA\n"
    return ""


def supported_symbols_for_profile(
    profile: str,
    include_vendor: bool,
    available_symbols: set[str],
) -> tuple[tuple[str, str], ...]:
    entries = list(SUPPORTED_COMMON)
    preferred_eth = preferred_ethernet_symbol(profile, available_symbols)
    if preferred_eth in available_symbols:
        entries.append((preferred_eth, "prefer"))
    if profile_is_acpi(profile):
        entries.extend(SUPPORTED_ACPI_ONLY)
    else:
        entries.extend(SUPPORTED_DT_ONLY)
    if include_vendor:
        if profile_is_acpi(profile):
            entries.extend(SUPPORTED_VENDOR_ACPI_COMMON)
            entries.extend(
                SUPPORTED_VENDOR_ACPI_O6N
                if profile_is_o6n(profile)
                else SUPPORTED_VENDOR_ACPI_O6
            )
        else:
            entries.extend(SUPPORTED_VENDOR_DT_COMMON)
            entries.extend(
                SUPPORTED_VENDOR_DT_O6N
                if profile_is_o6n(profile)
                else SUPPORTED_VENDOR_DT_O6
            )
    return tuple(entries)


def disabled_symbols_for_profile(profile: str, include_vendor: bool) -> tuple[str, ...]:
    disabled = list(PATCH_ONLY_DISABLED_SYMBOLS)
    if profile_is_acpi(profile):
        disabled.extend(symbol for symbol in ACPI_COMMON_DISABLED_SYMBOLS if symbol not in disabled)
        disabled.extend(symbol for symbol in ACPI_DT_IDLE_DISABLED_SYMBOLS if symbol not in disabled)
        disabled.extend(symbol for symbol in ACPI_FIRMWARE_ABSENT_DISABLED_SYMBOLS if symbol not in disabled)
        disabled.extend(symbol for symbol in ACPI_CHROME_EC_DISABLED_SYMBOLS if symbol not in disabled)
        disabled.extend(symbol for symbol in ACPI_SCPI_DISABLED_SYMBOLS if symbol not in disabled)
        disabled.extend(symbol for symbol in ACPI_USB_MODEL_DISABLED_SYMBOLS if symbol not in disabled)
        if include_vendor:
            disabled.extend(symbol for symbol in ACPI_VENDOR_DISABLED_SYMBOLS if symbol not in disabled)
        else:
            disabled.extend(symbol for symbol in ACPI_UPSTREAM_DISABLED_SYMBOLS if symbol not in disabled)
    if include_vendor:
        disabled.extend(symbol for symbol in ALL_PROFILE_DISABLED_SYMBOLS if symbol not in disabled)
        disabled.extend(symbol for symbol in VENDOR_ENGINEERING_DISABLED_SYMBOLS if symbol not in disabled)
    return tuple(disabled)


def dynamic_disabled_symbols(
    current: dict[str, str],
    profile: str,
    include_vendor: bool,
    with_tpm: bool,
    available_symbols: set[str],
) -> tuple[str, ...]:
    disabled: set[str] = set()
    if not profile_is_acpi(profile):
        return ()

    if current.get("CONFIG_OF") != "y":
        disabled.update(OF_DISABLED_SYMBOLS)

    for config_key, value in current.items():
        if value not in ("y", "m"):
            continue
        symbol = config_key.removeprefix("CONFIG_")
        if symbol.startswith("RTC_DRV_") and symbol != "RTC_DRV_EFI":
            disabled.add(symbol)
        if symbol.startswith("EC_"):
            disabled.add(symbol)
        if symbol.startswith("KEYBOARD_ATKBD_"):
            disabled.add(symbol)
        if symbol.startswith("MOUSE_PS2_"):
            disabled.add(symbol)
        if symbol.startswith("SERIAL_8250_"):
            disabled.add(symbol)
        if symbol.startswith("SERIO_"):
            disabled.add(symbol)
        if symbol.startswith("PARPORT_"):
            disabled.add(symbol)
        if (
            symbol.startswith("CHROMEOS_")
            or symbol.startswith("CROS_")
            or "_CROS_EC" in symbol
            or symbol.startswith("IIO_CROS_EC_")
            or symbol.startswith("CHARGER_CROS_")
        ):
            disabled.add(symbol)
        if include_vendor and (
            symbol == "USB_CDNS3" or symbol.startswith("USB_CDNS3_")
        ):
            disabled.add(symbol)
        if not with_tpm:
            if (
                symbol.startswith("TCG_")
                or symbol == "HW_RANDOM_TPM"
                or symbol == "TRUSTED_KEYS_TPM"
            ):
                disabled.add(symbol)

    if profile_is_o6(profile) and "R8126" in available_symbols:
        disabled.add("R8169")
    elif profile_is_o6n(profile):
        disabled.add("R8126")

    if not include_vendor and current.get("CONFIG_I2C_CADENCE") in ("y", "m"):
        disabled.add("I2C_CADENCE")

    if include_vendor:
        for symbol in ("PCI_SKY1", "PCIE_CADENCE_PLAT_HOST"):
            if current.get(f"CONFIG_{symbol}") in ("y", "m"):
                disabled.add(symbol)

    return tuple(sorted(disabled))


def tristate_value(kind: str, policy: str, force_mode: str) -> str:
    if kind == "bool":
        return "y"
    if force_mode in ("always", "builtin") or policy == "builtin":
        return "y"
    return "m"


def kernel_memory_debug_updates(available_symbols: set[str]) -> tuple[tuple[str, str], ...]:
    updates: list[tuple[str, str]] = []
    for symbol in KERNEL_MEMORY_DEBUG_ENABLED_SYMBOLS:
        if symbol in available_symbols:
            updates.append((symbol, "y"))

    kasan_choice = next(
        (symbol for symbol in KERNEL_MEMORY_DEBUG_KASAN_CHOICES if symbol in available_symbols),
        None,
    )
    if kasan_choice is not None and "KASAN" in available_symbols:
        updates.append(("KASAN", "y"))
        for symbol in KERNEL_MEMORY_DEBUG_KASAN_CHOICES:
            if symbol in available_symbols:
                updates.append((symbol, "y" if symbol == kasan_choice else "n"))

        for symbol in ("KASAN_EXTRA_INFO", "KASAN_VMALLOC"):
            if symbol in available_symbols:
                updates.append((symbol, "y"))

    return tuple(updates)


def format_setting(symbol: str, value: str) -> str:
    if value == "n":
        return f"# CONFIG_{symbol} is not set"
    return f"CONFIG_{symbol}={value}"


def quote_config_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def build_config_updates(
    kernel_tree: Path,
    profile: str,
    include_vendor: bool,
    driver_preference: str,
    existing_config: Path | None,
    prune: bool,
    with_tpm: bool,
    acpi_table_upgrade: str | None,
    acpi_table_upgrade_initramfs_source: str | None,
    rewrite_existing_driver_states: bool,
    enable_kernel_memory_debug: bool,
) -> tuple[list[tuple[str, str]], Path | None]:
    symbol_types = scan_kconfig_types(kernel_tree)
    available_symbols = set(symbol_types)
    updates: list[tuple[str, str]] = []
    current = parse_existing_config(existing_config) if existing_config is not None else {}
    of_enabled = current.get("CONFIG_OF") == "y" if current else None

    if profile_is_acpi(profile):
        updates.append(("ACPI", "y"))
        updates.append(("IOMMU_DEFAULT_DMA_STRICT", "y"))
        updates.append(("IOMMU_DEFAULT_DMA_LAZY", "n"))
        updates.append(("IOMMU_DEFAULT_PASSTHROUGH", "n"))
    else:
        updates.append(("ACPI", "n"))
        updates.append(("OF", "y"))

    seen: set[str] = set()
    for symbol, value in updates:
        seen.add(symbol)

    for symbol, minimum in BUILD_HYGIENE_MINIMUMS.items():
        if symbol not in symbol_types:
            continue
        try:
            current_value = int(current.get(f"CONFIG_{symbol}", "0"), 0)
        except ValueError:
            current_value = 0
        if current_value < minimum and symbol not in seen:
            updates.append((symbol, str(minimum)))
            seen.add(symbol)

    for symbol, value in profile_config_symbol_updates(profile):
        kind = symbol_types.get(symbol)
        if kind in ("bool", "tristate") and symbol not in seen:
            updates.append((symbol, value))
            seen.add(symbol)

    for symbol, force_mode in supported_symbols_for_profile(profile, include_vendor, available_symbols):
        kind = symbol_types.get(symbol)
        if kind not in ("bool", "tristate"):
            continue
        if (
            symbol in ("TYPEC", "PHY_CIX_USBDP")
            and symbol_types.get("PHY_CIX_USBDP") == "tristate"
            and force_mode == "always"
        ):
            force_mode = "prefer"
        if of_enabled is False and symbol in OF_DISABLED_SYMBOLS:
            continue
        config_key = f"CONFIG_{symbol}"
        if (
            force_mode != "builtin"
            and not rewrite_existing_driver_states
            and current.get(config_key) in ("y", "m")
        ):
            value = current[config_key]
        else:
            value = tristate_value(kind, driver_preference, force_mode)
        updates.append((symbol, value))
        seen.add(symbol)

    if prune and existing_config is not None:
        disabled_symbols = list(disabled_symbols_for_profile(profile, include_vendor))
        for symbol in dynamic_disabled_symbols(current, profile, include_vendor, with_tpm, available_symbols):
            if symbol not in disabled_symbols:
                disabled_symbols.append(symbol)
        for symbol in disabled_symbols:
            kind = symbol_types.get(symbol)
            if kind in ("bool", "tristate") and symbol not in seen:
                updates.append((symbol, "n"))
                seen.add(symbol)

    if acpi_table_upgrade is None:
        acpi_table_upgrade_updates = [
            ("ACPI_TABLE_UPGRADE", "n"),
            ("ACPI_TABLE_OVERRIDE_VIA_BUILTIN_INITRD", "n"),
        ]
        for symbol, value in acpi_table_upgrade_updates:
            if symbol not in seen:
                updates.append((symbol, value))
                seen.add(symbol)
    elif acpi_table_upgrade in ACPI_TABLE_UPGRADE_CHOICES:
        if acpi_table_upgrade_initramfs_source is None:
            raise ValueError("missing ACPI table-upgrade initramfs source")
        acpi_table_upgrade_updates = [
            ("BLK_DEV_INITRD", "y"),
            ("ACPI_TABLE_UPGRADE", "y"),
            ("ACPI_TABLE_OVERRIDE_VIA_BUILTIN_INITRD", "y"),
            ("INITRAMFS_SOURCE", quote_config_string(acpi_table_upgrade_initramfs_source)),
        ]
        acpi_table_upgrade_updates.extend(
            (symbol, "n") for symbol in INITRAMFS_COMPRESSION_SYMBOLS
        )
        acpi_table_upgrade_updates.append(("INITRAMFS_COMPRESSION_NONE", "y"))

        for symbol, value in acpi_table_upgrade_updates:
            if symbol not in seen:
                updates.append((symbol, value))
                seen.add(symbol)
    else:
        raise ValueError(f"unknown ACPI table-upgrade mode: {acpi_table_upgrade}")

    if enable_kernel_memory_debug:
        for symbol, value in kernel_memory_debug_updates(available_symbols):
            if symbol not in seen:
                updates.append((symbol, value))
                seen.add(symbol)

    return updates, existing_config if prune else None


def render_config_fragment(
    kernel_tree: Path,
    profile: str,
    firmware: str,
    include_vendor: bool,
    driver_preference: str,
    existing_config: Path | None,
    prune: bool,
    with_tpm: bool,
    acpi_table_upgrade: str | None,
    acpi_table_upgrade_initramfs_source: str | None,
    rewrite_existing_driver_states: bool,
    enable_kernel_memory_debug: bool,
    npu_abi: str,
) -> str:
    updates, prune_source = build_config_updates(
        kernel_tree=kernel_tree,
        profile=profile,
        include_vendor=include_vendor,
        driver_preference=driver_preference,
        existing_config=existing_config,
        prune=prune,
        with_tpm=with_tpm,
        acpi_table_upgrade=acpi_table_upgrade,
        acpi_table_upgrade_initramfs_source=acpi_table_upgrade_initramfs_source,
        rewrite_existing_driver_states=rewrite_existing_driver_states,
        enable_kernel_memory_debug=enable_kernel_memory_debug,
    )
    fragment_lines = [
        f"# Generated CIX/Radxa Orion config fragment for {profile}",
        f"# tristate driver preference: {driver_preference}",
        f"# NPU userspace ABI: {npu_abi}",
        f"# ACPI table-upgrade mode: {acpi_table_upgrade or 'disabled'}",
        f"# kernel memory debug profile: {'enabled' if enable_kernel_memory_debug else 'disabled'}",
    ]
    if firmware != "n/a":
        fragment_lines.insert(1, f"# firmware profile: {firmware}")
    if acpi_table_upgrade is not None:
        fragment_lines.append(
            f"# ACPI table-upgrade initramfs: {acpi_table_upgrade_initramfs_source}"
        )
    header_count = len(fragment_lines)
    for symbol, value in updates:
        fragment_lines.append(format_setting(symbol, value))
    if prune_source is not None:
        insert_at = header_count + len(updates) - sum(1 for _, value in updates if value == "n")
        # Keep the prune note between the positive settings and the disables.
        fragment_lines.insert(insert_at, "")
        fragment_lines.insert(
            insert_at + 1,
            f"# Conservative board-internal hardware disables derived from {prune_source}",
        )
    return "\n".join(fragment_lines) + "\n"


def apply_updates_to_config(original: str, updates: list[tuple[str, str]], profile: str) -> str:
    update_map = {f"CONFIG_{symbol}": format_setting(symbol, value) for symbol, value in updates}
    applied: set[str] = set()
    new_lines: list[str] = []

    for raw_line in original.splitlines():
        match = (
            CONFIG_SET_RE.match(raw_line)
            or CONFIG_STRING_RE.match(raw_line)
            or CONFIG_VALUE_RE.match(raw_line)
            or CONFIG_UNSET_RE.match(raw_line)
        )
        if match and match.group(1) in update_map:
            new_lines.append(update_map[match.group(1)])
            applied.add(match.group(1))
        else:
            new_lines.append(raw_line)

    pending = [(key, line) for key, line in update_map.items() if key not in applied]
    if pending:
        if new_lines and new_lines[-1] != "":
            new_lines.append("")
        new_lines.append(f"# Updated by {INVOKED_BASENAME} for {profile}")
        for _, line in pending:
            new_lines.append(line)

    return "\n".join(new_lines) + "\n"


def choose_backup_path(target: Path) -> Path:
    candidate = target.with_name(target.name + ".bak")
    if not candidate.exists():
        return candidate
    index = 1
    while True:
        candidate = target.with_name(f"{target.name}.bak.{index}")
        if not candidate.exists():
            return candidate
        index += 1


def make_diff(old: str, new: str, path: str) -> str:
    diff = difflib.unified_diff(
        old.splitlines(keepends=True),
        new.splitlines(keepends=True),
        fromfile=f"a/{path}",
        tofile=f"b/{path}",
        n=3,
    )
    lines = list(diff)
    if not lines:
        return ""
    return f"diff --git a/{path} b/{path}\n" + "".join(lines)


def make_new_file_diff(new: str, path: str) -> str:
    diff = difflib.unified_diff(
        [],
        new.splitlines(keepends=True),
        fromfile="/dev/null",
        tofile=f"b/{path}",
        n=3,
    )
    return (
        f"diff --git a/{path} b/{path}\n"
        "new file mode 100644\n"
        + "".join(diff)
    )


def main() -> int:
    args = parse_args()
    kernel_tree = args.kernel_tree.resolve()
    (
        arm64_platforms_path,
        original_arm64_platforms,
        arm64_platform_devices_path,
        original_arm64_platform_devices,
    ) = ensure_kernel_tree(kernel_tree)
    include_vendor = resolve_vendor_mode(kernel_tree, args.cix_patches)
    available_symbols = scan_kconfig_symbols(kernel_tree)
    target_config = args.target_config.resolve() if args.target_config else None
    if args.mode in ("fragment", "update"):
        validate_npu_abi(kernel_tree, args.npu_abi)

    if args.mode == "fragment":
        fragment = render_config_fragment(
            kernel_tree=kernel_tree,
            profile=args.board_profile,
            firmware=args.firmware,
            include_vendor=include_vendor,
            driver_preference=args.driver_preference,
            existing_config=target_config,
            prune=args.prune,
            with_tpm=args.with_tpm,
            acpi_table_upgrade=args.acpi_table_upgrade,
            acpi_table_upgrade_initramfs_source=args.acpi_table_upgrade_initramfs_source,
            rewrite_existing_driver_states=args.rewrite_existing_driver_states,
            enable_kernel_memory_debug=args.enable_kernel_memory_debug,
            npu_abi=args.npu_abi,
        )
        sys.stdout.write(fragment)
        return 0

    if args.mode == "update":
        if target_config is None or not target_config.is_file():
            raise SystemExit(f"error: target_config file must exist: {target_config}")
        original = target_config.read_text(encoding="utf-8")
        updates, _ = build_config_updates(
            kernel_tree=kernel_tree,
            profile=args.board_profile,
            include_vendor=include_vendor,
            driver_preference=args.driver_preference,
            existing_config=target_config,
            prune=args.prune,
            with_tpm=args.with_tpm,
            acpi_table_upgrade=args.acpi_table_upgrade,
            acpi_table_upgrade_initramfs_source=args.acpi_table_upgrade_initramfs_source,
            rewrite_existing_driver_states=args.rewrite_existing_driver_states,
            enable_kernel_memory_debug=args.enable_kernel_memory_debug,
        )
        updated = apply_updates_to_config(original, updates, args.board_profile)
        diff = "".join(
            difflib.unified_diff(
                original.splitlines(keepends=True),
                updated.splitlines(keepends=True),
                fromfile=f"a/{target_config}",
                tofile=f"b/{target_config}",
                n=3,
            )
        )
        if not diff:
            print(f"No changes needed for {target_config}", file=sys.stderr)
            return 0
        sys.stdout.write(diff)
        if not args.apply:
            print(
                f"Dry run only; rerun with --apply to update {target_config}",
                file=sys.stderr,
            )
            return 0
        backup = choose_backup_path(target_config)
        backup.write_text(original, encoding="utf-8")
        target_config.write_text(updated, encoding="utf-8")
        print(f"Updated {target_config}", file=sys.stderr)
        print(f"Backup written to {backup}", file=sys.stderr)
        return 0

    kernel_version = args.kernel_version or detect_kernel_version(kernel_tree)
    updated_arm64_platforms = insert_radxa_platform_menu(original_arm64_platforms)
    updated_arm64_platform_devices = insert_radxa_source_line(original_arm64_platform_devices)
    new_kconfig_radxa = render_kconfig_radxa(
        kernel_version,
        include_vendor,
        args.driver_preference,
        available_symbols,
    )

    patch_parts = [
        make_diff(
            original_arm64_platforms,
            updated_arm64_platforms,
            str(arm64_platforms_path.relative_to(kernel_tree)),
        ),
        make_diff(
            original_arm64_platform_devices,
            updated_arm64_platform_devices,
            str(arm64_platform_devices_path.relative_to(kernel_tree)),
        ),
        make_new_file_diff(new_kconfig_radxa, "drivers/platform/arm64/Kconfig.radxa"),
    ]

    sys.stdout.write("".join(part for part in patch_parts if part))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
