/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 *
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of the ORIONO6 SSDT extracted from the Radxa O6 1.2.1
 * cix_flash_all.bin release image. The corresponding vendor source is
 * unchanged through Radxa firmware 1.2.4.
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00003EF8 (16120)
 *     Revision         0x02
 *     Checksum         0xCE
 *     OEM ID           "RADXA"
 *     OEM Table ID     "ORIONO6"
 *     OEM Revision     0x00000001 (1)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200925 (538970405)
 *
 * The replacement table uses OEM revision 2 so Linux upgrades the firmware's
 * revision 1 table. The three USB VBUS consumers below use the pin-group names
 * published by MUX1. Regulator names remain unchanged.
 */
DefinitionBlock ("", "SSDT", 2, "RADXA", "ORIONO6", 0x00000002)
{
    External (_SB_.AMTX, MethodObj)    // 2 Arguments
    External (_SB_.GPI0, DeviceObj)
    External (_SB_.GPI1, DeviceObj)
    External (_SB_.GPI2, DeviceObj)
    External (_SB_.GPI3, DeviceObj)
    External (_SB_.GPI4, DeviceObj)
    External (_SB_.GPI5, DeviceObj)
    External (_SB_.HDA_, DeviceObj)
    External (_SB_.I2C0, DeviceObj)
    External (_SB_.I2C1, DeviceObj)
    External (_SB_.I2C3.MXID, IntObj)
    External (_SB_.I2C6.MXID, IntObj)
    External (_SB_.ISP0, DeviceObj)
    External (_SB_.MUX1, DeviceObj)
    External (_SB_.PRC0, DeviceObj)
    External (_SB_.PRC1, DeviceObj)
    External (_SB_.PRC2, DeviceObj)
    External (_SB_.PRC3, DeviceObj)
    External (_SB_.PRC4, DeviceObj)
    External (_SB_.RMTX, MethodObj)    // 2 Arguments
    External (_SB_.SUB0.CUB0, DeviceObj)
    External (_SB_.SUB2.CUB2, DeviceObj)
    External (_SB_.UCP0, DeviceObj)
    External (_SB_.UCP2, DeviceObj)

    Scope (_SB)
    {
        Device (SNDC)
        {
            Name (_HID, "CIXH6070")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_sndcard", ResourceConsumer, ,)
            })
        }

        Device (CPE4)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI1", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0006
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "cam_power_en_4"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^CPE4,
                            Zero,
                            Zero,
                            Zero
                        }
                    }
                }
            })
        }

        Scope (\_SB.I2C0)
        {
            Device (IIS0)
            {
                Name (_HID, "CIXH3024")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    I2cSerialBusV2 (0x0034, ControllerInitiated, 0x00061A80,
                        AddressingMode7Bit, "\\_SB.I2C0",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                    PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                        "pinctrl_cam0_hw", ResourceConsumer, ,)
                    GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                        "\\_SB.GPI1", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x000D,
                            0x000E
                        }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x06)
                    {
                        Package (0x02)
                        {
                            "actuator-src",
                            \_SB.I2C0.MTR0
                        },

                        Package (0x02)
                        {
                            "isp-src",
                            \_SB.ISP0
                        },

                        Package (0x02)
                        {
                            "cix,camera-module-index",
                            Zero
                        },

                        Package (0x02)
                        {
                            "power0-supply",
                            Package (0x01)
                            {
                                \_SB.CPE4
                            }
                        },

                        Package (0x02)
                        {
                            "reset-gpios",
                            Package (0x04)
                            {
                                ^IIS0,
                                Zero,
                                Zero,
                                Zero
                            }
                        },

                        Package (0x02)
                        {
                            "pwdn-gpios",
                            Package (0x04)
                            {
                                ^IIS0,
                                Zero,
                                One,
                                Zero
                            }
                        }
                    }
                })
                Name (CLKT, Package (0x01)
                {
                    Package (0x03)
                    {
                        0x48,
                        "mclk",
                        \_SB.I2C0.IIS0
                    }
                })
            }

            Device (MTR0)
            {
                Name (_HID, "CIXH3023")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    I2cSerialBusV2 (0x0040, ControllerInitiated, 0x0773593F,
                        AddressingMode7Bit, "\\_SB.I2C0",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "pi-max-frequency",
                            0x0773593F
                        }
                    }
                })
            }
        }

        Scope (\_SB.I2C1)
        {
            Device (IIS1)
            {
                Name (_HID, "CIXH3024")  // _HID: Hardware ID
                Name (_UID, One)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    I2cSerialBusV2 (0x0036, ControllerInitiated, 0x00061A80,
                        AddressingMode7Bit, "\\_SB.I2C1",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                    PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                        "pinctrl_cam1_hw", ResourceConsumer, ,)
                    GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                        "\\_SB.GPI1", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x000A,
                            0x0007
                        }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x04)
                    {
                        Package (0x02)
                        {
                            "cix,camera-module-index",
                            One
                        },

                        Package (0x02)
                        {
                            "power0-supply",
                            Package (0x01)
                            {
                                \_SB.CPE4
                            }
                        },

                        Package (0x02)
                        {
                            "reset-gpios",
                            Package (0x04)
                            {
                                ^IIS1,
                                Zero,
                                Zero,
                                Zero
                            }
                        },

                        Package (0x02)
                        {
                            "pwdn-gpios",
                            Package (0x04)
                            {
                                ^IIS1,
                                Zero,
                                One,
                                Zero
                            }
                        }
                    }
                })
                Name (CLKT, Package (0x01)
                {
                    Package (0x03)
                    {
                        0x4A,
                        "mclk",
                        \_SB.I2C1.IIS1
                    }
                })
            }
        }

        Device (EC0)
        {
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_HID, "CIXHA015")  // _HID: Hardware ID
            Mutex (ECMX, 0x00)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x03)
            }

            OperationRegion (I2CA, SystemMemory, 0x04070000, 0x0100)
            Field (I2CA, DWordAcc, NoLock, Preserve)
            {
                CR,     32,
                SR,     32,
                AR,     32,
                DR,     32,
                ISR,    32,
                TSR,    32,
                SMPR,   32,
                TOR,    32,
                IMR,    32,
                IER,    32,
                IDR,    32,
                GFCR,   32
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                REST ()
            }

            Method (REST, 0, Serialized)
            {
                IDR = 0x02FF
                Local0 = CR /* \_SB_.EC0_.CR__ */
                Local0 &= 0xFFFFFFFFFFFFFFEF
                Local0 |= 0x40
                CR = Local0
                TSR = Zero
                Local0 = ISR /* \_SB_.EC0_.ISR_ */
                ISR = Local0
                Local0 = SR /* \_SB_.EC0_.SR__ */
                SR = Local0
            }

            Method (STAT, 0, Serialized)
            {
                Local0 = CR /* \_SB_.EC0_.CR__ */
                If (!(Local0 & 0x04))
                {
                    CR = (Local0 | 0x04)
                }

                CLRB ()
                Local1 = 0x000F4240
                While (Local1)
                {
                    Local0 = SR /* \_SB_.EC0_.SR__ */
                    If (!(Local0 & 0x0100))
                    {
                        Break
                    }

                    Local1--
                }

                If ((Local1 == Zero))
                {
                    Return (0x02)
                }

                SETB ()
                Return (Zero)
            }

            Method (STOP, 0, Serialized)
            {
                CLRB ()
                CLRF ()
            }

            Method (READ, 4, Serialized)
            {
                If ((Arg1 == Zero))
                {
                    Return (Zero)
                }

                If ((Arg1 > 0x10))
                {
                    TSR = 0x11
                }
                Else
                {
                    TSR = Arg1
                }

                Local0 = Arg3
                Local0 = CR /* \_SB_.EC0_.CR__ */
                Local0 |= One
                CR = Local0
                AR = (Arg0 & 0x03FF)
                Local3 = Zero
                While ((Arg1 != Zero))
                {
                    Local0 = ISR /* \_SB_.EC0_.ISR_ */
                    ISR = Local0
                    If ((Local0 & 0x08))
                    {
                        Return (0x02)
                    }

                    If ((Local0 & 0x04))
                    {
                        Return (One)
                    }

                    Local0 &= 0xFFFFFFFFFFFFFFFD
                    Local0 &= 0xFFFFFFFFFFFFFFFE
                    If ((Local0 != Zero))
                    {
                        Return (One)
                    }

                    If ((Arg1 <= 0x10))
                    {
                        Local1 = One
                    }
                    Else
                    {
                        Local1 = Zero
                    }

                    If ((Local1 == One))
                    {
                        If ((SR & 0x20))
                        {
                            Arg2 [Local3] = DR /* \_SB_.EC0_.DR__ */
                            Local3 += One
                            Arg1 -= One
                        }

                        Continue
                    }

                    Local4 = TSR /* \_SB_.EC0_.TSR_ */
                    If ((Local4 != One))
                    {
                        Continue
                    }

                    Local5 = (Arg1 - 0x10)
                    If ((Local5 > 0x10))
                    {
                        TSR = 0x11
                    }
                    Else
                    {
                        TSR = Local5
                    }

                    Local5 = 0x10
                    While ((Local5 != Zero))
                    {
                        Arg2 [Local3] = DR /* \_SB_.EC0_.DR__ */
                        Local3 += One
                        Arg1 -= One
                        Local5 -= One
                    }
                }

                Return (Zero)
            }

            Method (WRIT, 4, Serialized)
            {
                If ((Arg1 == Zero))
                {
                    Return (Zero)
                }

                Local0 = Arg3
                Local0 = IER /* \_SB_.EC0_.IER_ */
                Local0 |= One
                IER = Local0
                Local0 = CR /* \_SB_.EC0_.CR__ */
                Local0 &= 0xFFFFFFFFFFFFFFFE
                CR = Local0
                Local0 = ISR /* \_SB_.EC0_.ISR_ */
                ISR = Local0
                TSR = Zero
                AR = (Arg0 & 0x03FF)
                Local0 = Zero
                Local1 = Arg1
                DR = DerefOf (Arg2 [Local0])
                Local0++
                Local1--
                While (One)
                {
                    If ((Local1 <= 0x0F))
                    {
                        Local2 = One
                        Local3 = Local1
                    }
                    Else
                    {
                        Local2 = Zero
                        Local3 = 0x0F
                    }

                    Local4 = Local3
                    While ((Local4 > Zero))
                    {
                        DR = DerefOf (Arg2 [Local0])
                        Local1--
                        Local4--
                        Local0++
                    }

                    If (Local2)
                    {
                        TSR = (Local3 + One)
                    }
                    Else
                    {
                        TSR = Local3
                    }

                    Local5 = 0x000F4240
                    While (One)
                    {
                        Local6 = ISR /* \_SB_.EC0_.ISR_ */
                        ISR = Local6
                        Local6 &= 0xFFFFFFFFFFFFFFFD
                        Local5--
                        If (((Local5 == Zero) || (Local6 != Zero)))
                        {
                            Break
                        }
                    }

                    If ((Local5 == Zero))
                    {
                        Return (0x02)
                    }

                    If ((Local6 & 0xFFFFFFFFFFFFFFFE))
                    {
                        If ((Local6 & 0x08))
                        {
                            Return (0x02)
                        }

                        If ((Local6 & 0x40))
                        {
                            CLRF ()
                        }

                        Return (One)
                    }

                    If (Local2)
                    {
                        Return (Zero)
                    }
                }

                Return (Zero)
            }

            Method (CKSB, 1, Serialized)
            {
                Local0 = SizeOf (Arg0)
                Local1 = Zero
                Local2 = Zero
                While ((Local1 < Local0))
                {
                    If ((Local1 != One))
                    {
                        Mid (Arg0, Local1, One, Local3)
                        Local2 += ToInteger (Local3)
                    }

                    Local1++
                }

                Return ((0x0100 - (Local2 & 0xFF)))
            }

            Method (CLRB, 0, Serialized)
            {
                Local0 = CR /* \_SB_.EC0_.CR__ */
                If ((Local0 & 0x10))
                {
                    CR = (Local0 & 0xFFFFFFFFFFFFFFEF)
                }
            }

            Method (SETB, 0, Serialized)
            {
                Local0 = CR /* \_SB_.EC0_.CR__ */
                If (!(Local0 & 0x10))
                {
                    CR = (Local0 | 0x10)
                }
            }

            Method (CLRF, 0, Serialized)
            {
                Local0 = CR /* \_SB_.EC0_.CR__ */
                CR = (Local0 | 0x40)
                While ((CR & 0x40)){}
            }

            Method (TRAS, 4, Serialized)
            {
                Acquire (ECMX, 0xFFFF)
                If (\_SB.AMTX (\_SB.I2C6.MXID, 0x1A))
                {
                    Return (One)
                }

                Local0 = Zero
                While (One)
                {
                    If ((STAT () != Zero))
                    {
                        Break
                    }

                    CLRF ()
                    Local1 = ISR /* \_SB_.EC0_.ISR_ */
                    ISR = Local1
                    If ((WRIT (0x76, Arg1, Arg0, Zero) != Zero))
                    {
                        Break
                    }

                    If ((READ (0x76, Arg3, Arg2, One) != Zero))
                    {
                        Break
                    }

                    Local0 = One
                    Break
                }

                If ((Local0 == Zero))
                {
                    REST ()
                    STOP ()
                    \_SB.RMTX (\_SB.I2C6.MXID, 0x1A)
                    Release (ECMX)
                    Return (One)
                }

                \_SB.RMTX (\_SB.I2C6.MXID, 0x1A)
                Release (ECMX)
                CreateByteField (Arg2, One, LENG)
                If ((LENG != Arg3))
                {
                    Return (One)
                }

                CreateByteField (Arg2, 0x03, CSUM)
                Mid (Arg2, 0x02, (LENG - 0x02), Local1)
                If ((CSUM != (CKSB (Local1) & 0xFF)))
                {
                    Return (One)
                }

                Return (Zero)
            }

            Method (EVNT, 0, Serialized)
            {
                Local1 = Buffer (0x09)
                    {
                        /* 0000 */  0xDA, 0x03, 0xA8, 0x00, 0x55, 0x00, 0x00, 0x00,  // ....U...
                        /* 0008 */  0x00                                             // .
                    }
                Local2 = Buffer (0x0F){}
                If ((TRAS (Local1, SizeOf (Local1), Local2, 0x0F) == Zero))
                {
                    CreateByteField (Local2, 0x0A, TYPE)
                    CreateDWordField (Local2, 0x0B, DATA)
                    Local0 = TYPE /* \_SB_.EC0_.EVNT.TYPE */
                    Local0 = DATA /* \_SB_.EC0_.EVNT.DATA */
                    Local0 = (((((Local0 & 0xFF) << 0x18) | (
                        (Local0 & 0xFF00) << 0x08)) | ((Local0 & 0x00FF0000) >> 0x08
                        )) | ((Local0 & 0xFF000000) >> 0x18))
                    NTII (Local0)
                }
            }

            Method (NTII, 1, Serialized)
            {
                If ((Arg0 & 0x02))
                {
                    Notify (\_SB.PWRB, 0x80) // Status Change
                }

                If ((Arg0 & 0x0200)){}
                If ((Arg0 & 0x0400)){}
                If ((Arg0 & 0x0800)){}
            }

            Method (WRGP, 2, Serialized)
            {
                Local1 = Buffer (0x0B)
                    {
                        /* 0000 */  0xDA, 0x03, 0x00, 0x00, 0x92, 0x00, 0x00, 0x00,  // ........
                        /* 0008 */  0x02, 0x00, 0x00                                 // ...
                    }
                CreateByteField (Local1, 0x02, CSUM)
                CreateByteField (Local1, 0x09, GNUM)
                CreateByteField (Local1, 0x0A, GVAL)
                GNUM = Arg0
                GVAL = Arg1
                Mid (Local1, One, (SizeOf (Local1) - One), Local0)
                CSUM = (CKSB (Local0) & 0xFF)
                Local2 = Buffer (0x0B){}
                TRAS (Local1, SizeOf (Local1), Local2, SizeOf (Local2))
            }

            Method (RDGP, 1, Serialized)
            {
                Local1 = Buffer (0x0A)
                    {
                        /* 0000 */  0xDA, 0x03, 0x00, 0x00, 0x93, 0x00, 0x00, 0x00,  // ........
                        /* 0008 */  0x01, 0x00                                       // ..
                    }
                CreateByteField (Local1, 0x02, CSUM)
                CreateByteField (Local1, 0x09, GNUM)
                GNUM = Arg0
                Mid (Local1, One, (SizeOf (Local1) - One), Local0)
                CSUM = (CKSB (Local0) & 0xFF)
                Local2 = Buffer (0x0B){}
                TRAS (Local1, SizeOf (Local1), Local2, SizeOf (Local2))
                Sleep (0x14)
                TRAS (Local1, SizeOf (Local1), Local2, SizeOf (Local2))
                CreateByteField (Local2, 0x0A, GVAL)
                Return (GVAL) /* \_SB_.EC0_.RDGP.GVAL */
            }

            Method (SFAT, 0, Serialized)
            {
                Local0 = Buffer (0x0A)
                    {
                        /* 0000 */  0xDA, 0x03, 0xA9, 0x00, 0x52, 0x00, 0x00, 0x00,  // ....R...
                        /* 0008 */  0x01, 0x01                                       // ..
                    }
                Local1 = Buffer (0x0A){}
                TRAS (Local0, SizeOf (Local0), Local1, SizeOf (Local1))
            }

            Method (SFMT, 0, Serialized)
            {
                Local0 = Buffer (0x0A)
                    {
                        /* 0000 */  0xDA, 0x03, 0xA8, 0x00, 0x52, 0x00, 0x00, 0x00,  // ....R...
                        /* 0008 */  0x01, 0x02                                       // ..
                    }
                Local1 = Buffer (0x0A){}
                TRAS (Local0, SizeOf (Local0), Local1, SizeOf (Local1))
            }

            Method (SFPF, 0, Serialized)
            {
                Local0 = Buffer (0x0A)
                    {
                        /* 0000 */  0xDA, 0x03, 0xA6, 0x00, 0x52, 0x00, 0x00, 0x00,  // ....R...
                        /* 0008 */  0x01, 0x04                                       // ..
                    }
                Local1 = Buffer (0x0A){}
                TRAS (Local0, SizeOf (Local0), Local1, SizeOf (Local1))
            }

            Method (SFFD, 0, Serialized)
            {
                SFPW (0x64)
            }

            Method (SFZD, 0, Serialized)
            {
                SFPW (Zero)
            }

            Method (GFPW, 0, Serialized)
            {
                Local0 = Buffer (0x0B)
                    {
                        /* 0000 */  0xDA, 0x03, 0xD5, 0x00, 0x26, 0x00, 0x00, 0x00,  // ....&...
                        /* 0008 */  0x02, 0x00, 0x00                                 // ...
                    }
                Local1 = Buffer (0x0C){}
                If ((TRAS (Local0, SizeOf (Local0), Local1, SizeOf (Local1)) == Zero))
                {
                    CreateByteField (Local1, 0x0B, DUTY)
                    Return (DUTY) /* \_SB_.EC0_.GFPW.DUTY */
                }

                Return (0xFF)
            }

            Method (SFPW, 1, Serialized)
            {
                If ((Arg0 > 0x64))
                {
                    Return (One)
                }

                SFAT ()
                Local0 = Buffer (0x0D)
                    {
                        /* 0000 */  0xDA, 0x03, 0xFF, 0x00, 0x25, 0x00, 0x00, 0x00,  // ....%...
                        /* 0008 */  0x04, 0x00, 0xFF, 0x00, 0x00                     // .....
                    }
                Local1 = Buffer (0x0A){}
                CreateByteField (Local0, 0x02, CSUM)
                CreateByteField (Local0, 0x0A, DUTY)
                CSUM = (0xD4 - Arg0)
                DUTY = Arg0
                TRAS (Local0, SizeOf (Local0), Local1, SizeOf (Local1))
                Return (Zero)
            }
        }

        Name (ECFM, Zero)
        PowerResource (ECFN, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Local0 = \_SB.EC0.GFPW ()
                If (((Local0 != 0xFF) && (Local0 != Zero)))
                {
                    Return (One)
                }

                Return (Zero)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Switch (ToInteger (\_SB.ECFM))
                {
                    Case (Zero)
                    {
                        \_SB.EC0.SFAT ()
                    }
                    Case (One)
                    {
                        \_SB.EC0.SFPF ()
                    }
                    Case (0x02)
                    {
                        \_SB.EC0.SFMT ()
                    }
                    Default
                    {
                        \_SB.EC0.SFAT ()
                    }

                }
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                \_SB.EC0.SFMT ()
                \_SB.EC0.SFZD ()
            }
        }

        Device (ECFP)
        {
            Name (_HID, EisaId ("PNP0C0B") /* Fan (Thermal Solution) */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                ECFN
            })
        }

        ThermalZone (ECTZ)
        {
            Name (_TZD, Package (0x01)  // _TZD: Thermal Zone Devices
            {
                \_SB
            })
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                Local2 = Buffer (0x09)
                    {
                        /* 0000 */  0xDA, 0x03, 0xB3, 0x3E, 0x0C, 0x00, 0x00, 0x00,  // ...>....
                        /* 0008 */  0x00                                             // .
                    }
                Local3 = Buffer (0x0C){}
                If ((\_SB.EC0.TRAS (Local2, SizeOf (Local2), Local3, SizeOf (Local3)) == Zero))
                {
                    CreateByteField (Local3, 0x0A, TMPI)
                    CreateByteField (Local3, 0x0B, TMPF)
                    TMPI = ToInteger (TMPI)
                    TMPF = ToInteger (TMPF)
                    Local0 = (TMPI * 0x0A)
                    Local1 = (TMPF / 0x0A)
                    Local0 += Local1
                    Local0 += 0x0AAC
                    Return (Local0)
                }

                Return (Zero)
            }

            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
            }

            Method (_TZP, 0, NotSerialized)  // _TZP: Thermal Zone Polling
            {
                Return (0x012C)
            }
        }

        Device (PWRB)
        {
            Name (_HID, EisaId ("PNP0C0C") /* Power Button Device */)  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }
        }

        Scope (\_SB.I2C1)
        {
            Device (PD10)
            {
                Name (_HID, "CIXH200D")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    I2cSerialBusV2 (0x0030, ControllerInitiated, 0x000186A0,
                        AddressingMode7Bit, "\\_SB.I2C1",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                    GpioInt (Level, ActiveLow, Exclusive, PullUp, 0x0000,
                        "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x0008
                        }
                })
                Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "id",
                            Zero
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "usbc_con0",
                            "UC00"
                        }
                    }
                })
                Name (UC00, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "data-role",
                            "host"
                        },

                        Package (0x02)
                        {
                            "power-role",
                            "source"
                        },

                        Package (0x02)
                        {
                            "try-power-role",
                            "source"
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "port@0",
                            "PRT0"
                        },

                        Package (0x02)
                        {
                            "port@1",
                            "PRT1"
                        },

                        Package (0x02)
                        {
                            "port@2",
                            "PRT2"
                        }
                    }
                })
                Name (PRT0, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg",
                            Zero
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "endpoint@0",
                            "EP00"
                        }
                    }
                })
                Name (EP00, Package (0x02)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "reg",
                            Zero
                        },

                        Package (0x02)
                        {
                            "remote-endpoint",
                            Package (0x03)
                            {
                                \_SB.SUB0.CUB0,
                                "port@0",
                                "endpoint@0"
                            }
                        }
                    }
                })
                Name (PRT1, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg",
                            One
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "endpoint@0",
                            "EP01"
                        }
                    }
                })
                Name (EP01, Package (0x02)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "reg",
                            Zero
                        },

                        Package (0x02)
                        {
                            "remote-endpoint",
                            Package (0x03)
                            {
                                \_SB.UCP0,
                                "port@0",
                                "endpoint@0"
                            }
                        }
                    }
                })
                Name (PRT2, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg",
                            0x02
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "endpoint@1",
                            "EP02"
                        }
                    }
                })
                Name (EP02, Package (0x02)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "reg",
                            One
                        },

                        Package (0x02)
                        {
                            "remote-endpoint",
                            Package (0x03)
                            {
                                \_SB.UCP0,
                                "port@0",
                                "endpoint@1"
                            }
                        }
                    }
                })
            }

            Device (PD11)
            {
                Name (_HID, "CIXH200D")  // _HID: Hardware ID
                Name (_UID, One)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    I2cSerialBusV2 (0x0031, ControllerInitiated, 0x000186A0,
                        AddressingMode7Bit, "\\_SB.I2C1",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                    GpioInt (Level, ActiveLow, Exclusive, PullUp, 0x0000,
                        "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x0008
                        }
                })
                Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "id",
                            0x02
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "usbc_con2",
                            "UC00"
                        }
                    }
                })
                Name (UC00, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "data-role",
                            "host"
                        },

                        Package (0x02)
                        {
                            "power-role",
                            "source"
                        },

                        Package (0x02)
                        {
                            "try-power-role",
                            "source"
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "port@0",
                            "PRT0"
                        },

                        Package (0x02)
                        {
                            "port@1",
                            "PRT1"
                        },

                        Package (0x02)
                        {
                            "port@2",
                            "PRT2"
                        }
                    }
                })
                Name (PRT0, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg",
                            Zero
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "endpoint@0",
                            "EP00"
                        }
                    }
                })
                Name (EP00, Package (0x02)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "reg",
                            Zero
                        },

                        Package (0x02)
                        {
                            "remote-endpoint",
                            Package (0x03)
                            {
                                \_SB.SUB2.CUB2,
                                "port@0",
                                "endpoint@0"
                            }
                        }
                    }
                })
                Name (PRT1, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg",
                            One
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "endpoint@0",
                            "EP01"
                        }
                    }
                })
                Name (EP01, Package (0x02)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "reg",
                            Zero
                        },

                        Package (0x02)
                        {
                            "remote-endpoint",
                            Package (0x03)
                            {
                                \_SB.UCP2,
                                "port@0",
                                "endpoint@0"
                            }
                        }
                    }
                })
                Name (PRT2, Package (0x04)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg",
                            0x02
                        }
                    },

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "endpoint@1",
                            "EP02"
                        }
                    }
                })
                Name (EP02, Package (0x02)
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "reg",
                            One
                        },

                        Package (0x02)
                        {
                            "remote-endpoint",
                            Package (0x03)
                            {
                                \_SB.UCP2,
                                "port@0",
                                "endpoint@1"
                            }
                        }
                    }
                })
            }
        }

        Device (MUX0)
        {
            Name (_HID, "CIXHA016")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04170000,         // Address Base
                    0x00001000,         // Address Length
                    )
                PinGroup ("pinctrl_sndcard", ResourceProducer, ,
                    RawDataBuffer (0x10)  // Vendor Data
                    {
                        0x02, 0x00, 0x00, 0x24, 0x02, 0x04, 0x00, 0x24,
                        0x02, 0x08, 0x00, 0x24, 0x02, 0x0C, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0080,
                        0x0081,
                        0x0082,
                        0x0083
                    }
                PinGroup ("pinctrl_fch_pwm0", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x50, 0x00, 0x07
                    })
                    {   // Pin list
                        0x0014
                    }
                PinGroup ("pinctrl_fch_pwm1", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x01, 0x3C, 0x00, 0xB7
                    })
                    {   // Pin list
                        0x004F
                    }
                PinGroup ("pinctrl_edp0", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0x48, 0x00, 0x24, 0x00, 0x4C, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0012,
                        0x0013
                    }
                PinGroup ("pinctrl_cam0_hw", ResourceProducer, ,
                    RawDataBuffer (0x0C)  // Vendor Data
                    {
                        0x01, 0x20, 0x00, 0xBC, 0x01, 0x24, 0x00, 0xBC,
                        0x01, 0x04, 0x00, 0x9C
                    })
                    {   // Pin list
                        0x0048,
                        0x0049,
                        0x0041
                    }
                PinGroup ("pinctrl_cam1_hw", ResourceProducer, ,
                    RawDataBuffer (0x0C)  // Vendor Data
                    {
                        0x01, 0x08, 0x00, 0xBC, 0x01, 0x04, 0x00, 0x9C,
                        0x01, 0x14, 0x00, 0xBC
                    })
                    {   // Pin list
                        0x0042,
                        0x0041,
                        0x0045
                    }
                PinGroup ("pinctrl_lt7911_hw", ResourceProducer, ,
                    RawDataBuffer (0x10)  // Vendor Data
                    {
                        0x01, 0x1C, 0x00, 0x8C, 0x01, 0x28, 0x00, 0x0C,
                        0x01, 0x2C, 0x00, 0x0C, 0x01, 0x34, 0x00, 0x1C
                    })
                    {   // Pin list
                        0x0047,
                        0x004A,
                        0x004B,
                        0x004D
                    }
                PinGroup ("pinctrl_fch_i2c0", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0x78, 0x00, 0x47, 0x00, 0x7C, 0x00, 0x47
                    })
                    {   // Pin list
                        0x001E,
                        0x001F
                    }
                PinGroup ("pinctrl_fch_i2c2", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0x88, 0x00, 0x5C, 0x00, 0x8C, 0x00, 0x5C
                    })
                    {   // Pin list
                        0x0022,
                        0x0023
                    }
                PinGroup ("pinctrl_fch_uart0", ResourceProducer, ,
                    RawDataBuffer (0x10)  // Vendor Data
                    {
                        0x01, 0x3C, 0x00, 0x37, 0x01, 0x40, 0x00, 0x37,
                        0x01, 0x44, 0x00, 0x37, 0x01, 0x48, 0x00, 0x37
                    })
                    {   // Pin list
                        0x004F,
                        0x0050,
                        0x0051,
                        0x0052
                    }
                PinGroup ("pinctrl_fch_uart1", ResourceProducer, ,
                    RawDataBuffer (0x10)  // Vendor Data
                    {
                        0x01, 0x4C, 0x00, 0x37, 0x01, 0x50, 0x00, 0x37,
                        0x01, 0x54, 0x00, 0x37, 0x01, 0x58, 0x00, 0x37
                    })
                    {   // Pin list
                        0x0053,
                        0x0054,
                        0x0055,
                        0x0056
                    }
                PinGroup ("pinctrl_fch_uart2", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x01, 0x5C, 0x00, 0x27, 0x01, 0x60, 0x00, 0x27
                    })
                    {   // Pin list
                        0x0057,
                        0x0058
                    }
                PinGroup ("pinctrl_hda", ResourceProducer, ,
                    RawDataBuffer (0x1C)  // Vendor Data
                    {
                        0x00, 0xA8, 0x00, 0x3C, 0x00, 0xAC, 0x00, 0x3C,
                        0x00, 0xB0, 0x00, 0x3C, 0x00, 0xB4, 0x00, 0x5C,
                        0x00, 0xB8, 0x00, 0x5C, 0x00, 0xBC, 0x00, 0x3C,
                        0x00, 0xC0, 0x00, 0x3C
                    })
                    {   // Pin list
                        0x002A,
                        0x002B,
                        0x002C,
                        0x002D,
                        0x002E,
                        0x002F,
                        0x0030
                    }
                PinGroup ("pinctrl_substrate_i2s0", ResourceProducer, ,
                    RawDataBuffer (0x14)  // Vendor Data
                    {
                        0x00, 0xA8, 0x00, 0xBC, 0x00, 0xAC, 0x00, 0xBC,
                        0x00, 0xB0, 0x00, 0xBC, 0x00, 0xB4, 0x00, 0xDC,
                        0x00, 0xB8, 0x00, 0xDC
                    })
                    {   // Pin list
                        0x002A,
                        0x002B,
                        0x002C,
                        0x002D,
                        0x002E
                    }
                PinGroup ("pinctrl_substrate_i2s1", ResourceProducer, ,
                    RawDataBuffer (0x14)  // Vendor Data
                    {
                        0x00, 0xC4, 0x00, 0x3C, 0x00, 0xC8, 0x00, 0x3C,
                        0x00, 0xCC, 0x00, 0x5C, 0x00, 0xD0, 0x00, 0x3C,
                        0x00, 0xD4, 0x00, 0x3C
                    })
                    {   // Pin list
                        0x0031,
                        0x0032,
                        0x0033,
                        0x0034,
                        0x0035
                    }
                PinGroup ("pinctrl_substrate_i2s2", ResourceProducer, ,
                    RawDataBuffer (0x2C)  // Vendor Data
                    {
                        0x00, 0xD8, 0x00, 0x3C, 0x00, 0xDC, 0x00, 0x3C,
                        0x00, 0xE0, 0x00, 0x5C, 0x00, 0xE4, 0x00, 0x3C,
                        0x00, 0xE8, 0x00, 0x5C, 0x00, 0xEC, 0x00, 0x3C,
                        0x00, 0xF0, 0x00, 0x3C, 0x00, 0xF4, 0x00, 0x5C,
                        0x00, 0xF8, 0x00, 0x5C, 0x00, 0xFC, 0x00, 0x5C,
                        0x01, 0x00, 0x00, 0x5C
                    })
                    {   // Pin list
                        0x0036,
                        0x0037,
                        0x0038,
                        0x0039,
                        0x003A,
                        0x003B,
                        0x003C,
                        0x003D,
                        0x003E,
                        0x003F,
                        0x0040
                    }
                PinGroup ("pinctrl_substrate_i2s3", ResourceProducer, ,
                    RawDataBuffer (0x24)  // Vendor Data
                    {
                        0x01, 0x04, 0x00, 0x3C, 0x01, 0x08, 0x00, 0x3C,
                        0x01, 0x0C, 0x00, 0x5C, 0x01, 0x10, 0x00, 0x3C,
                        0x01, 0x14, 0x00, 0x5C, 0x01, 0x18, 0x00, 0x3C,
                        0x01, 0x1C, 0x00, 0x3C, 0x01, 0x20, 0x00, 0x5C,
                        0x01, 0x24, 0x00, 0x5C
                    })
                    {   // Pin list
                        0x0041,
                        0x0042,
                        0x0043,
                        0x0044,
                        0x0045,
                        0x0046,
                        0x0047,
                        0x0048,
                        0x0049
                    }
                PinGroup ("pinctrl_substrate_i2s4", ResourceProducer, ,
                    RawDataBuffer (0x14)  // Vendor Data
                    {
                        0x01, 0x28, 0x00, 0x9C, 0x01, 0x2C, 0x00, 0x9C,
                        0x01, 0x30, 0x00, 0x9C, 0x01, 0x34, 0x00, 0x9C,
                        0x01, 0x38, 0x00, 0x9C
                    })
                    {   // Pin list
                        0x004A,
                        0x004B,
                        0x004C,
                        0x004D,
                        0x004E
                    }
                PinGroup ("pinctrl_substrate_i2s5", ResourceProducer, ,
                    RawDataBuffer (0x20)  // Vendor Data
                    {
                        0x00, 0xDC, 0x01, 0x3C, 0x00, 0xE0, 0x01, 0x5C,
                        0x00, 0xE4, 0x01, 0x3C, 0x00, 0xE8, 0x01, 0x3C,
                        0x00, 0xEC, 0x01, 0x3C, 0x00, 0xF0, 0x01, 0x3C,
                        0x00, 0xF4, 0x01, 0x5C, 0x00, 0xF8, 0x01, 0x5C
                    })
                    {   // Pin list
                        0x0037,
                        0x0038,
                        0x0039,
                        0x003A,
                        0x003B,
                        0x003C,
                        0x003D,
                        0x003E
                    }
                PinGroup ("pinctrl_substrate_i2s6", ResourceProducer, ,
                    RawDataBuffer (0x20)  // Vendor Data
                    {
                        0x00, 0xDC, 0x01, 0xBC, 0x00, 0xE0, 0x01, 0xDC,
                        0x00, 0xE4, 0x01, 0xBC, 0x00, 0xE8, 0x01, 0xBC,
                        0x00, 0xEC, 0x01, 0xBC, 0x00, 0xF0, 0x01, 0xBC,
                        0x00, 0xF4, 0x01, 0xDC, 0x00, 0xF8, 0x01, 0xDC
                    })
                    {   // Pin list
                        0x0037,
                        0x0038,
                        0x0039,
                        0x003A,
                        0x003B,
                        0x003C,
                        0x003D,
                        0x003E
                    }
                PinGroup ("pinctrl_substrate_i2s7", ResourceProducer, ,
                    RawDataBuffer (0x20)  // Vendor Data
                    {
                        0x01, 0x08, 0x01, 0x3C, 0x01, 0x0C, 0x01, 0x5C,
                        0x01, 0x10, 0x01, 0x3C, 0x01, 0x14, 0x01, 0x5C,
                        0x01, 0x18, 0x01, 0x3C, 0x01, 0x1C, 0x01, 0x3C,
                        0x01, 0x20, 0x01, 0x5C, 0x01, 0x24, 0x01, 0x5C
                    })
                    {   // Pin list
                        0x0042,
                        0x0043,
                        0x0044,
                        0x0045,
                        0x0046,
                        0x0047,
                        0x0048,
                        0x0049
                    }
                PinGroup ("pinctrl_substrate_i2s8", ResourceProducer, ,
                    RawDataBuffer (0x20)  // Vendor Data
                    {
                        0x01, 0x08, 0x01, 0xBC, 0x01, 0x0C, 0x01, 0xDC,
                        0x01, 0x10, 0x01, 0xBC, 0x01, 0x14, 0x01, 0xDC,
                        0x01, 0x18, 0x01, 0xBC, 0x01, 0x1C, 0x01, 0xBC,
                        0x01, 0x20, 0x01, 0xDC, 0x01, 0x24, 0x01, 0xDC
                    })
                    {   // Pin list
                        0x0042,
                        0x0043,
                        0x0044,
                        0x0045,
                        0x0046,
                        0x0047,
                        0x0048,
                        0x0049
                    }
                PinGroup ("pinctrl_alc5682_irq", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x02, 0x14, 0x00, 0x1C
                    })
                    {   // Pin list
                        0x0085
                    }
                PinGroup ("pinctrl_fch_i3c0", ResourceProducer, ,
                    RawDataBuffer (0x0C)  // Vendor Data
                    {
                        0x00, 0x88, 0x00, 0xDC, 0x00, 0x8C, 0x00, 0xDC,
                        0x00, 0x90, 0x00, 0xDC
                    })
                    {   // Pin list
                        0x0022,
                        0x0023,
                        0x0024
                    }
                PinGroup ("pinctrl_fch_i3c1", ResourceProducer, ,
                    RawDataBuffer (0x0C)  // Vendor Data
                    {
                        0x00, 0x94, 0x00, 0xDC, 0x00, 0x98, 0x00, 0xDC,
                        0x00, 0x9C, 0x00, 0xDC
                    })
                    {   // Pin list
                        0x0025,
                        0x0026,
                        0x0027
                    }
            })
        }

        Device (MUX1)
        {
            Name (_HID, "CIXHA017")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x16007000,         // Address Base
                    0x00001000,         // Address Length
                    )
                PinGroup ("wifi_vbat_gpio", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x30, 0x00, 0x5C
                    })
                    {   // Pin list
                        0x000C
                    }
                PinGroup ("i2c0_grp", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0x70, 0x00, 0x5C, 0x00, 0x74, 0x00, 0x5C
                    })
                    {   // Pin list
                        0x001C,
                        0x001D
                    }
                PinGroup ("i2c1_grp", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0x78, 0x00, 0x57, 0x00, 0x7C, 0x00, 0x57
                    })
                    {   // Pin list
                        0x001E,
                        0x001F
                    }
                PinGroup ("pinctrl_fch_spi0", ResourceProducer, ,
                    RawDataBuffer (0x14)  // Vendor Data
                    {
                        0x00, 0xA8, 0x00, 0x5C, 0x00, 0xAC, 0x00, 0x5C,
                        0x00, 0xB0, 0x00, 0x5C, 0x00, 0xB4, 0x00, 0x5C,
                        0x00, 0xB8, 0x00, 0x1C
                    })
                    {   // Pin list
                        0x002A,
                        0x002B,
                        0x002C,
                        0x002D,
                        0x002E
                    }
                PinGroup ("pinctrl_fch_xspi", ResourceProducer, ,
                    RawDataBuffer (0x18)  // Vendor Data
                    {
                        0x00, 0xF0, 0x00, 0xDC, 0x00, 0xF4, 0x00, 0xDC,
                        0x00, 0xF8, 0x00, 0xDC, 0x00, 0xFC, 0x00, 0xDC,
                        0x01, 0x00, 0x00, 0xDC, 0x01, 0x04, 0x00, 0xDC
                    })
                    {   // Pin list
                        0x003C,
                        0x003D,
                        0x003E,
                        0x003F,
                        0x0040,
                        0x0041
                    }
                PinGroup ("pinctrl_usb0", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0xD4, 0x00, 0x44, 0x00, 0xE4, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0035,
                        0x0039
                    }
                PinGroup ("pinctrl_usb1", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0xD8, 0x00, 0x44
                    })
                    {   // Pin list
                        0x0036
                    }
                PinGroup ("pinctrl_usb2", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0xDC, 0x00, 0x44
                    })
                    {   // Pin list
                        0x0037
                    }
                PinGroup ("pinctrl_usb3", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0xE0, 0x00, 0x44
                    })
                    {   // Pin list
                        0x0038
                    }
                PinGroup ("pinctrl_usb4", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0xCC, 0x00, 0x44, 0x00, 0xE8, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0033,
                        0x003A
                    }
                PinGroup ("pinctrl_usb5", ResourceProducer, ,
                    RawDataBuffer (0x08)  // Vendor Data
                    {
                        0x00, 0xD0, 0x00, 0x44, 0x00, 0xEC, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0034,
                        0x003B
                    }
                PinGroup ("pinctrl_usb7", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0xC0, 0x00, 0x44
                    })
                    {   // Pin list
                        0x0030
                    }
                PinGroup ("pinctrl_usb8", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0xC4, 0x00, 0x44
                    })
                    {   // Pin list
                        0x0031
                    }
                PinGroup ("pinctrl_pcie_x8_rc", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x04, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0001
                    }
                PinGroup ("pinctrl_pcie_x4_rc", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x0C, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0003
                    }
                PinGroup ("pinctrl_pcie_x2_rc", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x10, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0004
                    }
                PinGroup ("pinctrl_pcie_x1_1_rc", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x08, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0002
                    }
                PinGroup ("pinctrl_pcie_x1_0_rc", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x14, 0x00, 0x24
                    })
                    {   // Pin list
                        0x0005
                    }
                PinGroup ("vgfx_poweren_gpio", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x88, 0x00, 0x44
                    })
                    {   // Pin list
                        0x0022
                    }
                PinGroup ("gbe1_poweren_gpio", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x24, 0x00, 0x44
                    })
                    {   // Pin list
                        0x0009
                    }
                PinGroup ("gbe2_poweren_gpio", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x9C, 0x00, 0xD4
                    })
                    {   // Pin list
                        0x0027
                    }
                PinGroup ("pinctrl_hym8563_irq", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x28, 0x00, 0x44
                    })
                    {   // Pin list
                        0x000A
                    }
                PinGroup ("vcc_ssd_pwren", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x2C, 0x00, 0x44
                    })
                    {   // Pin list
                        0x000B
                    }
                PinGroup ("gpio_leds", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x80, 0x00, 0x57
                    })
                    {   // Pin list
                        0x0020
                    }
                PinGroup ("wl_radio_disable_l", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x90, 0x00, 0xD4
                    })
                    {   // Pin list
                        0x0024
                    }
                PinGroup ("bt_radio_disable_l", ResourceProducer, ,
                    RawDataBuffer (0x04)  // Vendor Data
                    {
                        0x00, 0x94, 0x00, 0xD4
                    })
                    {   // Pin list
                        0x0025
                    }
            })
        }

        Scope (\_SB.GPI4)
        {
            Name (_AEI, ResourceTemplate ()  // _AEI: ACPI Event Interrupts
            {
                GpioInt (Level, ActiveLow, Exclusive, PullUp, 0x0000,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0006
                    }
                GpioInt (Level, ActiveLow, ExclusiveAndWake, PullUp, 0x0000,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x000A
                    }
            })
            Method (_L06, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx=0x00-0xFF
            {
                \_SB.EC0.EVNT ()
            }

            Method (_L0A, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx=0x00-0xFF
            {
                \_SB.ERTC.CAFG ()
            }
        }

        Device (LEDS)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x20)  // _UID: Unique ID
            Name (_DDN, "GPIO LEDs device")  // _DDN: DOS Device Name
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0007
                    }
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI5", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0000
                    }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "gpio_leds", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "compatible",
                        Package (0x01)
                        {
                            "gpio-leds"
                        }
                    }
                },

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */,
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "led@0",
                        "LED0"
                    },

                    Package (0x02)
                    {
                        "led@1",
                        "LED1"
                    }
                }
            })
            Name (LED0, Package (0x02)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "label",
                        "blue:status"
                    },

                    Package (0x02)
                    {
                        "linux,default-trigger",
                        "heartbeat"
                    },

                    Package (0x02)
                    {
                        "gpios",
                        Package (0x04)
                        {
                            ^LEDS,
                            Zero,
                            Zero,
                            One
                        }
                    }
                }
            })
            Name (LED1, Package (0x02)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "label",
                        "green:power"
                    },

                    Package (0x02)
                    {
                        "linux,default-trigger",
                        "default-on"
                    },

                    Package (0x02)
                    {
                        "gpios",
                        Package (0x04)
                        {
                            ^LEDS,
                            One,
                            Zero,
                            One
                        }
                    }
                }
            })
        }

        Scope (\_SB.GPI0)
        {
            Name (GPIN, Package (0x20)
            {
                "GPIO043",
                "PIN_18",
                "PIN_22",
                "PIN_32",
                "GPIO047",
                "GPIO048",
                "GPIO049",
                "GPIO050",
                "GPIO051",
                "GPIO052",
                "GPIO053",
                "GPIO054",
                "PIN_28",
                "PIN_27",
                "GPIO057",
                "GPIO058",
                "GPIO059",
                "GPIO060",
                "PIN_5",
                "PIN_3",
                "GPIO063",
                "GPIO064",
                "GPIO065",
                "GPIO066",
                "GPIO067",
                "GPIO068",
                "GPIO069",
                "GPIO070",
                "PIN_7",
                "GPIO072",
                "GPIO073",
                "GPIO074"
            })
        }

        Scope (\_SB.GPI1)
        {
            Name (GPIN, Package (0x20)
            {
                "GPIO075",
                "PIN_29",
                "GPIO077",
                "PIN_31",
                "PIN_33",
                "PIN_37",
                "GPIO081",
                "GPIO082",
                "GPIO083",
                "GPIO084",
                "GPIO085",
                "GPIO086",
                "GPIO087",
                "GPIO088",
                "GPIO089",
                "PIN_36",
                "PIN_12",
                "PIN_35",
                "PIN_38",
                "PIN_40",
                "PIN_11",
                "PIN_13",
                "GPIO097",
                "GPIO098",
                "PIN_15",
                "PIN_16",
                "GPIO101",
                "GPIO102",
                "GPIO103",
                "GPIO104",
                "PIN_8",
                "PIN_10"
            })
        }

        Scope (\_SB.GPI2)
        {
            Name (GPIN, Package (0x20)
            {
                "GPIO107",
                "GPIO108",
                "GPIO109",
                "GPIO110",
                "GPIO111",
                "GPIO112",
                "GPIO113",
                "GPIO114",
                "GPIO115",
                "GPIO116",
                "GPIO117",
                "GPIO118",
                "GPIO119",
                "GPIO120",
                "GPIO121",
                "GPIO122",
                "GPIO123",
                "GPIO124",
                "GPIO125",
                "GPIO126",
                "GPIO127",
                "GPIO128",
                "GPIO129",
                "GPIO130",
                "GPIO131",
                "GPIO132",
                "GPIO133",
                "GPIO134",
                "GPIO135",
                "GPIO136",
                "GPIO137",
                "PIN_21"
            })
        }

        Scope (\_SB.GPI3)
        {
            Name (GPIN, Package (0x11)
            {
                "PIN_24",
                "PIN_26",
                "PIN_19",
                "PIN_23",
                "GPIO143",
                "GPIO144",
                "GPIO145",
                "GPIO146",
                "GPIO147",
                "GPIO148",
                "GPIO149",
                "GPIO150",
                "GPIO151",
                "GPIO152",
                "GPIO153",
                "DP2_DIGON",
                "DP2_BLON"
            })
        }

        Scope (\_SB.GPI4)
        {
            Name (GPIN, Package (0x20)
            {
                "GPIO001",
                "GPIO002",
                "GPIO003",
                "GPIO004",
                "GPIO005",
                "GPIO006",
                "GPIO007",
                "GPIO008",
                "GPIO009",
                "GPIO010",
                "GPIO011",
                "GPIO012",
                "GPIO013",
                "GPIO014",
                "GPIO025",
                "GPIO026",
                "GPIO027",
                "GPIO028",
                "GPIO029",
                "GPIO030",
                "GPIO031",
                "GPIO032",
                "GPIO033",
                "GPIO034",
                "GPIO035",
                "GPIO036",
                "GPIO037",
                "GPIO038",
                "GPIO039",
                "GPIO040",
                "GPIO041",
                "GPIO042"
            })
        }

        Scope (\_SB.GPI5)
        {
            Name (GPIN, Package (0x0A)
            {
                "GPIO015",
                "GPIO016",
                "GPIO017",
                "GPIO018",
                "GPIO019",
                "GPIO020",
                "GPIO021",
                "GPIO022",
                "GPIO023",
                "GPIO024"
            })
        }

        Device (ERTC)
        {
            Name (_HID, "ERTC0000")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Mutex (RTMX, 0x00)
            OperationRegion (I2CA, SystemMemory, 0x04040000, 0x0100)
            Field (I2CA, DWordAcc, NoLock, Preserve)
            {
                CR,     32,
                SR,     32,
                AR,     32,
                DR,     32,
                ISR,    32,
                TSR,    32,
                SMPR,   32,
                TOR,    32,
                IMR,    32,
                IER,    32,
                IDR,    32,
                GFCR,   32
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                REST ()
            }

            Method (REST, 0, Serialized)
            {
                IDR = 0x02FF
                Local0 = CR /* \_SB_.ERTC.CR__ */
                Local0 &= 0xFFFFFFFFFFFFFFEF
                Local0 |= 0x40
                CR = Local0
                TSR = Zero
                Local0 = ISR /* \_SB_.ERTC.ISR_ */
                ISR = Local0
                Local0 = SR /* \_SB_.ERTC.SR__ */
                SR = Local0
            }

            Method (STAT, 0, Serialized)
            {
                Local0 = CR /* \_SB_.ERTC.CR__ */
                If (!(Local0 & 0x04))
                {
                    CR = (Local0 | 0x04)
                }

                CLRB ()
                Local1 = 0x000F4240
                While (Local1)
                {
                    Local0 = SR /* \_SB_.ERTC.SR__ */
                    If (!(Local0 & 0x0100))
                    {
                        Break
                    }

                    Local1--
                }

                If ((Local1 == Zero))
                {
                    Return (0x02)
                }

                SETB ()
                Return (Zero)
            }

            Method (STOP, 0, Serialized)
            {
                CLRB ()
                CLRF ()
            }

            Method (READ, 4, Serialized)
            {
                If ((Arg1 == Zero))
                {
                    Return (Zero)
                }

                If ((Arg1 > 0x10))
                {
                    TSR = 0x11
                }
                Else
                {
                    TSR = Arg1
                }

                Local0 = Arg3
                Local0 = CR /* \_SB_.ERTC.CR__ */
                Local0 |= One
                CR = Local0
                AR = (Arg0 & 0x03FF)
                Local3 = Zero
                While ((Arg1 != Zero))
                {
                    Local0 = ISR /* \_SB_.ERTC.ISR_ */
                    ISR = Local0
                    If ((Local0 & 0x08))
                    {
                        Return (0x02)
                    }

                    If ((Local0 & 0x04))
                    {
                        Return (One)
                    }

                    Local0 &= 0xFFFFFFFFFFFFFFFD
                    Local0 &= 0xFFFFFFFFFFFFFFFE
                    If ((Local0 != Zero))
                    {
                        Return (One)
                    }

                    If ((Arg1 <= 0x10))
                    {
                        Local1 = One
                    }
                    Else
                    {
                        Local1 = Zero
                    }

                    If ((Local1 == One))
                    {
                        If ((SR & 0x20))
                        {
                            Arg2 [Local3] = DR /* \_SB_.ERTC.DR__ */
                            Local3 += One
                            Arg1 -= One
                        }

                        Continue
                    }

                    Local4 = TSR /* \_SB_.ERTC.TSR_ */
                    If ((Local4 != One))
                    {
                        Continue
                    }

                    Local5 = (Arg1 - 0x10)
                    If ((Local5 > 0x10))
                    {
                        TSR = 0x11
                    }
                    Else
                    {
                        TSR = Local5
                    }

                    Local5 = 0x10
                    While ((Local5 != Zero))
                    {
                        Arg2 [Local3] = DR /* \_SB_.ERTC.DR__ */
                        Local3 += One
                        Arg1 -= One
                        Local5 -= One
                    }
                }

                Return (Zero)
            }

            Method (WRIT, 4, Serialized)
            {
                If ((Arg1 == Zero))
                {
                    Return (Zero)
                }

                Local0 = Arg3
                Local0 = IER /* \_SB_.ERTC.IER_ */
                Local0 |= One
                IER = Local0
                Local0 = CR /* \_SB_.ERTC.CR__ */
                Local0 &= 0xFFFFFFFFFFFFFFFE
                CR = Local0
                Local0 = ISR /* \_SB_.ERTC.ISR_ */
                ISR = Local0
                TSR = Zero
                AR = (Arg0 & 0x03FF)
                Local0 = Zero
                Local1 = Arg1
                DR = DerefOf (Arg2 [Local0])
                Local0++
                Local1--
                While (One)
                {
                    If ((Local1 <= 0x0F))
                    {
                        Local2 = One
                        Local3 = Local1
                    }
                    Else
                    {
                        Local2 = Zero
                        Local3 = 0x0F
                    }

                    Local4 = Local3
                    While ((Local4 > Zero))
                    {
                        DR = DerefOf (Arg2 [Local0])
                        Local1--
                        Local4--
                        Local0++
                    }

                    If (Local2)
                    {
                        TSR = (Local3 + One)
                    }
                    Else
                    {
                        TSR = Local3
                    }

                    Local5 = 0x000F4240
                    While (One)
                    {
                        Local6 = ISR /* \_SB_.ERTC.ISR_ */
                        ISR = Local6
                        Local6 &= 0xFFFFFFFFFFFFFFFD
                        Local5--
                        If (((Local5 == Zero) || (Local6 != Zero)))
                        {
                            Break
                        }
                    }

                    If ((Local5 == Zero))
                    {
                        Return (0x02)
                    }

                    If ((Local6 & 0xFFFFFFFFFFFFFFFE))
                    {
                        If ((Local6 & 0x08))
                        {
                            Return (0x02)
                        }

                        If ((Local6 & 0x40))
                        {
                            CLRF ()
                        }

                        Return (One)
                    }

                    If (Local2)
                    {
                        Return (Zero)
                    }
                }

                Return (Zero)
            }

            Method (CKSB, 1, Serialized)
            {
                Local0 = SizeOf (Arg0)
                Local1 = Zero
                Local2 = Zero
                While ((Local1 < Local0))
                {
                    If ((Local1 != One))
                    {
                        Mid (Arg0, Local1, One, Local3)
                        Local2 += ToInteger (Local3)
                    }

                    Local1++
                }

                Return ((0x0100 - (Local2 & 0xFF)))
            }

            Method (CLRB, 0, Serialized)
            {
                Local0 = CR /* \_SB_.ERTC.CR__ */
                If ((Local0 & 0x10))
                {
                    CR = (Local0 & 0xFFFFFFFFFFFFFFEF)
                }
            }

            Method (SETB, 0, Serialized)
            {
                Local0 = CR /* \_SB_.ERTC.CR__ */
                If (!(Local0 & 0x10))
                {
                    CR = (Local0 | 0x10)
                }
            }

            Method (CLRF, 0, Serialized)
            {
                Local0 = CR /* \_SB_.ERTC.CR__ */
                CR = (Local0 | 0x40)
                While ((CR & 0x40)){}
            }

            Method (TRAS, 4, Serialized)
            {
                Acquire (RTMX, 0xFFFF)
                If (\_SB.AMTX (\_SB.I2C3.MXID, 0x1A))
                {
                    Return (One)
                }

                Local0 = Zero
                While (One)
                {
                    If ((STAT () != Zero))
                    {
                        Break
                    }

                    CLRF ()
                    Local1 = ISR /* \_SB_.ERTC.ISR_ */
                    ISR = Local1
                    If ((WRIT (0x51, Arg1, Arg0, Zero) != Zero))
                    {
                        Break
                    }

                    If ((READ (0x51, Arg3, Arg2, One) != Zero))
                    {
                        Break
                    }

                    Local0 = One
                    Break
                }

                If ((Local0 == Zero))
                {
                    REST ()
                    STOP ()
                    \_SB.RMTX (\_SB.I2C3.MXID, 0x1A)
                    Release (RTMX)
                    Return (One)
                }

                \_SB.RMTX (\_SB.I2C3.MXID, 0x1A)
                Release (RTMX)
                Return (Zero)
            }

            Method (CAFG, 0, Serialized)
            {
                Local0 = Buffer (One)
                    {
                         0x01                                             // .
                    }
                Local1 = Buffer (One){}
                Local2 = Buffer (0x02)
                    {
                         0x01                                             // .
                    }
                If ((TRAS (Local0, SizeOf (Local0), Local1, SizeOf (Local1)) != Zero))
                {
                    Return (One)
                }

                CreateByteField (Local1, Zero, CTL2)
                CTL2 &= 0xFFFFFFFFFFFFFFF7
                CreateByteField (Local2, One, DATA)
                DATA = CTL2 /* \_SB_.ERTC.CAFG.CTL2 */
                If ((WRIT (0x51, SizeOf (Local2), Local2, One) != Zero))
                {
                    Return (One)
                }

                Return (Zero)
            }
        }

        Device (PVC0)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "vgfx_poweren_gpio", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI5", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0002
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "vgfx_power"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^PVC0,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (PVC1)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "vcc_ssd_pwren", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x000B
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "vcc_ssd_pwren"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^PVC1,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (PVC2)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "wifi_vbat_gpio", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x000C
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x09)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "vdd_3v3_pcie"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^PVC2,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "regulator-always-on",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (PVC3)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x08)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "gbe1_poweren_gpio", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI5", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0007
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "gbe1_power_3v3"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^PVC3,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (PVC4)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x09)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "gbe2_poweren_gpio", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0009
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "gbe2_power_3v3"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x00325AA0
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^PVC4,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (HWMN)
        {
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_HID, "CIXHA024")  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x03)
            }

            Method (SFAT, 0, Serialized)
            {
                \_SB.EC0.SFAT ()
            }

            Method (SFMT, 0, Serialized)
            {
                \_SB.EC0.SFMT ()
            }

            Method (SFPF, 0, Serialized)
            {
                \_SB.EC0.SFPF ()
            }

            Method (GFPW, 2, Serialized)
            {
                Return (\_SB.EC0.GFPW ())
            }

            Method (SFPW, 3, Serialized)
            {
                \_SB.EC0.SFPW (Arg0)
            }
        }

        Device (VWL0)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x23)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "wl_radio_disable_l", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI5", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0004
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "wl_radio_disable_l"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x001B7740
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x001B7740
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^VWL0,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "regulator-always-on",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (VBT0)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x24)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "bt_radio_disable_l", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI5", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0005
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "bt_radio_disable_l"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x001B7740
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x001B7740
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^VBT0,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "regulator-always-on",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (VUS0)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x25)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb0", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x001D
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x09)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "vdd_usb_drive_vbus0"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x004C4B40
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x004C4B40
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^VUS0,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-always-on",
                        One
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (VUS4)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x26)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb4", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x001E
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x09)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "vdd_usb_drive_vbus4"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x004C4B40
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x004C4B40
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^VUS4,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-always-on",
                        One
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }

        Device (VUS5)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x27)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb5", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x001F
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */,
                Package (0x09)
                {
                    Package (0x02)
                    {
                        "compatible",
                        "regulator-fixed"
                    },

                    Package (0x02)
                    {
                        "regulator-name",
                        "vdd_usb_drive_vbus5"
                    },

                    Package (0x02)
                    {
                        "regulator-min-microvolt",
                        0x004C4B40
                    },

                    Package (0x02)
                    {
                        "regulator-max-microvolt",
                        0x004C4B40
                    },

                    Package (0x02)
                    {
                        "gpio",
                        Package (0x04)
                        {
                            ^VUS5,
                            Zero,
                            Zero,
                            Zero
                        }
                    },

                    Package (0x02)
                    {
                        "regulator-always-on",
                        One
                    },

                    Package (0x02)
                    {
                        "regulator-pull-down",
                        One
                    },

                    Package (0x02)
                    {
                        "enable-active-high",
                        One
                    },

                    Package (0x02)
                    {
                        "off-on-delay-us",
                        0x3A98
                    }
                }
            })
        }
    }
}
