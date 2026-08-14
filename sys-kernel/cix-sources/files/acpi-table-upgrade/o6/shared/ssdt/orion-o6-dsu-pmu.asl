/** @file
  Add the Radxa Orion O6 DSU PMU described by the vendor DTB.

  The vendor DTB exposes an arm,dsu-pmu node using SPI 2. In ACPI that is
  represented by the ARMHD500 HID and GSI 34 (SPI 2 + 32).

  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

DefinitionBlock ("", "SSDT", 2, "RADXA", "O6DSUP", 0x00000001)
{
    Scope (\_SB)
    {
        Device (DSUP)
        {
            Name (_HID, "ARMHD500")
            Name (_UID, Zero)
            Name (_STA, 0x0F)

            Name (_CRS, ResourceTemplate ()
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 34 }
            })
        }
    }
}
