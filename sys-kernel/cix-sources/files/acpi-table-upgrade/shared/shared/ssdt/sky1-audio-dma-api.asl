DefinitionBlock ("", "SSDT", 2, "CIXTEK", "S1AUDAPI", 0x00000001)
{
    /*
     * Use normal DMA-API allocation rather than the vendor's late, private
     * fixed-pool metadata.  RSVL is not an EFI reservation and the retained
     * ACPI drivers do not consume it.  Empty the DMA1/HDA entries on native
     * tables while leaving any later, unrelated entry unchanged.
     *
     * The vendor DMA1.CLKT package is intentionally left unchanged.  Its
     * tuple names DMA0 as the consumer of the FCH DMA SCMI clock; DMA1 gets
     * its separate AUDSS-local DMAC AXI clock from ADSS.ACLK.CLKA.
     */
    External (\_SB.HDA, DeviceObj)
    External (\_SB.REST, DeviceObj)
    External (\_SB.REST.RSVL, PkgObj)

    Scope (\_SB.REST)
    {
        Method (_INI, 0, NotSerialized)
        {
            If (LGreaterEqual (SizeOf (RSVL), 0x02))
            {
                Store (Package () { Zero }, Index (RSVL, Zero))
                Store (Package () { Zero }, Index (RSVL, One))
            }
        }
    }

    Scope (\_SB.HDA)
    {
        Name (_DMA, ResourceTemplate ()
        {
            QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                0x0000000000000000, // Granularity
                0x0000000000000000, // Range Minimum
                0x000000007FFFFFFF, // Range Maximum
                0x0000000090000000, // Translation Offset
                0x0000000080000000, // Length
                ,, , AddressRangeMemory, TypeStatic)
        })
    }
}
