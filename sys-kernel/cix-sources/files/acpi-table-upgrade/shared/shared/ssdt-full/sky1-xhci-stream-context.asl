DefinitionBlock ("", "SSDT", 2, "CIXTEK", "S1XHCSCT", 0x00000001)
{
    // The build includes this table only with a verified replacement DSDT.
    External (\_SB.XHC0, DeviceObj)
    External (\_SB.XHC1, DeviceObj)
    External (\_SB.XHC2, DeviceObj)
    External (\_SB.XHC3, DeviceObj)
    External (\_SB.XHC4, DeviceObj)
    External (\_SB.XHC5, DeviceObj)

    Scope (\_SB.XHC0)
    {
        Name (_DSD, Package (0x02)
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package (0x01)
            {
                Package (0x02)
                {
                    "cdns,stream-context-quirk",
                    One
                }
            }
        })
    }

    Scope (\_SB.XHC1)
    {
        Name (_DSD, Package (0x02)
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package (0x01)
            {
                Package (0x02)
                {
                    "cdns,stream-context-quirk",
                    One
                }
            }
        })
    }

    Scope (\_SB.XHC2)
    {
        Name (_DSD, Package (0x02)
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package (0x01)
            {
                Package (0x02)
                {
                    "cdns,stream-context-quirk",
                    One
                }
            }
        })
    }

    Scope (\_SB.XHC3)
    {
        Name (_DSD, Package (0x02)
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package (0x01)
            {
                Package (0x02)
                {
                    "cdns,stream-context-quirk",
                    One
                }
            }
        })
    }

    Scope (\_SB.XHC4)
    {
        Name (_DSD, Package (0x02)
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package (0x01)
            {
                Package (0x02)
                {
                    "cdns,stream-context-quirk",
                    One
                }
            }
        })
    }

    Scope (\_SB.XHC5)
    {
        Name (_DSD, Package (0x02)
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package (0x01)
            {
                Package (0x02)
                {
                    "cdns,stream-context-quirk",
                    One
                }
            }
        })
    }
}
