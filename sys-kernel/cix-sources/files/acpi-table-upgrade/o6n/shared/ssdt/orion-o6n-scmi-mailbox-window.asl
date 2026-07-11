DefinitionBlock ("", "SSDT", 2, "CIXTEK", "O6NMBX", 0x00000001)
{
    External (\_SB.MBX6, DeviceObj)
    External (\_SB.MBX6._CRS, BuffObj)
    External (\_SB.MBX7, DeviceObj)
    External (\_SB.MBX7._CRS, BuffObj)

    Scope (\_SB.MBX6)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite, 0x06590080, 0x0000FF80)
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive)
                    { 0x0000018B }
            }, _CRS)
        }
    }

    Scope (\_SB.MBX7)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite, 0x065A0080, 0x0000FF80)
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive)
                    { 0x00000187 }
            }, _CRS)
        }
    }
}
