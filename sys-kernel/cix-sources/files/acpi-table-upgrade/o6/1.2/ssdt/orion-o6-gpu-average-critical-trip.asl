/** @file
  Add the firmware-1.3 GPU-average critical trip to O6 firmware 1.2.

  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

DefinitionBlock ("", "SSDT", 2, "RADXA", "O6GCRT", 0x00000001)
{
    External (\_SB.TZGT, ThermalZoneObj)

    Scope (\_SB.TZGT)
    {
        Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
    }
}
