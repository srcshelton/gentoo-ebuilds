#define CLK_DMAC_AXI 0x09

DefinitionBlock ("", "SSDT", 2, "CIXTEK", "O6AUDMD", 0x00000001)
{
    /*
     * Align stock ACPI audio metadata with the vendor Device Tree:
     * - DMA1 gets the 12 MiB audio_alsa carveout at 0xd0000000.
     * - HDA gets the missing ACPI _DMA translation for normal DMA API use.
     * - HDA skips the legacy RSVL carveout now that _DMA is present.
     * - DMA1 consumes the AUDSS DMAC AXI clock rather than the FCH DMA clock.
     */
    External (\_SB.DMA1, DeviceObj)
    External (\_SB.DMA1.CLKT, PkgObj)
    External (\_SB.HDA, DeviceObj)
    External (\_SB.REST, DeviceObj)
    External (\_SB.REST.RSVL, PkgObj)

    Scope (\_SB.REST)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (Package () { 0xD0000000, 0x00C00000, "no-map", \_SB.DMA1 },
                Index (RSVL, Zero))
            Store (Package () {}, Index (RSVL, One))
        }
    }

    Scope (\_SB.DMA1)
    {
        Method (_INI, 0, NotSerialized)
        {
            If (CondRefOf (\_SB.DMA1.CLKT))
            {
                Store (Package () { CLK_DMAC_AXI, "", \_SB.DMA1 }, Index (\_SB.DMA1.CLKT, Zero))
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
