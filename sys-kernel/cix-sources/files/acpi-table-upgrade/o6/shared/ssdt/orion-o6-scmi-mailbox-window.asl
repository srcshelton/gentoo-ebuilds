DefinitionBlock ("", "SSDT", 2, "CIXTEK", "O6MBX", 0x00000003)
{
    External (\_SB.MBXM, MutexObj)
    External (\_SB.MBX6, DeviceObj)
    External (\_SB.MBX6._CRS, BuffObj)
    External (\_SB.MBX7, DeviceObj)
    External (\_SB.MBX7._CRS, BuffObj)
    External (\_SB.PMMX, DeviceObj)
    External (\_SB.PMMX.BEEL, FieldUnitObj)
    External (\_SB.PMMX.BUFF, BuffObj)
    External (\_SB.PMMX.CERR, FieldUnitObj)
    External (\_SB.PMMX.CFRE, FieldUnitObj)
    External (\_SB.PMMX.FLAG, FieldUnitObj)
    External (\_SB.PMMX.LENG, FieldUnitObj)
    External (\_SB.PMMX.MSID, FieldUnitObj)
    External (\_SB.PMMX.MSGP, FieldUnitObj)
    External (\_SB.PMMX.PRID, FieldUnitObj)
    External (\_SB.PMMX.SIGN, FieldUnitObj)

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

    Scope (\_SB.PMMX)
    {
        /*
         * Translate the numeric ACPI processor _UID into the SCMI
         * performance-domain ID used by Sky1 firmware.  This is distinct
         * from the ACPI _PSD coordination-domain number.
         */
        Method (PEGM, 1, NotSerialized)
        {
            If ((Arg0 <= 0x01))
            {
                Return (0x04)
            }

            If ((Arg0 <= 0x05))
            {
                Return (0x02)
            }

            If ((Arg0 <= 0x07))
            {
                Return (0x05)
            }

            If ((Arg0 <= 0x09))
            {
                Return (0x06)
            }

            If ((Arg0 <= 0x0B))
            {
                Return (0x03)
            }

            Return (Ones)
        }

        /*
         * Relay SCMI PERFORMANCE_PROTOCOL_ATTRIBUTES so Linux can prove
         * the unit used by PEFG's power-cost field before registering a
         * real-unit Energy Model.
         */
        Method (PEGA, 0, Serialized)
        {
            If (Acquire (\_SB.MBXM, 0xFFFF))
            {
                Return (Buffer (0x04)
                {
                    0x06
                })
            }

            CERR = Zero
            If ((CFRE == Zero))
            {
                Local0 = 0x0190
                While ((Local0 > Zero))
                {
                    If ((CFRE == One))
                    {
                        Break
                    }

                    Sleep (One)
                    Local0--
                }

                If ((Local0 == Zero))
                {
                    Release (\_SB.MBXM)
                    Return (Buffer (0x04)
                    {
                        0x06
                    })
                }
            }

            SIGN = 0x50434303
            FLAG = Zero
            LENG = 0x04
            MSID = One
            PRID = 0x13
            MSGP = BUFF
            CFRE = Zero
            BEEL = One
            Local0 = 0x0190
            While ((Local0 > Zero))
            {
                If ((CFRE == One))
                {
                    Break
                }

                Sleep (One)
                Local0--
            }

            If ((Local0 == Zero))
            {
                Debug = "ASL Debug: SCMI Timeout\n"
                Release (\_SB.MBXM)
                Return (Buffer (0x04)
                {
                    0x0B
                })
            }

            Local1 = MSGP
            Release (\_SB.MBXM)
            Return (Local1)
        }
    }
}
