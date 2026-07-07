/** @file
  Add only a critical trip point to the stock Radxa Orion O6 EC thermal zone.

  This intentionally does not add new sensor-backed thermal zones, so it can be
  tested independently from the PMMX.SENG sensor overlays.

  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

DefinitionBlock ("", "SSDT", 2, "RADXA", "O6ECTZ", 0x00000001)
{
    External (\_SB.ECTZ, ThermalZoneObj)

    Scope (\_SB.ECTZ)
    {
        Name (_STR, Unicode ("EC"))
        Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
    }
}
