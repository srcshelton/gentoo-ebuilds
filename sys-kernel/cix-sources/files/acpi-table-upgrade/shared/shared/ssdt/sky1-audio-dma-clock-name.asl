DefinitionBlock ("", "SSDT", 2, "CIXTEK", "S1DMACLK", 0x00000001)
{
    /*
     * CLKA IDs are local to the AUDSS clock provider.  Firmware 1.3 and the
     * inspected O6N table publish the DMA1 DMAC AXI tuple with an empty
     * connection name, while the DMA350 driver requests "axiclk".  In the
     * exact supported tables AUDSS-local ID 9 is unique and its consumer is
     * DMA1.  Match that local ID independently of package order; AML cannot
     * compare Device objects for identity.  Leave malformed or ambiguous
     * alternative-firmware packages unchanged rather than guessing.
     */
    External (\_SB.ADSS.ACLK, DeviceObj)
    External (\_SB.ADSS.ACLK.CLKA, PkgObj)

    Scope (\_SB.ADSS.ACLK)
    {
        Method (_INI, 0, NotSerialized)
        {
            Local0 = Zero
            Local2 = Zero
            Local3 = Zero
            While (Local0 < SizeOf (CLKA))
            {
                Local1 = DerefOf (CLKA [Local0])
                If ((ObjectType (Local1) == 0x04) &&
                    (SizeOf (Local1) == 0x03) &&
                    (ObjectType (DerefOf (Local1 [Zero])) == 0x01) &&
                    (ObjectType (DerefOf (Local1 [One])) == 0x02) &&
                    (DerefOf (Local1 [Zero]) == 0x09))
                {
                    Increment (Local2)
                    Local3 = Local0
                }

                Increment (Local0)
            }

            If (Local2 == One)
            {
                Local1 = DerefOf (CLKA [Local3])
                Store ("axiclk", Local1 [One])
            }
        }
    }
}
