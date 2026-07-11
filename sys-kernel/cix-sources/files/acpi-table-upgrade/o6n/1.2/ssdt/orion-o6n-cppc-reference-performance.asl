DefinitionBlock ("", "SSDT", 2, "CIXTEK", "O6NCPPC", 0x00000001)
{
    /*
     * Static repair for vendor firmware 1.2 CPPC ReferencePerformance.
     *
     * The stock table reports 1000 for every CPU. These values are derived from
     * the existing NominalPerformance and NominalFrequency fields using the
     * 1 GHz architected timer seen on Orion O6:
     *
     *   ReferencePerformance = NominalPerformance * 1000 / NominalFrequencyMHz
     *
     * This overlay intentionally leaves CPU topology and CPU numbering alone.
     */
    External (\_SB.C000.C001.CPU0, DeviceObj)
    External (\_SB.C000.C001.CPU0._CPC, PkgObj)
    External (\_SB.C000.C001.CPU1, DeviceObj)
    External (\_SB.C000.C001.CPU1._CPC, PkgObj)
    External (\_SB.C000.C002.CPU2, DeviceObj)
    External (\_SB.C000.C002.CPU2._CPC, PkgObj)
    External (\_SB.C000.C002.CPU3, DeviceObj)
    External (\_SB.C000.C002.CPU3._CPC, PkgObj)
    External (\_SB.C000.C002.CPU4, DeviceObj)
    External (\_SB.C000.C002.CPU4._CPC, PkgObj)
    External (\_SB.C000.C002.CPU5, DeviceObj)
    External (\_SB.C000.C002.CPU5._CPC, PkgObj)
    External (\_SB.C000.C003.CPU6, DeviceObj)
    External (\_SB.C000.C003.CPU6._CPC, PkgObj)
    External (\_SB.C000.C003.CPU7, DeviceObj)
    External (\_SB.C000.C003.CPU7._CPC, PkgObj)
    External (\_SB.C000.C004.CPU8, DeviceObj)
    External (\_SB.C000.C004.CPU8._CPC, PkgObj)
    External (\_SB.C000.C004.CPU9, DeviceObj)
    External (\_SB.C000.C004.CPU9._CPC, PkgObj)
    External (\_SB.C000.C005.CPUA, DeviceObj)
    External (\_SB.C000.C005.CPUA._CPC, PkgObj)
    External (\_SB.C000.C005.CPUB, DeviceObj)
    External (\_SB.C000.C005.CPUB._CPC, PkgObj)

    Scope (\_SB.C000.C001.CPU0)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C001.CPU1)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C002.CPU2)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x04D8, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C002.CPU3)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x04D8, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C002.CPU4)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x04D8, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C002.CPU5)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x04D8, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C003.CPU6)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C003.CPU7)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C004.CPU8)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C004.CPU9)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C005.CPUA)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }

    Scope (\_SB.C000.C005.CPUB)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (0x0C4E, Index (_CPC, 0x14))
        }
    }
}
