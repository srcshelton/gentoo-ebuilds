DefinitionBlock ("", "SSDT", 2, "CIXTEK", "S1DMAR", 0x00000001)
{
    /*
     * DMA1 has a 32-bit view of system memory.  Device address 0x30000000
     * corresponds to CPU physical address 0xc0000000, giving a 3.25 GiB
     * aperture before the device address reaches 0xffffffff.
     *
     * Linux retains address translation offsets from producer descriptors
     * when constructing dma_range_map.  Keep this descriptor form aligned
     * with that parser until the ACPI _DMA consumer example and Linux
     * resource handling are reconciled upstream.
     */
    External (\_SB.DMA1, DeviceObj)

    Scope (\_SB.DMA1)
    {
        Name (_DMA, ResourceTemplate ()
        {
            QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                0x0000000000000000, // Granularity
                0x0000000030000000, // Device address minimum
                0x00000000FFFFFFFF, // Device address maximum
                0x0000000090000000, // CPU minus device address
                0x00000000D0000000, // Length
                ,, , AddressRangeMemory, TypeStatic)
        })
    }
}
