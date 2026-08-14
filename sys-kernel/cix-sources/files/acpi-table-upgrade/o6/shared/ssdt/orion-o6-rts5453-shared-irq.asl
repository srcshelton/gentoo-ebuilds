DefinitionBlock ("", "SSDT", 2, "RADXA", "O6RTSIRQ", 0x00000001)
{
    External (\_SB.I2C1.PD10, DeviceObj)
    External (\_SB.I2C1.PD10._CRS, BuffObj)
    External (\_SB.I2C1.PD11, DeviceObj)
    External (\_SB.I2C1.PD11._CRS, BuffObj)

    Scope (\_SB.I2C1.PD10)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (ResourceTemplate ()
            {
                I2cSerialBusV2 (0x0030, ControllerInitiated, 0x000186A0,
                    AddressingMode7Bit, "\\_SB.I2C1", 0x00, ResourceConsumer,
                    , Exclusive, )
                GpioInt (Level, ActiveLow, Shared, PullUp, 0x0000,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, , )
                    { 0x0008 }
            }, _CRS)
        }
    }

    Scope (\_SB.I2C1.PD11)
    {
        Method (_INI, 0, NotSerialized)
        {
            Store (ResourceTemplate ()
            {
                I2cSerialBusV2 (0x0031, ControllerInitiated, 0x000186A0,
                    AddressingMode7Bit, "\\_SB.I2C1", 0x00, ResourceConsumer,
                    , Exclusive, )
                GpioInt (Level, ActiveLow, Shared, PullUp, 0x0000,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, , )
                    { 0x0008 }
            }, _CRS)
        }
    }
}
