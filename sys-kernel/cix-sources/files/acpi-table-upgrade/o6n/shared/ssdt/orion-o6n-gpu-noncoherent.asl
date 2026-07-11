DefinitionBlock ("", "SSDT", 2, "CIXTEK", "O6NGPUCA", 0x00000001)
{
    External (\_SB.GPU, DeviceObj)
    External (\_SB.GPU._CCA, IntObj)

    Scope (\_SB.GPU)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (Zero, _CCA)
        }
    }
}
