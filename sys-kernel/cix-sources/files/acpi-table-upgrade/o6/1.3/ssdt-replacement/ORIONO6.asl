/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20260408 (64-bit version)
 * Copyright (c) 2000 - 2026 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of the ORIONO6 table shipped by Radxa O6 firmware 1.3.0.
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00003EBB (16059)
 *     Revision         0x02
 *     Checksum         0x60
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
        }

        Device (CPE4)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, Buffer (0x25)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x8C, 0x20, 0x00, 0x01, 0x01, 0x01, 0x00, 0x02,  // . ......
                /* 0008 */  0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x17, 0x00,  // ........
                /* 0010 */  0x00, 0x19, 0x00, 0x23, 0x00, 0x00, 0x00, 0x06,  // ...#....
                /* 0018 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50,  // .\_SB.GP
                /* 0020 */  0x49, 0x31, 0x00, 0x79, 0x00                     // I1.y.
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
                            ^CPE4, , 
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
                Name (_CRS, Buffer (0x6E)  // _CRS: Current Resource Settings
                {
                    /* 0000 */  0x8E, 0x19, 0x00, 0x02, 0x00, 0x01, 0x02, 0x00,  // ........
                    /* 0008 */  0x00, 0x01, 0x06, 0x00, 0x80, 0x1A, 0x06, 0x00,  // ........
                    /* 0010 */  0x34, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x49,  // 4.\_SB.I
                    /* 0018 */  0x32, 0x43, 0x30, 0x00, 0x91, 0x28, 0x00, 0x01,  // 2C0..(..
                    /* 0020 */  0x02, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x1B,  // ........
                    /* 0028 */  0x00, 0x2B, 0x00, 0x00, 0x00, 0x5C, 0x5F, 0x53,  // .+...\_S
                    /* 0030 */  0x42, 0x2E, 0x4D, 0x55, 0x58, 0x30, 0x00, 0x70,  // B.MUX0.p
                    /* 0038 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x63,  // inctrl_c
                    /* 0040 */  0x61, 0x6D, 0x30, 0x5F, 0x68, 0x77, 0x00, 0x8C,  // am0_hw..
                    /* 0048 */  0x22, 0x00, 0x01, 0x01, 0x01, 0x00, 0x02, 0x00,  // ".......
                    /* 0050 */  0x03, 0x00, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00,  // ........
                    /* 0058 */  0x1B, 0x00, 0x25, 0x00, 0x00, 0x00, 0x0D, 0x00,  // ..%.....
                    /* 0060 */  0x0E, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47,  // ..\_SB.G
                    /* 0068 */  0x50, 0x49, 0x31, 0x00, 0x79, 0x00               // PI1.y.
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x06)
                    {
                        Package (0x02)
                        {
                            "actuator-src", 
                            \_SB.I2C0.MTR0, 
                        }, 

                        Package (0x02)
                        {
                            "isp-src", 
                            \_SB.ISP0, 
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
                                \_SB.CPE4, 
                            }
                        }, 

                        Package (0x02)
                        {
                            "reset-gpios", 
                            Package (0x04)
                            {
                                ^IIS0, , 
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
                                ^IIS0, , 
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
                        \_SB.I2C0.IIS0, 
                    }
                })
            }

            Device (MTR0)
            {
                Name (_HID, "CIXH3023")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Name (_CRS, Buffer (0x1E)  // _CRS: Current Resource Settings
                {
                    /* 0000 */  0x8E, 0x19, 0x00, 0x02, 0x00, 0x01, 0x02, 0x00,  // ........
                    /* 0008 */  0x00, 0x01, 0x06, 0x00, 0x3F, 0x59, 0x73, 0x07,  // ....?Ys.
                    /* 0010 */  0x40, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x49,  // @.\_SB.I
                    /* 0018 */  0x32, 0x43, 0x30, 0x00, 0x79, 0x00               // 2C0.y.
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
                Name (_CRS, Buffer (0x6E)  // _CRS: Current Resource Settings
                {
                    /* 0000 */  0x8E, 0x19, 0x00, 0x02, 0x00, 0x01, 0x02, 0x00,  // ........
                    /* 0008 */  0x00, 0x01, 0x06, 0x00, 0x80, 0x1A, 0x06, 0x00,  // ........
                    /* 0010 */  0x36, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x49,  // 6.\_SB.I
                    /* 0018 */  0x32, 0x43, 0x31, 0x00, 0x91, 0x28, 0x00, 0x01,  // 2C1..(..
                    /* 0020 */  0x02, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x1B,  // ........
                    /* 0028 */  0x00, 0x2B, 0x00, 0x00, 0x00, 0x5C, 0x5F, 0x53,  // .+...\_S
                    /* 0030 */  0x42, 0x2E, 0x4D, 0x55, 0x58, 0x30, 0x00, 0x70,  // B.MUX0.p
                    /* 0038 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x63,  // inctrl_c
                    /* 0040 */  0x61, 0x6D, 0x31, 0x5F, 0x68, 0x77, 0x00, 0x8C,  // am1_hw..
                    /* 0048 */  0x22, 0x00, 0x01, 0x01, 0x01, 0x00, 0x02, 0x00,  // ".......
                    /* 0050 */  0x03, 0x00, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00,  // ........
                    /* 0058 */  0x1B, 0x00, 0x25, 0x00, 0x00, 0x00, 0x0A, 0x00,  // ..%.....
                    /* 0060 */  0x07, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47,  // ..\_SB.G
                    /* 0068 */  0x50, 0x49, 0x31, 0x00, 0x79, 0x00               // PI1.y.
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
                                \_SB.CPE4, 
                            }
                        }, 

                        Package (0x02)
                        {
                            "reset-gpios", 
                            Package (0x04)
                            {
                                ^IIS1, , 
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
                                ^IIS1, , 
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
                        \_SB.I2C1.IIS1, 
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
                ECFN, 
            })
        }

        ThermalZone (ECTZ)
        {
            Name (_TZD, Package (0x01)  // _TZD: Thermal Zone Devices
            {
                \_SB, 
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
                Name (_CRS, Buffer (0x41)  // _CRS: Current Resource Settings
                {
                    /* 0000 */  0x8E, 0x19, 0x00, 0x02, 0x00, 0x01, 0x02, 0x00,  // ........
                    /* 0008 */  0x00, 0x01, 0x06, 0x00, 0xA0, 0x86, 0x01, 0x00,  // ........
                    /* 0010 */  0x30, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x49,  // 0.\_SB.I
                    /* 0018 */  0x32, 0x43, 0x31, 0x00, 0x8C, 0x20, 0x00, 0x01,  // 2C1.. ..
                    /* 0020 */  0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00,  // ........
                    /* 0028 */  0x00, 0x00, 0x17, 0x00, 0x00, 0x19, 0x00, 0x23,  // .......#
                    /* 0030 */  0x00, 0x00, 0x00, 0x08, 0x00, 0x5C, 0x5F, 0x53,  // .....\_S
                    /* 0038 */  0x42, 0x2E, 0x47, 0x50, 0x49, 0x34, 0x00, 0x79,  // B.GPI4.y
                    /* 0040 */  0x00                                             // .
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
                                \_SB.SUB0.CUB0, , 
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
                                \_SB.UCP0, , 
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
                                \_SB.UCP0, , 
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
                Name (_CRS, Buffer (0x41)  // _CRS: Current Resource Settings
                {
                    /* 0000 */  0x8E, 0x19, 0x00, 0x02, 0x00, 0x01, 0x02, 0x00,  // ........
                    /* 0008 */  0x00, 0x01, 0x06, 0x00, 0xA0, 0x86, 0x01, 0x00,  // ........
                    /* 0010 */  0x31, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x49,  // 1.\_SB.I
                    /* 0018 */  0x32, 0x43, 0x31, 0x00, 0x8C, 0x20, 0x00, 0x01,  // 2C1.. ..
                    /* 0020 */  0x00, 0x01, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00,  // ........
                    /* 0028 */  0x00, 0x00, 0x17, 0x00, 0x00, 0x19, 0x00, 0x23,  // .......#
                    /* 0030 */  0x00, 0x00, 0x00, 0x08, 0x00, 0x5C, 0x5F, 0x53,  // .....\_S
                    /* 0038 */  0x42, 0x2E, 0x47, 0x50, 0x49, 0x34, 0x00, 0x79,  // B.GPI4.y
                    /* 0040 */  0x00                                             // .
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
                                \_SB.SUB2.CUB2, , 
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
                                \_SB.UCP2, , 
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
                                \_SB.UCP2, , 
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
            Name (_CRS, Buffer (0x05E6)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x86, 0x09, 0x00, 0x01, 0x00, 0x00, 0x17, 0x04,  // ........
                /* 0008 */  0x00, 0x10, 0x00, 0x00, 0x90, 0x33, 0x00, 0x01,  // .....3..
                /* 0010 */  0x00, 0x00, 0x0E, 0x00, 0x16, 0x00, 0x26, 0x00,  // ......&.
                /* 0018 */  0x10, 0x00, 0x80, 0x00, 0x81, 0x00, 0x82, 0x00,  // ........
                /* 0020 */  0x83, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72,  // ..pinctr
                /* 0028 */  0x6C, 0x5F, 0x73, 0x6E, 0x64, 0x63, 0x61, 0x72,  // l_sndcar
                /* 0030 */  0x64, 0x00, 0x02, 0x00, 0x00, 0x24, 0x02, 0x04,  // d....$..
                /* 0038 */  0x00, 0x24, 0x02, 0x08, 0x00, 0x24, 0x02, 0x0C,  // .$...$..
                /* 0040 */  0x00, 0x24, 0x90, 0x22, 0x00, 0x01, 0x00, 0x00,  // .$."....
                /* 0048 */  0x0E, 0x00, 0x10, 0x00, 0x21, 0x00, 0x04, 0x00,  // ....!...
                /* 0050 */  0x14, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72,  // ..pinctr
                /* 0058 */  0x6C, 0x5F, 0x66, 0x63, 0x68, 0x5F, 0x70, 0x77,  // l_fch_pw
                /* 0060 */  0x6D, 0x30, 0x00, 0x00, 0x50, 0x00, 0x07, 0x90,  // m0..P...
                /* 0068 */  0x22, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x10,  // ".......
                /* 0070 */  0x00, 0x21, 0x00, 0x04, 0x00, 0x4F, 0x00, 0x70,  // .!...O.p
                /* 0078 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x66,  // inctrl_f
                /* 0080 */  0x63, 0x68, 0x5F, 0x70, 0x77, 0x6D, 0x31, 0x00,  // ch_pwm1.
                /* 0088 */  0x01, 0x3C, 0x00, 0xB7, 0x90, 0x24, 0x00, 0x01,  // .<...$..
                /* 0090 */  0x00, 0x00, 0x0E, 0x00, 0x12, 0x00, 0x1F, 0x00,  // ........
                /* 0098 */  0x08, 0x00, 0x12, 0x00, 0x13, 0x00, 0x70, 0x69,  // ......pi
                /* 00A0 */  0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x65, 0x64,  // nctrl_ed
                /* 00A8 */  0x70, 0x30, 0x00, 0x00, 0x48, 0x00, 0x24, 0x00,  // p0..H.$.
                /* 00B0 */  0x4C, 0x00, 0x24, 0x90, 0x2D, 0x00, 0x01, 0x00,  // L.$.-...
                /* 00B8 */  0x00, 0x0E, 0x00, 0x14, 0x00, 0x24, 0x00, 0x0C,  // .....$..
                /* 00C0 */  0x00, 0x48, 0x00, 0x49, 0x00, 0x41, 0x00, 0x70,  // .H.I.A.p
                /* 00C8 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x63,  // inctrl_c
                /* 00D0 */  0x61, 0x6D, 0x30, 0x5F, 0x68, 0x77, 0x00, 0x01,  // am0_hw..
                /* 00D8 */  0x20, 0x00, 0xBC, 0x01, 0x24, 0x00, 0xBC, 0x01,  //  ...$...
                /* 00E0 */  0x04, 0x00, 0x9C, 0x90, 0x27, 0x00, 0x01, 0x00,  // ....'...
                /* 00E8 */  0x00, 0x0E, 0x00, 0x12, 0x00, 0x22, 0x00, 0x08,  // ....."..
                /* 00F0 */  0x00, 0x42, 0x00, 0x45, 0x00, 0x70, 0x69, 0x6E,  // .B.E.pin
                /* 00F8 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x63, 0x61, 0x6D,  // ctrl_cam
                /* 0100 */  0x31, 0x5F, 0x68, 0x77, 0x00, 0x01, 0x08, 0x00,  // 1_hw....
                /* 0108 */  0xBC, 0x01, 0x14, 0x00, 0xBC, 0x90, 0x35, 0x00,  // ......5.
                /* 0110 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x16, 0x00, 0x28,  // .......(
                /* 0118 */  0x00, 0x10, 0x00, 0x47, 0x00, 0x4A, 0x00, 0x4B,  // ...G.J.K
                /* 0120 */  0x00, 0x4D, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74,  // .M.pinct
                /* 0128 */  0x72, 0x6C, 0x5F, 0x6C, 0x74, 0x37, 0x39, 0x31,  // rl_lt791
                /* 0130 */  0x31, 0x5F, 0x68, 0x77, 0x00, 0x01, 0x1C, 0x00,  // 1_hw....
                /* 0138 */  0x8C, 0x01, 0x28, 0x00, 0x0C, 0x01, 0x2C, 0x00,  // ..(...,.
                /* 0140 */  0x0C, 0x01, 0x34, 0x00, 0x1C, 0x90, 0x28, 0x00,  // ..4...(.
                /* 0148 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x12, 0x00, 0x23,  // .......#
                /* 0150 */  0x00, 0x08, 0x00, 0x1E, 0x00, 0x1F, 0x00, 0x70,  // .......p
                /* 0158 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x66,  // inctrl_f
                /* 0160 */  0x63, 0x68, 0x5F, 0x69, 0x32, 0x63, 0x30, 0x00,  // ch_i2c0.
                /* 0168 */  0x00, 0x78, 0x00, 0x47, 0x00, 0x7C, 0x00, 0x47,  // .x.G.|.G
                /* 0170 */  0x90, 0x28, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00,  // .(......
                /* 0178 */  0x12, 0x00, 0x23, 0x00, 0x08, 0x00, 0x22, 0x00,  // ..#...".
                /* 0180 */  0x23, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72,  // #.pinctr
                /* 0188 */  0x6C, 0x5F, 0x66, 0x63, 0x68, 0x5F, 0x69, 0x32,  // l_fch_i2
                /* 0190 */  0x63, 0x32, 0x00, 0x00, 0x88, 0x00, 0x5C, 0x00,  // c2....\.
                /* 0198 */  0x8C, 0x00, 0x5C, 0x90, 0x35, 0x00, 0x01, 0x00,  // ..\.5...
                /* 01A0 */  0x00, 0x0E, 0x00, 0x16, 0x00, 0x28, 0x00, 0x10,  // .....(..
                /* 01A8 */  0x00, 0x4F, 0x00, 0x50, 0x00, 0x51, 0x00, 0x52,  // .O.P.Q.R
                /* 01B0 */  0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C,  // .pinctrl
                /* 01B8 */  0x5F, 0x66, 0x63, 0x68, 0x5F, 0x75, 0x61, 0x72,  // _fch_uar
                /* 01C0 */  0x74, 0x30, 0x00, 0x01, 0x3C, 0x00, 0x37, 0x01,  // t0..<.7.
                /* 01C8 */  0x40, 0x00, 0x37, 0x01, 0x44, 0x00, 0x37, 0x01,  // @.7.D.7.
                /* 01D0 */  0x48, 0x00, 0x37, 0x90, 0x35, 0x00, 0x01, 0x00,  // H.7.5...
                /* 01D8 */  0x00, 0x0E, 0x00, 0x16, 0x00, 0x28, 0x00, 0x10,  // .....(..
                /* 01E0 */  0x00, 0x53, 0x00, 0x54, 0x00, 0x55, 0x00, 0x56,  // .S.T.U.V
                /* 01E8 */  0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C,  // .pinctrl
                /* 01F0 */  0x5F, 0x66, 0x63, 0x68, 0x5F, 0x75, 0x61, 0x72,  // _fch_uar
                /* 01F8 */  0x74, 0x31, 0x00, 0x01, 0x4C, 0x00, 0x37, 0x01,  // t1..L.7.
                /* 0200 */  0x50, 0x00, 0x37, 0x01, 0x54, 0x00, 0x37, 0x01,  // P.7.T.7.
                /* 0208 */  0x58, 0x00, 0x37, 0x90, 0x29, 0x00, 0x01, 0x00,  // X.7.)...
                /* 0210 */  0x00, 0x0E, 0x00, 0x12, 0x00, 0x24, 0x00, 0x08,  // .....$..
                /* 0218 */  0x00, 0x57, 0x00, 0x58, 0x00, 0x70, 0x69, 0x6E,  // .W.X.pin
                /* 0220 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x66, 0x63, 0x68,  // ctrl_fch
                /* 0228 */  0x5F, 0x75, 0x61, 0x72, 0x74, 0x32, 0x00, 0x01,  // _uart2..
                /* 0230 */  0x5C, 0x00, 0x27, 0x01, 0x60, 0x00, 0x27, 0x90,  // \.'.`.'.
                /* 0238 */  0x41, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x1C,  // A.......
                /* 0240 */  0x00, 0x28, 0x00, 0x1C, 0x00, 0x2A, 0x00, 0x2B,  // .(...*.+
                /* 0248 */  0x00, 0x2C, 0x00, 0x2D, 0x00, 0x2E, 0x00, 0x2F,  // .,.-.../
                /* 0250 */  0x00, 0x30, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74,  // .0.pinct
                /* 0258 */  0x72, 0x6C, 0x5F, 0x68, 0x64, 0x61, 0x00, 0x00,  // rl_hda..
                /* 0260 */  0xA8, 0x00, 0x3C, 0x00, 0xAC, 0x00, 0x3C, 0x00,  // ..<...<.
                /* 0268 */  0xB0, 0x00, 0x3C, 0x00, 0xB4, 0x00, 0x5C, 0x00,  // ..<...\.
                /* 0270 */  0xB8, 0x00, 0x5C, 0x00, 0xBC, 0x00, 0x3C, 0x00,  // ..\...<.
                /* 0278 */  0xC0, 0x00, 0x3C, 0x90, 0x40, 0x00, 0x01, 0x00,  // ..<.@...
                /* 0280 */  0x00, 0x0E, 0x00, 0x18, 0x00, 0x2F, 0x00, 0x14,  // ...../..
                /* 0288 */  0x00, 0x2A, 0x00, 0x2B, 0x00, 0x2C, 0x00, 0x2D,  // .*.+.,.-
                /* 0290 */  0x00, 0x2E, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74,  // ...pinct
                /* 0298 */  0x72, 0x6C, 0x5F, 0x73, 0x75, 0x62, 0x73, 0x74,  // rl_subst
                /* 02A0 */  0x72, 0x61, 0x74, 0x65, 0x5F, 0x69, 0x32, 0x73,  // rate_i2s
                /* 02A8 */  0x30, 0x00, 0x00, 0xA8, 0x00, 0xBC, 0x00, 0xAC,  // 0.......
                /* 02B0 */  0x00, 0xBC, 0x00, 0xB0, 0x00, 0xBC, 0x00, 0xB4,  // ........
                /* 02B8 */  0x00, 0xDC, 0x00, 0xB8, 0x00, 0xDC, 0x90, 0x40,  // .......@
                /* 02C0 */  0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x18, 0x00,  // ........
                /* 02C8 */  0x2F, 0x00, 0x14, 0x00, 0x31, 0x00, 0x32, 0x00,  // /...1.2.
                /* 02D0 */  0x33, 0x00, 0x34, 0x00, 0x35, 0x00, 0x70, 0x69,  // 3.4.5.pi
                /* 02D8 */  0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x73, 0x75,  // nctrl_su
                /* 02E0 */  0x62, 0x73, 0x74, 0x72, 0x61, 0x74, 0x65, 0x5F,  // bstrate_
                /* 02E8 */  0x69, 0x32, 0x73, 0x31, 0x00, 0x00, 0xC4, 0x00,  // i2s1....
                /* 02F0 */  0x3C, 0x00, 0xC8, 0x00, 0x3C, 0x00, 0xCC, 0x00,  // <...<...
                /* 02F8 */  0x5C, 0x00, 0xD0, 0x00, 0x3C, 0x00, 0xD4, 0x00,  // \...<...
                /* 0300 */  0x3C, 0x90, 0x64, 0x00, 0x01, 0x00, 0x00, 0x0E,  // <.d.....
                /* 0308 */  0x00, 0x24, 0x00, 0x3B, 0x00, 0x2C, 0x00, 0x36,  // .$.;.,.6
                /* 0310 */  0x00, 0x37, 0x00, 0x38, 0x00, 0x39, 0x00, 0x3A,  // .7.8.9.:
                /* 0318 */  0x00, 0x3B, 0x00, 0x3C, 0x00, 0x3D, 0x00, 0x3E,  // .;.<.=.>
                /* 0320 */  0x00, 0x3F, 0x00, 0x40, 0x00, 0x70, 0x69, 0x6E,  // .?.@.pin
                /* 0328 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x73, 0x75, 0x62,  // ctrl_sub
                /* 0330 */  0x73, 0x74, 0x72, 0x61, 0x74, 0x65, 0x5F, 0x69,  // strate_i
                /* 0338 */  0x32, 0x73, 0x32, 0x00, 0x00, 0xD8, 0x00, 0x3C,  // 2s2....<
                /* 0340 */  0x00, 0xDC, 0x00, 0x3C, 0x00, 0xE0, 0x00, 0x5C,  // ...<...\
                /* 0348 */  0x00, 0xE4, 0x00, 0x3C, 0x00, 0xE8, 0x00, 0x5C,  // ...<...\
                /* 0350 */  0x00, 0xEC, 0x00, 0x3C, 0x00, 0xF0, 0x00, 0x3C,  // ...<...<
                /* 0358 */  0x00, 0xF4, 0x00, 0x5C, 0x00, 0xF8, 0x00, 0x5C,  // ...\...\
                /* 0360 */  0x00, 0xFC, 0x00, 0x5C, 0x01, 0x00, 0x00, 0x5C,  // ...\...\
                /* 0368 */  0x90, 0x58, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00,  // .X......
                /* 0370 */  0x20, 0x00, 0x37, 0x00, 0x24, 0x00, 0x41, 0x00,  //  .7.$.A.
                /* 0378 */  0x42, 0x00, 0x43, 0x00, 0x44, 0x00, 0x45, 0x00,  // B.C.D.E.
                /* 0380 */  0x46, 0x00, 0x47, 0x00, 0x48, 0x00, 0x49, 0x00,  // F.G.H.I.
                /* 0388 */  0x70, 0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F,  // pinctrl_
                /* 0390 */  0x73, 0x75, 0x62, 0x73, 0x74, 0x72, 0x61, 0x74,  // substrat
                /* 0398 */  0x65, 0x5F, 0x69, 0x32, 0x73, 0x33, 0x00, 0x01,  // e_i2s3..
                /* 03A0 */  0x04, 0x00, 0x3C, 0x01, 0x08, 0x00, 0x3C, 0x01,  // ..<...<.
                /* 03A8 */  0x0C, 0x00, 0x5C, 0x01, 0x10, 0x00, 0x3C, 0x01,  // ..\...<.
                /* 03B0 */  0x14, 0x00, 0x5C, 0x01, 0x18, 0x00, 0x3C, 0x01,  // ..\...<.
                /* 03B8 */  0x1C, 0x00, 0x3C, 0x01, 0x20, 0x00, 0x5C, 0x01,  // ..<. .\.
                /* 03C0 */  0x24, 0x00, 0x5C, 0x90, 0x40, 0x00, 0x01, 0x00,  // $.\.@...
                /* 03C8 */  0x00, 0x0E, 0x00, 0x18, 0x00, 0x2F, 0x00, 0x14,  // ...../..
                /* 03D0 */  0x00, 0x4A, 0x00, 0x4B, 0x00, 0x4C, 0x00, 0x4D,  // .J.K.L.M
                /* 03D8 */  0x00, 0x4E, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74,  // .N.pinct
                /* 03E0 */  0x72, 0x6C, 0x5F, 0x73, 0x75, 0x62, 0x73, 0x74,  // rl_subst
                /* 03E8 */  0x72, 0x61, 0x74, 0x65, 0x5F, 0x69, 0x32, 0x73,  // rate_i2s
                /* 03F0 */  0x34, 0x00, 0x01, 0x28, 0x00, 0x9C, 0x01, 0x2C,  // 4..(...,
                /* 03F8 */  0x00, 0x9C, 0x01, 0x30, 0x00, 0x9C, 0x01, 0x34,  // ...0...4
                /* 0400 */  0x00, 0x9C, 0x01, 0x38, 0x00, 0x9C, 0x90, 0x52,  // ...8...R
                /* 0408 */  0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x1E, 0x00,  // ........
                /* 0410 */  0x35, 0x00, 0x20, 0x00, 0x37, 0x00, 0x38, 0x00,  // 5. .7.8.
                /* 0418 */  0x39, 0x00, 0x3A, 0x00, 0x3B, 0x00, 0x3C, 0x00,  // 9.:.;.<.
                /* 0420 */  0x3D, 0x00, 0x3E, 0x00, 0x70, 0x69, 0x6E, 0x63,  // =.>.pinc
                /* 0428 */  0x74, 0x72, 0x6C, 0x5F, 0x73, 0x75, 0x62, 0x73,  // trl_subs
                /* 0430 */  0x74, 0x72, 0x61, 0x74, 0x65, 0x5F, 0x69, 0x32,  // trate_i2
                /* 0438 */  0x73, 0x35, 0x00, 0x00, 0xDC, 0x01, 0x3C, 0x00,  // s5....<.
                /* 0440 */  0xE0, 0x01, 0x5C, 0x00, 0xE4, 0x01, 0x3C, 0x00,  // ..\...<.
                /* 0448 */  0xE8, 0x01, 0x3C, 0x00, 0xEC, 0x01, 0x3C, 0x00,  // ..<...<.
                /* 0450 */  0xF0, 0x01, 0x3C, 0x00, 0xF4, 0x01, 0x5C, 0x00,  // ..<...\.
                /* 0458 */  0xF8, 0x01, 0x5C, 0x90, 0x52, 0x00, 0x01, 0x00,  // ..\.R...
                /* 0460 */  0x00, 0x0E, 0x00, 0x1E, 0x00, 0x35, 0x00, 0x20,  // .....5. 
                /* 0468 */  0x00, 0x37, 0x00, 0x38, 0x00, 0x39, 0x00, 0x3A,  // .7.8.9.:
                /* 0470 */  0x00, 0x3B, 0x00, 0x3C, 0x00, 0x3D, 0x00, 0x3E,  // .;.<.=.>
                /* 0478 */  0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C,  // .pinctrl
                /* 0480 */  0x5F, 0x73, 0x75, 0x62, 0x73, 0x74, 0x72, 0x61,  // _substra
                /* 0488 */  0x74, 0x65, 0x5F, 0x69, 0x32, 0x73, 0x36, 0x00,  // te_i2s6.
                /* 0490 */  0x00, 0xDC, 0x01, 0xBC, 0x00, 0xE0, 0x01, 0xDC,  // ........
                /* 0498 */  0x00, 0xE4, 0x01, 0xBC, 0x00, 0xE8, 0x01, 0xBC,  // ........
                /* 04A0 */  0x00, 0xEC, 0x01, 0xBC, 0x00, 0xF0, 0x01, 0xBC,  // ........
                /* 04A8 */  0x00, 0xF4, 0x01, 0xDC, 0x00, 0xF8, 0x01, 0xDC,  // ........
                /* 04B0 */  0x90, 0x52, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00,  // .R......
                /* 04B8 */  0x1E, 0x00, 0x35, 0x00, 0x20, 0x00, 0x42, 0x00,  // ..5. .B.
                /* 04C0 */  0x43, 0x00, 0x44, 0x00, 0x45, 0x00, 0x46, 0x00,  // C.D.E.F.
                /* 04C8 */  0x47, 0x00, 0x48, 0x00, 0x49, 0x00, 0x70, 0x69,  // G.H.I.pi
                /* 04D0 */  0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x73, 0x75,  // nctrl_su
                /* 04D8 */  0x62, 0x73, 0x74, 0x72, 0x61, 0x74, 0x65, 0x5F,  // bstrate_
                /* 04E0 */  0x69, 0x32, 0x73, 0x37, 0x00, 0x01, 0x08, 0x01,  // i2s7....
                /* 04E8 */  0x3C, 0x01, 0x0C, 0x01, 0x5C, 0x01, 0x10, 0x01,  // <...\...
                /* 04F0 */  0x3C, 0x01, 0x14, 0x01, 0x5C, 0x01, 0x18, 0x01,  // <...\...
                /* 04F8 */  0x3C, 0x01, 0x1C, 0x01, 0x3C, 0x01, 0x20, 0x01,  // <...<. .
                /* 0500 */  0x5C, 0x01, 0x24, 0x01, 0x5C, 0x90, 0x52, 0x00,  // \.$.\.R.
                /* 0508 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x1E, 0x00, 0x35,  // .......5
                /* 0510 */  0x00, 0x20, 0x00, 0x42, 0x00, 0x43, 0x00, 0x44,  // . .B.C.D
                /* 0518 */  0x00, 0x45, 0x00, 0x46, 0x00, 0x47, 0x00, 0x48,  // .E.F.G.H
                /* 0520 */  0x00, 0x49, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74,  // .I.pinct
                /* 0528 */  0x72, 0x6C, 0x5F, 0x73, 0x75, 0x62, 0x73, 0x74,  // rl_subst
                /* 0530 */  0x72, 0x61, 0x74, 0x65, 0x5F, 0x69, 0x32, 0x73,  // rate_i2s
                /* 0538 */  0x38, 0x00, 0x01, 0x08, 0x01, 0xBC, 0x01, 0x0C,  // 8.......
                /* 0540 */  0x01, 0xDC, 0x01, 0x10, 0x01, 0xBC, 0x01, 0x14,  // ........
                /* 0548 */  0x01, 0xDC, 0x01, 0x18, 0x01, 0xBC, 0x01, 0x1C,  // ........
                /* 0550 */  0x01, 0xBC, 0x01, 0x20, 0x01, 0xDC, 0x01, 0x24,  // ... ...$
                /* 0558 */  0x01, 0xDC, 0x90, 0x25, 0x00, 0x01, 0x00, 0x00,  // ...%....
                /* 0560 */  0x0E, 0x00, 0x10, 0x00, 0x24, 0x00, 0x04, 0x00,  // ....$...
                /* 0568 */  0x85, 0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72,  // ..pinctr
                /* 0570 */  0x6C, 0x5F, 0x61, 0x6C, 0x63, 0x35, 0x36, 0x38,  // l_alc568
                /* 0578 */  0x32, 0x5F, 0x69, 0x72, 0x71, 0x00, 0x02, 0x14,  // 2_irq...
                /* 0580 */  0x00, 0x1C, 0x90, 0x2E, 0x00, 0x01, 0x00, 0x00,  // ........
                /* 0588 */  0x0E, 0x00, 0x14, 0x00, 0x25, 0x00, 0x0C, 0x00,  // ....%...
                /* 0590 */  0x22, 0x00, 0x23, 0x00, 0x24, 0x00, 0x70, 0x69,  // ".#.$.pi
                /* 0598 */  0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x66, 0x63,  // nctrl_fc
                /* 05A0 */  0x68, 0x5F, 0x69, 0x33, 0x63, 0x30, 0x00, 0x00,  // h_i3c0..
                /* 05A8 */  0x88, 0x00, 0xDC, 0x00, 0x8C, 0x00, 0xDC, 0x00,  // ........
                /* 05B0 */  0x90, 0x00, 0xDC, 0x90, 0x2E, 0x00, 0x01, 0x00,  // ........
                /* 05B8 */  0x00, 0x0E, 0x00, 0x14, 0x00, 0x25, 0x00, 0x0C,  // .....%..
                /* 05C0 */  0x00, 0x25, 0x00, 0x26, 0x00, 0x27, 0x00, 0x70,  // .%.&.'.p
                /* 05C8 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x66,  // inctrl_f
                /* 05D0 */  0x63, 0x68, 0x5F, 0x69, 0x33, 0x63, 0x31, 0x00,  // ch_i3c1.
                /* 05D8 */  0x00, 0x94, 0x00, 0xDC, 0x00, 0x98, 0x00, 0xDC,  // ........
                /* 05E0 */  0x00, 0x9C, 0x00, 0xDC, 0x79, 0x00               // ....y.
            })
        }

        Device (MUX1)
        {
            Name (_HID, "CIXHA017")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, Buffer (0x0400)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x86, 0x09, 0x00, 0x01, 0x00, 0x70, 0x00, 0x16,  // .....p..
                /* 0008 */  0x00, 0x10, 0x00, 0x00, 0x90, 0x20, 0x00, 0x01,  // ..... ..
                /* 0010 */  0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x1F, 0x00,  // ........
                /* 0018 */  0x04, 0x00, 0x0C, 0x00, 0x77, 0x69, 0x66, 0x69,  // ....wifi
                /* 0020 */  0x5F, 0x76, 0x62, 0x61, 0x74, 0x5F, 0x67, 0x70,  // _vbat_gp
                /* 0028 */  0x69, 0x6F, 0x00, 0x00, 0x30, 0x00, 0x5C, 0x90,  // io..0.\.
                /* 0030 */  0x20, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x12,  //  .......
                /* 0038 */  0x00, 0x1B, 0x00, 0x08, 0x00, 0x1C, 0x00, 0x1D,  // ........
                /* 0040 */  0x00, 0x69, 0x32, 0x63, 0x30, 0x5F, 0x67, 0x72,  // .i2c0_gr
                /* 0048 */  0x70, 0x00, 0x00, 0x70, 0x00, 0x5C, 0x00, 0x74,  // p..p.\.t
                /* 0050 */  0x00, 0x5C, 0x90, 0x20, 0x00, 0x01, 0x00, 0x00,  // .\. ....
                /* 0058 */  0x0E, 0x00, 0x12, 0x00, 0x1B, 0x00, 0x08, 0x00,  // ........
                /* 0060 */  0x1E, 0x00, 0x1F, 0x00, 0x69, 0x32, 0x63, 0x31,  // ....i2c1
                /* 0068 */  0x5F, 0x67, 0x72, 0x70, 0x00, 0x00, 0x78, 0x00,  // _grp..x.
                /* 0070 */  0x57, 0x00, 0x7C, 0x00, 0x57, 0x90, 0x3A, 0x00,  // W.|.W.:.
                /* 0078 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x18, 0x00, 0x29,  // .......)
                /* 0080 */  0x00, 0x14, 0x00, 0x2A, 0x00, 0x2B, 0x00, 0x2C,  // ...*.+.,
                /* 0088 */  0x00, 0x2D, 0x00, 0x2E, 0x00, 0x70, 0x69, 0x6E,  // .-...pin
                /* 0090 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x66, 0x63, 0x68,  // ctrl_fch
                /* 0098 */  0x5F, 0x73, 0x70, 0x69, 0x30, 0x00, 0x00, 0xA8,  // _spi0...
                /* 00A0 */  0x00, 0x5C, 0x00, 0xAC, 0x00, 0x5C, 0x00, 0xB0,  // .\...\..
                /* 00A8 */  0x00, 0x5C, 0x00, 0xB4, 0x00, 0x5C, 0x00, 0xB8,  // .\...\..
                /* 00B0 */  0x00, 0x1C, 0x90, 0x40, 0x00, 0x01, 0x00, 0x00,  // ...@....
                /* 00B8 */  0x0E, 0x00, 0x1A, 0x00, 0x2B, 0x00, 0x18, 0x00,  // ....+...
                /* 00C0 */  0x3C, 0x00, 0x3D, 0x00, 0x3E, 0x00, 0x3F, 0x00,  // <.=.>.?.
                /* 00C8 */  0x40, 0x00, 0x41, 0x00, 0x70, 0x69, 0x6E, 0x63,  // @.A.pinc
                /* 00D0 */  0x74, 0x72, 0x6C, 0x5F, 0x66, 0x63, 0x68, 0x5F,  // trl_fch_
                /* 00D8 */  0x78, 0x73, 0x70, 0x69, 0x00, 0x00, 0xF0, 0x00,  // xspi....
                /* 00E0 */  0xDC, 0x00, 0xF4, 0x00, 0xDC, 0x00, 0xF8, 0x00,  // ........
                /* 00E8 */  0xDC, 0x00, 0xFC, 0x00, 0xDC, 0x01, 0x00, 0x00,  // ........
                /* 00F0 */  0xDC, 0x01, 0x04, 0x00, 0xDC, 0x90, 0x24, 0x00,  // ......$.
                /* 00F8 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x12, 0x00, 0x1F,  // ........
                /* 0100 */  0x00, 0x08, 0x00, 0x35, 0x00, 0x39, 0x00, 0x70,  // ...5.9.p
                /* 0108 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x75,  // inctrl_u
                /* 0110 */  0x73, 0x62, 0x30, 0x00, 0x00, 0xD4, 0x00, 0x44,  // sb0....D
                /* 0118 */  0x00, 0xE4, 0x00, 0x24, 0x90, 0x1E, 0x00, 0x01,  // ...$....
                /* 0120 */  0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x1D, 0x00,  // ........
                /* 0128 */  0x04, 0x00, 0x36, 0x00, 0x70, 0x69, 0x6E, 0x63,  // ..6.pinc
                /* 0130 */  0x74, 0x72, 0x6C, 0x5F, 0x75, 0x73, 0x62, 0x31,  // trl_usb1
                /* 0138 */  0x00, 0x00, 0xD8, 0x00, 0x44, 0x90, 0x1E, 0x00,  // ....D...
                /* 0140 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x1D,  // ........
                /* 0148 */  0x00, 0x04, 0x00, 0x37, 0x00, 0x70, 0x69, 0x6E,  // ...7.pin
                /* 0150 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x75, 0x73, 0x62,  // ctrl_usb
                /* 0158 */  0x32, 0x00, 0x00, 0xDC, 0x00, 0x44, 0x90, 0x1E,  // 2....D..
                /* 0160 */  0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00,  // ........
                /* 0168 */  0x1D, 0x00, 0x04, 0x00, 0x38, 0x00, 0x70, 0x69,  // ....8.pi
                /* 0170 */  0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x75, 0x73,  // nctrl_us
                /* 0178 */  0x62, 0x33, 0x00, 0x00, 0xE0, 0x00, 0x44, 0x90,  // b3....D.
                /* 0180 */  0x24, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x12,  // $.......
                /* 0188 */  0x00, 0x1F, 0x00, 0x08, 0x00, 0x33, 0x00, 0x3A,  // .....3.:
                /* 0190 */  0x00, 0x70, 0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C,  // .pinctrl
                /* 0198 */  0x5F, 0x75, 0x73, 0x62, 0x34, 0x00, 0x00, 0xCC,  // _usb4...
                /* 01A0 */  0x00, 0x44, 0x00, 0xE8, 0x00, 0x24, 0x90, 0x24,  // .D...$.$
                /* 01A8 */  0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x12, 0x00,  // ........
                /* 01B0 */  0x1F, 0x00, 0x08, 0x00, 0x34, 0x00, 0x3B, 0x00,  // ....4.;.
                /* 01B8 */  0x70, 0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F,  // pinctrl_
                /* 01C0 */  0x75, 0x73, 0x62, 0x35, 0x00, 0x00, 0xD0, 0x00,  // usb5....
                /* 01C8 */  0x44, 0x00, 0xEC, 0x00, 0x24, 0x90, 0x1E, 0x00,  // D...$...
                /* 01D0 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x1D,  // ........
                /* 01D8 */  0x00, 0x04, 0x00, 0x30, 0x00, 0x70, 0x69, 0x6E,  // ...0.pin
                /* 01E0 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x75, 0x73, 0x62,  // ctrl_usb
                /* 01E8 */  0x37, 0x00, 0x00, 0xC0, 0x00, 0x44, 0x90, 0x1E,  // 7....D..
                /* 01F0 */  0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00,  // ........
                /* 01F8 */  0x1D, 0x00, 0x04, 0x00, 0x31, 0x00, 0x70, 0x69,  // ....1.pi
                /* 0200 */  0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x75, 0x73,  // nctrl_us
                /* 0208 */  0x62, 0x38, 0x00, 0x00, 0xC4, 0x00, 0x44, 0x90,  // b8....D.
                /* 0210 */  0x24, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x10,  // $.......
                /* 0218 */  0x00, 0x23, 0x00, 0x04, 0x00, 0x01, 0x00, 0x70,  // .#.....p
                /* 0220 */  0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x70,  // inctrl_p
                /* 0228 */  0x63, 0x69, 0x65, 0x5F, 0x78, 0x38, 0x5F, 0x72,  // cie_x8_r
                /* 0230 */  0x63, 0x00, 0x00, 0x04, 0x00, 0x24, 0x90, 0x24,  // c....$.$
                /* 0238 */  0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00,  // ........
                /* 0240 */  0x23, 0x00, 0x04, 0x00, 0x03, 0x00, 0x70, 0x69,  // #.....pi
                /* 0248 */  0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F, 0x70, 0x63,  // nctrl_pc
                /* 0250 */  0x69, 0x65, 0x5F, 0x78, 0x34, 0x5F, 0x72, 0x63,  // ie_x4_rc
                /* 0258 */  0x00, 0x00, 0x0C, 0x00, 0x24, 0x90, 0x24, 0x00,  // ....$.$.
                /* 0260 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x23,  // .......#
                /* 0268 */  0x00, 0x04, 0x00, 0x04, 0x00, 0x70, 0x69, 0x6E,  // .....pin
                /* 0270 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x70, 0x63, 0x69,  // ctrl_pci
                /* 0278 */  0x65, 0x5F, 0x78, 0x32, 0x5F, 0x72, 0x63, 0x00,  // e_x2_rc.
                /* 0280 */  0x00, 0x10, 0x00, 0x24, 0x90, 0x26, 0x00, 0x01,  // ...$.&..
                /* 0288 */  0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x25, 0x00,  // ......%.
                /* 0290 */  0x04, 0x00, 0x02, 0x00, 0x70, 0x69, 0x6E, 0x63,  // ....pinc
                /* 0298 */  0x74, 0x72, 0x6C, 0x5F, 0x70, 0x63, 0x69, 0x65,  // trl_pcie
                /* 02A0 */  0x5F, 0x78, 0x31, 0x5F, 0x31, 0x5F, 0x72, 0x63,  // _x1_1_rc
                /* 02A8 */  0x00, 0x00, 0x08, 0x00, 0x24, 0x90, 0x26, 0x00,  // ....$.&.
                /* 02B0 */  0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x25,  // .......%
                /* 02B8 */  0x00, 0x04, 0x00, 0x05, 0x00, 0x70, 0x69, 0x6E,  // .....pin
                /* 02C0 */  0x63, 0x74, 0x72, 0x6C, 0x5F, 0x70, 0x63, 0x69,  // ctrl_pci
                /* 02C8 */  0x65, 0x5F, 0x78, 0x31, 0x5F, 0x30, 0x5F, 0x72,  // e_x1_0_r
                /* 02D0 */  0x63, 0x00, 0x00, 0x14, 0x00, 0x24, 0x90, 0x23,  // c....$.#
                /* 02D8 */  0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x10, 0x00,  // ........
                /* 02E0 */  0x22, 0x00, 0x04, 0x00, 0x22, 0x00, 0x76, 0x67,  // "...".vg
                /* 02E8 */  0x66, 0x78, 0x5F, 0x70, 0x6F, 0x77, 0x65, 0x72,  // fx_power
                /* 02F0 */  0x65, 0x6E, 0x5F, 0x67, 0x70, 0x69, 0x6F, 0x00,  // en_gpio.
                /* 02F8 */  0x00, 0x88, 0x00, 0x44, 0x90, 0x23, 0x00, 0x01,  // ...D.#..
                /* 0300 */  0x00, 0x00, 0x0E, 0x00, 0x10, 0x00, 0x22, 0x00,  // ......".
                /* 0308 */  0x04, 0x00, 0x09, 0x00, 0x67, 0x62, 0x65, 0x31,  // ....gbe1
                /* 0310 */  0x5F, 0x70, 0x6F, 0x77, 0x65, 0x72, 0x65, 0x6E,  // _poweren
                /* 0318 */  0x5F, 0x67, 0x70, 0x69, 0x6F, 0x00, 0x00, 0x24,  // _gpio..$
                /* 0320 */  0x00, 0x44, 0x90, 0x23, 0x00, 0x01, 0x00, 0x00,  // .D.#....
                /* 0328 */  0x0E, 0x00, 0x10, 0x00, 0x22, 0x00, 0x04, 0x00,  // ...."...
                /* 0330 */  0x27, 0x00, 0x67, 0x62, 0x65, 0x32, 0x5F, 0x70,  // '.gbe2_p
                /* 0338 */  0x6F, 0x77, 0x65, 0x72, 0x65, 0x6E, 0x5F, 0x67,  // oweren_g
                /* 0340 */  0x70, 0x69, 0x6F, 0x00, 0x00, 0x9C, 0x00, 0xD4,  // pio.....
                /* 0348 */  0x90, 0x25, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00,  // .%......
                /* 0350 */  0x10, 0x00, 0x24, 0x00, 0x04, 0x00, 0x0A, 0x00,  // ..$.....
                /* 0358 */  0x70, 0x69, 0x6E, 0x63, 0x74, 0x72, 0x6C, 0x5F,  // pinctrl_
                /* 0360 */  0x68, 0x79, 0x6D, 0x38, 0x35, 0x36, 0x33, 0x5F,  // hym8563_
                /* 0368 */  0x69, 0x72, 0x71, 0x00, 0x00, 0x28, 0x00, 0x44,  // irq..(.D
                /* 0370 */  0x90, 0x1F, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00,  // ........
                /* 0378 */  0x10, 0x00, 0x1E, 0x00, 0x04, 0x00, 0x0B, 0x00,  // ........
                /* 0380 */  0x76, 0x63, 0x63, 0x5F, 0x73, 0x73, 0x64, 0x5F,  // vcc_ssd_
                /* 0388 */  0x70, 0x77, 0x72, 0x65, 0x6E, 0x00, 0x00, 0x2C,  // pwren..,
                /* 0390 */  0x00, 0x44, 0x90, 0x1B, 0x00, 0x01, 0x00, 0x00,  // .D......
                /* 0398 */  0x0E, 0x00, 0x10, 0x00, 0x1A, 0x00, 0x04, 0x00,  // ........
                /* 03A0 */  0x20, 0x00, 0x67, 0x70, 0x69, 0x6F, 0x5F, 0x6C,  //  .gpio_l
                /* 03A8 */  0x65, 0x64, 0x73, 0x00, 0x00, 0x80, 0x00, 0x57,  // eds....W
                /* 03B0 */  0x90, 0x24, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00,  // .$......
                /* 03B8 */  0x10, 0x00, 0x23, 0x00, 0x04, 0x00, 0x24, 0x00,  // ..#...$.
                /* 03C0 */  0x77, 0x6C, 0x5F, 0x72, 0x61, 0x64, 0x69, 0x6F,  // wl_radio
                /* 03C8 */  0x5F, 0x64, 0x69, 0x73, 0x61, 0x62, 0x6C, 0x65,  // _disable
                /* 03D0 */  0x5F, 0x6C, 0x00, 0x00, 0x90, 0x00, 0xD4, 0x90,  // _l......
                /* 03D8 */  0x24, 0x00, 0x01, 0x00, 0x00, 0x0E, 0x00, 0x10,  // $.......
                /* 03E0 */  0x00, 0x23, 0x00, 0x04, 0x00, 0x25, 0x00, 0x62,  // .#...%.b
                /* 03E8 */  0x74, 0x5F, 0x72, 0x61, 0x64, 0x69, 0x6F, 0x5F,  // t_radio_
                /* 03F0 */  0x64, 0x69, 0x73, 0x61, 0x62, 0x6C, 0x65, 0x5F,  // disable_
                /* 03F8 */  0x6C, 0x00, 0x00, 0x94, 0x00, 0xD4, 0x79, 0x00   // l.....y.
            })
        }

        Scope (\_SB.GPI4)
        {
            Name (_AEI, Buffer (0x48)  // _AEI: ACPI Event Interrupts
            {
                /* 0000 */  0x8C, 0x20, 0x00, 0x01, 0x00, 0x01, 0x00, 0x02,  // . ......
                /* 0008 */  0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x17, 0x00,  // ........
                /* 0010 */  0x00, 0x19, 0x00, 0x23, 0x00, 0x00, 0x00, 0x06,  // ...#....
                /* 0018 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50,  // .\_SB.GP
                /* 0020 */  0x49, 0x34, 0x00, 0x8C, 0x20, 0x00, 0x01, 0x00,  // I4.. ...
                /* 0028 */  0x01, 0x00, 0x12, 0x00, 0x01, 0x00, 0x00, 0x00,  // ........
                /* 0030 */  0x00, 0x17, 0x00, 0x00, 0x19, 0x00, 0x23, 0x00,  // ......#.
                /* 0038 */  0x00, 0x00, 0x0A, 0x00, 0x5C, 0x5F, 0x53, 0x42,  // ....\_SB
                /* 0040 */  0x2E, 0x47, 0x50, 0x49, 0x34, 0x00, 0x79, 0x00   // .GPI4.y.
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
            Name (_CRS, Buffer (0x6D)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x8C, 0x20, 0x00, 0x01, 0x01, 0x01, 0x00, 0x02,  // . ......
                /* 0008 */  0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x17, 0x00,  // ........
                /* 0010 */  0x00, 0x19, 0x00, 0x23, 0x00, 0x00, 0x00, 0x07,  // ...#....
                /* 0018 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50,  // .\_SB.GP
                /* 0020 */  0x49, 0x34, 0x00, 0x8C, 0x20, 0x00, 0x01, 0x01,  // I4.. ...
                /* 0028 */  0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00,  // ........
                /* 0030 */  0x00, 0x17, 0x00, 0x00, 0x19, 0x00, 0x23, 0x00,  // ......#.
                /* 0038 */  0x00, 0x00, 0x00, 0x00, 0x5C, 0x5F, 0x53, 0x42,  // ....\_SB
                /* 0040 */  0x2E, 0x47, 0x50, 0x49, 0x35, 0x00, 0x91, 0x22,  // .GPI5.."
                /* 0048 */  0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x00, 0x11,  // ........
                /* 0050 */  0x00, 0x1B, 0x00, 0x25, 0x00, 0x00, 0x00, 0x5C,  // ...%...\
                /* 0058 */  0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55, 0x58, 0x31,  // _SB.MUX1
                /* 0060 */  0x00, 0x67, 0x70, 0x69, 0x6F, 0x5F, 0x6C, 0x65,  // .gpio_le
                /* 0068 */  0x64, 0x73, 0x00, 0x79, 0x00                     // ds.y.
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
                            ^LEDS, , 
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
                            ^LEDS, , 
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
            Name (_CRS, Buffer (0x52)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x91, 0x2A, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,  // .*......
                /* 0008 */  0x00, 0x11, 0x00, 0x1B, 0x00, 0x2D, 0x00, 0x00,  // .....-..
                /* 0010 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55,  // .\_SB.MU
                /* 0018 */  0x58, 0x31, 0x00, 0x76, 0x67, 0x66, 0x78, 0x5F,  // X1.vgfx_
                /* 0020 */  0x70, 0x6F, 0x77, 0x65, 0x72, 0x65, 0x6E, 0x5F,  // poweren_
                /* 0028 */  0x67, 0x70, 0x69, 0x6F, 0x00, 0x8C, 0x20, 0x00,  // gpio.. .
                /* 0030 */  0x01, 0x01, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00,  // ........
                /* 0038 */  0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x19, 0x00,  // ........
                /* 0040 */  0x23, 0x00, 0x00, 0x00, 0x02, 0x00, 0x5C, 0x5F,  // #.....\_
                /* 0048 */  0x53, 0x42, 0x2E, 0x47, 0x50, 0x49, 0x35, 0x00,  // SB.GPI5.
                /* 0050 */  0x79, 0x00                                       // y.
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
                            ^PVC0, , 
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
            Name (_CRS, Buffer (0x4E)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x91, 0x26, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,  // .&......
                /* 0008 */  0x00, 0x11, 0x00, 0x1B, 0x00, 0x29, 0x00, 0x00,  // .....)..
                /* 0010 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55,  // .\_SB.MU
                /* 0018 */  0x58, 0x31, 0x00, 0x76, 0x63, 0x63, 0x5F, 0x73,  // X1.vcc_s
                /* 0020 */  0x73, 0x64, 0x5F, 0x70, 0x77, 0x72, 0x65, 0x6E,  // sd_pwren
                /* 0028 */  0x00, 0x8C, 0x20, 0x00, 0x01, 0x01, 0x01, 0x00,  // .. .....
                /* 0030 */  0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x17,  // ........
                /* 0038 */  0x00, 0x00, 0x19, 0x00, 0x23, 0x00, 0x00, 0x00,  // ....#...
                /* 0040 */  0x0B, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47,  // ..\_SB.G
                /* 0048 */  0x50, 0x49, 0x34, 0x00, 0x79, 0x00               // PI4.y.
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
                            ^PVC1, , 
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
            Name (_CRS, Buffer (0x4F)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x91, 0x27, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,  // .'......
                /* 0008 */  0x00, 0x11, 0x00, 0x1B, 0x00, 0x2A, 0x00, 0x00,  // .....*..
                /* 0010 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55,  // .\_SB.MU
                /* 0018 */  0x58, 0x31, 0x00, 0x77, 0x69, 0x66, 0x69, 0x5F,  // X1.wifi_
                /* 0020 */  0x76, 0x62, 0x61, 0x74, 0x5F, 0x67, 0x70, 0x69,  // vbat_gpi
                /* 0028 */  0x6F, 0x00, 0x8C, 0x20, 0x00, 0x01, 0x01, 0x01,  // o.. ....
                /* 0030 */  0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00,  // ........
                /* 0038 */  0x17, 0x00, 0x00, 0x19, 0x00, 0x23, 0x00, 0x00,  // .....#..
                /* 0040 */  0x00, 0x0C, 0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E,  // ...\_SB.
                /* 0048 */  0x47, 0x50, 0x49, 0x34, 0x00, 0x79, 0x00         // GPI4.y.
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
                            ^PVC2, , 
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
            Name (_CRS, Buffer (0x52)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x91, 0x2A, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,  // .*......
                /* 0008 */  0x00, 0x11, 0x00, 0x1B, 0x00, 0x2D, 0x00, 0x00,  // .....-..
                /* 0010 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55,  // .\_SB.MU
                /* 0018 */  0x58, 0x31, 0x00, 0x67, 0x62, 0x65, 0x31, 0x5F,  // X1.gbe1_
                /* 0020 */  0x70, 0x6F, 0x77, 0x65, 0x72, 0x65, 0x6E, 0x5F,  // poweren_
                /* 0028 */  0x67, 0x70, 0x69, 0x6F, 0x00, 0x8C, 0x20, 0x00,  // gpio.. .
                /* 0030 */  0x01, 0x01, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00,  // ........
                /* 0038 */  0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x19, 0x00,  // ........
                /* 0040 */  0x23, 0x00, 0x00, 0x00, 0x07, 0x00, 0x5C, 0x5F,  // #.....\_
                /* 0048 */  0x53, 0x42, 0x2E, 0x47, 0x50, 0x49, 0x35, 0x00,  // SB.GPI5.
                /* 0050 */  0x79, 0x00                                       // y.
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
                            ^PVC3, , 
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
            Name (_CRS, Buffer (0x52)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x91, 0x2A, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,  // .*......
                /* 0008 */  0x00, 0x11, 0x00, 0x1B, 0x00, 0x2D, 0x00, 0x00,  // .....-..
                /* 0010 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55,  // .\_SB.MU
                /* 0018 */  0x58, 0x31, 0x00, 0x67, 0x62, 0x65, 0x32, 0x5F,  // X1.gbe2_
                /* 0020 */  0x70, 0x6F, 0x77, 0x65, 0x72, 0x65, 0x6E, 0x5F,  // poweren_
                /* 0028 */  0x67, 0x70, 0x69, 0x6F, 0x00, 0x8C, 0x20, 0x00,  // gpio.. .
                /* 0030 */  0x01, 0x01, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00,  // ........
                /* 0038 */  0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x19, 0x00,  // ........
                /* 0040 */  0x23, 0x00, 0x00, 0x00, 0x09, 0x00, 0x5C, 0x5F,  // #.....\_
                /* 0048 */  0x53, 0x42, 0x2E, 0x47, 0x50, 0x49, 0x34, 0x00,  // SB.GPI4.
                /* 0050 */  0x79, 0x00                                       // y.
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
                            ^PVC4, , 
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
            Name (_CRS, Buffer (0x53)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x91, 0x2B, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,  // .+......
                /* 0008 */  0x00, 0x11, 0x00, 0x1B, 0x00, 0x2E, 0x00, 0x00,  // ........
                /* 0010 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55,  // .\_SB.MU
                /* 0018 */  0x58, 0x31, 0x00, 0x77, 0x6C, 0x5F, 0x72, 0x61,  // X1.wl_ra
                /* 0020 */  0x64, 0x69, 0x6F, 0x5F, 0x64, 0x69, 0x73, 0x61,  // dio_disa
                /* 0028 */  0x62, 0x6C, 0x65, 0x5F, 0x6C, 0x00, 0x8C, 0x20,  // ble_l.. 
                /* 0030 */  0x00, 0x01, 0x01, 0x01, 0x00, 0x02, 0x00, 0x03,  // ........
                /* 0038 */  0x00, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x19,  // ........
                /* 0040 */  0x00, 0x23, 0x00, 0x00, 0x00, 0x04, 0x00, 0x5C,  // .#.....\
                /* 0048 */  0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50, 0x49, 0x35,  // _SB.GPI5
                /* 0050 */  0x00, 0x79, 0x00                                 // .y.
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
                            ^VWL0, , 
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
            Name (_CRS, Buffer (0x53)  // _CRS: Current Resource Settings
            {
                /* 0000 */  0x91, 0x2B, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00,  // .+......
                /* 0008 */  0x00, 0x11, 0x00, 0x1B, 0x00, 0x2E, 0x00, 0x00,  // ........
                /* 0010 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x4D, 0x55,  // .\_SB.MU
                /* 0018 */  0x58, 0x31, 0x00, 0x62, 0x74, 0x5F, 0x72, 0x61,  // X1.bt_ra
                /* 0020 */  0x64, 0x69, 0x6F, 0x5F, 0x64, 0x69, 0x73, 0x61,  // dio_disa
                /* 0028 */  0x62, 0x6C, 0x65, 0x5F, 0x6C, 0x00, 0x8C, 0x20,  // ble_l.. 
                /* 0030 */  0x00, 0x01, 0x01, 0x01, 0x00, 0x02, 0x00, 0x03,  // ........
                /* 0038 */  0x00, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x19,  // ........
                /* 0040 */  0x00, 0x23, 0x00, 0x00, 0x00, 0x05, 0x00, 0x5C,  // .#.....\
                /* 0048 */  0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50, 0x49, 0x35,  // _SB.GPI5
                /* 0050 */  0x00, 0x79, 0x00                                 // .y.
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
                            ^VBT0, , 
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
                            ^VUS0, , 
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
                            ^VUS4, , 
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
                            ^VUS5, , 
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
