/** @file
  Supplemental BusPerf devices for Radxa Orion O6 ACPI table upgrade.

  Copyright 2026 Cix Technology Group Co., Ltd. All Rights Reserved.

  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

DefinitionBlock ("", "SSDT", 2, "CIXTEK", "O6BPERF", 0x00000001)
{
    External (\_SB.SCMI.DVFS, DeviceObj)

    Scope (\_SB)
    {
        Device (CI70)
        {
            Name (_HID, "CIXHA030")
            Name (_UID, Zero)
            Name (_STA, 0x0F)

            Name (_DSD, Package ()
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package ()
                {
                    Package () { "compatible", "cix,bus-ci700" },
                    Package () { "power-domains", Package () { \_SB.SCMI.DVFS, 10 } },
                    Package () { "power-domain-names", Package () { "perf" } },
                },
            })
        }

        Device (MMHB)
        {
            Name (_HID, "CIXHA031")
            Name (_UID, Zero)
            Name (_STA, 0x0F)

            Name (_DSD, Package ()
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package ()
                {
                    Package () { "compatible", "cix,bus-ni700" },
                    Package () { "power-domains", Package () { \_SB.SCMI.DVFS, 11 } },
                    Package () { "power-domain-names", Package () { "perf" } },
                },
            })
        }
    }
}
