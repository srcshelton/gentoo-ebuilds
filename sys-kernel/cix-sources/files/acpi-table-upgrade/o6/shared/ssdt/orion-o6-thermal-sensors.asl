/** @file
  Add the Radxa Orion O6 PMMX.SENG-backed thermal sensor zones.

  The stock EC thermal-zone critical-trip overlay remains separate as O6ECTZ so
  the EC path can be tested and excluded independently from these sensor zones.

  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

DefinitionBlock ("", "SSDT", 2, "RADXA", "O6TZSNS", 0x00000001)
{
    External (\_SB.C2DK, MethodObj)
    External (\_SB.GPU, DeviceObj)
    External (\_SB.PMMX.SENG, MethodObj)

    Scope (\_SB)
    {
        ThermalZone (TZVP)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (Zero, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("VPU"))
        }

        ThermalZone (TZGB)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Name (_TZD, Package () { \_SB.GPU })
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (One, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("GPU Bottom"))
        }

        ThermalZone (TZGP)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Name (_TZD, Package () { \_SB.GPU })
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x02, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("GPU Top"))
        }

        ThermalZone (TZBR)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x03, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("SoC Bridge"))
        }

        ThermalZone (TZD0)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x04, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("DDR Bottom"))
        }

        ThermalZone (TZD1)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x05, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("DDR Top"))
        }

        ThermalZone (TZCI)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x06, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("CI700 Interconnect"))
        }

        ThermalZone (TZNP)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x07, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("NPU"))
        }

        ThermalZone (TZTR)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x0C, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("SoC Trace"))
        }

        ThermalZone (TZN0)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x0E, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("Board Thermistor 0"))
        }

        ThermalZone (TZN1)
        {
            Method (_CRT, 0, NotSerialized) { Return (0x0E80) }
            Method (_TMP, 0, Serialized)
            {
                Local0 = \_SB.PMMX.SENG (0x0F, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (\_SB.C2DK (TEMP))
                }

                Return (Ones)
            }
            Method (_TZP, 0, NotSerialized) { Return (0x0A) }
            Name (_STR, Unicode ("Board Thermistor 1"))
        }
    }
}
