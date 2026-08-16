#!/usr/bin/env python3
"""Generate CIX/Radxa Orion board-profile artifacts.

Default behavior emits a git-style patch suitable for `patch -p1`.
It adds:
  - Radxa Orion board identity options below `ARCH_CIX` in
    `arch/arm64/Kconfig.platforms`
  - `source "drivers/platform/arm64/Kconfig.radxa"`
  - a new `drivers/platform/arm64/Kconfig.radxa`
  - a Sky1 default for a legacy broad ArmChina NPU SoC choice; the maintained
    fixed V3/Sky1 source scope is recognized and left unchanged

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
    "CIX_BUS_PERF",
    "PINCTRL_SKY1",
    "SKY1_PDC",
    "DRM_CIX",
    "DRM_CIX_VIRTUAL",
    "DRM_LINLONDP",
    "DRM_TRILIN_DPSUB",
    "PHY_CIX_USBDP",
    "SND_HDA_CIX_IPBLOQ",
    "SND_SOC_CIX",
    "SND_SOC_CDNS_I2S_MC",
    "SND_SOC_SKY1_SOUND_CARD",
    "TYPEC_RTS5453",
    "SENSORS_CIX_FAN",
    "CIX_SKY1_REBOOT_REASON",
)

VENDOR_SYMBOL_VARIANTS = (
    ("USB_CDNSP_SKY1", "USB_CDNS3_SKY1"),
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
    "DRM_CIX_VIRTUAL",
    "DRM_CIX_COMPONENT_BIND_BYPASSED",
    "TRILIN_DP_HDCP_VALIDATION",
)

# These are profile policy decisions, not optional pruning. Emit them during
# every fragment/update so configurations inherited from an older forced
# selection are migrated deterministically. O6 and O6N are intentionally
# scoped to their shared Zhouyi V3 implementation; the ABI selection remains
# independent of these hardware-object choices.
PROFILE_POLICY_DISABLED_SYMBOLS = (
    "ARMCHINA_NPU_ARCH_V1",
    "ARMCHINA_NPU_ARCH_V2",
    "ARMCHINA_NPU_ARCH_V3_2",
    "CIX_SCMI_ENERGY_MODEL",
    # Sky1 contains Cortex-A520 and Cortex-A720 CPUs, never Cortex-A72.
    "EDAC_CORTEX_A72",
)

# Keep this as a tuple so ACPI stub-FDT-specific disables can be added without
# changing the fragment/update machinery. The CIX display Kconfig symbols are
# ACPI-capable after the retained display fixes, so they are no longer pruned
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
HARDWARE_PROFILE_CHOICES = ("server", "desktop", "full")
GRAPHICS_PROFILE_CHOICES = (
    "auto",
    "none",
    "display",
    "gpu",
    "desktop",
    "media",
    "all",
)
AUDIO_PROFILE_CHOICES = ("auto", "none", "analog", "display", "all")
NPU_ABI_CHOICES = ("auto", "r2p0", "r2p1", "separate")
KERNEL_VERSION_CHOICES = ("6.18", "7.1", "7.2")
FIRMWARE_CHOICES = ("auto", "1.2", "1.3")
FIRMWARE_METAVAR = "{" + ",".join(FIRMWARE_CHOICES) + "}"
DMI_FIRMWARE_VERSION_PATHS = (
    Path("/sys/class/dmi/id/bios_version"),
    Path("/sys/class/dmi/id/product_version"),
    Path("/sys/class/dmi/id/board_version"),
)

SUPPORTED_COMMON = (
    ("EFI", "always"),
    ("PM_SLEEP", "always"),
    ("PM_SLEEP_SMP", "always"),
    ("SUSPEND", "always"),
    ("SUSPEND_FREEZER", "always"),
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
    ("FW_LOADER_COMPRESS", "always"),
    ("FW_LOADER_COMPRESS_XZ", "always"),
    ("MAILBOX", "builtin"),
    ("ARM_SCMI_PROTOCOL", "builtin"),
    ("ARM_SCMI_TRANSPORT_MAILBOX", "builtin"),
    ("ARM_SCMI_PERF_DOMAIN", "prefer"),
    ("ARM_SCMI_POWER_DOMAIN", "prefer"),
    ("CIX_MBOX", "builtin"),
    ("SKY1_PDC", "prefer"),
    ("I2C_CADENCE", "prefer"),
    ("GPIOLIB", "builtin"),
    ("GPIO_CADENCE", "prefer"),
    ("GPIO_CDEV", "builtin"),
    ("GPIO_AGGREGATOR", "prefer"),
    ("ARM_DMA350", "prefer"),
    ("COMMON_CLK_SCMI", "builtin"),
    ("CLK_SKY1_ACPI", "builtin"),
    ("CIX_ACPI_RESOURCE_LOOKUP", "always"),
    ("CIX_ACPI_PCIE_SCAN", "always"),
    ("CIX_ACPI_USB_SCAN", "always"),
    ("CIX_ACPI_GPU_SCAN", "always"),
    ("CIX_BUS_PERF", "prefer"),
    ("CIX_DDR_LP", "prefer"),
    # ACPI describes the console UART's PinGroupFunction through the Sky1
    # pinctrl provider.  A modular provider defers the built-in PL011 console
    # until module loading, defeating SERIAL_AMBA_PL011_CONSOLE=y.
    ("PINCTRL", "builtin"),
    ("PINCTRL_SKY1", "builtin"),
    ("PHY_CIX_USBDP", "prefer"),
    ("TYPEC_RTS5453", "prefer"),
    ("CIX_SKY1_REBOOT_REASON", "prefer"),
    ("I2C", "prefer"),
    ("PM", "builtin"),
    ("RESET_CONTROLLER", "builtin"),
    ("COMMON_CLK", "builtin"),
    ("REGULATOR", "builtin"),
    ("THERMAL", "builtin"),
    ("THERMAL_GOV_POWER_ALLOCATOR", "builtin"),
    ("CPU_FREQ", "builtin"),
    ("ENERGY_MODEL", "builtin"),
    ("ACPI_CPPC_CPUFREQ", "builtin"),
    ("CIX_THERMAL", "always"),
    ("PM_DEVFREQ", "always"),
)

SUPPORTED_VENDOR_ACPI_O6 = (
    # Orion O6 exposes the EC/HWMN fan-control path and HDA/audio hardware
    # through the firmware paths exercised by the local table upgrades.
    ("SENSORS_CIX_FAN", "prefer"),
)

SUPPORTED_VENDOR_ACPI_O6N = (
    # Public O6N hardware documentation and the captured stock ACPI/dmesg data
    # show active CIX/Cadence USB and PCIe PHY devices. Unlike O6, O6N is not
    # documented as having the EC chip or 3.5mm audio path used by the O6 fan
    # and HDA presets.
)

SUPPORTED_VENDOR_DT_COMMON = (
    ("FW_LOADER_COMPRESS", "always"),
    ("FW_LOADER_COMPRESS_XZ", "always"),
    ("ARM_SCMI_PROTOCOL", "prefer"),
    ("ARM_SCMI_TRANSPORT_MAILBOX", "prefer"),
    ("ARM_SCMI_PERF_DOMAIN", "prefer"),
    ("ARM_SCMI_POWER_DOMAIN", "prefer"),
    ("CIX_MBOX", "prefer"),
    ("SKY1_PDC", "prefer"),
    ("PHY_CIX_USBDP", "prefer"),
    ("TYPEC_RTS5453", "prefer"),
    ("I2C_CADENCE", "prefer"),
    ("GPIOLIB", "builtin"),
    ("GPIO_CADENCE", "prefer"),
    ("ARM_DMA350", "prefer"),
    ("CIX_DDR_LP", "prefer"),
    ("COMMON_CLK_SCMI", "prefer"),
    ("PINCTRL", "builtin"),
    ("PINCTRL_SKY1", "builtin"),
    ("I2C", "prefer"),
    ("PM", "builtin"),
    ("RESET_CONTROLLER", "builtin"),
    ("COMMON_CLK", "builtin"),
    ("REGULATOR", "builtin"),
    ("PM_DEVFREQ", "always"),
)

SUPPORTED_VENDOR_DT_O6 = (
)

SUPPORTED_VENDOR_DT_O6N = (
)

SUPPORTED_VENDOR_DISPLAY = (
    ("FW_LOADER_COMPRESS", "always"),
    ("FW_LOADER_COMPRESS_XZ", "always"),
    ("DMA_SHARED_BUFFER", "always"),
    ("DRM", "prefer"),
    ("DRM_CIX", "prefer"),
    ("DRM_LINLONDP", "prefer"),
    ("DRM_TRILIN_DPSUB", "prefer"),
)

SUPPORTED_VENDOR_GPU = (
    ("FW_LOADER_COMPRESS", "always"),
    ("FW_LOADER_COMPRESS_XZ", "always"),
    ("DMA_SHARED_BUFFER", "always"),
    ("DRM", "prefer"),
    ("DRM_PANTHOR", "prefer"),
)

SUPPORTED_VENDOR_MEDIA = (
    ("DMA_SHARED_BUFFER", "always"),
    ("MEDIA_SUPPORT", "prefer"),
    ("MEDIA_CAMERA_SUPPORT", "always"),
    ("MEDIA_PLATFORM_SUPPORT", "always"),
    ("MEDIA_PLATFORM_DRIVERS", "always"),
    ("VIDEO_DEV", "prefer"),
    ("MEDIA_CONTROLLER", "always"),
    ("VIDEO_LINLON", "prefer"),
    ("VIDEO_CIX_ARMCB_ISP", "prefer"),
)

SUPPORTED_VENDOR_NPU = (
    ("MODULES", "always"),
    ("DMA_SHARED_BUFFER", "always"),
    # The version-matched R2P0 and R2P1 backends claim the same device and
    # expose the same /dev/aipu name.  Keep both modular so an administrator
    # can select the userspace-matched backend without rebuilding the kernel.
    ("ARMCHINA_NPU", "module"),
    ("ARMCHINA_NPU_R2P0", "module"),
    ("ARMCHINA_NPU_ARCH_V3", "always"),
    ("ARMCHINA_NPU_SOC_SKY1", "always"),
)

SUPPORTED_VENDOR_EDP = (
    ("PWM", "builtin"),
    ("PWM_SKY1", "prefer"),
    ("BACKLIGHT_CLASS_DEVICE", "prefer"),
    ("BACKLIGHT_PWM", "prefer"),
)

SUPPORTED_TOUCHSCREEN = (
    ("INPUT", "prefer"),
    ("INPUT_EVDEV", "prefer"),
    ("INPUT_TOUCHSCREEN", "builtin"),
    ("TOUCHSCREEN_GOODIX", "prefer"),
)

SUPPORTED_VENDOR_AUDIO_ANALOG_O6 = (
    ("SOUND", "prefer"),
    ("SND", "prefer"),
    ("SND_HDA_CIX_IPBLOQ", "prefer"),
)

SUPPORTED_VENDOR_AUDIO_DISPLAY = (
    ("SOUND", "prefer"),
    ("SND", "prefer"),
    ("SND_SOC", "prefer"),
    ("SND_SOC_CIX", "prefer"),
    ("SND_SOC_CDNS_I2S_MC", "prefer"),
    ("SND_SOC_SKY1_SOUND_CARD", "prefer"),
)

DISPLAY_DRIVER_SYMBOLS = (
    "DRM_CIX",
    "DRM_LINLONDP",
    "DRM_TRILIN_DPSUB",
)
GPU_DRIVER_SYMBOLS = ("DRM_PANTHOR",)
MEDIA_DRIVER_SYMBOLS = (
    "VIDEO_LINLON",
    "VIDEO_CIX_ARMCB_ISP",
)
NPU_DRIVER_SYMBOLS = (
    "ARMCHINA_NPU",
    "ARMCHINA_NPU_R2P0",
    "ARMCHINA_NPU_ARCH_V3",
    "ARMCHINA_NPU_SOC_SKY1",
)
EDP_DRIVER_SYMBOLS = (
    "PWM_SKY1",
    "BACKLIGHT_PWM",
)
TOUCHSCREEN_DRIVER_SYMBOLS = ("TOUCHSCREEN_GOODIX",)
AUDIO_ANALOG_DRIVER_SYMBOLS = ("SND_HDA_CIX_IPBLOQ",)
AUDIO_DISPLAY_DRIVER_SYMBOLS = (
    "SND_SOC_CIX",
    "SND_SOC_CDNS_I2S_MC",
    "SND_SOC_SKY1_SOUND_CARD",
)

KCONFIG_SYMBOL_RE = re.compile(r"^\s*(?:menu)?config\s+([A-Z0-9_]+)\s*$")
KCONFIG_TYPE_KEYWORDS = {
    "bool": "bool",
    "def_bool": "bool",
    "tristate": "tristate",
    "def_tristate": "tristate",
    "string": "string",
    "int": "int",
    "hex": "hex",
}
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
# The memory-debug profile needs these facilities when selected, but does not
# own their disabled state. They are also useful independently of this helper:
# DEBUG_KERNEL remains an independent end-user choice, KALLSYMS is required by
# BPF struct_ops, and STACKTRACE is selected by several unrelated facilities.
# Preserve those choices when the profile is omitted.  SLUB_DEBUG is handled
# separately because unpatched upstream trees hide its default-enabled prompt
# unless EXPERT is enabled.
KERNEL_MEMORY_DEBUG_ENABLE_ONLY_SYMBOLS = (
    "DEBUG_KERNEL",
    "STACKTRACE",
    "KALLSYMS",
)
KERNEL_MEMORY_DEBUG_KASAN_CHOICES = (
    "KASAN_HW_TAGS",
    "KASAN_SW_TAGS",
    "KASAN_GENERIC",
)
KERNEL_MEMORY_DEBUG_KASAN_SYMBOLS = (
    "KASAN",
    *KERNEL_MEMORY_DEBUG_KASAN_CHOICES,
    "KASAN_EXTRA_INFO",
    "KASAN_VMALLOC",
)

RUNTIME_QUALIFICATION_ENABLED_SYMBOLS = (
    "DEBUG_MISC",
    "DEBUG_FS",
    "PM_DEBUG",
    "PM_ADVANCED_DEBUG",
    "PM_SLEEP_DEBUG",
    "THERMAL_STATISTICS",
    "CPU_FREQ_STAT",
    "IOMMU_DEBUGFS",
    "FTRACE",
    "TRACING",
    "EVENT_TRACING",
    # Keep the useful, non-destructive SOF diagnostics reproducible.  The
    # cache keeps post-failure inspection away from powered-down Sky1 DSP
    # SRAM and firmware tracing records DSP-side activity.  Both are
    # intentionally confined to the opt-in qualification profile.
    "SND_SOC_SOF_DEVELOPER_SUPPORT",
    "SND_SOC_SOF_DEBUG",
    "SND_SOC_SOF_DEBUG_ENABLE_DEBUGFS_CACHE",
    "SND_SOC_SOF_DEBUG_ENABLE_FIRMWARE_TRACE",
)

# Clear every other SOF development or fault-injection setting in both forms
# of the runtime-qualification profile.  A maintainer can still select one
# manually for a deliberately scoped investigation after running the helper.
RUNTIME_QUALIFICATION_CLEARED_SYMBOLS = (
    "SND_SOC_SOF_FORCE_PROBE_WORKQUEUE",
    "SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT",
    "SND_SOC_SOF_FORCE_NOCODEC_MODE",
    "SND_SOC_SOF_DEBUG_XRUN_STOP",
    "SND_SOC_SOF_DEBUG_RETAIN_DSP_CONTEXT",
    "SND_SOC_SOF_DEBUG_VERBOSE_IPC",
    "SND_SOC_SOF_DEBUG_FORCE_IPC_POSITION",
    "SND_SOC_SOF_DEBUG_IPC_FLOOD_TEST",
    "SND_SOC_SOF_DEBUG_IPC_MSG_INJECTOR",
    "SND_SOC_SOF_DEBUG_IPC_KERNEL_INJECTOR",
)

# Resolve the remaining SOF compatibility choices when the qualification
# profile opens the menu.  The Sky1 driver owns its no-codec machine explicitly
# and the distributed firmware requires the normal IPC3 minor-version policy.
RUNTIME_QUALIFICATION_DISABLED_SYMBOLS = (
    "SND_SOC_SOF_NOCODEC_SUPPORT",
    "SND_SOC_SOF_STRICT_ABI_CHECKS",
    "SND_SOC_SOF_ALLOW_FALLBACK_TO_NEWER_IPC_VERSION",
)

# SOF keeps its debug controls behind EXPERT.  The explicit qualification
# profile enables both EXPERT and DEBUG_KERNEL while active, but disabling the
# profile must not erase either independent end-user choice.
RUNTIME_QUALIFICATION_ENABLE_ONLY_SYMBOLS = (
    "EXPERT",
    "DEBUG_KERNEL",
)

# The allocation fault-injection controls are deliberately separate from both
# runtime qualification and the broader memory-debug profile.  They add hooks
# to hot allocation paths even while no failure is armed, so a production
# configuration should not retain them accidentally.  DEBUG_KERNEL, DEBUG_FS
# and STACKTRACE are shared prerequisites rather than profile-owned settings.
FAULT_INJECTION_ENABLED_SYMBOLS = (
    "FAULT_INJECTION",
    "FAULT_INJECTION_DEBUG_FS",
    "FAIL_PAGE_ALLOC",
    "FAILSLAB",
)
FAULT_INJECTION_ENABLE_ONLY_SYMBOLS = (
    "DEBUG_KERNEL",
    "DEBUG_FS",
    "STACKTRACE",
)

# These are the generic facilities used by the audited Sky1 HiFi5 XAF remoteproc
# and its userspace RPMsg qualification path. The platform driver selects its
# mailbox, virtio-RPMsg, early-reservation and hardened fixed-heap dependencies
# itself; keeping the visible RPMsg symbols here also makes generated fragments
# self-explanatory. The fixed heap is deliberately not a system-heap allocation.
HIFI5_XAF_BUILTIN_SYMBOLS = (
    "NET",
    "MAILBOX",
    "RESET_CONTROLLER",
    "COMMON_CLK",
    "REMOTEPROC",
)
HIFI5_XAF_DRIVER_SYMBOLS = (
    "CIX_DSP_RPROC",
    "RPMSG_VIRTIO",
    "RPMSG_CHAR",
    "RPMSG_CTRL",
)

HIFI5_SOF_BUILTIN_SYMBOLS = (
    "SND_SOC_SOF_TOPLEVEL",
    "CIX_HIFI5_FIRMWARE_SOF",
)
HIFI5_SOF_DRIVER_SYMBOLS = (
    "SOUND",
    "SND",
    "SND_SOC",
    "SND_SOC_SOF_CIX_SKY1",
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
        "--hardware-profile",
        choices=HARDWARE_PROFILE_CHOICES,
        default="full",
        help=option_help(
            "Select the breadth of Orion hardware support. 'server' keeps the "
            "headless platform, storage, networking and USB base; 'desktop' "
            "adds GPU/display; and 'full' additionally adds VPU and ISP/camera "
            "support. The graphics and audio profiles can override those "
            "defaults. NPU, eDP-panel, touchscreen and experimental HiFi5 "
            "support remain separately controlled.",
            "full",
        ),
    )
    config_modes.add_argument(
        "--graphics-profile",
        choices=GRAPHICS_PROFILE_CHOICES,
        default="auto",
        help=option_help(
            "Select CIX graphics and media drivers independently of the broad "
            "hardware profile. 'display' enables Linlon/DPTX, 'gpu' enables "
            "Panthor, 'desktop' enables both, 'media' enables VPU and ISP, and "
            "'all' enables every group. 'auto' follows '--hardware-profile'.",
            "auto",
        ),
    )
    config_modes.add_argument(
        "--audio-profile",
        choices=AUDIO_PROFILE_CHOICES,
        default="auto",
        help=option_help(
            "Select physical audio paths. 'analog' enables the O6 HDA codec "
            "path, 'display' enables Sky1 I2S HDMI/DisplayPort audio, and 'all' "
            "enables both where firmware supports them. 'auto' enables every "
            "supported path but omits display audio when the resolved graphics "
            "profile has no display pipeline. HiFi5 remains separately selected.",
            "auto",
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
        "--with-tpm",
        action="store_true",
        help=option_help(
            "Treat optional TPM hardware as present when '--prune' decides "
            "which symbols to disable.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--with-npu",
        action="store_true",
        help=option_help(
            "Enable the audited, separately selectable Sky1 Zhouyi V3 R2P0 "
            "and R2P1 NPU backends and their DMA/devfreq prerequisites "
            "independently of the hardware profile. The backends remain "
            "modules even when built-in drivers are otherwise preferred.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--with-edp",
        action="store_true",
        help=option_help(
            "Enable the shared display pipeline plus the Sky1 PWM/backlight "
            "support used by an attached eDP panel. HDMI and DisplayPort do not "
            "require this option.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--with-touchscreen",
        action="store_true",
        help=option_help(
            "Enable the eDP-panel settings and the generic Goodix I2C touchscreen "
            "driver used by the former BSP. Firmware must also expose I2C2 and a "
            "matching touchscreen child; that ACPI work is tracked separately.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--require-npu-abi",
        choices=NPU_ABI_CHOICES,
        help=argparse.SUPPRESS,
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
        "--enable-hifi5-xaf",
        action="store_true",
        help=option_help(
            "Enable the Sky1 HiFi5 DSP for software built with CIX's Xtensa "
            "Audio Framework (XAF) SDK. This selects the DSP, messaging and "
            "shared-memory support and chooses the XAF firmware. The DSP "
            "starts only when an XAF application requests it. XAF and SOF "
            "are alternative ways to use the same DSP and cannot be enabled "
            "together.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--enable-hifi5-sof",
        action="store_true",
        help=option_help(
            "Enable the Sky1 HiFi5 DSP through Linux Sound Open Firmware "
            "(SOF), including the codec-free ALSA processing interface. This "
            "is supported on Linux 7.1 and 7.2 and requires "
            "'--acpi-table-upgrade "
            "dsdt' plus sys-firmware/cix-sky1-firmware[sof]. XAF and SOF are "
            "alternative ways to use the same DSP and cannot be enabled "
            "together.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--enable-runtime-qualification",
        action="store_true",
        help=option_help(
            "Enable the lightweight PM, thermal, cpufreq, IOMMU debugfs and "
            "event-tracing facilities used by the removable CIX runtime "
            "qualification helpers. When this option is omitted, those "
            "facilities are explicitly disabled for a performance-oriented "
            "production configuration. This does not enable heavyweight "
            "function tracing or memory-corruption instrumentation.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--enable-fault-injection",
        action="store_true",
        help=option_help(
            "Enable the generic page and slab allocation fault-injection "
            "controls used for bounded recovery testing. No failure is "
            "injected until a maintainer arms the debugfs controls. When this "
            "option is omitted, fault-injection-specific facilities are "
            "explicitly disabled; shared debugfs and stack-trace prerequisites "
            "continue to follow the other diagnostic profiles.",
            "off",
        ),
    )
    config_modes.add_argument(
        "--enable-kernel-memory-debug",
        action="store_true",
        help=option_help(
            "Enable a performance-impacting diagnostic profile for suspected "
            "kernel memory/DMA corruption. This turns on DMA API checking, "
            "page/slub poisoning, KASAN/KFENCE where available, and "
            "tracing/probe infrastructure. When this option is omitted, "
            "memory-debug-only facilities are explicitly disabled; shared "
            "profile facilities remain enabled only when required by another "
            "diagnostic profile. Generic enable-only prerequisites such as "
            "KALLSYMS and STACKTRACE retain the end-user's existing choice.",
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
    if args.enable_hifi5_xaf and args.enable_hifi5_sof:
        parser.error(
            "'--enable-hifi5-xaf' and '--enable-hifi5-sof' "
            "select mutually exclusive DSP firmware owners"
        )

    if args.mode == "patch":
        if args.board_profile:
            warn_ignored(parser, "'--board-profile' ignored in 'patch' mode")
            args.board_profile = None
        if args.hardware_profile != "full":
            warn_ignored(parser, "'--hardware-profile' ignored in 'patch' mode")
            args.hardware_profile = "full"
        for option_name in ("graphics_profile", "audio_profile"):
            if getattr(args, option_name) != "auto":
                display_name = option_name.replace("_", "-")
                warn_ignored(parser, f"'--{display_name}' ignored in 'patch' mode")
                setattr(args, option_name, "auto")
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
        for option_name in ("with_npu", "with_edp", "with_touchscreen"):
            if getattr(args, option_name):
                display_name = option_name.replace("_", "-")
                warn_ignored(parser, f"'--{display_name}' ignored in 'patch' mode")
                setattr(args, option_name, False)
        if args.require_npu_abi is not None:
            warn_ignored(parser, "internal NPU ABI assertion ignored in 'patch' mode")
            args.require_npu_abi = None
        if args.acpi_table_upgrade is not None:
            warn_ignored(parser, "'--acpi-table-upgrade' ignored in 'patch' mode")
            args.acpi_table_upgrade = None
        if args.acpi_table_upgrade_initramfs_source:
            warn_ignored(parser, "'--acpi-table-upgrade-initramfs-source' ignored in 'patch' mode")
            args.acpi_table_upgrade_initramfs_source = None
        if args.enable_kernel_memory_debug:
            warn_ignored(parser, "'--enable-kernel-memory-debug' ignored in 'patch' mode")
            args.enable_kernel_memory_debug = False
        if args.enable_runtime_qualification:
            warn_ignored(parser, "'--enable-runtime-qualification' ignored in 'patch' mode")
            args.enable_runtime_qualification = False
        if args.enable_fault_injection:
            warn_ignored(parser, "'--enable-fault-injection' ignored in 'patch' mode")
            args.enable_fault_injection = False
        if args.enable_hifi5_xaf:
            warn_ignored(parser, "'--enable-hifi5-xaf' ignored in 'patch' mode")
            args.enable_hifi5_xaf = False
        if args.enable_hifi5_sof:
            warn_ignored(parser, "'--enable-hifi5-sof' ignored in 'patch' mode")
            args.enable_hifi5_sof = False
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
        if args.require_npu_abi is None:
            args.require_npu_abi = "auto"
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
        if args.enable_hifi5_sof and args.acpi_table_upgrade != "dsdt":
            parser.error(
                "'--enable-hifi5-sof' requires '--acpi-table-upgrade dsdt'"
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


def detect_separate_r2p0_backend(tree: Path) -> bool:
    directory = tree / "drivers/misc/armchina-npu-r2p0"
    paths = {
        "Kconfig": directory / "Kconfig",
        "Makefile": directory / "Makefile",
        "header": directory / "include/armchina_aipu.h",
        "dispatcher": directory / "aipu.c",
        "misc device": directory / "aipu_priv.c",
        "platform": directory / "sky1/sky1.c",
    }
    present = {name: path.is_file() for name, path in paths.items()}
    if not any(present.values()):
        return False
    if not all(present.values()):
        missing = ", ".join(name for name, exists in present.items() if not exists)
        raise SystemExit(
            "error: incomplete separate R2P0 NPU backend; missing " + missing
        )

    kconfig = paths["Kconfig"].read_text(encoding="utf-8", errors="ignore")
    makefile = paths["Makefile"].read_text(encoding="utf-8", errors="ignore")
    header = paths["header"].read_text(encoding="utf-8", errors="ignore")
    dispatcher = paths["dispatcher"].read_text(
        encoding="utf-8", errors="ignore"
    )
    misc_device = paths["misc device"].read_text(
        encoding="utf-8", errors="ignore"
    )
    platform = paths["platform"].read_text(encoding="utf-8", errors="ignore")
    markers = (
        ("config ARMCHINA_NPU_R2P0", kconfig),
        ("depends on ARMCHINA_NPU != y", kconfig),
        ("depends on m || !ARMCHINA_NPU", kconfig),
        ("armchina_npu_r2p0.o", makefile),
        ("__u64 asid_base[32];", header),
        ("AIPU_ISA_VERSION_ZHOUYI_V3   = 5", header),
        ("struct aipu_buf_desc", header),
        ("struct aipu_job_desc", header),
        (
            "#define AIPU_IOCTL_QUERY_CAP "
            "_IOR(AIPU_IOCTL_MAGIC, 0, struct aipu_cap)",
            header,
        ),
        (
            "#define AIPU_IOCTL_FREE_BUF "
            "_IOW(AIPU_IOCTL_MAGIC, 3, struct aipu_buf_desc)",
            header,
        ),
        (
            "#define AIPU_IOCTL_SCHEDULE_JOB "
            "_IOW(AIPU_IOCTL_MAGIC, 6, struct aipu_job_desc)",
            header,
        ),
        (
            "#define AIPU_IOCTL_BUF_CACHE_INVALID "
            "_IOW(AIPU_IOCTL_MAGIC, 24, struct aipu_buf_desc)",
            header,
        ),
        (
            "#define AIPU_IOCTL_BUF_CACHE_FLUSH "
            "_IOW(AIPU_IOCTL_MAGIC, 25, struct aipu_buf_desc)",
            header,
        ),
        ("case AIPU_IOCTL_QUERY_CAP:", dispatcher),
        ("case AIPU_IOCTL_FREE_BUF:", dispatcher),
        ("case AIPU_IOCTL_SCHEDULE_JOB:", dispatcher),
        ("case AIPU_IOCTL_BUF_CACHE_INVALID:", dispatcher),
        ("case AIPU_IOCTL_BUF_CACHE_FLUSH:", dispatcher),
        ('aipu->misc.name = "aipu";', misc_device),
        ("aipu->misc.mode = 0660;", misc_device),
        ('name = "armchina-r2p0"', platform),
    )
    missing_markers = [marker for marker, text in markers if marker not in text]
    if missing_markers:
        raise SystemExit(
            "error: incomplete separate R2P0 NPU backend markers: "
            + ", ".join(missing_markers)
        )

    expected_fields = {
        "aipu_cap": (
            "__u32 partition_cnt",
            "__u32 asid_cnt",
            "__u64 asid_base[32]",
            "__u32 is_homogeneous",
            "__u64 dtcm_base",
            "__u32 dtcm_size",
            "__u32 gm0_size",
            "__u32 gm1_size",
            "struct aipu_partition_cap partition_cap",
        ),
        "aipu_buf_desc": (
            "__u64 pa",
            "__u64 dev_offset",
            "__u64 bytes",
            "__u8 region",
            "__u8 asid",
        ),
        "aipu_job_desc": (
            "__u32 is_defer_run",
            "__u32 version_compatible",
            "__u32 core_id",
            "__u32 partition_id",
            "__u32 do_trigger",
            "__u32 aipu_arch",
            "__u32 aipu_version",
            "__u32 aipu_config",
            "__u32 start_pc_addr",
            "__u32 intr_handler_addr",
            "__u32 data_0_addr",
            "__u32 data_1_addr",
            "__u64 job_id",
            "__u32 enable_prof",
            "__s64 profile_fd",
            "__u64 profile_pa",
            "__u32 profile_sz",
            "__u32 enable_poll_opt",
            "__u32 exec_flag",
            "__u32 dtcm_size_kb",
            "__u64 head_tcb_pa",
            "__u64 first_task_tcb_pa",
            "__u64 last_task_tcb_pa",
            "__u64 tail_tcb_pa",
            "__u32 is_coredump_en",
        ),
    }
    for name, expected in expected_fields.items():
        match = re.search(
            rf"\bstruct\s+{re.escape(name)}\s*\{{(?P<body>.*?)\n\}};",
            header,
            re.DOTALL,
        )
        if not match:
            raise SystemExit(
                f"error: separate R2P0 NPU backend is missing struct {name}"
            )
        body = re.sub(r"/\*.*?\*/", "", match.group("body"), flags=re.DOTALL)
        fields = tuple(
            " ".join(field.split())
            for field in body.split(";")
            if field.strip()
        )
        if fields != expected:
            raise SystemExit(
                f"error: separate R2P0 NPU backend has an unexpected "
                f"struct {name} layout"
            )
    alias_source = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for path in directory.rglob("*.[ch]")
        if path.is_file()
    )
    if "MODULE_ALIAS" in alias_source or "MODULE_DEVICE_TABLE" in alias_source:
        raise SystemExit(
            "error: separate R2P0 NPU backend must remain explicit-load only"
        )
    return True


def detect_npu_abi(tree: Path) -> str | None:
    separate_r2p0 = detect_separate_r2p0_backend(tree)
    header = tree / "drivers/misc/armchina-npu/include/armchina_aipu.h"
    if not header.is_file():
        return "r2p0" if separate_r2p0 else None

    text = header.read_text(encoding="utf-8", errors="ignore")
    asid_match = re.search(r"\b__u64\s+asid_base\[(\d+)\]\s*;", text)
    if not asid_match:
        raise SystemExit(f"error: unable to identify the NPU ASID ABI width in {header}")
    asid_count = int(asid_match.group(1))
    private_engine_markers = (
        "AIPU_ISA_VERSION_ZHOUYI_V3_2_0",
        "AIPU_ISA_VERSION_ZHOUYI_V3_2_1",
    )
    marker_count = sum(marker in text for marker in private_engine_markers)
    if marker_count:
        if marker_count != len(private_engine_markers):
            raise SystemExit(
                f"error: incomplete later-engine NPU markers in {header}"
            )
        if asid_count != 4:
            raise SystemExit(
                f"error: later-engine NPU markers require asid_base[4], but "
                f"{header} declares asid_base[{asid_count}]"
            )
        job_match = re.search(
            r"\bstruct\s+aipu_job_desc\s*\{(?P<body>.*?)\n\};", text, re.DOTALL
        )
        if not job_match or not re.search(
            r"\b__u32\s+group_id\s*;.*"
            r"\b__u64\s+job_id\s*;.*"
            r"\b__u64\s+head_tcb_pa\s*;.*"
            r"\b__u64\s+tail_tcb_pa\s*;.*"
            r"\b__u64\s+asid0_base\s*;",
            job_match.group("body"),
            re.DOTALL,
        ):
            raise SystemExit(
                f"error: later-engine NPU markers require the retained private "
                f"group/job/TCB/ASID layout in {header}; request numbers and "
                "payload sizes alone are ambiguous"
            )

        p1_header = tree / "drivers/misc/armchina-npu/aipu_abi_p1.h"
        p1_source = tree / "drivers/misc/armchina-npu/aipu_abi_p1.c"
        p1_present = p1_header.is_file() and p1_source.is_file()
        if p1_present:
            p1_text = p1_header.read_text(encoding="utf-8", errors="ignore")
            p1_source_text = p1_source.read_text(
                encoding="utf-8", errors="ignore"
            )
            p1_markers = (
                "25b55cc08ec735093b5808c7cd0723f1a128c645",
                "sizeof(struct aipu_p1_buf_desc) == 40",
                "offsetof(struct aipu_p1_buf_desc, exec_id) == 24",
                "sizeof(struct aipu_p1_job_desc) == 144",
                "offsetof(struct aipu_p1_job_desc, job_id) == 48",
                "offsetof(struct aipu_p1_job_desc, profile_fd) == 64",
                "offsetof(struct aipu_p1_job_desc, head_tcb_pa) == 96",
                "offsetof(struct aipu_p1_job_desc, asid0_base) == 136",
                "AIPU_P1_IOCTL_FREE_BUF == 0x40284103UL",
                "AIPU_P1_IOCTL_SCHEDULE_JOB == 0x40904106UL",
                "AIPU_P1_IOCTL_BUF_CACHE_INVALID == 0x40284118UL",
                "AIPU_P1_IOCTL_BUF_CACHE_FLUSH == 0x40284119UL",
            )
            p1_source_markers = (
                "internal.group_id = 0",
                "internal.asid0_base = aipu->job_manager.asid0_base",
                "aipu_job_manager_owner_guard_begin",
            )
            if not all(marker in p1_text for marker in p1_markers) or not all(
                marker in p1_source_text for marker in p1_source_markers
            ):
                raise SystemExit(
                    f"error: incomplete R2P1 (CIX P1) userspace ABI adapter in "
                    f"{p1_header} and {p1_source}"
                )
        elif p1_header.is_file() or p1_source.is_file():
            raise SystemExit(
                "error: incomplete R2P1 (CIX P1) userspace ABI adapter: both "
                f"{p1_header} and {p1_source} are required"
            )

        compat_header = tree / "drivers/misc/armchina-npu/aipu_compat_r2p0.h"
        compat_present = compat_header.is_file()
        if compat_present:
            compat_text = compat_header.read_text(encoding="utf-8", errors="ignore")
            compat_asid_match = re.search(
                r"\b__u64\s+asid_base\[(\d+)\]\s*;", compat_text
            )
            if not compat_asid_match or int(compat_asid_match.group(1)) != 32:
                raise SystemExit(
                    f"error: R2P0 compatibility requires asid_base[32] in "
                    f"{compat_header}"
                )
            compat_markers = (
                "AIPU_R2P0_IOCTL_QUERY_CAP",
                "0x81a84100UL",
                "sizeof(struct aipu_r2p0_cap) == 424",
                "sizeof(struct aipu_r2p0_job_desc) == 136",
                "AIPU_R2P0_IOCTL_FREE_BUF == 0x40204103UL",
                "AIPU_R2P0_IOCTL_SCHEDULE_JOB == 0x40884106UL",
                "AIPU_R2P0_IOCTL_BUF_CACHE_INVALID == 0x40204118UL",
                "AIPU_R2P0_IOCTL_BUF_CACHE_FLUSH == 0x40204119UL",
            )
            if not all(marker in compat_text for marker in compat_markers):
                raise SystemExit(
                    f"error: incomplete R2P0 compatibility ABI in {compat_header}"
                )

        dispatch_source = tree / "drivers/misc/armchina-npu/aipu.c"
        dispatch_text = ""
        if p1_present or compat_present:
            if not dispatch_source.is_file():
                raise SystemExit(
                    f"error: missing NPU ioctl dispatcher {dispatch_source}"
                )
            dispatch_text = dispatch_source.read_text(
                encoding="utf-8", errors="ignore"
            )
        if p1_present and "aipu_p1_ioctl(aipu, filp, cmd, arg)" not in dispatch_text:
            raise SystemExit(
                f"error: R2P1 (CIX P1) adapter is not dispatched by "
                f"{dispatch_source}"
            )
        if compat_present and (
            "aipu_compat_r2p0_ioctl(aipu, filp, cmd, arg)" not in dispatch_text
        ):
            raise SystemExit(
                f"error: R2P0 adapter is not dispatched by {dispatch_source}"
            )
        colliding_public_cases = (
            "case AIPU_IOCTL_FREE_BUF:",
            "case AIPU_IOCTL_SCHEDULE_JOB:",
            "case AIPU_IOCTL_BUF_CACHE_INVALID:",
            "case AIPU_IOCTL_BUF_CACHE_FLUSH:",
        )
        if p1_present and any(
            marker in dispatch_text for marker in colliding_public_cases
        ):
            raise SystemExit(
                f"error: {dispatch_source} still exposes the incompatible "
                "later-engine ioctl interpretation alongside R2P1 (CIX P1)"
            )

        if p1_present and compat_present:
            return "dual"
        if p1_present:
            return "separate" if separate_r2p0 else "r2p1"
        raise SystemExit(
            "error: the retained later NPU engine is a private implementation "
            "detail and cannot identify a safe userspace ABI without the exact "
            f"R2P1 (CIX P1) adapter in {p1_header} and {p1_source}"
        )

    if re.search(r"\bAIPU_ISA_VERSION_ZHOUYI_V3_2\b", text):
        if asid_count != 32:
            raise SystemExit(
                f"error: R2P0 NPU ABI markers require asid_base[32] for the "
                f"0x1a8 capability ioctl, but {header} declares "
                f"asid_base[{asid_count}]"
            )
        return "r2p0"

    raise SystemExit(f"error: unable to identify the ArmChina NPU ABI in {header}")


def validate_npu_abi(tree: Path, requested: str) -> str | None:
    detected = detect_npu_abi(tree)
    if requested == "auto" or detected is None or detected == requested:
        return detected

    raise SystemExit(
        f"error: requested NPU ABI {requested}, but {tree} contains {detected}; "
        "prepare the matching NPU patch stack"
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
            type_keyword = stripped.split(maxsplit=1)[0] if stripped else ""
            symbol_type = KCONFIG_TYPE_KEYWORDS.get(type_keyword)
            if symbol_type is not None:
                symbol_types[current_symbol] = symbol_type
                current_symbol = None
                continue

            if stripped and not stripped.startswith(("#", "depends on", "select", "imply", "default", "help", "prompt")):
                current_symbol = None
    return symbol_types


def slub_debug_can_be_disabled(tree: Path, expert_enabled: bool) -> bool:
    """Return whether an explicit CONFIG_SLUB_DEBUG=n can survive Kconfig."""
    path = tree / "mm/Kconfig.debug"
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False

    match = re.search(
        r"(?ms)^config SLUB_DEBUG\s*$\n(?P<body>.*?)(?=^(?:menu)?config\s|\Z)",
        text,
    )
    if match is None:
        return False

    return expert_enabled or not any(
        re.match(r"^(?:bool|prompt)\b.*\bif\b.*\bEXPERT\b", line.strip())
        for line in match.group("body").splitlines()
    )


def resolve_vendor_mode(tree: Path, mode: str) -> bool:
    if mode == "yes":
        return True
    if mode == "no":
        return False

    present = scan_kconfig_symbols(tree)
    found = [symbol for symbol in VENDOR_SYMBOLS if symbol in present]
    found.extend(
        symbol
        for variants in VENDOR_SYMBOL_VARIANTS
        for symbol in variants
        if symbol in present
    )
    found.sort()
    if not found:
        return False

    missing = [symbol for symbol in VENDOR_SYMBOLS if symbol not in present]
    missing.extend(
        "/".join(variants)
        for variants in VENDOR_SYMBOL_VARIANTS
        if not any(symbol in present for symbol in variants)
    )
    missing.sort()
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


def insert_npu_sky1_choice_default(original: str) -> str:
    conditional_default = (
        "\tdefault ARMCHINA_NPU_SOC_SKY1 if "
        "CIX_RADXA_ORION_O6 || CIX_RADXA_ORION_O6N\n"
    )
    if conditional_default in original:
        raise SystemExit(
            "error: ArmChina NPU Kconfig already contains the Radxa Sky1 choice default"
        )

    marker = (
        'choice\n\tprompt "ArmChina NPU SoC integration"\n'
        "\tdefault ARMCHINA_NPU_SOC_DEFAULT\n"
    )
    if marker not in original:
        scoped_markers = (
            "\tdepends on ARCH_CIX || COMPILE_TEST\n",
            "if ARMCHINA_NPU\n",
            "config ARMCHINA_NPU_ARCH_V3\n\tdef_bool y\n",
            "config ARMCHINA_NPU_SOC_SKY1\n\tdef_bool y\n",
        )
        scoped_forbidden = (
            "config ARMCHINA_NPU_ARCH_V1\n",
            "config ARMCHINA_NPU_ARCH_V2\n",
            "config ARMCHINA_NPU_ARCH_V3_2\n",
            "config ARMCHINA_NPU_ARCH_V1_V2\n",
            "config ARMCHINA_NPU_SOC_DEFAULT\n",
            "config ARMCHINA_NPU_SOC_R329\n",
            'prompt "ArmChina NPU SoC integration"',
        )
        if all(original.count(item) == 1 for item in scoped_markers) and not any(
            item in original for item in scoped_forbidden
        ):
            return original
        raise SystemExit(
            "error: unable to locate the ArmChina NPU SoC choice default"
        )

    return original.replace(
        marker,
        marker.replace(
            "\tdefault ARMCHINA_NPU_SOC_DEFAULT\n",
            conditional_default + "\tdefault ARMCHINA_NPU_SOC_DEFAULT\n",
        ),
        1,
    )


def optional_default(driver_preference: str) -> str:
    if driver_preference == "builtin":
        return "\tdefault y\n"
    return (
        "\tdefault m if MODULES\n"
        "\tdefault y if !MODULES\n"
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
    accelerator_symbols = []
    if "ARMCHINA_NPU" in available_symbols:
        accelerator_symbols.extend(
            (
                "DMA_SHARED_BUFFER",
                "PM_DEVFREQ",
                "ARMCHINA_NPU",
                "ARMCHINA_NPU_ARCH_V3",
            )
        )
    if "VIDEO_CIX_ARMCB_ISP" in available_symbols:
        accelerator_symbols.extend(
            (
                "DMA_SHARED_BUFFER",
                "I2C",
                "PM",
                "RESET_CONTROLLER",
                "COMMON_CLK",
                "REGULATOR",
                "MEDIA_SUPPORT",
                "MEDIA_CAMERA_SUPPORT",
                "MEDIA_PLATFORM_SUPPORT",
                "MEDIA_PLATFORM_DRIVERS",
                "VIDEO_DEV",
                "MEDIA_CONTROLLER",
                "VIDEO_CIX_ARMCB_ISP",
            )
        )
    if "VIDEO_LINLON" in available_symbols:
        accelerator_symbols.extend(
            (
                "PM",
                "RESET_CONTROLLER",
                "MEDIA_SUPPORT",
                "VIDEO_DEV",
                "VIDEO_LINLON",
            )
        )
    accelerator_imply = "".join(
        f"\timply {symbol}\n"
        for symbol in dict.fromkeys(accelerator_symbols)
        if symbol in available_symbols
    )
    accelerator_descriptions = []
    if "ARMCHINA_NPU" in available_symbols:
        accelerator_descriptions.append("Sky1 V3 NPU")
    if "VIDEO_CIX_ARMCB_ISP" in available_symbols:
        accelerator_descriptions.append("ArmChina ISP")
    if "VIDEO_LINLON" in available_symbols:
        accelerator_descriptions.append("Linlon MVX VPU")
    accelerator_description = " and ".join(accelerator_descriptions) or "available accelerator"
    accelerator_noun = "driver" if len(accelerator_descriptions) == 1 else "drivers"
    ddr_lp_imply = "\timply CIX_DDR_LP\n" if "CIX_DDR_LP" in available_symbols else ""
    header = textwrap.dedent(
        f"""\
        # SPDX-License-Identifier: GPL-2.0-only
        #
        # Generated CIX/Radxa Orion board presets for Linux {kernel_version}.x.
        # Driver preference for tristates: {driver_preference}.
        # This menu is intentionally conservative and only covers the driver
        # groups supported by the firmware interfaces and maintained driver stack.

        menu "Radxa Orion hardware driver presets"
        \tdepends on ARM64_PLATFORM_DEVICES
        \tdepends on {profile_active}

        config CIX_RADXA_ESSENTIAL
        \tbool "Essential drivers"
        \tdefault y
        \timply SERIAL_AMBA_PL011
        \timply SERIAL_AMBA_PL011_CONSOLE
        \timply ARM_SMMU_V3
        \timply PM_OPP
        \timply SUSPEND
        \timply SUSPEND_FREEZER
        \timply BLK_DEV_NVME
        \timply ACPI_BUTTON if CIX_RADXA_ORION_ACPI
        \timply ACPI_FAN if CIX_RADXA_ORION_ACPI
        \timply ACPI_THERMAL if CIX_RADXA_ORION_ACPI
        \tselect PINCTRL if CIX_RADXA_ORION_DT
        \tselect PINCTRL_SKY1 if CIX_RADXA_ORION_DT
{render_template_block(cpu_ipa_imply)}
        \timply RTC_DRV_HYM8563 if CIX_RADXA_ORION_DT
        \thelp
        \t  Keep the smallest always-on set that is useful on current
        \t  Orion O6/O6N systems.

        menu "Optional drivers"

        config CIX_RADXA_OPTIONAL_IO
        \ttristate "Optional system bus / external I/O drivers"
{render_template_block(optional_default(driver_preference))}
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
            f"{optional_default(driver_preference)}"
            f"{accelerator_imply}"
            "\thelp\n"
            f"\t  Enable the {accelerator_description} {accelerator_noun}.\n"
            "\t  Unsafe legacy DMA/IOMMU and privileged control\n"
            "\t  paths remain gated in the drivers rather than disabling\n"
            "\t  normal accelerator operation.\n"
        )
        accelerator_section = textwrap.indent(accelerator_section.rstrip("\n"), "        ")

    vendor_sections = textwrap.dedent(
        f"""\

        config CIX_RADXA_OPTIONAL_PLATFORM
        \ttristate "Optional platform bus / SoC glue drivers"
{render_template_block(optional_default(driver_preference))}
        \timply SKY1_PDC
        \timply I2C
        \timply I2C_CADENCE
        \timply GPIOLIB
        \timply GPIO_CADENCE
        \timply GPIO_AGGREGATOR if CIX_RADXA_ORION_ACPI
        \timply GPIO_CDEV if GPIO_AGGREGATOR
        \timply ARM_DMA350
        \timply MAILBOX if CIX_RADXA_ORION_DT
        \timply ARM_SCMI_PROTOCOL if CIX_RADXA_ORION_DT
        \timply ARM_SCMI_TRANSPORT_MAILBOX if CIX_RADXA_ORION_DT
        \timply CIX_MBOX if CIX_RADXA_ORION_DT
        \timply COMMON_CLK if CIX_RADXA_ORION_DT
        \timply COMMON_CLK_SCMI if CIX_RADXA_ORION_DT
        \timply RESET_CONTROLLER if CIX_RADXA_ORION_DT
        \timply ARM_SCMI_PERF_DOMAIN
        \timply ARM_SCMI_POWER_DOMAIN
        \timply CIX_BUS_PERF if CIX_RADXA_ORION_ACPI
{render_template_block(ddr_lp_imply)}
        \timply PHY_CIX_USBDP
        \timply TYPEC_RTS5453
        \timply SENSORS_CIX_FAN if CIX_RADXA_ORION_O6 && CIX_RADXA_ORION_ACPI
        \thelp
        \t  Enable the Sky1 platform-resource plumbing used by
        \t  the CIX ACPI and DT driver stack, including the USB/DP
        \t  combo PHY and RTS5453 Type-C controller. The unrelated vendor
        \t  PCIe, USB2 and USB3 PHY drivers remain excluded. Firmware-scratch
        \t  diagnostics remain opt-in because the scratch value is not
        \t  guaranteed to describe the last reset.

        config CIX_RADXA_OPTIONAL_DISPLAY
        \ttristate "Optional display / GPU drivers"
{render_template_block(optional_default(driver_preference))}
        \timply FW_LOADER_COMPRESS
        \timply FW_LOADER_COMPRESS_XZ
        \timply DRM
        \timply DRM_PANTHOR
        \timply DRM_CIX
        \timply DRM_LINLONDP
        \timply DRM_TRILIN_DPSUB
        \timply PWM
        \timply PWM_SKY1
        \timply BACKLIGHT_CLASS_DEVICE
        \timply BACKLIGHT_PWM
        \thelp
        \t  Enable the vendor display path for ACPI and DT.
        \t  Internal bring-up switches remain outside this preset.
{accelerator_section}

        config CIX_RADXA_OPTIONAL_AUDIO
        \ttristate "Optional audio drivers"
        \tdepends on CIX_RADXA_ORION_O6 || (CIX_RADXA_ORION_O6N && CIX_RADXA_ORION_DT)
{render_template_block(optional_default(driver_preference))}
        \timply SOUND
        \timply SND
        \timply SND_SOC
        \timply SND_HDA_CIX_IPBLOQ if CIX_RADXA_ORION_O6
        \timply SND_SOC_CIX
        \timply SND_SOC_CDNS_I2S_MC
        \timply SND_SOC_SKY1_SOUND_CARD
        \thelp
        \t  Enable the vendor audio stack for Orion O6 and the
        \t  DP-audio-oriented DT sound-card path described by the maintained
        \t  O6N DTS. O6N ACPI leaves these drivers opt-in because the stock
        \t  ACPI card path has not been shown to bind successfully.

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
        ("ARCH_CIX", "y"),
        ("CIX_RADXA_ORION_O6", "y" if board_symbol == "CIX_RADXA_ORION_O6" else "n"),
        ("CIX_RADXA_ORION_O6N", "y" if board_symbol == "CIX_RADXA_ORION_O6N" else "n"),
        ("CIX_RADXA_ORION_ACPI", "y" if interface_symbol == "CIX_RADXA_ORION_ACPI" else "n"),
        ("CIX_RADXA_ORION_DT", "y" if interface_symbol == "CIX_RADXA_ORION_DT" else "n"),
    )


def preferred_ethernet_symbol(profile: str, available_symbols: set[str]) -> str:
    if profile_is_o6(profile) and "R8126" in available_symbols:
        return "R8126"
    return "R8169" if "R8169" in available_symbols else ""


def render_ethernet_implies(available_symbols: set[str]) -> str:
    lines: list[str] = []
    if "R8126" in available_symbols:
        lines.append("\timply R8126 if CIX_RADXA_ORION_O6")
    elif "R8169" in available_symbols:
        lines.append("\timply R8169 if CIX_RADXA_ORION_O6")
    if "R8169" in available_symbols:
        lines.append("\timply R8169 if CIX_RADXA_ORION_O6N")
    return "\n".join(lines) + ("\n" if lines else "")


def ethernet_conflict_updates(
    profile: str,
    available_symbols: set[str],
) -> tuple[tuple[str, str], ...]:
    if profile_is_o6(profile) and "R8126" in available_symbols:
        return (("R8169", "n"),) if "R8169" in available_symbols else ()
    if profile_is_o6n(profile) and "R8126" in available_symbols:
        return (("R8126", "n"),)
    return ()


def render_cpu_ipa_imply(available_symbols: set[str]) -> str:
    if "CIX_THERMAL" not in available_symbols:
        return ""
    dependencies = (
        "THERMAL",
        "THERMAL_GOV_POWER_ALLOCATOR",
        "CPU_FREQ",
        "ENERGY_MODEL",
        "ACPI_PROCESSOR",
        "ACPI_CPPC_CPUFREQ",
        "CIX_THERMAL",
    )
    return "".join(
        f"\timply {symbol} if CIX_RADXA_ORION_ACPI\n"
        for symbol in dependencies
        if symbol in available_symbols
    )


def audio_capabilities(profile: str) -> frozenset[str]:
    if profile_is_o6(profile):
        return frozenset(("analog", "display"))
    if not profile_is_acpi(profile):
        # The maintained O6N DT enables DP audio through the Sky1 sound card,
        # but does not describe the O6 HDA controller path.
        return frozenset(("display",))
    return frozenset()


def selected_optional_hardware(
    profile: str,
    hardware_profile: str,
    graphics_profile: str,
    audio_profile: str,
    with_edp: bool,
    with_touchscreen: bool,
) -> tuple[frozenset[str], frozenset[str]]:
    if graphics_profile == "auto":
        graphics = {
            "server": set(),
            "desktop": {"display", "gpu"},
            "full": {"display", "gpu", "media"},
        }[hardware_profile]
    else:
        graphics = {
            "none": set(),
            "display": {"display"},
            "gpu": {"gpu"},
            "desktop": {"display", "gpu"},
            "media": {"media"},
            "all": {"display", "gpu", "media"},
        }[graphics_profile]

    if with_edp or with_touchscreen:
        graphics.add("display")

    capabilities = audio_capabilities(profile)
    if audio_profile == "auto":
        audio = set(capabilities)
        if "display" not in graphics:
            audio.discard("display")
    else:
        audio = {
            "none": set(),
            "analog": {"analog"},
            "display": {"display"},
            "all": {"analog", "display"},
        }[audio_profile] & capabilities

    # These explicit requests close over the display pipeline they need.
    if audio_profile != "auto" and "display" in audio:
        graphics.add("display")

    return frozenset(graphics), frozenset(audio)


def supported_symbols_for_profile(
    profile: str,
    hardware_profile: str,
    include_vendor: bool,
    with_npu: bool,
    with_edp: bool,
    with_touchscreen: bool,
    available_symbols: set[str],
    graphics_profile: str = "auto",
    audio_profile: str = "auto",
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

        graphics, audio = selected_optional_hardware(
            profile,
            hardware_profile,
            graphics_profile,
            audio_profile,
            with_edp,
            with_touchscreen,
        )
        if "display" in graphics:
            entries.extend(SUPPORTED_VENDOR_DISPLAY)
        if "gpu" in graphics:
            entries.extend(SUPPORTED_VENDOR_GPU)
        if "media" in graphics:
            entries.extend(SUPPORTED_VENDOR_MEDIA)

        if "analog" in audio:
            entries.extend(SUPPORTED_VENDOR_AUDIO_ANALOG_O6)
        if "display" in audio:
            entries.extend(SUPPORTED_VENDOR_AUDIO_DISPLAY)

        if with_npu:
            entries.extend(SUPPORTED_VENDOR_NPU)

        if with_edp or with_touchscreen:
            entries.extend(SUPPORTED_VENDOR_EDP)

    if with_touchscreen:
        entries.extend(SUPPORTED_TOUCHSCREEN)

    return tuple(entries)


def feature_gate_updates(
    profile: str,
    hardware_profile: str,
    include_vendor: bool,
    with_npu: bool,
    with_edp: bool,
    with_touchscreen: bool,
    graphics_profile: str = "auto",
    audio_profile: str = "auto",
) -> tuple[tuple[str, str], ...]:
    """Disable only feature-specific drivers which the selected profile omits.

    Generic subsystems such as DRM, MEDIA_SUPPORT, INPUT, PWM and SND remain an
    end-user choice. This lets the helper remove CIX hardware drivers when a
    profile is narrowed without making policy decisions for unrelated USB or
    PCI devices in the same kernel configuration.
    """

    if not include_vendor:
        return tuple(
            (symbol, "n")
            for symbol in TOUCHSCREEN_DRIVER_SYMBOLS
            if not with_touchscreen
        )

    updates: list[tuple[str, str]] = []
    graphics, audio = selected_optional_hardware(
        profile,
        hardware_profile,
        graphics_profile,
        audio_profile,
        with_edp,
        with_touchscreen,
    )
    if "display" not in graphics:
        updates.extend((symbol, "n") for symbol in DISPLAY_DRIVER_SYMBOLS)
    if "gpu" not in graphics:
        updates.extend((symbol, "n") for symbol in GPU_DRIVER_SYMBOLS)
    if "media" not in graphics:
        updates.extend((symbol, "n") for symbol in MEDIA_DRIVER_SYMBOLS)
    if "analog" not in audio:
        updates.extend((symbol, "n") for symbol in AUDIO_ANALOG_DRIVER_SYMBOLS)
    if "display" not in audio:
        updates.extend((symbol, "n") for symbol in AUDIO_DISPLAY_DRIVER_SYMBOLS)
    if not with_npu:
        updates.extend((symbol, "n") for symbol in NPU_DRIVER_SYMBOLS)
    if not (with_edp or with_touchscreen):
        updates.extend((symbol, "n") for symbol in EDP_DRIVER_SYMBOLS)
    if not with_touchscreen:
        updates.extend((symbol, "n") for symbol in TOUCHSCREEN_DRIVER_SYMBOLS)
    return tuple(updates)


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

    cdns3_sky1 = "USB_CDNS3_SKY1" in available_symbols
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
            if not cdns3_sky1 or symbol not in (
                "USB_CDNS3",
                "USB_CDNS3_SKY1",
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
    if force_mode == "module":
        return "m"
    if force_mode in ("always", "builtin") or policy == "builtin":
        return "y"
    return "m"


def kernel_memory_debug_updates(
    available_symbols: set[str], enabled: bool, slub_debug_can_disable: bool
) -> tuple[tuple[str, str], ...]:
    if not enabled:
        enable_only = set(KERNEL_MEMORY_DEBUG_ENABLE_ONLY_SYMBOLS)
        return tuple(
            (symbol, "n")
            for symbol in (
                *KERNEL_MEMORY_DEBUG_ENABLED_SYMBOLS,
                *KERNEL_MEMORY_DEBUG_KASAN_SYMBOLS,
            )
            if symbol in available_symbols
            and symbol not in enable_only
            and (symbol != "SLUB_DEBUG" or slub_debug_can_disable)
        )

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


def runtime_qualification_updates(
    available_symbols: set[str], enabled: bool
) -> tuple[tuple[str, str], ...]:
    updates = [
        (symbol, "y" if enabled else "n")
        for symbol in RUNTIME_QUALIFICATION_ENABLED_SYMBOLS
        if symbol in available_symbols
    ]
    updates.extend(
        (symbol, "n")
        for symbol in RUNTIME_QUALIFICATION_CLEARED_SYMBOLS
        if symbol in available_symbols
    )
    if enabled:
        updates.extend(
            (symbol, "y")
            for symbol in RUNTIME_QUALIFICATION_ENABLE_ONLY_SYMBOLS
            if symbol in available_symbols
        )
        updates.extend(
            (symbol, "n")
            for symbol in RUNTIME_QUALIFICATION_DISABLED_SYMBOLS
            if symbol in available_symbols
        )
    return tuple(updates)


def fault_injection_updates(
    available_symbols: set[str], enabled: bool
) -> tuple[tuple[str, str], ...]:
    updates = [
        (symbol, "y" if enabled else "n")
        for symbol in FAULT_INJECTION_ENABLED_SYMBOLS
        if symbol in available_symbols
    ]
    if enabled:
        updates.extend(
            (symbol, "y")
            for symbol in FAULT_INJECTION_ENABLE_ONLY_SYMBOLS
            if symbol in available_symbols
        )
    return tuple(updates)


def hifi5_xaf_updates(
    symbol_types: dict[str, str],
    driver_preference: str,
    enabled: bool,
    current: dict[str, str] | None = None,
) -> tuple[tuple[str, str], ...]:
    if not enabled:
        return ()

    updates: list[tuple[str, str]] = []
    for symbol in HIFI5_XAF_BUILTIN_SYMBOLS:
        if symbol_types.get(symbol) in ("bool", "tristate"):
            updates.append((symbol, "y"))

    for symbol in HIFI5_XAF_DRIVER_SYMBOLS:
        kind = symbol_types.get(symbol)
        if kind in ("bool", "tristate"):
            updates.append(
                (symbol, tristate_value(kind, driver_preference, "prefer"))
            )

    for symbol, value in (
        ("CIX_HIFI5_FIRMWARE_XAF", "y"),
        ("CIX_HIFI5_FIRMWARE_SOF", "n"),
        ("SND_SOC_SOF_CIX_SKY1", "n"),
    ):
        if symbol_types.get(symbol) in ("bool", "tristate"):
            updates.append((symbol, value))

    updates.extend(hifi5_pageblock_updates(symbol_types, True, current))
    return tuple(updates)


def hifi5_sof_updates(
    symbol_types: dict[str, str],
    driver_preference: str,
    enabled: bool,
    current: dict[str, str] | None = None,
) -> tuple[tuple[str, str], ...]:
    if not enabled:
        return ()
    if symbol_types.get("SND_SOC_SOF_CIX_SKY1") not in ("bool", "tristate"):
        raise SystemExit(
            "error: this prepared kernel tree does not provide the audited "
            "CIX Sky1 SOF owner; use a supported Linux 7.1 or 7.2 source"
        )

    updates: list[tuple[str, str]] = []
    for symbol in HIFI5_SOF_BUILTIN_SYMBOLS:
        if symbol_types.get(symbol) in ("bool", "tristate"):
            updates.append((symbol, "y"))

    for symbol in HIFI5_SOF_DRIVER_SYMBOLS:
        kind = symbol_types.get(symbol)
        if kind in ("bool", "tristate"):
            updates.append(
                (symbol, tristate_value(kind, driver_preference, "prefer"))
            )

    for symbol in (
        "CIX_HIFI5_FIRMWARE_XAF",
        "CIX_DSP_RPROC",
        # Sky1 has an explicit no-codec machine owner and supports IPC3 only.
        # The distributed firmware has a newer compatible IPC3 minor ABI than
        # Linux 7.2, so strict release-CI checks would reject working firmware.
        "SND_SOC_SOF_FORCE_PROBE_WORKQUEUE",
        "SND_SOC_SOF_NOCODEC_SUPPORT",
        "SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT",
        "SND_SOC_SOF_STRICT_ABI_CHECKS",
        "SND_SOC_SOF_ALLOW_FALLBACK_TO_NEWER_IPC_VERSION",
    ):
        if symbol_types.get(symbol) in ("bool", "tristate"):
            updates.append((symbol, "n"))

    updates.extend(hifi5_pageblock_updates(symbol_types, True, current))
    return tuple(updates)


def hifi5_pageblock_updates(
    symbol_types: dict[str, str],
    enabled: bool,
    current: dict[str, str] | None = None,
) -> tuple[tuple[str, str], ...]:
    if not enabled:
        return ()

    updates: list[tuple[str, str]] = []

    if symbol_types.get("PAGE_BLOCK_MAX_ORDER") == "int":
        current = current or {}
        pageblock_limit: int | None = None
        default_needs_cap = False
        for page_symbol, limit, needs_cap in (
            ("CONFIG_ARM64_4K_PAGES", 10, False),
            ("CONFIG_ARM64_16K_PAGES", 11, False),
            ("CONFIG_ARM64_64K_PAGES", 9, True),
        ):
            if current.get(page_symbol) == "y":
                pageblock_limit = limit
                default_needs_cap = needs_cap
                break

        if pageblock_limit is not None:
            configured = current.get("CONFIG_PAGE_BLOCK_MAX_ORDER")
            try:
                configured_order = (
                    int(configured, 0) if configured is not None else None
                )
            except ValueError:
                configured_order = 0
            if (
                configured_order is not None
                and not 1 <= configured_order <= pageblock_limit
            ) or (configured_order is None and default_needs_cap):
                updates.append(("PAGE_BLOCK_MAX_ORDER", str(pageblock_limit)))

    return tuple(updates)


def cix_platform_memory_updates(
    symbol_types: dict[str, str],
    current: dict[str, str] | None = None,
) -> tuple[tuple[str, str], ...]:
    current = current or {}
    if (
        current.get("CONFIG_ARM64_64K_PAGES") != "y"
        or current.get("CONFIG_CMA") != "y"
        or symbol_types.get("CMA_SIZE_MBYTES") != "int"
    ):
        return ()

    configured = current.get("CONFIG_CMA_SIZE_MBYTES")
    try:
        configured_mbytes = int(configured, 0) if configured is not None else 0
    except ValueError:
        configured_mbytes = 0
    if configured_mbytes >= 128:
        return ()
    return (("CMA_SIZE_MBYTES", "128"),)


def format_setting(symbol: str, value: str) -> str:
    if value == "n":
        return f"# CONFIG_{symbol} is not set"
    return f"CONFIG_{symbol}={value}"


def quote_config_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def build_config_updates(
    kernel_tree: Path,
    profile: str,
    hardware_profile: str,
    graphics_profile: str,
    audio_profile: str,
    include_vendor: bool,
    driver_preference: str,
    existing_config: Path | None,
    prune: bool,
    with_tpm: bool,
    with_npu: bool,
    with_edp: bool,
    with_touchscreen: bool,
    acpi_table_upgrade: str | None,
    acpi_table_upgrade_initramfs_source: str | None,
    rewrite_existing_driver_states: bool,
    enable_kernel_memory_debug: bool,
    enable_runtime_qualification: bool,
    enable_fault_injection: bool,
    enable_hifi5_xaf: bool,
    enable_hifi5_sof: bool,
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

    for symbol, value in ethernet_conflict_updates(profile, available_symbols):
        kind = symbol_types.get(symbol)
        if kind in ("bool", "tristate") and symbol not in seen:
            updates.append((symbol, value))
            seen.add(symbol)

    for symbol in PROFILE_POLICY_DISABLED_SYMBOLS:
        kind = symbol_types.get(symbol)
        if kind in ("bool", "tristate") and symbol not in seen:
            updates.append((symbol, "n"))
            seen.add(symbol)

    for symbol, force_mode in supported_symbols_for_profile(
        profile,
        hardware_profile,
        include_vendor,
        with_npu,
        with_edp,
        with_touchscreen,
        available_symbols,
        graphics_profile,
        audio_profile,
    ):
        kind = symbol_types.get(symbol)
        if kind not in ("bool", "tristate"):
            continue
        if of_enabled is False and symbol in OF_DISABLED_SYMBOLS:
            continue
        config_key = f"CONFIG_{symbol}"
        if (
            force_mode not in ("builtin", "module")
            and not rewrite_existing_driver_states
            and current.get(config_key) in ("y", "m")
        ):
            value = current[config_key]
        else:
            value = tristate_value(kind, driver_preference, force_mode)
        updates.append((symbol, value))
        seen.add(symbol)

    for symbol, value in feature_gate_updates(
        profile,
        hardware_profile,
        include_vendor,
        with_npu,
        with_edp,
        with_touchscreen,
        graphics_profile,
        audio_profile,
    ):
        kind = symbol_types.get(symbol)
        if kind not in ("bool", "tristate"):
            continue
        if symbol in seen:
            for index, (existing_symbol, _) in enumerate(updates):
                if existing_symbol == symbol:
                    updates[index] = (symbol, value)
                    break
        else:
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

    diagnostic_updates: dict[str, str] = {}
    for profile_updates in (
        kernel_memory_debug_updates(
            available_symbols,
            enable_kernel_memory_debug,
            slub_debug_can_be_disabled(
                kernel_tree,
                current.get("CONFIG_EXPERT") == "y"
                or enable_runtime_qualification,
            ),
        ),
        runtime_qualification_updates(available_symbols, enable_runtime_qualification),
        fault_injection_updates(available_symbols, enable_fault_injection),
    ):
        for symbol, value in profile_updates:
            if value == "y" or diagnostic_updates.get(symbol) != "y":
                diagnostic_updates[symbol] = value

    for symbol, value in diagnostic_updates.items():
        if symbol in seen:
            for index, (existing_symbol, _) in enumerate(updates):
                if existing_symbol == symbol:
                    updates[index] = (symbol, value)
                    break
        else:
            updates.append((symbol, value))
            seen.add(symbol)

    for profile_updates in (
        cix_platform_memory_updates(symbol_types, current),
        hifi5_xaf_updates(
            symbol_types, driver_preference, enable_hifi5_xaf, current
        ),
        hifi5_sof_updates(
            symbol_types, driver_preference, enable_hifi5_sof, current
        ),
    ):
        for symbol, value in profile_updates:
            if symbol in seen:
                for index, (existing_symbol, _) in enumerate(updates):
                    if existing_symbol == symbol:
                        updates[index] = (symbol, value)
                        break
            else:
                updates.append((symbol, value))
                seen.add(symbol)

    return updates, existing_config if prune else None


def render_config_fragment(
    kernel_tree: Path,
    profile: str,
    hardware_profile: str,
    graphics_profile: str,
    audio_profile: str,
    firmware: str,
    include_vendor: bool,
    driver_preference: str,
    existing_config: Path | None,
    prune: bool,
    with_tpm: bool,
    with_npu: bool,
    with_edp: bool,
    with_touchscreen: bool,
    acpi_table_upgrade: str | None,
    acpi_table_upgrade_initramfs_source: str | None,
    rewrite_existing_driver_states: bool,
    enable_kernel_memory_debug: bool,
    enable_runtime_qualification: bool,
    enable_fault_injection: bool,
    enable_hifi5_xaf: bool,
    enable_hifi5_sof: bool,
    detected_npu_abi: str,
) -> str:
    updates, prune_source = build_config_updates(
        kernel_tree=kernel_tree,
        profile=profile,
        hardware_profile=hardware_profile,
        graphics_profile=graphics_profile,
        audio_profile=audio_profile,
        include_vendor=include_vendor,
        driver_preference=driver_preference,
        existing_config=existing_config,
        prune=prune,
        with_tpm=with_tpm,
        with_npu=with_npu,
        with_edp=with_edp,
        with_touchscreen=with_touchscreen,
        acpi_table_upgrade=acpi_table_upgrade,
        acpi_table_upgrade_initramfs_source=acpi_table_upgrade_initramfs_source,
        rewrite_existing_driver_states=rewrite_existing_driver_states,
        enable_kernel_memory_debug=enable_kernel_memory_debug,
        enable_runtime_qualification=enable_runtime_qualification,
        enable_fault_injection=enable_fault_injection,
        enable_hifi5_xaf=enable_hifi5_xaf,
        enable_hifi5_sof=enable_hifi5_sof,
    )
    fragment_lines = [
        f"# Generated CIX/Radxa Orion config fragment for {profile}",
    ]
    if firmware != "n/a":
        fragment_lines.append(f"# firmware profile: {firmware}")
    graphics, audio = selected_optional_hardware(
        profile,
        hardware_profile,
        graphics_profile,
        audio_profile,
        with_edp,
        with_touchscreen,
    )
    fragment_lines.extend(
        (
            f"# hardware profile: {hardware_profile}",
            f"# graphics profile: {graphics_profile} ({','.join(sorted(graphics)) or 'none'})",
            f"# audio profile: {audio_profile} ({','.join(sorted(audio)) or 'none'})",
            f"# tristate driver preference: {driver_preference}",
            f"# NPU backends: {'enabled' if with_npu else 'disabled'}",
        )
    )
    if with_npu:
        fragment_lines.append(f"# NPU userspace ABI layout: {detected_npu_abi}")
    fragment_lines.extend(
        (
            f"# eDP panel support: {'enabled' if with_edp or with_touchscreen else 'disabled'}",
            f"# touchscreen support: {'enabled' if with_touchscreen else 'disabled'}",
            f"# ACPI table-upgrade mode: {acpi_table_upgrade or 'disabled'}",
            f"# HiFi5 XAF profile: {'enabled' if enable_hifi5_xaf else 'unchanged'}",
            f"# HiFi5 SOF profile: {'enabled' if enable_hifi5_sof else 'disabled'}",
            f"# kernel memory debug profile: {'enabled' if enable_kernel_memory_debug else 'disabled'}",
            f"# runtime qualification profile: {'enabled' if enable_runtime_qualification else 'disabled'}",
            f"# fault injection profile: {'enabled' if enable_fault_injection else 'disabled'}",
        )
    )
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
        detected_npu_abi = validate_npu_abi(kernel_tree, args.require_npu_abi)
        if args.require_npu_abi != "auto":
            detected_npu_abi = args.require_npu_abi
        else:
            detected_npu_abi = detected_npu_abi or "none"

    if args.mode == "fragment":
        fragment = render_config_fragment(
            kernel_tree=kernel_tree,
            profile=args.board_profile,
            hardware_profile=args.hardware_profile,
            graphics_profile=args.graphics_profile,
            audio_profile=args.audio_profile,
            firmware=args.firmware,
            include_vendor=include_vendor,
            driver_preference=args.driver_preference,
            existing_config=target_config,
            prune=args.prune,
            with_tpm=args.with_tpm,
            with_npu=args.with_npu,
            with_edp=args.with_edp,
            with_touchscreen=args.with_touchscreen,
            acpi_table_upgrade=args.acpi_table_upgrade,
            acpi_table_upgrade_initramfs_source=args.acpi_table_upgrade_initramfs_source,
            rewrite_existing_driver_states=args.rewrite_existing_driver_states,
            enable_kernel_memory_debug=args.enable_kernel_memory_debug,
            enable_runtime_qualification=args.enable_runtime_qualification,
            enable_fault_injection=args.enable_fault_injection,
            enable_hifi5_xaf=args.enable_hifi5_xaf,
            enable_hifi5_sof=args.enable_hifi5_sof,
            detected_npu_abi=detected_npu_abi,
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
            hardware_profile=args.hardware_profile,
            graphics_profile=args.graphics_profile,
            audio_profile=args.audio_profile,
            include_vendor=include_vendor,
            driver_preference=args.driver_preference,
            existing_config=target_config,
            prune=args.prune,
            with_tpm=args.with_tpm,
            with_npu=args.with_npu,
            with_edp=args.with_edp,
            with_touchscreen=args.with_touchscreen,
            acpi_table_upgrade=args.acpi_table_upgrade,
            acpi_table_upgrade_initramfs_source=args.acpi_table_upgrade_initramfs_source,
            rewrite_existing_driver_states=args.rewrite_existing_driver_states,
            enable_kernel_memory_debug=args.enable_kernel_memory_debug,
            enable_runtime_qualification=args.enable_runtime_qualification,
            enable_fault_injection=args.enable_fault_injection,
            enable_hifi5_xaf=args.enable_hifi5_xaf,
            enable_hifi5_sof=args.enable_hifi5_sof,
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

    npu_kconfig_path = kernel_tree / "drivers/misc/armchina-npu/Kconfig"
    original_npu_kconfig = ""
    updated_npu_kconfig = ""
    if "ARMCHINA_NPU_SOC_SKY1" in available_symbols:
        if not npu_kconfig_path.is_file():
            raise SystemExit(f"error: missing ArmChina NPU Kconfig: {npu_kconfig_path}")
        original_npu_kconfig = npu_kconfig_path.read_text(encoding="utf-8")
        updated_npu_kconfig = insert_npu_sky1_choice_default(original_npu_kconfig)

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
        make_diff(
            original_npu_kconfig,
            updated_npu_kconfig,
            str(npu_kconfig_path.relative_to(kernel_tree)),
        )
        if original_npu_kconfig
        else "",
        make_new_file_diff(new_kconfig_radxa, "drivers/platform/arm64/Kconfig.radxa"),
    ]

    sys.stdout.write("".join(part for part in patch_parts if part))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
