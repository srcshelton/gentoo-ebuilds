#!/usr/bin/env python3
"""Regression tests for CIX diagnostic Kconfig profile ownership."""

from __future__ import annotations

import importlib.util
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch


SCRIPT = (
    Path(__file__).parents[2]
    / "sys-kernel"
    / "cix-sources"
    / "files"
    / "kconfig_update.py"
)
SPEC = importlib.util.spec_from_file_location("kconfig_update", SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot load {SCRIPT}")
KCONFIG = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(KCONFIG)


class CommandLineTests(unittest.TestCase):
    def test_hifi5_dsp_selects_one_interface(self) -> None:
        with patch.object(
            sys,
            "argv",
            [
                str(SCRIPT),
                "--mode",
                "fragment",
                "--board-profile",
                "o6-acpi",
                "--enable-hifi5-dsp",
                "xaf",
            ],
        ):
            args = KCONFIG.parse_args()

        self.assertEqual(args.enable_hifi5_dsp, "xaf")

    def test_fragment_update_help_has_semantic_option_order(self) -> None:
        with patch.object(sys, "argv", [str(SCRIPT), "--help"]):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                with self.assertRaises(SystemExit) as error:
                    KCONFIG.parse_args()

        self.assertEqual(error.exception.code, 0)
        options = stdout.getvalue().split("'fragment'/'update' options:", 1)[1]
        options = options.split("'update' options:", 1)[0]
        expected = (
            "--board-profile",
            "--firmware",
            "--hardware-profile",
            "--graphics-profile",
            "--audio-profile",
            "--enable-hifi5-dsp",
            "--with-npu",
            "--with-edp",
            "--with-touchscreen",
            "--with-tpm",
            "--acpi-table-upgrade",
            "--acpi-table-upgrade-initramfs-source",
            "--enable-runtime-qualification",
            "--enable-fault-injection",
            "--enable-kernel-memory-debug",
            "--prune",
            "--rewrite-existing-driver-states",
        )
        positions = [options.index(f"\n  {option}") for option in expected]
        self.assertEqual(positions, sorted(positions))


class VendorModeDetectionTests(unittest.TestCase):
    def test_accepts_each_sky1_usb_integration_generation(self) -> None:
        base = set(KCONFIG.VENDOR_SYMBOLS)

        for usb_symbol in ("USB_CDNSP_SKY1", "USB_CDNS3_SKY1"):
            with self.subTest(usb_symbol=usb_symbol):
                with patch.object(
                    KCONFIG, "scan_kconfig_symbols", return_value=base | {usb_symbol}
                ):
                    self.assertTrue(KCONFIG.resolve_vendor_mode(Path(), "auto"))

    def test_rejects_vendor_tree_without_sky1_usb_integration(self) -> None:
        with patch.object(
            KCONFIG, "scan_kconfig_symbols", return_value=set(KCONFIG.VENDOR_SYMBOLS)
        ):
            with self.assertRaisesRegex(
                SystemExit, "USB_CDNSP_SKY1/USB_CDNS3_SKY1"
            ):
                KCONFIG.resolve_vendor_mode(Path(), "auto")


class HardwareProfileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.available = {
            symbol
            for group in (
                KCONFIG.SUPPORTED_COMMON,
                KCONFIG.SUPPORTED_ACPI_ONLY,
                KCONFIG.SUPPORTED_VENDOR_ACPI_COMMON,
                KCONFIG.SUPPORTED_VENDOR_ACPI_O6,
                KCONFIG.SUPPORTED_VENDOR_DISPLAY,
                KCONFIG.SUPPORTED_VENDOR_GPU,
                KCONFIG.SUPPORTED_VENDOR_MEDIA,
                KCONFIG.SUPPORTED_VENDOR_NPU,
                KCONFIG.SUPPORTED_VENDOR_EDP,
                KCONFIG.SUPPORTED_TOUCHSCREEN,
                KCONFIG.SUPPORTED_VENDOR_AUDIO_ANALOG_O6,
                KCONFIG.SUPPORTED_VENDOR_AUDIO_DISPLAY,
            )
            for symbol, _ in group
        }
        self.available.update(("R8126", "R8169"))

    def test_acpi_prune_preserves_linux_7_2_sky1_cdns3(self) -> None:
        current = {
            "CONFIG_USB_CDNS3": "m",
            "CONFIG_USB_CDNS3_SKY1": "m",
            "CONFIG_USB_CDNS3_STARFIVE": "m",
        }
        available = self.available | {"USB_CDNS3_SKY1"}

        disabled = KCONFIG.dynamic_disabled_symbols(
            current, "o6-acpi", True, False, available
        )

        self.assertNotIn("USB_CDNS3", disabled)
        self.assertNotIn("USB_CDNS3_SKY1", disabled)
        self.assertIn("USB_CDNS3_STARFIVE", disabled)

    def test_acpi_prune_keeps_legacy_cdns3_quarantine(self) -> None:
        current = {
            "CONFIG_USB_CDNS3": "m",
            "CONFIG_USB_CDNS3_STARFIVE": "m",
        }

        disabled = KCONFIG.dynamic_disabled_symbols(
            current, "o6-acpi", True, False, self.available
        )

        self.assertIn("USB_CDNS3", disabled)
        self.assertIn("USB_CDNS3_STARFIVE", disabled)

    def test_generated_platform_menu_is_profile_scoped_without_redundant_guards(self) -> None:
        rendered = KCONFIG.render_kconfig_radxa(
            "7.2", True, "module", self.available
        )

        self.assertIn("\timply CIX_DDR_LP\n", rendered)
        self.assertIn(
            "\timply GPIO_AGGREGATOR if CIX_RADXA_ORION_ACPI\n", rendered
        )
        self.assertIn("\timply GPIOLIB\n", rendered)
        self.assertIn("\timply GPIO_CDEV if GPIO_AGGREGATOR\n", rendered)
        self.assertIn(
            "\tselect PINCTRL_SKY1 if CIX_RADXA_ORION_DT\n", rendered
        )
        self.assertNotIn(
            "\tselect PINCTRL_SKY1 if CIX_RADXA_ORION_ACPI\n", rendered
        )
        self.assertNotIn("\timply CLK_SKY1_ACPI", rendered)
        self.assertNotIn("\timply CIX_ACPI_RESOURCE_LOOKUP", rendered)
        self.assertIn("\tdefault m if MODULES\n", rendered)
        self.assertIn("\tdefault y if !MODULES\n", rendered)
        self.assertNotIn("default m if MODULES &&", rendered)
        self.assertEqual(
            rendered.count(
                "\tdepends on (CIX_RADXA_ORION_O6 || CIX_RADXA_ORION_O6N)\n"
            ),
            1,
        )
        self.assertNotIn("validated vendor", rendered)
        self.assertNotIn("audited Sky1", rendered)

    def supported(
        self,
        hardware_profile: str,
        *,
        with_npu: bool = False,
        with_edp: bool = False,
        with_touchscreen: bool = False,
        graphics_profile: str = "auto",
        audio_profile: str = "auto",
    ) -> dict[str, str]:
        return dict(
            KCONFIG.supported_symbols_for_profile(
                "o6-acpi",
                hardware_profile,
                True,
                with_npu,
                with_edp,
                with_touchscreen,
                self.available,
                graphics_profile,
                audio_profile,
            )
        )

    def test_server_defaults_to_analog_audio_without_graphics(self) -> None:
        supported = self.supported("server")

        self.assertNotIn("DRM_PANTHOR", supported)
        self.assertNotIn("DRM_TRILIN_DPSUB", supported)
        self.assertIn("SND_HDA_CIX_IPBLOQ", supported)
        self.assertNotIn("SND_SOC_SKY1_SOUND_CARD", supported)
        self.assertNotIn("VIDEO_LINLON", supported)
        self.assertNotIn("VIDEO_CIX_ARMCB_ISP", supported)
        self.assertNotIn("ARMCHINA_NPU", supported)
        self.assertNotIn("ARMCHINA_NPU_R2P0", supported)
        self.assertNotIn("PWM_SKY1", supported)
        self.assertNotIn("TOUCHSCREEN_GOODIX", supported)
        self.assertEqual(supported["GPIO_CDEV"], "builtin")
        self.assertEqual(supported["GPIOLIB"], "builtin")
        self.assertEqual(supported["GPIO_CADENCE"], "prefer")
        self.assertEqual(supported["ARM_SCMI_POWER_DOMAIN"], "prefer")
        self.assertEqual(supported["I2C"], "prefer")
        self.assertNotIn("GPIO_CDEV_V1", supported)
        self.assertEqual(supported["GPIO_AGGREGATOR"], "prefer")

    def test_modular_safe_platform_drivers_follow_driver_preference(self) -> None:
        acpi = dict(KCONFIG.SUPPORTED_VENDOR_ACPI_COMMON)
        dt = dict(KCONFIG.SUPPORTED_VENDOR_DT_COMMON)

        for symbol in (
            "ARM_SCMI_POWER_DOMAIN",
            "GPIO_CADENCE",
            "I2C",
            "I2C_CADENCE",
        ):
            self.assertEqual(acpi[symbol], "prefer")

        for symbol in (
            "ARM_SCMI_PROTOCOL",
            "ARM_SCMI_TRANSPORT_MAILBOX",
            "ARM_SCMI_PERF_DOMAIN",
            "ARM_SCMI_POWER_DOMAIN",
            "CIX_MBOX",
            "COMMON_CLK_SCMI",
            "GPIO_CADENCE",
            "I2C",
            "I2C_CADENCE",
        ):
            self.assertEqual(dt[symbol], "prefer")

        self.assertEqual(dict(KCONFIG.SUPPORTED_TOUCHSCREEN)["INPUT"], "prefer")

    def test_desktop_adds_display_and_supported_audio_but_not_media(self) -> None:
        supported = self.supported("desktop")

        self.assertIn("DRM_PANTHOR", supported)
        self.assertIn("DRM_TRILIN_DPSUB", supported)
        self.assertIn("SND_HDA_CIX_IPBLOQ", supported)
        self.assertIn("SND_SOC_SKY1_SOUND_CARD", supported)
        self.assertNotIn("VIDEO_LINLON", supported)
        self.assertNotIn("VIDEO_CIX_ARMCB_ISP", supported)
        self.assertNotIn("ARMCHINA_NPU", supported)
        self.assertNotIn("ARMCHINA_NPU_R2P0", supported)
        self.assertNotIn("PWM_SKY1", supported)

    def test_full_adds_media_while_independent_features_remain_opt_in(self) -> None:
        supported = self.supported("full")

        self.assertIn("DRM_PANTHOR", supported)
        self.assertIn("DRM_TRILIN_DPSUB", supported)
        self.assertIn("SND_HDA_CIX_IPBLOQ", supported)
        self.assertIn("SND_SOC_SKY1_SOUND_CARD", supported)
        self.assertIn("VIDEO_LINLON", supported)
        self.assertIn("VIDEO_CIX_ARMCB_ISP", supported)
        self.assertNotIn("ARMCHINA_NPU", supported)
        self.assertNotIn("ARMCHINA_NPU_R2P0", supported)
        self.assertNotIn("PWM_SKY1", supported)
        self.assertNotIn("TOUCHSCREEN_GOODIX", supported)

    def test_independent_feature_switches_close_over_prerequisites(self) -> None:
        supported = self.supported(
            "server", with_npu=True, with_touchscreen=True
        )

        self.assertIn("ARMCHINA_NPU", supported)
        self.assertIn("ARMCHINA_NPU_R2P0", supported)
        self.assertIn("DMA_SHARED_BUFFER", supported)
        self.assertNotIn("DRM_PANTHOR", supported)
        self.assertIn("DRM_TRILIN_DPSUB", supported)
        self.assertIn("PWM_SKY1", supported)
        self.assertIn("TOUCHSCREEN_GOODIX", supported)
        self.assertEqual(supported["INPUT"], "prefer")

    def test_graphics_override_controls_independent_driver_groups(self) -> None:
        supported = self.supported(
            "full", graphics_profile="gpu", audio_profile="auto"
        )

        self.assertIn("DRM_PANTHOR", supported)
        self.assertNotIn("DRM_TRILIN_DPSUB", supported)
        self.assertNotIn("VIDEO_LINLON", supported)
        self.assertIn("SND_HDA_CIX_IPBLOQ", supported)
        self.assertNotIn("SND_SOC_SKY1_SOUND_CARD", supported)

    def test_explicit_display_audio_closes_over_display_pipeline(self) -> None:
        supported = self.supported(
            "server", graphics_profile="none", audio_profile="display"
        )

        self.assertIn("DRM_TRILIN_DPSUB", supported)
        self.assertNotIn("DRM_PANTHOR", supported)
        self.assertNotIn("SND_HDA_CIX_IPBLOQ", supported)
        self.assertIn("SND_SOC_SKY1_SOUND_CARD", supported)

    def test_audio_none_disables_both_physical_audio_stacks(self) -> None:
        supported = self.supported("full", audio_profile="none")

        self.assertNotIn("SND_HDA_CIX_IPBLOQ", supported)
        self.assertNotIn("SND_SOC_SKY1_SOUND_CARD", supported)

    def test_narrowing_disables_only_owned_hardware_drivers(self) -> None:
        updates = dict(
            KCONFIG.feature_gate_updates(
                "o6-acpi", "server", True, False, False, False
            )
        )

        for symbol in (
            "DRM_PANTHOR",
            "DRM_TRILIN_DPSUB",
            "SND_SOC_SKY1_SOUND_CARD",
            "VIDEO_LINLON",
            "VIDEO_CIX_ARMCB_ISP",
            "ARMCHINA_NPU",
            "ARMCHINA_NPU_R2P0",
            "PWM_SKY1",
            "TOUCHSCREEN_GOODIX",
        ):
            self.assertEqual(updates[symbol], "n")
        for generic in ("DRM", "SND", "MEDIA_SUPPORT", "PWM", "INPUT"):
            self.assertNotIn(generic, updates)

    def test_npu_backends_remain_modules_under_builtin_preference(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            (tree / "Kconfig").write_text(
                """
config MODULES
    bool
config DMA_SHARED_BUFFER
    bool
config ARMCHINA_NPU
    tristate
config ARMCHINA_NPU_R2P0
    tristate
config ARMCHINA_NPU_ARCH_V3
    bool
config ARMCHINA_NPU_SOC_SKY1
    bool
""",
                encoding="utf-8",
            )
            config = tree / ".config"
            config.write_text(
                "\n".join(
                    (
                        "CONFIG_MODULES=y",
                        "CONFIG_DMA_SHARED_BUFFER=y",
                        "CONFIG_ARMCHINA_NPU=y",
                        "CONFIG_ARMCHINA_NPU_R2P0=y",
                        "CONFIG_ARMCHINA_NPU_ARCH_V3=y",
                        "CONFIG_ARMCHINA_NPU_SOC_SKY1=y",
                        "",
                    )
                ),
                encoding="utf-8",
            )

            updates, _ = KCONFIG.build_config_updates(
                kernel_tree=tree,
                profile="o6-acpi",
                hardware_profile="server",
                graphics_profile="auto",
                audio_profile="auto",
                include_vendor=True,
                driver_preference="builtin",
                existing_config=config,
                prune=False,
                with_tpm=False,
                with_npu=True,
                with_edp=False,
                with_touchscreen=False,
                acpi_table_upgrade=None,
                acpi_table_upgrade_initramfs_source=None,
                rewrite_existing_driver_states=False,
                enable_kernel_memory_debug=False,
                enable_runtime_qualification=False,
                enable_fault_injection=False,
                hifi5_dsp=None,
            )

        resolved = dict(updates)
        self.assertEqual(resolved["MODULES"], "y")
        self.assertEqual(resolved["ARMCHINA_NPU"], "m")
        self.assertEqual(resolved["ARMCHINA_NPU_R2P0"], "m")

    def test_input_respects_upstream_builtin_constraints(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            (tree / "Kconfig").write_text(
                """
config EXPERT
    bool
config VT
    bool
config INPUT
    tristate
config INPUT_EVDEV
    tristate
config INPUT_TOUCHSCREEN
    bool
config TOUCHSCREEN_GOODIX
    tristate
""",
                encoding="utf-8",
            )
            config = tree / ".config"

            def resolved_input(expert: str, vt: str) -> str:
                config.write_text(
                    f"CONFIG_EXPERT={expert}\nCONFIG_VT={vt}\nCONFIG_INPUT=y\n",
                    encoding="utf-8",
                )
                updates, _ = KCONFIG.build_config_updates(
                    kernel_tree=tree,
                    profile="o6-acpi",
                    hardware_profile="server",
                    graphics_profile="auto",
                    audio_profile="auto",
                    include_vendor=False,
                    driver_preference="module",
                    existing_config=config,
                    prune=False,
                    with_tpm=False,
                    with_npu=False,
                    with_edp=False,
                    with_touchscreen=True,
                    acpi_table_upgrade=None,
                    acpi_table_upgrade_initramfs_source=None,
                    rewrite_existing_driver_states=True,
                    enable_kernel_memory_debug=False,
                    enable_runtime_qualification=False,
                    enable_fault_injection=False,
                    hifi5_dsp=None,
                )
                return dict(updates)["INPUT"]

            self.assertEqual(resolved_input("n", "n"), "y")
            self.assertEqual(resolved_input("y", "y"), "y")
            self.assertEqual(resolved_input("y", "n"), "m")


class NpuBackendDetectionTests(unittest.TestCase):
    @staticmethod
    def write_file(tree: Path, relative: str, text: str) -> None:
        path = tree / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def populate_separate_backends(self, tree: Path, alias: str = "") -> None:
        self.write_file(
            tree,
            "drivers/misc/armchina-npu-r2p0/Kconfig",
            "config ARMCHINA_NPU_R2P0\n"
            "\ttristate\n"
            "\tdepends on ARMCHINA_NPU != y\n"
            "\tdepends on m || !ARMCHINA_NPU\n",
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu-r2p0/Makefile",
            "obj-$(CONFIG_ARMCHINA_NPU_R2P0) += armchina_npu_r2p0.o\n",
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu-r2p0/include/armchina_aipu.h",
            "AIPU_ISA_VERSION_ZHOUYI_V3   = 5,\n"
            "struct aipu_cap {\n"
            "    __u32 partition_cnt;\n"
            "    __u32 asid_cnt;\n"
            "    __u64 asid_base[32];\n"
            "    __u32 is_homogeneous;\n"
            "    __u64 dtcm_base;\n"
            "    __u32 dtcm_size;\n"
            "    __u32 gm0_size;\n"
            "    __u32 gm1_size;\n"
            "    struct aipu_partition_cap partition_cap;\n"
            "};\n"
            "struct aipu_buf_desc {\n"
            "    __u64 pa;\n"
            "    __u64 dev_offset;\n"
            "    __u64 bytes;\n"
            "    __u8 region;\n"
            "    __u8 asid;\n"
            "};\n"
            "struct aipu_job_desc {\n"
            "    __u32 is_defer_run;\n"
            "    __u32 version_compatible;\n"
            "    __u32 core_id;\n"
            "    __u32 partition_id;\n"
            "    __u32 do_trigger;\n"
            "    __u32 aipu_arch;\n"
            "    __u32 aipu_version;\n"
            "    __u32 aipu_config;\n"
            "    __u32 start_pc_addr;\n"
            "    __u32 intr_handler_addr;\n"
            "    __u32 data_0_addr;\n"
            "    __u32 data_1_addr;\n"
            "    __u64 job_id;\n"
            "    __u32 enable_prof;\n"
            "    __s64 profile_fd;\n"
            "    __u64 profile_pa;\n"
            "    __u32 profile_sz;\n"
            "    __u32 enable_poll_opt;\n"
            "    __u32 exec_flag;\n"
            "    __u32 dtcm_size_kb;\n"
            "    __u64 head_tcb_pa;\n"
            "    __u64 first_task_tcb_pa;\n"
            "    __u64 last_task_tcb_pa;\n"
            "    __u64 tail_tcb_pa;\n"
            "    __u32 is_coredump_en;\n"
            "};\n"
            "#define AIPU_IOCTL_QUERY_CAP _IOR(AIPU_IOCTL_MAGIC, 0, struct aipu_cap)\n"
            "#define AIPU_IOCTL_FREE_BUF _IOW(AIPU_IOCTL_MAGIC, 3, struct aipu_buf_desc)\n"
            "#define AIPU_IOCTL_SCHEDULE_JOB _IOW(AIPU_IOCTL_MAGIC, 6, struct aipu_job_desc)\n"
            "#define AIPU_IOCTL_BUF_CACHE_INVALID _IOW(AIPU_IOCTL_MAGIC, 24, struct aipu_buf_desc)\n"
            "#define AIPU_IOCTL_BUF_CACHE_FLUSH _IOW(AIPU_IOCTL_MAGIC, 25, struct aipu_buf_desc)\n",
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu-r2p0/aipu.c",
            "case AIPU_IOCTL_QUERY_CAP:\n"
            "case AIPU_IOCTL_FREE_BUF:\n"
            "case AIPU_IOCTL_SCHEDULE_JOB:\n"
            "case AIPU_IOCTL_BUF_CACHE_INVALID:\n"
            "case AIPU_IOCTL_BUF_CACHE_FLUSH:\n",
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu-r2p0/aipu_priv.c",
            'aipu->misc.name = "aipu";\n'
            "aipu->misc.mode = 0660;\n",
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu-r2p0/sky1/sky1.c",
            'static const char *name = "armchina-r2p0";\n' + alias,
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu/include/armchina_aipu.h",
            """
AIPU_ISA_VERSION_ZHOUYI_V3_2_0
AIPU_ISA_VERSION_ZHOUYI_V3_2_1
__u64 asid_base[4];
struct aipu_job_desc {
    __u32 group_id;
    __u64 job_id;
    __u64 head_tcb_pa;
    __u64 tail_tcb_pa;
    __u64 asid0_base;
};
""",
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu/aipu_abi_p1.h",
            "\n".join(
                (
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
                    "",
                )
            ),
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu/aipu_abi_p1.c",
            "internal.group_id = 0;\n"
            "internal.asid0_base = aipu->job_manager.asid0_base;\n"
            "aipu_job_manager_owner_guard_begin();\n",
        )
        self.write_file(
            tree,
            "drivers/misc/armchina-npu/aipu.c",
            "aipu_p1_ioctl(aipu, filp, cmd, arg);\n",
        )

    def test_detects_exact_separate_backend_layout(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            self.populate_separate_backends(tree)

            self.assertTrue(KCONFIG.detect_separate_r2p0_backend(tree))
            self.assertEqual(KCONFIG.detect_npu_abi(tree), "separate")
            self.assertEqual(KCONFIG.validate_npu_abi(tree, "auto"), "separate")
            self.assertEqual(
                KCONFIG.validate_npu_abi(tree, "separate"), "separate"
            )
            for incompatible in ("r2p0", "r2p1", "dual"):
                with self.assertRaises(SystemExit):
                    KCONFIG.validate_npu_abi(tree, incompatible)

    def test_rejects_autoload_alias_on_explicit_backend(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            self.populate_separate_backends(
                tree, "MODULE_DEVICE_TABLE(acpi, aipu_acpi_match);\n"
            )

            with self.assertRaisesRegex(SystemExit, "explicit-load only"):
                KCONFIG.detect_separate_r2p0_backend(tree)

    def test_rejects_changed_r2p0_job_layout(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            self.populate_separate_backends(tree)
            header = (
                tree
                / "drivers/misc/armchina-npu-r2p0/include/armchina_aipu.h"
            )
            header.write_text(
                header.read_text(encoding="utf-8").replace(
                    "    __u64 tail_tcb_pa;\n",
                    "    __u64 tail_tcb_pa;\n    __u32 group_id;\n",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                SystemExit, "unexpected struct aipu_job_desc"
            ):
                KCONFIG.detect_separate_r2p0_backend(tree)

    def test_rejects_changed_r2p0_ioctl_contract(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            self.populate_separate_backends(tree)
            header = (
                tree
                / "drivers/misc/armchina-npu-r2p0/include/armchina_aipu.h"
            )
            header.write_text(
                header.read_text(encoding="utf-8").replace(
                    "AIPU_IOCTL_MAGIC, 6, struct aipu_job_desc",
                    "AIPU_IOCTL_MAGIC, 7, struct aipu_job_desc",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(SystemExit, "backend markers"):
                KCONFIG.detect_separate_r2p0_backend(tree)


class DiagnosticProfileTests(unittest.TestCase):
    def test_disabled_memory_profile_preserves_enable_only_prerequisites(self) -> None:
        available = {
            "DEBUG_KERNEL",
            "KALLSYMS",
            "SLUB_DEBUG",
            "STACKTRACE",
            "FUNCTION_TRACER",
            "DMA_API_DEBUG",
            "KASAN",
        }

        updates = dict(
            KCONFIG.kernel_memory_debug_updates(available, False, True)
        )

        self.assertNotIn("DEBUG_KERNEL", updates)
        self.assertNotIn("KALLSYMS", updates)
        self.assertEqual(updates["SLUB_DEBUG"], "n")
        self.assertNotIn("STACKTRACE", updates)
        self.assertEqual(updates["FUNCTION_TRACER"], "n")
        self.assertEqual(updates["DMA_API_DEBUG"], "n")
        self.assertEqual(updates["KASAN"], "n")

    def test_enabled_memory_profile_requests_enable_only_prerequisites(self) -> None:
        available = {
            "DEBUG_KERNEL",
            "KALLSYMS",
            "SLUB_DEBUG",
            "STACKTRACE",
            "FUNCTION_TRACER",
            "DMA_API_DEBUG",
        }

        updates = dict(
            KCONFIG.kernel_memory_debug_updates(available, True, True)
        )

        self.assertEqual(updates["DEBUG_KERNEL"], "y")
        self.assertEqual(updates["KALLSYMS"], "y")
        self.assertEqual(updates["SLUB_DEBUG"], "y")
        self.assertEqual(updates["STACKTRACE"], "y")
        self.assertEqual(updates["FUNCTION_TRACER"], "y")
        self.assertEqual(updates["DMA_API_DEBUG"], "y")

    def test_disabled_memory_profile_preserves_hidden_upstream_slub_debug(self) -> None:
        updates = dict(
            KCONFIG.kernel_memory_debug_updates(
                {"DEBUG_KERNEL", "SLUB_DEBUG"}, False, False
            )
        )

        self.assertNotIn("DEBUG_KERNEL", updates)
        self.assertNotIn("SLUB_DEBUG", updates)

    def test_detects_patched_and_upstream_slub_debug_controls(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tree = Path(directory)
            path = tree / "mm/Kconfig.debug"
            path.parent.mkdir(parents=True)
            path.write_text(
                'config SLUB_DEBUG\n\tdefault y\n'
                '\tbool "Enable SLUB debugging support" if EXPERT\n',
                encoding="utf-8",
            )

            self.assertFalse(
                KCONFIG.slub_debug_can_be_disabled(tree, False)
            )
            self.assertTrue(
                KCONFIG.slub_debug_can_be_disabled(tree, True)
            )

            path.write_text(
                'config SLUB_DEBUG\n\tdefault y\n'
                '\tbool "Enable SLUB debugging support"\n',
                encoding="utf-8",
            )
            self.assertTrue(
                KCONFIG.slub_debug_can_be_disabled(tree, False)
            )

    def test_runtime_profile_does_not_claim_memory_profile_prerequisites(self) -> None:
        available = {
            "DEBUG_KERNEL",
            "EXPERT",
            "KALLSYMS",
            "STACKTRACE",
            "FTRACE",
            "TRACING",
        }

        enabled = dict(KCONFIG.runtime_qualification_updates(available, True))
        disabled = dict(KCONFIG.runtime_qualification_updates(available, False))

        self.assertNotIn("KALLSYMS", enabled)
        self.assertNotIn("STACKTRACE", enabled)
        self.assertEqual(enabled["DEBUG_KERNEL"], "y")
        self.assertEqual(enabled["EXPERT"], "y")
        self.assertNotIn("KALLSYMS", disabled)
        self.assertNotIn("STACKTRACE", disabled)
        self.assertNotIn("DEBUG_KERNEL", disabled)
        self.assertNotIn("EXPERT", disabled)
        self.assertEqual(enabled["FTRACE"], "y")
        self.assertEqual(enabled["TRACING"], "y")
        self.assertEqual(disabled["FTRACE"], "n")
        self.assertEqual(disabled["TRACING"], "n")

    def test_runtime_profile_resolves_sof_developer_choices(self) -> None:
        useful_diagnostics = {
            "SND_SOC_SOF_DEBUG_ENABLE_DEBUGFS_CACHE",
            "SND_SOC_SOF_DEBUG_ENABLE_FIRMWARE_TRACE",
        }
        cleared_diagnostics = {
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
        }
        excluded_diagnostics = {
            "SND_SOC_SOF_NOCODEC_SUPPORT",
            "SND_SOC_SOF_STRICT_ABI_CHECKS",
            "SND_SOC_SOF_ALLOW_FALLBACK_TO_NEWER_IPC_VERSION",
        }
        available = useful_diagnostics | cleared_diagnostics | excluded_diagnostics

        enabled = dict(KCONFIG.runtime_qualification_updates(available, True))
        disabled = dict(KCONFIG.runtime_qualification_updates(available, False))

        for symbol in useful_diagnostics:
            self.assertEqual(enabled[symbol], "y")
            self.assertEqual(disabled[symbol], "n")
        for symbol in cleared_diagnostics:
            self.assertEqual(enabled[symbol], "n")
            self.assertEqual(disabled[symbol], "n")
        for symbol in excluded_diagnostics:
            self.assertEqual(enabled[symbol], "n")
            self.assertNotIn(symbol, disabled)

    def test_hifi5_profile_selects_driver_without_unimplemented_sof(self) -> None:
        symbols = {
            "CIX_DSP_RPROC": "tristate",
            "CIX_HIFI5_FIRMWARE_XAF": "bool",
            "CIX_HIFI5_FIRMWARE_SOF": "bool",
            "RPMSG_VIRTIO": "tristate",
            "RPMSG_CHAR": "tristate",
            "RPMSG_CTRL": "tristate",
            "PAGE_BLOCK_MAX_ORDER": "int",
            "CMA_SIZE_MBYTES": "int",
            "DMABUF_HEAPS": "bool",
            "DMABUF_HEAPS_SYSTEM": "bool",
            "SND_SOC_SOF_TOPLEVEL": "bool",
            "SND_SOC_SOF_ACPI": "tristate",
        }

        updates = dict(
            KCONFIG.hifi5_dsp_updates(
                symbols,
                "module",
                "xaf",
                {
                    "CONFIG_ARM64_64K_PAGES": "y",
                    "CONFIG_PAGE_BLOCK_MAX_ORDER": "13",
                },
            )
        )

        self.assertEqual(updates["CIX_DSP_RPROC"], "m")
        self.assertEqual(updates["RPMSG_VIRTIO"], "m")
        self.assertEqual(updates["RPMSG_CHAR"], "m")
        self.assertEqual(updates["RPMSG_CTRL"], "m")
        self.assertEqual(updates["CIX_HIFI5_FIRMWARE_XAF"], "y")
        self.assertEqual(updates["CIX_HIFI5_FIRMWARE_SOF"], "n")
        self.assertEqual(updates["PAGE_BLOCK_MAX_ORDER"], "9")
        # These are hidden dependencies selected by CIX_DSP_RPROC itself,
        # rather than user-visible settings emitted by the helper.
        self.assertNotIn("DMABUF_HEAPS", updates)
        self.assertNotIn("DMABUF_HEAPS_SYSTEM", updates)
        self.assertNotIn("SND_SOC_SOF_TOPLEVEL", updates)
        self.assertNotIn("SND_SOC_SOF_ACPI", updates)

    def test_hifi5_sof_profile_selects_exclusive_modular_owner(self) -> None:
        symbols = {
            "SOUND": "tristate",
            "SND": "tristate",
            "SND_SOC": "tristate",
            "SND_SOC_SOF_TOPLEVEL": "bool",
            "CIX_HIFI5_FIRMWARE_XAF": "bool",
            "CIX_HIFI5_FIRMWARE_SOF": "bool",
            "CIX_DSP_RPROC": "tristate",
            "SND_SOC_SOF_CIX_SKY1": "tristate",
            "SND_SOC_SOF_FORCE_PROBE_WORKQUEUE": "bool",
            "SND_SOC_SOF_NOCODEC_SUPPORT": "bool",
            "SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT": "bool",
            "SND_SOC_SOF_STRICT_ABI_CHECKS": "bool",
            "SND_SOC_SOF_ALLOW_FALLBACK_TO_NEWER_IPC_VERSION": "bool",
            "PAGE_BLOCK_MAX_ORDER": "int",
        }

        updates = dict(
            KCONFIG.hifi5_dsp_updates(
                symbols,
                "module",
                "sof",
                {
                    "CONFIG_ARM64_64K_PAGES": "y",
                    "CONFIG_PAGE_BLOCK_MAX_ORDER": "13",
                },
            )
        )

        for symbol in (
            "SOUND",
            "SND",
            "SND_SOC",
            "SND_SOC_SOF_CIX_SKY1",
        ):
            self.assertEqual(updates[symbol], "m")
        for symbol in (
            "SND_SOC_SOF_TOPLEVEL",
            "CIX_HIFI5_FIRMWARE_SOF",
        ):
            self.assertEqual(updates[symbol], "y")
        self.assertEqual(updates["CIX_HIFI5_FIRMWARE_XAF"], "n")
        self.assertEqual(updates["CIX_DSP_RPROC"], "n")
        for symbol in (
            "SND_SOC_SOF_FORCE_PROBE_WORKQUEUE",
            "SND_SOC_SOF_NOCODEC_SUPPORT",
            "SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT",
            "SND_SOC_SOF_STRICT_ABI_CHECKS",
            "SND_SOC_SOF_ALLOW_FALLBACK_TO_NEWER_IPC_VERSION",
        ):
            self.assertEqual(updates[symbol], "n")
        self.assertEqual(updates["PAGE_BLOCK_MAX_ORDER"], "9")

        builtin_updates = dict(
            KCONFIG.hifi5_dsp_updates(symbols, "builtin", "sof")
        )
        for symbol in (
            "SOUND",
            "SND",
            "SND_SOC",
            "SND_SOC_SOF_CIX_SKY1",
        ):
            self.assertEqual(builtin_updates[symbol], "y")

    def test_hifi5_sof_profile_rejects_unpatched_kernel(self) -> None:
        with self.assertRaisesRegex(SystemExit, "does not provide"):
            KCONFIG.hifi5_dsp_updates({}, "module", "sof")

    def test_omitted_hifi5_dsp_excludes_both_driver_owners(self) -> None:
        symbols = {
            "CIX_DSP_RPROC": "tristate",
            "SND_SOC_SOF_CIX_SKY1": "tristate",
            "RPMSG_CHAR": "tristate",
        }

        updates = dict(KCONFIG.hifi5_dsp_updates(symbols, "module", None))

        self.assertEqual(updates["CIX_DSP_RPROC"], "n")
        self.assertEqual(updates["SND_SOC_SOF_CIX_SKY1"], "n")
        self.assertNotIn("RPMSG_CHAR", updates)

    def test_platform_cma_minimum_is_limited_to_enabled_64k_cma(self) -> None:
        symbols = {
            "PAGE_BLOCK_MAX_ORDER": "int",
            "CMA_SIZE_MBYTES": "int",
        }

        for page_symbol, cma, configured, expected in (
            ("CONFIG_ARM64_64K_PAGES", "y", None, "128"),
            ("CONFIG_ARM64_64K_PAGES", "y", "32", "128"),
            ("CONFIG_ARM64_64K_PAGES", "y", "128", None),
            ("CONFIG_ARM64_64K_PAGES", "y", "256", None),
            ("CONFIG_ARM64_64K_PAGES", "n", "32", None),
            ("CONFIG_ARM64_16K_PAGES", "y", "32", None),
            ("CONFIG_ARM64_4K_PAGES", "y", "32", None),
        ):
            with self.subTest(
                page_symbol=page_symbol,
                cma=cma,
                configured=configured,
            ):
                current = {
                    page_symbol: "y",
                    "CONFIG_CMA": cma,
                    "CONFIG_PAGE_BLOCK_MAX_ORDER": "9",
                }
                if configured is not None:
                    current["CONFIG_CMA_SIZE_MBYTES"] = configured
                updates = dict(
                    KCONFIG.cix_platform_memory_updates(symbols, current)
                )
                self.assertEqual(updates.get("CMA_SIZE_MBYTES"), expected)

        updates = dict(
            KCONFIG.cix_platform_memory_updates(
                symbols,
                {
                    "CONFIG_ARM64_64K_PAGES": "y",
                    "CONFIG_CMA": "n",
                    "CONFIG_CMA_SIZE_MBYTES": "32",
                    "CONFIG_PAGE_BLOCK_MAX_ORDER": "9",
                },
            )
        )
        self.assertNotIn("CMA_SIZE_MBYTES", updates)

    def test_board_profile_applies_64k_cma_without_hifi5(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Kconfig").write_text(
                "config ARM64_64K_PAGES\n"
                "\tbool\n"
                "config CMA\n"
                "\tbool\n"
                "config CMA_SIZE_MBYTES\n"
                "\tint\n",
                encoding="utf-8",
            )
            current = root / ".config"
            current.write_text(
                "CONFIG_ARM64_64K_PAGES=y\n"
                "CONFIG_CMA=y\n"
                "CONFIG_CMA_SIZE_MBYTES=32\n",
                encoding="utf-8",
            )

            updates, _ = KCONFIG.build_config_updates(
                kernel_tree=root,
                profile="o6-acpi",
                hardware_profile="server",
                graphics_profile="auto",
                audio_profile="auto",
                include_vendor=True,
                driver_preference="module",
                existing_config=current,
                prune=False,
                with_tpm=False,
                with_npu=False,
                with_edp=False,
                with_touchscreen=False,
                acpi_table_upgrade=None,
                acpi_table_upgrade_initramfs_source=None,
                rewrite_existing_driver_states=True,
                enable_kernel_memory_debug=False,
                enable_runtime_qualification=False,
                enable_fault_injection=False,
                hifi5_dsp=None,
            )

        self.assertEqual(dict(updates)["CMA_SIZE_MBYTES"], "128")

    def test_hifi5_pageblock_cap_preserves_compatible_user_values(self) -> None:
        symbols = {"PAGE_BLOCK_MAX_ORDER": "int"}

        for page_symbol, configured, expected in (
            ("CONFIG_ARM64_4K_PAGES", None, None),
            ("CONFIG_ARM64_4K_PAGES", "10", None),
            ("CONFIG_ARM64_4K_PAGES", "8", None),
            ("CONFIG_ARM64_4K_PAGES", "13", "10"),
            ("CONFIG_ARM64_16K_PAGES", None, None),
            ("CONFIG_ARM64_16K_PAGES", "11", None),
            ("CONFIG_ARM64_16K_PAGES", "9", None),
            ("CONFIG_ARM64_16K_PAGES", "13", "11"),
            ("CONFIG_ARM64_64K_PAGES", None, "9"),
            ("CONFIG_ARM64_64K_PAGES", "13", "9"),
            ("CONFIG_ARM64_64K_PAGES", "10", "9"),
            ("CONFIG_ARM64_64K_PAGES", "9", None),
            ("CONFIG_ARM64_64K_PAGES", "8", None),
        ):
            with self.subTest(page_symbol=page_symbol, configured=configured):
                current = {page_symbol: "y"}
                if configured is not None:
                    current["CONFIG_PAGE_BLOCK_MAX_ORDER"] = configured
                updates = dict(
                    KCONFIG.hifi5_xaf_updates(
                        symbols, "module", True, current
                    )
                )
                self.assertEqual(updates.get("PAGE_BLOCK_MAX_ORDER"), expected)

        updates = dict(
            KCONFIG.hifi5_xaf_updates(
                symbols,
                "module",
                True,
                {"CONFIG_PAGE_BLOCK_MAX_ORDER": "13"},
            )
        )
        self.assertNotIn("PAGE_BLOCK_MAX_ORDER", updates)

    def test_board_profile_preserves_smccc_trng_choice(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Kconfig").write_text(
                "config HW_RANDOM_ARM_SMCCC_TRNG\n"
                "\ttristate \"Arm SMCCC TRNG\"\n",
                encoding="utf-8",
            )
            current = root / ".config"
            current.write_text(
                "CONFIG_HW_RANDOM_ARM_SMCCC_TRNG=m\n",
                encoding="utf-8",
            )

            updates, _ = KCONFIG.build_config_updates(
                kernel_tree=root,
                profile="o6-acpi",
                hardware_profile="server",
                graphics_profile="auto",
                audio_profile="auto",
                include_vendor=True,
                driver_preference="module",
                existing_config=current,
                prune=True,
                with_tpm=False,
                with_npu=False,
                with_edp=False,
                with_touchscreen=False,
                acpi_table_upgrade=None,
                acpi_table_upgrade_initramfs_source=None,
                rewrite_existing_driver_states=True,
                enable_kernel_memory_debug=False,
                enable_runtime_qualification=False,
                enable_fault_injection=False,
                hifi5_dsp=None,
            )

        self.assertNotIn("HW_RANDOM_ARM_SMCCC_TRNG", dict(updates))


if __name__ == "__main__":
    unittest.main()
