/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of dsdt.dat
 *
 * Original Table Header:
 *     Signature        "DSDT"
 *     Length           0x000118C0 (71872)
 *     Revision         0x02
 *     Checksum         0x5C
 *     OEM ID           "CIXTEK"
 *     OEM Table ID     "SKY1EDK2"
 *     OEM Revision     0x00000001 (1)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200925 (538970405)
 *
 * The replacement DefinitionBlock intentionally uses OEM revision 0x00010001
 * so Linux treats it as newer than the firmware 1.2.1 DSDT.
 */
DefinitionBlock ("", "DSDT", 2, "CIXTEK", "SKY1EDK2", 0x00010001)
{
    External (_SB_.CPB0, PkgObj)
    External (_SB_.CPB1, PkgObj)
    External (_SB_.CPM0, PkgObj)
    External (_SB_.CPM1, PkgObj)
    External (_SB_.GPI0.GPIN, UnknownObj)
    External (_SB_.GPI1.GPIN, UnknownObj)
    External (_SB_.GPI2.GPIN, UnknownObj)
    External (_SB_.GPI3.GPIN, UnknownObj)
    External (_SB_.GPI4.GPIN, UnknownObj)
    External (_SB_.GPI5.GPIN, UnknownObj)
    External (_SB_.I2C5.PD10, DeviceObj)
    External (_SB_.PVC0, DeviceObj)
    External (_SB_.PVC1, DeviceObj)
    External (_SB_.PVC2, DeviceObj)
    External (_SB_.PVC3, DeviceObj)
    External (_SB_.PVC4, DeviceObj)
    External (CPB0, IntObj)
    External (CPB1, IntObj)
    External (CPM0, IntObj)
    External (CPM1, IntObj)

    Scope (_SB)
    {
        Mutex (DBGM, 0x00)
        OperationRegion (COMA, SystemMemory, 0x040E0000, 0x0100)
        Field (COMA, ByteAcc, NoLock, Preserve)
        {
            UTXD,   8,
            Offset (0x18),
            UTS,    8
        }

        Method (UDBG, 1, Serialized)
        {
            ToHexString (Arg0, Local0)
            Local1 = SizeOf (Local0)
            Local2 = Zero
            Acquire (DBGM, 0xFFFF)
            While ((Local2 < Local1))
            {
                Local3 = Zero
                While ((Local3 < 0x00989680))
                {
                    If (((UTS & 0x20) == Zero))
                    {
                        Break
                    }

                    Local3++
                }

                Mid (Local0, Local2, One, UTXD) /* \_SB_.UDBG.UTXD */
                Local2++
            }

            UTXD = 0x0D
            UTXD = 0x0A
            Release (DBGM)
        }

        Method (_OSC, 4, Serialized)  // _OSC: Operating System Capabilities
        {
            CreateDWordField (Arg3, Zero, STS0)
            CreateDWordField (Arg3, 0x04, CAP0)
            If ((Arg0 == ToUUID ("0811b06e-4a27-44f9-8d60-3cbbc22e7b48") /* Platform-wide Capabilities */))
            {
                If ((Arg1 == One))
                {
                    STS0 &= 0xFFFFFFFFFFFFFFE0
                    If ((CAP0 & 0x0100))
                    {
                        CAP0 &= 0xFFFFFFFFFFFFFEFF
                        STS0 |= 0x10
                    }

                    If ((CAP0 & 0x20))
                    {
                        CAP0 &= 0xFFFFFFFFFFFFFFDF
                        STS0 |= 0x10
                    }
                }
                Else
                {
                    STS0 &= 0xFFFFFFFFFFFFFFE0
                    STS0 |= 0x0A
                }
            }
            Else
            {
                STS0 &= 0xFFFFFFFFFFFFFFE0
                STS0 |= 0x06
            }

            Return (Arg3)
        }

        Method (_INI, 0, NotSerialized)  // _INI: Initialize
        {
            ULPI ()
        }

        Method (ULPI, 0, NotSerialized)
        {
            Local0 = GETV (0x1F)
            Local1 = GETV (0x20)
            Local2 = GETV (0x21)
            DerefOf (LPIB [0x03]) [0x02] = Local0
            DerefOf (LPIL [0x03]) [0x02] = Local0
            DerefOf (LPIB [0x04]) [0x02] = Local1
            DerefOf (LPIL [0x04]) [0x02] = Local1
            DerefOf (LPIB [0x05]) [0x02] = Local2
            DerefOf (LPIL [0x05]) [0x02] = Local2
        }

        Name (LPIB, Package (0x06)
        {
            Zero, 
            Zero, 
            0x03, 
            Package (0x0A)
            {
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x20,               // Bit Width
                        0x00,               // Bit Offset
                        0x00000000FFFFFFFF, // Address
                        0x03,               // Access Size
                        )
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                "Standby"
            }, 

            Package (0x0A)
            {
                0x0BB8, 
                0x0168, 
                Zero, 
                One, 
                Zero, 
                Zero, 
                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x20,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000010000, // Address
                        0x03,               // Access Size
                        )
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                "Powerdown"
            }, 

            Package (0x0A)
            {
                0x2710, 
                0x01F4, 
                Zero, 
                One, 
                Zero, 
                Zero, 
                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x20,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000001010000, // Address
                        0x03,               // Access Size
                        )
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                "ClusterPD"
            }
        })
        Name (LPIL, Package (0x06)
        {
            Zero, 
            Zero, 
            0x03, 
            Package (0x0A)
            {
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x20,               // Bit Width
                        0x00,               // Bit Offset
                        0x00000000FFFFFFFF, // Address
                        0x03,               // Access Size
                        )
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                "Standby"
            }, 

            Package (0x0A)
            {
                0x0BB8, 
                0x0168, 
                Zero, 
                One, 
                Zero, 
                Zero, 
                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x20,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000010000, // Address
                        0x03,               // Access Size
                        )
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                "Powerdown"
            }, 

            Package (0x0A)
            {
                0x2710, 
                0x01F4, 
                Zero, 
                One, 
                Zero, 
                Zero, 
                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x20,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000001010000, // Address
                        0x03,               // Access Size
                        )
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (SystemMemory, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                "ClusterPD"
            }
        })
        OperationRegion (DBGR, SystemMemory, 0x05040100, 0x20)
        Field (DBGR, DWordAcc, NoLock, Preserve)
        {
            UCLK,   32
        }

        Device (UCRU)
        {
            Name (_HID, "CIXHA018")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0416009C,         // Address Base
                    0x00000080,         // Address Length
                    )
            })
        }

        Device (COM0)
        {
            Name (_HID, "ARMH0011")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (Zero)
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x040B0000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000148,
                }
                FixedDMA (0x0000, 0x0002, Width32bit, )
                FixedDMA (0x0001, 0x0003, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_uart0", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "uartclk", 
                        UCLK
                    }, 

                    Package (0x02)
                    {
                        "timeout-value", 
                        0x2710
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x02)
                        {
                            "tx", 
                            "rx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "sky1,fch_cru", 
                        UCRU
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xF6, 
                    "apb_pclk", 
                    COM0
                }, 

                Package (0x03)
                {
                    0x0107, 
                    "uartclk", 
                    COM0
                }
            })
        }

        Device (COM1)
        {
            Name (_HID, "ARMH0011")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (Zero)
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x040C0000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000149,
                }
                FixedDMA (0x0002, 0x0004, Width32bit, )
                FixedDMA (0x0003, 0x0005, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_uart1", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "uartclk", 
                        UCLK
                    }, 

                    Package (0x02)
                    {
                        "timeout-value", 
                        0x2710
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x02)
                        {
                            "tx", 
                            "rx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "sky1,fch_cru", 
                        UCRU
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xF7, 
                    "apb_pclk", 
                    COM1
                }, 

                Package (0x03)
                {
                    0x0108, 
                    "uartclk", 
                    COM1
                }
            })
        }

        Device (COM2)
        {
            Name (_HID, "ARMH0011")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (One)
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x040D0000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000014A,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_uart2", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "uartclk", 
                        UCLK
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xF8, 
                    "apb_pclk", 
                    COM2
                }, 

                Package (0x03)
                {
                    0x0109, 
                    "uartclk", 
                    COM2
                }
            })
        }

        Device (COM3)
        {
            Name (_HID, "ARMH0011")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (Zero)
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x040E0000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000014B,
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xF9, 
                    "apb_pclk", 
                    COM3
                }, 

                Package (0x03)
                {
                    0x010A, 
                    "uartclk", 
                    COM3
                }
            })
        }

        Device (DSTD)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x83000000,         // Address Base
                    0x00400000,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x0C)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "cix,dst"
                    }, 

                    Package (0x02)
                    {
                        "ramlog_addr", 
                        0x83DA0000
                    }, 

                    Package (0x02)
                    {
                        "ramlog_size", 
                        0x00040000
                    }, 

                    Package (0x02)
                    {
                        "rdr-log-max-size", 
                        0x00800000
                    }, 

                    Package (0x02)
                    {
                        "rdr_area_num", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "rdr_area_sizes", 
                        Package (0x0F)
                        {
                            0x00100000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000, 
                            0x00010000
                        }
                    }, 

                    Package (0x02)
                    {
                        "rdr_area_sizes", 
                        0x00040000
                    }, 

                    Package (0x02)
                    {
                        "rdr-log-max-nums", 
                        0x06
                    }, 

                    Package (0x02)
                    {
                        "wait-dumplog-timeout", 
                        0x03E8
                    }, 

                    Package (0x02)
                    {
                        "unexpected-max-reboot-times", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "rdr-dumpctl", 
                        "1111111111"
                    }, 

                    Package (0x02)
                    {
                        "ramlog_size2", 
                        0x00040000
                    }
                }
            })
            Device (EXTR)
            {
                Name (_HID, "PRP0001")  // _HID: Hardware ID
                Name (_UID, One)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "compatible", 
                            "rdr,exceptiontrace"
                        }, 

                        Package (0x02)
                        {
                            "area_num", 
                            One
                        }, 

                        Package (0x02)
                        {
                            "area_sizes", 
                            0x1000
                        }
                    }
                })
            }

            Device (APAD)
            {
                Name (_HID, "PRP0001")  // _HID: Hardware ID
                Name (_UID, 0x02)  // _UID: Unique ID
                Name (_STA, 0x0F)  // _STA: Status
                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x83DE0000,         // Address Base
                        0x00020000,         // Address Length
                        )
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x15)
                    {
                        Package (0x02)
                        {
                            "compatible", 
                            "rdr,rdr_ap_adapter"
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_irq_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_task_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_cpu_idle_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_worker_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_time_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_cpu_on_off_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_syscall_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_hung_task_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_trace_tasklet_size", 
                            0x00010000
                        }, 

                        Package (0x02)
                        {
                            "ap_last_task_switch", 
                            One
                        }, 

                        Package (0x02)
                        {
                            "mntndump_addr", 
                            0x83DE0000
                        }, 

                        Package (0x02)
                        {
                            "mntndump_size", 
                            0x00020000
                        }, 

                        Package (0x02)
                        {
                            "ap_dump_mem_modu_test_size", 
                            0x0400
                        }, 

                        Package (0x02)
                        {
                            "ap_dump_mem_modu_idm_size", 
                            0x1000
                        }, 

                        Package (0x02)
                        {
                            "ap_dump_mem_modu_tzc400_size", 
                            0x1000
                        }, 

                        Package (0x02)
                        {
                            "ap_dump_mem_modu_smmu_size", 
                            0x1000
                        }, 

                        Package (0x02)
                        {
                            "ap_dump_mem_modu_tfa_size", 
                            0x4000
                        }, 

                        Package (0x02)
                        {
                            "ap_dump_mem_modu_gap_size", 
                            0x0100
                        }, 

                        Package (0x02)
                        {
                            "ap_log_console_size", 
                            0x00020000
                        }, 

                        Package (0x02)
                        {
                            "ap_log_dmesg_size", 
                            0x00080000
                        }
                    }
                })
            }
        }

        Device (RAOP)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x12)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x83D00000,         // Address Base
                    0x000A0000,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "ramoops"
                    }, 

                    Package (0x02)
                    {
                        "record-size", 
                        0x00040000
                    }, 

                    Package (0x02)
                    {
                        "console-size", 
                        0x00040000
                    }, 

                    Package (0x02)
                    {
                        "pmsg-size", 
                        0x1000
                    }
                }
            })
        }

        Device (DCT0)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x83)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0C010000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x83C00000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000EF,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "cadence,ddr_ctrl"
                    }, 

                    Package (0x02)
                    {
                        "channel_id", 
                        Zero
                    }
                }
            })
        }

        Device (DCT1)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x84)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0C030000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x83C00000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000F2,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "cadence,ddr_ctrl"
                    }, 

                    Package (0x02)
                    {
                        "channel_id", 
                        One
                    }
                }
            })
        }

        Device (DCT2)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x85)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0C050000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x83C00000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000F5,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "cadence,ddr_ctrl"
                    }, 

                    Package (0x02)
                    {
                        "channel_id", 
                        0x02
                    }
                }
            })
        }

        Device (DCT3)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x86)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0C070000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x83C00000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000F8,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "cadence,ddr_ctrl"
                    }, 

                    Package (0x02)
                    {
                        "channel_id", 
                        0x03
                    }
                }
            })
        }

        Device (SEPM)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x10)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "cix,se_pm_crash"
                    }
                }
            })
        }

        Device (DSMC)
        {
            Name (_HID, "PRP0001")  // _HID: Hardware ID
            Name (_UID, 0x11)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "cix,cix_se2ap_mbox"
                    }, 

                    Package (0x02)
                    {
                        "mbox-names", 
                        Package (0x02)
                        {
                            "tx4", 
                            "rx4"
                        }
                    }, 

                    Package (0x02)
                    {
                        "mboxes", 
                        Package (0x04)
                        {
                            MBX0, 
                            0x0A, 
                            MBX1, 
                            0x09
                        }
                    }
                }
            })
        }

        Device (PDC0)
        {
            Name (_HID, "CIXHA019")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x16000000,         // Address Base
                    0x00001000,         // Address Length
                    )
            })
        }

        Device (MBX0)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x05060000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000019A,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (MBX1)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x05070000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000019B,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (MBX2)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x080A0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001A8,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (MBX3)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x08090000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001A7,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (MBX4)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x28))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07100000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000109,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (MBX5)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x28))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x070F0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000108,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (MBX6)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x06590000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000018B,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (MBX7)
        {
            Name (_HID, "CIXHA001")  // _HID: Hardware ID
            Name (_CID, "CIXHA001")  // _CID: Compatible ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x065A0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000187,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "cix,mbox_dir", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "#mbox-cells", 
                        One
                    }
                }
            })
        }

        Device (CCLK)
        {
            Name (_HID, "CIXHA010")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (CLKT, Package (0x00){})
            Method (GCLK, 1, Serialized)
            {
                Return (^^PMMX.CLKG (Arg0))
            }

            Method (SCLK, 3, Serialized)
            {
                Return (^^PMMX.CLKS (Arg0, Arg1, Arg2))
            }

            Method (CLKD, 2, Serialized)
            {
                Return (^^PMMX.CLKD (Arg0, Arg1))
            }

            Method (CLKC, 2, Serialized)
            {
                Return (^^PMMX.CLKC (Arg0, Arg1))
            }
        }

        Device (REST)
        {
            Name (_HID, "CIXA1019")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (RSVL, Package (0x03)
            {
                Package (0x04)
                {
                    0xD0000000, 
                    0x00700000, 
                    "no-map", 
                    DMA1
                }, 

                Package (0x04)
                {
                    0xD0700000, 
                    0x00700000, 
                    "no-map", 
                    HDA
                }, 

                Package (0x04)
                {
                    0xCDE08000, 
                    0x00100000, 
                    "no-map", 
                    DSP
                }
            })
            Name (RSTL, Package (0x00){})
            Name (IRQL, Package (0x00){})
            Name (DLKL, Package (0x00){})
        }

        Device (RST0)
        {
            Name (_HID, "CIXHA020")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x16000000,         // Address Base
                    0x00001000,         // Address Length
                    )
            })
        }

        Device (RST1)
        {
            Name (_HID, "CIXHA021")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04160000,         // Address Base
                    0x00001000,         // Address Length
                    )
            })
        }

        Device (CRU0)
        {
            Name (_HID, "CIXHA018")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x16000000,         // Address Base
                    0x00001000,         // Address Length
                    )
            })
        }

        Device (GCRU)
        {
            Name (_HID, "CIXHA018")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09310000,         // Address Base
                    0x00001000,         // Address Length
                    )
            })
        }

        Device (MAC0)
        {
            Name (_HID, "CIXH7020")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x2A))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09320000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000177,
                    0x00000178,
                    0x00000179,
                    0x0000017A,
                    0x0000017B,
                    0x0000017C,
                    0x0000017D,
                    0x0000017E,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "gmac0", ResourceConsumer, ,
                    RawDataBuffer (0x01)  // Vendor Data
                    {
                        0x00
                    })
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "gmac0-init", ResourceConsumer, ,
                    RawDataBuffer (0x01)  // Vendor Data
                    {
                        0x01
                    })
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI0", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0000
                    }
            })
            Device (PHY0)
            {
                Name (_ADR, One)  // _ADR: Address
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "compatible", 
                            "ethernet-phy-ieee802.3-c22"
                        }
                    }
                })
            }

            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "port-id", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "phy-mode", 
                        "rgmii-id"
                    }, 

                    Package (0x02)
                    {
                        "phy-handle", 
                        PHY0
                    }, 

                    Package (0x02)
                    {
                        "cix,gmac-ctrl", 
                        GCRU
                    }, 

                    Package (0x02)
                    {
                        "reset-gpio", 
                        Package (0x04)
                        {
                            MAC0, 
                            Zero, 
                            Zero, 
                            One
                        }
                    }, 

                    Package (0x02)
                    {
                        "reset-delay-us", 
                        0x4E20
                    }, 

                    Package (0x02)
                    {
                        "reset-post-delay-us", 
                        0x000186A0
                    }, 

                    Package (0x02)
                    {
                        "pinctrl-names", 
                        Package (0x02)
                        {
                            "default", 
                            "init"
                        }
                    }
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x52, 
                    "aclk", 
                    MAC0
                }, 

                Package (0x03)
                {
                    0x5A, 
                    "pclk", 
                    MAC0
                }, 

                Package (0x03)
                {
                    0x55, 
                    "tx_clk", 
                    MAC0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x2C, 
                    MAC0, 
                    "gmac_rstn"
                }
            })
        }

        Device (MAC1)
        {
            Name (_HID, "CIXH7020")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x2B))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09330000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000017F,
                    0x00000180,
                    0x00000181,
                    0x00000182,
                    0x00000183,
                    0x00000184,
                    0x00000185,
                    0x00000186,
                }
            })
            Device (PHY1)
            {
                Name (_ADR, 0x02)  // _ADR: Address
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "compatible", 
                            "ethernet-phy-ieee802.3-c22"
                        }
                    }
                })
            }

            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "port-id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "phy-mode", 
                        "rgmii-id"
                    }, 

                    Package (0x02)
                    {
                        "phy-handle", 
                        PHY1
                    }, 

                    Package (0x02)
                    {
                        "cix,gmac-ctrl", 
                        GCRU
                    }
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x53, 
                    "aclk", 
                    MAC1
                }, 

                Package (0x03)
                {
                    0x5B, 
                    "pclk", 
                    MAC1
                }, 

                Package (0x03)
                {
                    0x58, 
                    "tx_clk", 
                    MAC1
                }
            })
        }

        Method (C2DK, 1, Serialized)
        {
            Local0 = (Arg0 * 0x0A)
            Local0 += 0x0AAC
            Return (Local0)
        }

        ThermalZone (TZB0)
        {
            Method (_PSV, 0, NotSerialized)  // _PSV: Passive Temperature
            {
                Return (0x0DFE)
            }

            Method (_CRT, 0, NotSerialized)  // _CRT: Critical Temperature
            {
                Return (0x0E80)
            }

            Method (_TC1, 0, NotSerialized)  // _TC1: Thermal Constant 1
            {
                Return (0x04)
            }

            Method (_TC2, 0, NotSerialized)  // _TC2: Thermal Constant 2
            {
                Return (0x03)
            }

            Method (_TSP, 0, NotSerialized)  // _TSP: Thermal Sampling Period
            {
                Return (One)
            }

            Method (_PSL, 0, NotSerialized)  // _PSL: Passive List
            {
                Return (CPB0) /* External reference */
            }

            Method (SWIT, 0, NotSerialized)
            {
                Return (0x0D04)
            }

            Method (SSTP, 0, NotSerialized)
            {
                Return (0x2EE0)
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                Local0 = ^^PMMX.SENG (0x0B, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (C2DK (TEMP))
                }
                Else
                {
                    Return (Ones)
                }
            }

            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
            }

            Method (_TZP, 0, NotSerialized)  // _TZP: Thermal Zone Polling
            {
                Return (0x0A)
            }

            Name (_STR, Unicode ("CPU-B0"))  // _STR: Description String
        }

        ThermalZone (TZB1)
        {
            Method (_PSV, 0, NotSerialized)  // _PSV: Passive Temperature
            {
                Return (0x0DFE)
            }

            Method (_CRT, 0, NotSerialized)  // _CRT: Critical Temperature
            {
                Return (0x0E80)
            }

            Method (_TC1, 0, NotSerialized)  // _TC1: Thermal Constant 1
            {
                Return (0x04)
            }

            Method (_TC2, 0, NotSerialized)  // _TC2: Thermal Constant 2
            {
                Return (0x03)
            }

            Method (_TSP, 0, NotSerialized)  // _TSP: Thermal Sampling Period
            {
                Return (One)
            }

            Method (_PSL, 0, NotSerialized)  // _PSL: Passive List
            {
                Return (CPB1) /* External reference */
            }

            Method (SWIT, 0, NotSerialized)
            {
                Return (0x0D04)
            }

            Method (SSTP, 0, NotSerialized)
            {
                Return (0x2EE0)
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                Local0 = ^^PMMX.SENG (0x09, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (C2DK (TEMP))
                }
                Else
                {
                    Return (Ones)
                }
            }

            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
            }

            Method (_TZP, 0, NotSerialized)  // _TZP: Thermal Zone Polling
            {
                Return (0x0A)
            }

            Name (_STR, Unicode ("CPU-B1"))  // _STR: Description String
        }

        ThermalZone (TZM0)
        {
            Method (_PSV, 0, NotSerialized)  // _PSV: Passive Temperature
            {
                Return (0x0DFE)
            }

            Method (_CRT, 0, NotSerialized)  // _CRT: Critical Temperature
            {
                Return (0x0E80)
            }

            Method (_TC1, 0, NotSerialized)  // _TC1: Thermal Constant 1
            {
                Return (0x04)
            }

            Method (_TC2, 0, NotSerialized)  // _TC2: Thermal Constant 2
            {
                Return (0x03)
            }

            Method (_TSP, 0, NotSerialized)  // _TSP: Thermal Sampling Period
            {
                Return (One)
            }

            Method (_PSL, 0, NotSerialized)  // _PSL: Passive List
            {
                Return (CPM0) /* External reference */
            }

            Method (SWIT, 0, NotSerialized)
            {
                Return (0x0D04)
            }

            Method (SSTP, 0, NotSerialized)
            {
                Return (0x2710)
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                Local0 = ^^PMMX.SENG (0x0A, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (C2DK (TEMP))
                }
                Else
                {
                    Return (Ones)
                }
            }

            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
            }

            Method (_TZP, 0, NotSerialized)  // _TZP: Thermal Zone Polling
            {
                Return (0x0A)
            }

            Name (_STR, Unicode ("CPU-M0"))  // _STR: Description String
        }

        ThermalZone (TZM1)
        {
            Method (_PSV, 0, NotSerialized)  // _PSV: Passive Temperature
            {
                Return (0x0DFE)
            }

            Method (_CRT, 0, NotSerialized)  // _CRT: Critical Temperature
            {
                Return (0x0E80)
            }

            Method (_TC1, 0, NotSerialized)  // _TC1: Thermal Constant 1
            {
                Return (0x04)
            }

            Method (_TC2, 0, NotSerialized)  // _TC2: Thermal Constant 2
            {
                Return (0x03)
            }

            Method (_TSP, 0, NotSerialized)  // _TSP: Thermal Sampling Period
            {
                Return (One)
            }

            Method (_PSL, 0, NotSerialized)  // _PSL: Passive List
            {
                Return (CPM1) /* External reference */
            }

            Method (SWIT, 0, NotSerialized)
            {
                Return (0x0D04)
            }

            Method (SSTP, 0, NotSerialized)
            {
                Return (0x2328)
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                Local0 = ^^PMMX.SENG (0x08, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (C2DK (TEMP))
                }
                Else
                {
                    Return (Ones)
                }
            }

            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
            }

            Method (_TZP, 0, NotSerialized)  // _TZP: Thermal Zone Polling
            {
                Return (0x0A)
            }

            Name (_STR, Unicode ("CPU-M1"))  // _STR: Description String
        }

        Method (SPFA, 0, Serialized)
        {
            ^PMMX.SFMD (One)
        }

        Method (SPFM, 0, Serialized)
        {
            ^PMMX.SFMD (Zero)
        }

        Method (SPFP, 0, Serialized)
        {
            ^PMMX.SFMD (0x02)
        }

        OperationRegion (IPBF, SystemMemory, 0x83BF0300, 0x0400)
        Field (IPBF, ByteAcc, NoLock, Preserve)
        {
            BUF,    8192
        }

        Method (SPRG, 1, Serialized)
        {
            Local0 = (Arg0 * 0x40)
            Local1 = (Local0 + 0x3C)
            CreateDWordField (BUF, Local1, SPWR)
            Return (SPWR) /* \_SB_.SPRG.SPWR */
        }

        Method (DPRG, 1, Serialized)
        {
            Local0 = (Arg0 * 0x40)
            Local1 = (Local0 + 0x38)
            CreateDWordField (BUF, Local1, DPWR)
            Return (DPWR) /* \_SB_.DPRG.DPWR */
        }

        ThermalZone (TZGT)
        {
            Method (_PSV, 0, NotSerialized)  // _PSV: Passive Temperature
            {
                Return (0x0DFE)
            }

            Method (SWIT, 0, NotSerialized)
            {
                Return (0x0D68)
            }

            Method (SSTP, 0, NotSerialized)
            {
                Return (0x3A98)
            }

            Method (_TC1, 0, NotSerialized)  // _TC1: Thermal Constant 1
            {
                Return (0x04)
            }

            Method (_TC2, 0, NotSerialized)  // _TC2: Thermal Constant 2
            {
                Return (0x03)
            }

            Method (_TSP, 0, NotSerialized)  // _TSP: Thermal Sampling Period
            {
                Return (One)
            }

            Name (_PSL, Package (0x01)  // _PSL: Passive List
            {
                GPU
            })
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                Local0 = ^^PMMX.SENG (0x0D, Zero)
                CreateDWordField (Local0, Zero, STAT)
                If ((STAT == Zero))
                {
                    CreateQWordField (Local0, 0x04, TEMP)
                    TEMP = ToInteger (TEMP)
                    Return (C2DK (TEMP))
                }
                Else
                {
                    Return (Ones)
                }
            }

            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
            }

            Method (_TZP, 0, NotSerialized)  // _TZP: Thermal Zone Polling
            {
                Return (0x0A)
            }
        }

        Mutex (MBXM, 0x00)
        Device (SHM0)
        {
            Name (_HID, "CIXHA004")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x06590000,         // Address Base
                    0x00000080,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "arm,scmi-shmem"
                    }, 

                    Package (0x02)
                    {
                        "reg-io-width", 
                        0x04
                    }
                }
            })
        }

        Device (SHM1)
        {
            Name (_HID, "CIXHA005")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x065A0000,         // Address Base
                    0x00000080,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "arm,scmi-shmem"
                    }, 

                    Package (0x02)
                    {
                        "reg-io-width", 
                        0x04
                    }
                }
            })
        }

        Name (SCMS, One)
        Device (SCMI)
        {
            Name (_HID, "CIXHA006")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "mboxes", 
                        Package (0x04)
                        {
                            MBX6, 
                            0x08, 
                            MBX7, 
                            0x08
                        }
                    }, 

                    Package (0x02)
                    {
                        "shmem", 
                        Package (0x02)
                        {
                            SHM0, 
                            SHM1
                        }
                    }
                }
            })
            Device (DVFS)
            {
                Name (_HID, "CIXHA008")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    If ((SCMS == One))
                    {
                        Return (0x0B)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg", 
                            0x13
                        }
                    }
                })
            }

            Device (CLKS)
            {
                Name (_HID, "CIXHA009")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    If ((SCMS == One))
                    {
                        Return (0x0B)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "reg", 
                            0x14
                        }
                    }
                })
            }
        }

        Device (PMMX)
        {
            Name (_HID, "CIXHA000")  // _HID: Hardware ID
            OperationRegion (MBXO, SystemMemory, 0x065D0000, 0xA0)
            Field (MBXO, DWordAcc, NoLock, Preserve)
            {
                Offset (0x04), 
                CFRE,   1, 
                CERR,   1, 
                Offset (0x0C), 
                SIGN,   32, 
                FLAG,   32, 
                LENG,   32, 
                MSID,   8, 
                MSTP,   2, 
                PRID,   8, 
                TOKN,   10, 
                Offset (0x1C), 
                MSGP,   768, 
                Offset (0x80), 
                BEEL,   1
            }

            Field (MBXO, DWordAcc, NoLock, Preserve)
            {
                MSGA,   32, 
                Offset (0x18), 
                MHED,   32
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x03)
            }

            Name (BUFF, Buffer (0x60){})
            CreateDWordField (BUFF, Zero, DAT0)
            CreateDWordField (BUFF, 0x04, DAT1)
            CreateDWordField (BUFF, 0x08, DAT2)
            CreateDWordField (BUFF, 0x0C, DAT3)
            Method (PRSS, 2, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                DAT0 = Zero
                DAT1 = Arg0
                DAT2 = Arg1
                LENG = 0x10
                MSID = 0x04
                PRID = 0x11
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.PRSS.RESP */
            }

            Method (PRSG, 1, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                LENG = 0x08
                DAT0 = Arg0
                MSID = 0x05
                PRID = 0x11
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.PRSG.RESP */
            }

            Method (PEFG, 2, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                LENG = 0x0C
                DAT0 = Arg0
                DAT1 = Arg1
                MSID = 0x04
                PRID = 0x13
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.PEFG.RESP */
            }

            Method (CLKG, 1, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                DAT0 = Arg0
                LENG = 0x08
                MSID = 0x06
                PRID = 0x14
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.CLKG.RESP */
            }

            Method (CLKS, 3, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                DAT0 = Zero
                DAT1 = Arg0
                DAT2 = Arg1
                DAT3 = Arg2
                LENG = 0x14
                MSID = 0x05
                PRID = 0x14
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.CLKS.RESP */
            }

            Method (CLKD, 2, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                DAT0 = Arg0
                DAT1 = Arg1
                LENG = 0x0C
                MSID = 0x04
                PRID = 0x14
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.CLKD.RESP */
            }

            Method (CLKC, 2, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                DAT0 = Arg0
                DAT1 = Arg1
                LENG = 0x0C
                MSID = 0x07
                PRID = 0x14
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.CLKC.RESP */
            }

            Method (SENG, 2, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                SIGN = 0x50434303
                FLAG = Zero
                DAT0 = Arg0
                DAT1 = Arg1
                LENG = 0x0C
                MSID = 0x06
                PRID = 0x15
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.SENG.RESP */
            }

            Method (SFMD, 1, Serialized)
            {
                Acquire (MBXM, 0xFFFF)
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
                        Release (MBXM)
                        Return (Buffer (0x04)
                        {
                             0x06                                             // .
                        })
                    }
                }

                Local1 = MSGA /* \_SB_.PMMX.MSGA */
                MSGA = 0x0C7F
                DAT0 = Arg0
                LENG = 0x08
                MHED = 0x0802
                Name (RESP, Buffer (0x60){})
                MSGP = BUFF /* \_SB_.PMMX.BUFF */
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
                    Release (MBXM)
                    Return (Buffer (0x04)
                    {
                         0x0B                                             // .
                    })
                }

                RESP = MSGP /* \_SB_.PMMX.MSGP */
                MSGA = Local1
                Release (MBXM)
                Return (RESP) /* \_SB_.PMMX.SFMD.RESP */
            }
        }

        Device (ADSS)
        {
            Name (_HID, "CIXH6060")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x28))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07110000,         // Address Base
                    0x00010000,         // Address Length
                    )
            })
            Device (ACLK)
            {
                Name (_HID, "CIXH6061")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    If (GETV (0x28))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "audss_cru", 
                            ACRU
                        }
                    }
                })
                Name (CLKA, Package (0x1E)
                {
                    Package (0x03)
                    {
                        0x10, 
                        "hst", 
                        I2S0
                    }, 

                    Package (0x03)
                    {
                        0x11, 
                        "hst", 
                        I2S1
                    }, 

                    Package (0x03)
                    {
                        0x12, 
                        "hst", 
                        I2S2
                    }, 

                    Package (0x03)
                    {
                        0x13, 
                        "hst", 
                        I2S3
                    }, 

                    Package (0x03)
                    {
                        0x14, 
                        "hst", 
                        I2S4
                    }, 

                    Package (0x03)
                    {
                        0x15, 
                        "hst", 
                        I2S5
                    }, 

                    Package (0x03)
                    {
                        0x16, 
                        "hst", 
                        I2S6
                    }, 

                    Package (0x03)
                    {
                        0x17, 
                        "hst", 
                        I2S7
                    }, 

                    Package (0x03)
                    {
                        0x18, 
                        "hst", 
                        I2S8
                    }, 

                    Package (0x03)
                    {
                        0x19, 
                        "hst", 
                        I2S9
                    }, 

                    Package (0x03)
                    {
                        0x1A, 
                        "i2s", 
                        I2S0
                    }, 

                    Package (0x03)
                    {
                        0x1B, 
                        "i2s", 
                        I2S1
                    }, 

                    Package (0x03)
                    {
                        0x1C, 
                        "i2s", 
                        I2S2
                    }, 

                    Package (0x03)
                    {
                        0x1D, 
                        "i2s", 
                        I2S3
                    }, 

                    Package (0x03)
                    {
                        0x1E, 
                        "i2s", 
                        I2S4
                    }, 

                    Package (0x03)
                    {
                        0x1F, 
                        "i2s", 
                        I2S5
                    }, 

                    Package (0x03)
                    {
                        0x20, 
                        "i2s", 
                        I2S6
                    }, 

                    Package (0x03)
                    {
                        0x21, 
                        "i2s", 
                        I2S7
                    }, 

                    Package (0x03)
                    {
                        0x22, 
                        "i2s", 
                        I2S8
                    }, 

                    Package (0x03)
                    {
                        0x23, 
                        "i2s", 
                        I2S9
                    }, 

                    Package (0x03)
                    {
                        0x24, 
                        "mclk", 
                        I2S0
                    }, 

                    Package (0x03)
                    {
                        0x09, 
                        "", 
                        DMA1
                    }, 

                    Package (0x03)
                    {
                        0x07, 
                        "sysclk", 
                        HDA
                    }, 

                    Package (0x03)
                    {
                        0x08, 
                        "clk48m", 
                        HDA
                    }, 

                    Package (0x03)
                    {
                        0x03, 
                        "clk", 
                        DSP
                    }, 

                    Package (0x03)
                    {
                        0x04, 
                        "bclk", 
                        DSP
                    }, 

                    Package (0x03)
                    {
                        0x05, 
                        "pbclk", 
                        DSP
                    }, 

                    Package (0x03)
                    {
                        0x06, 
                        "sramclk", 
                        DSP
                    }, 

                    Package (0x03)
                    {
                        0x0E, 
                        "mb0clk", 
                        DSP
                    }, 

                    Package (0x03)
                    {
                        0x0F, 
                        "mb1clk", 
                        DSP
                    }
                })
                Name (CLKT, Package (0x06)
                {
                    Package (0x03)
                    {
                        0x4C, 
                        "audio_clk0", 
                        ACLK
                    }, 

                    Package (0x03)
                    {
                        0x4D, 
                        "audio_clk1", 
                        ACLK
                    }, 

                    Package (0x03)
                    {
                        0x4E, 
                        "audio_clk2", 
                        ACLK
                    }, 

                    Package (0x03)
                    {
                        0x4F, 
                        "audio_clk3", 
                        ACLK
                    }, 

                    Package (0x03)
                    {
                        0x46, 
                        "audio_clk4", 
                        ACLK
                    }, 

                    Package (0x03)
                    {
                        0x47, 
                        "audio_clk5", 
                        ACLK
                    }
                })
                Name (RSTL, Package (0x01)
                {
                    Package (0x04)
                    {
                        RST0, 
                        0x1F, 
                        ACLK, 
                        "noc"
                    }
                })
                PowerResource (PPRS, 0x00, 0x0000)
                {
                    OperationRegion (OPR0, SystemMemory, 0x07000020, 0x04)
                    Field (OPR0, DWordAcc, NoLock, Preserve)
                    {
                        MSK0,   32
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Local0 = MSK0 /* \_SB_.ADSS.ACLK.PPRS.MSK0 */
                        Local0 &= One
                        If ((Local0 > Zero))
                        {
                            Return (One)
                        }
                        Else
                        {
                            Return (Zero)
                        }
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        Local0 = MSK0 /* \_SB_.ADSS.ACLK.PPRS.MSK0 */
                        Local0 = ((Local0 | One) | 0x0FFC)
                        MSK0 = Local0
                        Sleep (One)
                        DMRP (One, 0x06, 0x07000000, One)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                        Local0 = MSK0 /* \_SB_.ADSS.ACLK.PPRS.MSK0 */
                        Local0 &= 0xFFFFFFFFFFFFFFFE
                        MSK0 = Local0
                        Sleep (One)
                    }
                }

                Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
                {
                    PPRS
                })
                Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
                {
                    PPRS
                })
            }

            Device (ARST)
            {
                Name (_HID, "CIXH6062")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    If (GETV (0x28))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "audss_cru", 
                            ACRU
                        }
                    }
                })
            }
        }

        Device (ACRU)
        {
            Name (_HID, "CIXHA018")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07110000,         // Address Base
                    0x00010000,         // Address Length
                    )
            })
        }

        Device (GPI0)
        {
            Name (_HID, "CIXH1002")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04120000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000150,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "ngpios", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "id", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "gpio-io-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "gpio-line-names", 
                        GPIN
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0106, 
                    "", 
                    GPI0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x1A, 
                    GPI0, 
                    "apb_reset"
                }
            })
            Name (GPIO, Package (0x20)
            {
                "GPIO043", 
                "GPIO044", 
                "GPIO045", 
                "GPIO046", 
                "GPIO047", 
                "GPIO048", 
                "GPIO049", 
                "GPIO050", 
                "GPIO051", 
                "GPIO052", 
                "GPIO053", 
                "GPIO054", 
                "GPIO055", 
                "GPIO056", 
                "GPIO057", 
                "GPIO058", 
                "GPIO059", 
                "GPIO060", 
                "GPIO061", 
                "GPIO062", 
                "GPIO063", 
                "GPIO064", 
                "GPIO065", 
                "GPIO066", 
                "GPIO067", 
                "GPIO068", 
                "GPIO069", 
                "GPIO070", 
                "GPIO071", 
                "GPIO072", 
                "GPIO073", 
                "GPIO074"
            })
        }

        Device (GPI1)
        {
            Name (_HID, "CIXH1003")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04130000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000151,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "ngpios", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "id", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "gpio-io-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "gpio-line-names", 
                        GPIN
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0106, 
                    "", 
                    GPI1
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x1A, 
                    GPI1, 
                    "apb_reset"
                }
            })
            Name (GPIO, Package (0x20)
            {
                "GPIO075", 
                "GPIO076", 
                "GPIO077", 
                "GPIO078", 
                "GPIO079", 
                "GPIO080", 
                "GPIO081", 
                "GPIO082", 
                "GPIO083", 
                "GPIO084", 
                "GPIO085", 
                "GPIO086", 
                "GPIO087", 
                "GPIO088", 
                "GPIO089", 
                "GPIO090", 
                "GPIO091", 
                "GPIO092", 
                "GPIO093", 
                "GPIO094", 
                "GPIO095", 
                "GPIO096", 
                "GPIO097", 
                "GPIO098", 
                "GPIO099", 
                "GPIO100", 
                "GPIO101", 
                "GPIO102", 
                "GPIO103", 
                "GPIO104", 
                "GPIO105", 
                "GPIO106"
            })
        }

        Device (GPI2)
        {
            Name (_HID, "CIXH1003")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04140000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000152,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "ngpios", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "id", 
                        0x05
                    }, 

                    Package (0x02)
                    {
                        "gpio-io-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "gpio-line-names", 
                        GPIN
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0106, 
                    "", 
                    GPI2
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x1A, 
                    GPI2, 
                    "apb_reset"
                }
            })
            Name (GPIO, Package (0x20)
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
                "GPIO138"
            })
        }

        Device (GPI3)
        {
            Name (_HID, "CIXH1003")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04150000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000153,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "ngpios", 
                        0x11
                    }, 

                    Package (0x02)
                    {
                        "id", 
                        0x06
                    }, 

                    Package (0x02)
                    {
                        "gpio-io-mask", 
                        0x00018000
                    }, 

                    Package (0x02)
                    {
                        "gpio-line-names", 
                        GPIN
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0106, 
                    "", 
                    GPI3
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x1A, 
                    GPI3, 
                    "apb_reset"
                }
            })
            Name (GPIO, Package (0x11)
            {
                "GPIO139", 
                "GPIO140", 
                "GPIO141", 
                "GPIO142", 
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

        Device (GPI4)
        {
            Name (_HID, "CIXH1003")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x16004000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000194,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "ngpios", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "id", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "gpio-io-mask", 
                        0xE0002040
                    }, 

                    Package (0x02)
                    {
                        "gpio-line-names", 
                        GPIN
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0106, 
                    "", 
                    GPI4
                }
            })
            Name (GPIO, Package (0x20)
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

        Device (GPI5)
        {
            Name (_HID, "CIXH1003")  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x16005000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000195,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "ngpios", 
                        0x0A
                    }, 

                    Package (0x02)
                    {
                        "id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "gpio-io-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "gpio-line-names", 
                        GPIN
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0106, 
                    "", 
                    GPI5
                }
            })
            Name (GPIO, Package (0x0A)
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

        Device (GPI6)
        {
            Name (_HID, "CIXH1003")  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x16006000,         // Address Base
                    0x00001000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000196,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "ngpios", 
                        0x0A
                    }, 

                    Package (0x02)
                    {
                        "id", 
                        0x02
                    }, 

                    Package (0x02)
                    {
                        "gpio-line-names", 
                        GPIO
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0106, 
                    "", 
                    GPI6
                }
            })
            Name (GPIO, Package (0x0A)
            {
                "SFI_GPIO0", 
                "SFI_GPIO1", 
                "SFI_GPIO2", 
                "SFI_GPIO3", 
                "SFI_GPIO4", 
                "SFI_GPIO5", 
                "SFI_GPIO6", 
                "SFI_GPIO7", 
                "SFI_GPIO8", 
                "SFI_GPIO9"
            })
        }

        Device (PWM0)
        {
            Name (_HID, "CIXH2011")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04110000,         // Address Base
                    0x00001000,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_pwm0", ResourceConsumer, ,)
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x0105, 
                    "fch_pwm_apb_clk", 
                    PWM0
                }, 

                Package (0x03)
                {
                    0xF2, 
                    "fch_pwm_func_clk", 
                    PWM0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x08, 
                    PWM0, 
                    "func_reset"
                }
            })
        }

        Device (PWM1)
        {
            Name (_HID, "CIXH2011")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04111000,         // Address Base
                    0x00001000,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_pwm1", ResourceConsumer, ,)
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x0105, 
                    "fch_pwm_apb_clk", 
                    PWM1
                }, 

                Package (0x03)
                {
                    0xF2, 
                    "fch_pwm_func_clk", 
                    PWM1
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x08, 
                    PWM1, 
                    "func_reset"
                }
            })
        }

        Device (TMR0)
        {
            Name (_HID, "CIXH1007")  // _HID: Hardware ID
            Name (_CID, "CIXH1007")  // _CID: Compatible ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04116000,         // Address Base
                    0x00002000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001F6,
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x0105, 
                    "fch_timer_apb_clk", 
                    TMR0
                }, 

                Package (0x03)
                {
                    0xF2, 
                    "fch_timer_func_clk", 
                    TMR0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x08, 
                    TMR0, 
                    "func_reset"
                }
            })
        }

        Device (HDA)
        {
            Name (_HID, "CIXH6020")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x070C0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000010A,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_hda", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "cru-ctrl", 
                        ACRU
                    }
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x0E, 
                    HDA, 
                    "hda"
                }
            })
            Name (DLKL, Package (0x02)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    HDA, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    HDA, 
                    Zero
                }
            })
        }

        Device (DCRU)
        {
            Name (_HID, "CIXHA018")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x28))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07110000,         // Address Base
                    0x00010000,         // Address Length
                    )
            })
        }

        Device (DSP)
        {
            Name (_HID, "CIXH6000")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x28))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07000000,         // Address Base
                    0x01000000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000105,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "firmware-name", 
                        "dsp_fw.bin"
                    }, 

                    Package (0x02)
                    {
                        "mbox-names", 
                        Package (0x02)
                        {
                            "tx0", 
                            "rx0"
                        }
                    }, 

                    Package (0x02)
                    {
                        "mboxes", 
                        Package (0x04)
                        {
                            MBX5, 
                            0x09, 
                            MBX4, 
                            0x09
                        }
                    }, 

                    Package (0x02)
                    {
                        "cix,dsp-ctrl", 
                        DCRU
                    }
                }
            })
            Name (RSTL, Package (0x03)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x0C, 
                    DSP, 
                    "mb0"
                }, 

                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x0D, 
                    DSP, 
                    "mb1"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x1E, 
                    DSP, 
                    "dsp"
                }
            })
            Name (DLKL, Package (0x02)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    DSP, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    DSP, 
                    Zero
                }
            })
        }

        Device (DMA0)
        {
            Name (_HID, "CIXHA014")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04190000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000014F,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "dma-channels", 
                        0x08
                    }, 

                    Package (0x02)
                    {
                        "dma-requests", 
                        0x08
                    }
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x0B, 
                    DMA0, 
                    "dma_reset"
                }
            })
        }

        Device (DMA1)
        {
            Name (_HID, "CIXH1006")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x28))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07010000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000106,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x06)
                {
                    Package (0x02)
                    {
                        "dma-channels", 
                        0x08
                    }, 

                    Package (0x02)
                    {
                        "dma-requests", 
                        0x14
                    }, 

                    Package (0x02)
                    {
                        "arm,clk-enable-atomic", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "arm,reg-map", 
                        Package (0x02)
                        {
                            0x07010000, 
                            0x20000000
                        }
                    }, 

                    Package (0x02)
                    {
                        "arm,ram-map", 
                        Package (0x02)
                        {
                            0xC0000000, 
                            0x30000000
                        }
                    }, 

                    Package (0x02)
                    {
                        "arm,remote-ctrl", 
                        ACRU
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0xEF, 
                    "", 
                    DMA0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x0F, 
                    DMA1, 
                    "dma_reset"
                }
            })
            Name (DLKL, Package (0x02)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    DMA1, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    DMA1, 
                    Zero
                }
            })
        }

        Device (XSPI)
        {
            Name (_HID, "CIXH2002")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04180000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x00010000,         // Address Base
                    0x04000000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000014E,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_fch_xspi", ResourceConsumer, ,)
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0xFC, 
                    "pclk", 
                    XSPI
                }, 

                Package (0x03)
                {
                    0xF1, 
                    "maclk", 
                    XSPI
                }, 

                Package (0x03)
                {
                    0xF0, 
                    "funcclk", 
                    XSPI
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST1, 
                    0x1B, 
                    XSPI, 
                    "xspi_reg_reset"
                }, 

                Package (0x04)
                {
                    RST1, 
                    0x1C, 
                    XSPI, 
                    "xspi_sys_reset"
                }
            })
        }

        Device (I2C0)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x05))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x2C)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x00061A80)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04010000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000013E,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_i2c0", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c0_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0xFD, 
                    "", 
                    I2C0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x12, 
                    I2C0, 
                    "i2c_reset"
                }
            })
        }

        Device (I2C1)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x06))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x2D)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x000186A0)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04020000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000013F,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c1_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0xFE, 
                    "", 
                    I2C1
                }
            })
        }

        Device (I2C2)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x07))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x2E)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x00061A80)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04030000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000140,
                }
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI0", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x000C,
                        0x000D
                    }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_i2c2", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c2_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }, 

                    Package (0x02)
                    {
                        "scl-gpios", 
                        Package (0x04)
                        {
                            I2C2, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "sda-gpios", 
                        Package (0x04)
                        {
                            I2C2, 
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
                    0xFF, 
                    "", 
                    I2C2
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x14, 
                    I2C2, 
                    "i2c_reset"
                }
            })
        }

        Device (I2C3)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x08))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x2F)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x00061A80)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04040000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000141,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c3_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0100, 
                    "", 
                    I2C3
                }
            })
        }

        Device (I2C4)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x09))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x30)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x00061A80)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04050000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000142,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c4_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0101, 
                    "", 
                    I2C4
                }
            })
        }

        Device (I2C5)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0A))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x31)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x00061A80)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04060000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000143,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c5_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0102, 
                    "", 
                    I2C5
                }
            })
        }

        Device (I2C6)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0B))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x32)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x00061A80)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04070000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000144,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c6_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0103, 
                    "", 
                    I2C6
                }
            })
        }

        Device (I2C7)
        {
            Name (_HID, "CIXH200B")  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0C))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x33)
                Local0 *= 0x2710
                CLKF = Local0
            }

            Name (CLKF, 0x000186A0)
            Name (MXID, 0xFF)
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04080000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000145,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "ClockName", 
                        "fch_i2c7_apb"
                    }, 

                    Package (0x02)
                    {
                        "clock-frequency", 
                        CLKF
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x0104, 
                    "", 
                    I2C7
                }
            })
        }

        Device (SPI0)
        {
            Name (_HID, "CIXH2001")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04090000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000146,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_fch_spi0", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "fifo-width", 
                        0x20
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xFA, 
                    "pclk", 
                    SPI0
                }, 

                Package (0x03)
                {
                    0xFA, 
                    "ref_clk", 
                    SPI0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x10, 
                    SPI0, 
                    "spi_reset"
                }
            })
        }

        Device (SPI1)
        {
            Name (_HID, "CIXH2001")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x040A0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000147,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_spi1", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "fifo-width", 
                        0x20
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xFB, 
                    "pclk", 
                    SPI1
                }, 

                Package (0x03)
                {
                    0xFB, 
                    "ref_clk", 
                    SPI1
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST1, 
                    0x11, 
                    SPI1, 
                    "spi_reset"
                }
            })
        }

        Device (I3C0)
        {
            Name (_HID, "CIXH200C")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x040F0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000014C,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_i3c0", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "i3c-scl-hz", 
                        0x000186A0
                    }, 

                    Package (0x02)
                    {
                        "i2c-scl-hz", 
                        0x000186A0
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xF4, 
                    "pclk", 
                    I3C0
                }, 

                Package (0x03)
                {
                    0xED, 
                    "sysclk", 
                    I3C0
                }
            })
        }

        Device (I3C1)
        {
            Name (_HID, "CIXH200C")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x04100000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000014D,
                }
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_fch_i3c1", ResourceConsumer, ,)
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xF5, 
                    "pclk", 
                    I3C1
                }, 

                Package (0x03)
                {
                    0xEE, 
                    "sysclk", 
                    I3C1
                }
            })
        }

        Device (PCI0)
        {
            Name (_HID, "PNP0A08" /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, "PNP0A03" /* PCI Bus */)  // _CID: Compatible ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 0 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0xC0)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0D))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                        0x0000,             // Granularity
                        0x00C0,             // Range Minimum
                        0x00FF,             // Range Maximum
                        0x0000,             // Translation Offset
                        0x0040,             // Length
                        ,, )
                    DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x00000000,         // Granularity
                        0x60000000,         // Range Minimum
                        0x7FFFFFFF,         // Range Maximum
                        0x00000000,         // Translation Offset
                        0x20000000,         // Length
                        ,, , AddressRangeMemory, TypeStatic)
                    QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x0000000000000000, // Granularity
                        0x0000001800000000, // Range Minimum
                        0x0000001BFFFFFFFF, // Range Maximum
                        0x0000000000000000, // Translation Offset
                        0x0000000400000000, // Length
                        ,, , AddressRangeMemory, TypeStatic)
                })
                Return (RBUF) /* \_SB_.PCI0._CRS.RBUF */
            }

            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01B7
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01B8
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01B9
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01BA
                }
            })
            Name (SUPP, Zero)
            Name (CTRL, Zero)
            Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
            {
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    CreateDWordField (Arg3, Zero, CDW1)
                    CreateDWordField (Arg3, 0x04, CDW2)
                    CreateDWordField (Arg3, 0x08, CDW3)
                    SUPP = CDW2 /* \_SB_.PCI0._OSC.CDW2 */
                    CTRL = CDW3 /* \_SB_.PCI0._OSC.CDW3 */
                    If (((SUPP & 0x16) != 0x16))
                    {
                        CTRL &= 0x1E
                    }

                    CTRL &= 0x10
                    If ((Arg1 != One))
                    {
                        CDW1 |= 0x08
                    }

                    If ((CDW3 != CTRL))
                    {
                        CDW1 |= 0x10
                    }

                    CDW3 = CTRL /* \_SB_.PCI0.CTRL */
                    Return (Arg3)
                }
                Else
                {
                    CDW1 |= 0x04
                    Return (Arg3)
                }
            }
        }

        Device (PCI1)
        {
            Name (_HID, "PNP0A08" /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, "PNP0A03" /* PCI Bus */)  // _CID: Compatible ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 1 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0x90)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0E))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                        0x0000,             // Granularity
                        0x0090,             // Range Minimum
                        0x00AF,             // Range Maximum
                        0x0000,             // Translation Offset
                        0x0020,             // Length
                        ,, )
                    DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x00000000,         // Granularity
                        0x50000000,         // Range Minimum
                        0x5FFFFFFF,         // Range Maximum
                        0x00000000,         // Translation Offset
                        0x10000000,         // Length
                        ,, , AddressRangeMemory, TypeStatic)
                    QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x0000000000000000, // Granularity
                        0x0000001400000000, // Range Minimum
                        0x00000017FFFFFFFF, // Range Maximum
                        0x0000000000000000, // Translation Offset
                        0x0000000400000000, // Length
                        ,, , AddressRangeMemory, TypeStatic)
                })
                Return (RBUF) /* \_SB_.PCI1._CRS.RBUF */
            }

            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01C1
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01C2
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01C3
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01C4
                }
            })
            Name (SUPP, Zero)
            Name (CTRL, Zero)
            Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
            {
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    CreateDWordField (Arg3, Zero, CDW1)
                    CreateDWordField (Arg3, 0x04, CDW2)
                    CreateDWordField (Arg3, 0x08, CDW3)
                    SUPP = CDW2 /* \_SB_.PCI1._OSC.CDW2 */
                    CTRL = CDW3 /* \_SB_.PCI1._OSC.CDW3 */
                    If (((SUPP & 0x16) != 0x16))
                    {
                        CTRL &= 0x1E
                    }

                    CTRL &= 0x10
                    If ((Arg1 != One))
                    {
                        CDW1 |= 0x08
                    }

                    If ((CDW3 != CTRL))
                    {
                        CDW1 |= 0x10
                    }

                    CDW3 = CTRL /* \_SB_.PCI1.CTRL */
                    Return (Arg3)
                }
                Else
                {
                    CDW1 |= 0x04
                    Return (Arg3)
                }
            }
        }

        Device (PCI2)
        {
            Name (_HID, "PNP0A08" /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, "PNP0A03" /* PCI Bus */)  // _CID: Compatible ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 2 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0x60)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0F))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                        0x0000,             // Granularity
                        0x0060,             // Range Minimum
                        0x007F,             // Range Maximum
                        0x0000,             // Translation Offset
                        0x0020,             // Length
                        ,, )
                    DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x00000000,         // Granularity
                        0x40000000,         // Range Minimum
                        0x4FFFFFFF,         // Range Maximum
                        0x00000000,         // Translation Offset
                        0x10000000,         // Length
                        ,, , AddressRangeMemory, TypeStatic)
                    QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x0000000000000000, // Granularity
                        0x0000001000000000, // Range Minimum
                        0x00000013FFFFFFFF, // Range Maximum
                        0x0000000000000000, // Translation Offset
                        0x0000000400000000, // Length
                        ,, , AddressRangeMemory, TypeStatic)
                })
                Return (RBUF) /* \_SB_.PCI2._CRS.RBUF */
            }

            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01CB
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01CC
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01CD
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01CE
                }
            })
            Name (SUPP, Zero)
            Name (CTRL, Zero)
            Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
            {
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    CreateDWordField (Arg3, Zero, CDW1)
                    CreateDWordField (Arg3, 0x04, CDW2)
                    CreateDWordField (Arg3, 0x08, CDW3)
                    SUPP = CDW2 /* \_SB_.PCI2._OSC.CDW2 */
                    CTRL = CDW3 /* \_SB_.PCI2._OSC.CDW3 */
                    If (((SUPP & 0x16) != 0x16))
                    {
                        CTRL &= 0x1E
                    }

                    CTRL &= 0x10
                    If ((Arg1 != One))
                    {
                        CDW1 |= 0x08
                    }

                    If ((CDW3 != CTRL))
                    {
                        CDW1 |= 0x10
                    }

                    CDW3 = CTRL /* \_SB_.PCI2.CTRL */
                    Return (Arg3)
                }
                Else
                {
                    CDW1 |= 0x04
                    Return (Arg3)
                }
            }
        }

        Device (PCI3)
        {
            Name (_HID, "PNP0A08" /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, "PNP0A03" /* PCI Bus */)  // _CID: Compatible ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 3 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0x30)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x10))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                        0x0000,             // Granularity
                        0x0030,             // Range Minimum
                        0x004F,             // Range Maximum
                        0x0000,             // Translation Offset
                        0x0020,             // Length
                        ,, )
                    DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x00000000,         // Granularity
                        0x38000000,         // Range Minimum
                        0x3FFFFFFF,         // Range Maximum
                        0x00000000,         // Translation Offset
                        0x08000000,         // Length
                        ,, , AddressRangeMemory, TypeStatic)
                    QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x0000000000000000, // Granularity
                        0x0000000C00000000, // Range Minimum
                        0x0000000FFFFFFFFF, // Range Maximum
                        0x0000000000000000, // Translation Offset
                        0x0000000400000000, // Length
                        ,, , AddressRangeMemory, TypeStatic)
                })
                Return (RBUF) /* \_SB_.PCI3._CRS.RBUF */
            }

            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01DD
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01DE
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01DF
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01E0
                }
            })
            Name (SUPP, Zero)
            Name (CTRL, Zero)
            Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
            {
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    CreateDWordField (Arg3, Zero, CDW1)
                    CreateDWordField (Arg3, 0x04, CDW2)
                    CreateDWordField (Arg3, 0x08, CDW3)
                    SUPP = CDW2 /* \_SB_.PCI3._OSC.CDW2 */
                    CTRL = CDW3 /* \_SB_.PCI3._OSC.CDW3 */
                    If (((SUPP & 0x16) != 0x16))
                    {
                        CTRL &= 0x1E
                    }

                    CTRL &= 0x10
                    If ((Arg1 != One))
                    {
                        CDW1 |= 0x08
                    }

                    If ((CDW3 != CTRL))
                    {
                        CDW1 |= 0x10
                    }

                    CDW3 = CTRL /* \_SB_.PCI3.CTRL */
                    Return (Arg3)
                }
                Else
                {
                    CDW1 |= 0x04
                    Return (Arg3)
                }
            }
        }

        Device (PCI4)
        {
            Name (_HID, "PNP0A08" /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, "PNP0A03" /* PCI Bus */)  // _CID: Compatible ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 4 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, Zero)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x11))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                        0x0000,             // Granularity
                        0x0000,             // Range Minimum
                        0x001F,             // Range Maximum
                        0x0000,             // Translation Offset
                        0x0020,             // Length
                        ,, )
                    DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x00000000,         // Granularity
                        0x30000000,         // Range Minimum
                        0x37FFFFFF,         // Range Maximum
                        0x00000000,         // Translation Offset
                        0x08000000,         // Length
                        ,, , AddressRangeMemory, TypeStatic)
                    QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x0000000000000000, // Granularity
                        0x0000000800000000, // Range Minimum
                        0x0000000BFFFFFFFF, // Range Maximum
                        0x0000000000000000, // Translation Offset
                        0x0000000400000000, // Length
                        ,, , AddressRangeMemory, TypeStatic)
                })
                Return (RBUF) /* \_SB_.PCI4._CRS.RBUF */
            }

            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01D4
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01D5
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01D6
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01D7
                }
            })
            Name (SUPP, Zero)
            Name (CTRL, Zero)
            Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
            {
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    CreateDWordField (Arg3, Zero, CDW1)
                    CreateDWordField (Arg3, 0x04, CDW2)
                    CreateDWordField (Arg3, 0x08, CDW3)
                    SUPP = CDW2 /* \_SB_.PCI4._OSC.CDW2 */
                    CTRL = CDW3 /* \_SB_.PCI4._OSC.CDW3 */
                    If (((SUPP & 0x16) != 0x16))
                    {
                        CTRL &= 0x1E
                    }

                    CTRL &= 0x10
                    If ((Arg1 != One))
                    {
                        CDW1 |= 0x08
                    }

                    If ((CDW3 != CTRL))
                    {
                        CDW1 |= 0x10
                    }

                    CDW3 = CTRL /* \_SB_.PCI4.CTRL */
                    Return (Arg3)
                }
                Else
                {
                    CDW1 |= 0x04
                    Return (Arg3)
                }
            }
        }

        Device (RES0)
        {
            Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                QWordMemory (ResourceConsumer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000000020000000, // Range Minimum
                    0x000000002FFFFFFF, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000010000000, // Length
                    ,, , AddressRangeMemory, TypeStatic)
            })
        }

        Device (PRC0)
        {
            Name (_HID, "CIXH2020")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 0 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0xC0)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (MLKS, 0x04)
            Name (NUML, 0x08)
            Name (MPAL, 0x0200)
            Name (MAPM, 0x03)
            Name (ASPM, Zero)
            Method (_INI, 0, Serialized)  // _INI: Initialize
            {
                Local0 = GETV (0x34)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }
                    Case (0x02)
                    {
                        Local1 = 0x04
                    }
                    Case (0x03)
                    {
                        Local1 = 0x08
                    }

                }

                If ((Local1 != Zero))
                {
                    NUML = Local1
                }

                Local0 = GETV (0x39)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }
                    Case (0x02)
                    {
                        Local1 = 0x03
                    }
                    Case (0x03)
                    {
                        Local1 = 0x04
                    }

                }

                If ((Local1 != Zero))
                {
                    MLKS = Local1
                }

                Local0 = GETV (0x3E)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = 0x80
                    }
                    Case (One)
                    {
                        Local1 = 0x0100
                    }
                    Case (0x02)
                    {
                        Local1 = 0x0200
                    }

                }

                If ((Local1 != Zero))
                {
                    MPAL = Local1
                }

                Local0 = GETV (0x43)
                MAPM = Local0
                Local0 = GETV (0x48)
                ASPM = Local0
            }

            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0D))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A010000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x0A000000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x2C000000,         // Address Base
                    0x04000000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x60000000,         // Address Base
                    0x00100000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001B2,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001B3,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001B4,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001B5,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001B6,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001BB,
                }
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x00C0,             // Range Minimum
                    0x00FF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0040,             // Length
                    ,, )
                DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x00000000,         // Granularity
                    0x60100000,         // Range Minimum
                    0x601FFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00100000,         // Length
                    ,, , TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x60200000,         // Range Minimum
                    0x6FFFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x0FE00000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000001800000000, // Range Minimum
                    0x0000001BFFFFFFFF, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000400000000, // Length
                    ,, , AddressRangeMemory, TypeStatic)
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_pcie_x8_rc", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0001
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x0F)
                {
                    Package (0x02)
                    {
                        "device_type", 
                        "pci"
                    }, 

                    Package (0x02)
                    {
                        "vendor-id", 
                        0x1F6C
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "bus-range", 
                        Package (0x02)
                        {
                            0xC0, 
                            0xFF
                        }
                    }, 

                    Package (0x02)
                    {
                        "max-link-speed", 
                        MLKS
                    }, 

                    Package (0x02)
                    {
                        "num-lanes", 
                        NUML
                    }, 

                    Package (0x02)
                    {
                        "cdns,no-inbound-bar", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "sky1,pcie-ctrl-id", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "sky1,aer-uncor-panic", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pcie-phy", 
                        ^PCP0.PX8P
                    }, 

                    Package (0x02)
                    {
                        "max-payload", 
                        MPAL
                    }, 

                    Package (0x02)
                    {
                        "max-aspm-support", 
                        MAPM
                    }, 

                    Package (0x02)
                    {
                        "aspm", 
                        ASPM
                    }, 

                    Package (0x02)
                    {
                        "reset-gpios", 
                        Package (0x04)
                        {
                            PRC0, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "vcc-pcie-supply", 
                        PVC0
                    }
                }
            })
            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01B7
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01B8
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01B9
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01BA
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0xAB, 
                    "axi_clk", 
                    PRC0
                }, 

                Package (0x03)
                {
                    0xA2, 
                    "apb_clk", 
                    PRC0
                }, 

                Package (0x03)
                {
                    0xDD, 
                    "refclk_b", 
                    PRC0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x2E, 
                    PRC0, 
                    "pcie_reset"
                }
            })
            Name (DLKL, Package (0x02)
            {
                Package (0x03)
                {
                    PCP0, 
                    PRC0, 
                    Zero
                }, 

                Package (0x03)
                {
                    PVC0, 
                    PRC0, 
                    Zero
                }
            })
            Name (RSNL, Package (0x0A)
            {
                Package (0x04)
                {
                    PRC0, 
                    0x0200, 
                    Zero, 
                    "reg"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0200, 
                    One, 
                    "rcsu"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0200, 
                    0x02, 
                    "cfg"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0200, 
                    0x03, 
                    "msg"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0400, 
                    Zero, 
                    "aer_c"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0400, 
                    One, 
                    "aer_f"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0400, 
                    0x02, 
                    "aer_nf"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0400, 
                    0x03, 
                    "local"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0400, 
                    0x04, 
                    "phy_int"
                }, 

                Package (0x04)
                {
                    PRC0, 
                    0x0400, 
                    0x05, 
                    "phy_sta"
                }
            })
            OperationRegion (OPR0, SystemMemory, 0x0A000020, 0x04)
            Field (OPR0, DWordAcc, NoLock, Preserve)
            {
                MSK0,   32
            }

            Method (PWON, 0, Serialized)
            {
                Local0 = MSK0 /* \_SB_.PRC0.MSK0 */
                Local0 = ((Local0 | One) | 0x0FFC)
                MSK0 = Local0
                DMRP (One, 0x0C, 0x0A000000, One)
            }
        }

        Device (PCP0)
        {
            Name (_HID, "CIXH2023")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0D))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A020000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xA7, 
                    "pclk", 
                    PCP0
                }, 

                Package (0x03)
                {
                    0xE2, 
                    "refclk", 
                    PCP0
                }
            })
            Device (PX8P)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (NUML, 0x08)
                Method (_INI, 0, Serialized)  // _INI: Initialize
                {
                    Local0 = GETV (0x34)
                    Local1 = Zero
                    Switch (ToInteger (Local0))
                    {
                        Case (Zero)
                        {
                            Local1 = One
                        }
                        Case (One)
                        {
                            Local1 = 0x02
                        }
                        Case (0x02)
                        {
                            Local1 = 0x04
                        }
                        Case (0x03)
                        {
                            Local1 = 0x08
                        }

                    }

                    If ((Local1 != Zero))
                    {
                        NUML = Local1
                    }
                }

                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
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
                            "num-lanes", 
                            NUML
                        }
                    }
                })
            }
        }

        Device (PRC1)
        {
            Name (_HID, "CIXH2020")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 1 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0x90)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (MLKS, 0x04)
            Name (NUML, 0x04)
            Name (MPAL, 0x0200)
            Name (MAPM, 0x03)
            Name (ASPM, Zero)
            Method (_INI, 0, Serialized)  // _INI: Initialize
            {
                Local0 = GETV (0x35)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }
                    Case (0x02)
                    {
                        Local1 = 0x04
                    }

                }

                If ((Local1 != Zero))
                {
                    NUML = Local1
                }

                Local0 = GETV (0x3A)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }
                    Case (0x02)
                    {
                        Local1 = 0x03
                    }
                    Case (0x03)
                    {
                        Local1 = 0x04
                    }

                }

                If ((Local1 != Zero))
                {
                    MLKS = Local1
                }

                Local0 = GETV (0x3F)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = 0x80
                    }
                    Case (One)
                    {
                        Local1 = 0x0100
                    }
                    Case (0x02)
                    {
                        Local1 = 0x0200
                    }

                }

                If ((Local1 != Zero))
                {
                    MPAL = Local1
                }

                Local0 = GETV (0x44)
                MAPM = Local0
                Local0 = GETV (0x49)
                ASPM = Local0
            }

            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0E))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A070000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x0A060000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x29000000,         // Address Base
                    0x03000000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x50000000,         // Address Base
                    0x00100000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001BC,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001BD,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001BE,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001BF,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001C0,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001C5,
                }
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0090,             // Range Minimum
                    0x00AF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0020,             // Length
                    ,, )
                DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x00000000,         // Granularity
                    0x50100000,         // Range Minimum
                    0x501FFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00100000,         // Length
                    ,, , TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x50200000,         // Range Minimum
                    0x5FFFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x0FE00000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000001400000000, // Range Minimum
                    0x00000017FFFFFFFF, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000400000000, // Length
                    ,, , AddressRangeMemory, TypeStatic)
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_pcie_x4_rc", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0003
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x0E)
                {
                    Package (0x02)
                    {
                        "device_type", 
                        "pci"
                    }, 

                    Package (0x02)
                    {
                        "vendor-id", 
                        0x1F6C
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "bus-range", 
                        Package (0x02)
                        {
                            0x90, 
                            0xAF
                        }
                    }, 

                    Package (0x02)
                    {
                        "max-link-speed", 
                        MLKS
                    }, 

                    Package (0x02)
                    {
                        "num-lanes", 
                        NUML
                    }, 

                    Package (0x02)
                    {
                        "cdns,no-inbound-bar", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "sky1,pcie-ctrl-id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "sky1,aer-uncor-panic", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pcie-phy", 
                        ^PCP1.PX4P
                    }, 

                    Package (0x02)
                    {
                        "max-payload", 
                        MPAL
                    }, 

                    Package (0x02)
                    {
                        "max-aspm-support", 
                        MAPM
                    }, 

                    Package (0x02)
                    {
                        "aspm", 
                        ASPM
                    }, 

                    Package (0x02)
                    {
                        "reset-gpios", 
                        Package (0x04)
                        {
                            PRC1, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }
                }
            })
            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01C1
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01C2
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01C3
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01C4
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0xAC, 
                    "axi_clk", 
                    PRC1
                }, 

                Package (0x03)
                {
                    0xA3, 
                    "apb_clk", 
                    PRC1
                }, 

                Package (0x03)
                {
                    0xDE, 
                    "refclk_b", 
                    PRC1
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x2F, 
                    PRC1, 
                    "pcie_reset"
                }
            })
            Name (DLKL, Package (0x01)
            {
                Package (0x03)
                {
                    PCP1, 
                    PRC1, 
                    Zero
                }
            })
            Name (RSNL, Package (0x0A)
            {
                Package (0x04)
                {
                    PRC1, 
                    0x0200, 
                    Zero, 
                    "reg"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0200, 
                    One, 
                    "rcsu"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0200, 
                    0x02, 
                    "cfg"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0200, 
                    0x03, 
                    "msg"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0400, 
                    Zero, 
                    "aer_c"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0400, 
                    One, 
                    "aer_f"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0400, 
                    0x02, 
                    "aer_nf"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0400, 
                    0x03, 
                    "local"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0400, 
                    0x04, 
                    "phy_int"
                }, 

                Package (0x04)
                {
                    PRC1, 
                    0x0400, 
                    0x05, 
                    "phy_sta"
                }
            })
        }

        Device (PCP1)
        {
            Name (_HID, "CIXH2023")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0E))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A080000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xA8, 
                    "pclk", 
                    PCP1
                }, 

                Package (0x03)
                {
                    0xE3, 
                    "refclk", 
                    PCP1
                }
            })
            Device (PX4P)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (NUML, 0x04)
                Method (_INI, 0, Serialized)  // _INI: Initialize
                {
                    Local0 = GETV (0x35)
                    Local1 = Zero
                    Switch (ToInteger (Local0))
                    {
                        Case (Zero)
                        {
                            Local1 = One
                        }
                        Case (One)
                        {
                            Local1 = 0x02
                        }
                        Case (0x02)
                        {
                            Local1 = 0x04
                        }

                    }

                    If ((Local1 != Zero))
                    {
                        NUML = Local1
                    }
                }

                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
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
                            "num-lanes", 
                            NUML
                        }
                    }
                })
            }
        }

        Device (PRC2)
        {
            Name (_HID, "CIXH2020")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 2 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0x60)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (MLKS, 0x04)
            Name (NUML, 0x02)
            Name (MPAL, 0x0200)
            Name (MAPM, 0x03)
            Name (ASPM, Zero)
            Method (_INI, 0, Serialized)  // _INI: Initialize
            {
                Local0 = GETV (0x36)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }

                }

                If ((Local1 != Zero))
                {
                    NUML = Local1
                }

                Local0 = GETV (0x3B)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }
                    Case (0x02)
                    {
                        Local1 = 0x03
                    }
                    Case (0x03)
                    {
                        Local1 = 0x04
                    }

                }

                If ((Local1 != Zero))
                {
                    MLKS = Local1
                }

                Local0 = GETV (0x40)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = 0x80
                    }
                    Case (One)
                    {
                        Local1 = 0x0100
                    }
                    Case (0x02)
                    {
                        Local1 = 0x0200
                    }

                }

                If ((Local1 != Zero))
                {
                    MPAL = Local1
                }

                Local0 = GETV (0x45)
                MAPM = Local0
                Local0 = GETV (0x4A)
                ASPM = Local0
            }

            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0F))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A0C0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x0A060000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x26000000,         // Address Base
                    0x03000000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x40000000,         // Address Base
                    0x00100000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001C6,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001C7,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001C8,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001C9,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001CA,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E3,
                }
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0060,             // Range Minimum
                    0x008F,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0030,             // Length
                    ,, )
                DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x00000000,         // Granularity
                    0x40100000,         // Range Minimum
                    0x401FFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00100000,         // Length
                    ,, , TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x40200000,         // Range Minimum
                    0x4FFFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x0FE00000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000001000000000, // Range Minimum
                    0x00000013FFFFFFFF, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000400000000, // Length
                    ,, , AddressRangeMemory, TypeStatic)
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_pcie_x2_rc", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0004
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x0F)
                {
                    Package (0x02)
                    {
                        "device_type", 
                        "pci"
                    }, 

                    Package (0x02)
                    {
                        "vendor-id", 
                        0x1F6C
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "bus-range", 
                        Package (0x02)
                        {
                            0x60, 
                            0x8F
                        }
                    }, 

                    Package (0x02)
                    {
                        "max-link-speed", 
                        MLKS
                    }, 

                    Package (0x02)
                    {
                        "num-lanes", 
                        NUML
                    }, 

                    Package (0x02)
                    {
                        "cdns,no-inbound-bar", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "sky1,pcie-ctrl-id", 
                        0x02
                    }, 

                    Package (0x02)
                    {
                        "sky1,aer-uncor-panic", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pcie-phy", 
                        ^PCP2.PX2P
                    }, 

                    Package (0x02)
                    {
                        "max-payload", 
                        MPAL
                    }, 

                    Package (0x02)
                    {
                        "max-aspm-support", 
                        MAPM
                    }, 

                    Package (0x02)
                    {
                        "aspm", 
                        ASPM
                    }, 

                    Package (0x02)
                    {
                        "reset-gpios", 
                        Package (0x04)
                        {
                            PRC2, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "vcc-pcie-supply", 
                        PVC2
                    }
                }
            })
            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01CB
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01CC
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01CD
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01CE
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0xAD, 
                    "axi_clk", 
                    PRC2
                }, 

                Package (0x03)
                {
                    0xA4, 
                    "apb_clk", 
                    PRC2
                }, 

                Package (0x03)
                {
                    0xDF, 
                    "refclk_b", 
                    PRC2
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x30, 
                    PRC2, 
                    "pcie_reset"
                }
            })
            Name (DLKL, Package (0x02)
            {
                Package (0x03)
                {
                    PCP2, 
                    PRC2, 
                    Zero
                }, 

                Package (0x03)
                {
                    PVC2, 
                    PRC2, 
                    Zero
                }
            })
            Name (RSNL, Package (0x0A)
            {
                Package (0x04)
                {
                    PRC2, 
                    0x0200, 
                    Zero, 
                    "reg"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0200, 
                    One, 
                    "rcsu"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0200, 
                    0x02, 
                    "cfg"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0200, 
                    0x03, 
                    "msg"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0400, 
                    Zero, 
                    "aer_c"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0400, 
                    One, 
                    "aer_f"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0400, 
                    0x02, 
                    "aer_nf"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0400, 
                    0x03, 
                    "local"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0400, 
                    0x04, 
                    "phy_int"
                }, 

                Package (0x04)
                {
                    PRC2, 
                    0x0400, 
                    0x05, 
                    "phy_sta"
                }
            })
        }

        Device (PRC3)
        {
            Name (_HID, "CIXH2020")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 3 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, 0x30)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (MLKS, 0x04)
            Name (NUML, One)
            Name (MPAL, 0x0200)
            Name (MAPM, 0x03)
            Name (ASPM, Zero)
            Method (_INI, 0, Serialized)  // _INI: Initialize
            {
                Local0 = GETV (0x3C)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }
                    Case (0x02)
                    {
                        Local1 = 0x03
                    }
                    Case (0x03)
                    {
                        Local1 = 0x04
                    }

                }

                If ((Local1 != Zero))
                {
                    MLKS = Local1
                }

                Local0 = GETV (0x41)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = 0x80
                    }
                    Case (One)
                    {
                        Local1 = 0x0100
                    }
                    Case (0x02)
                    {
                        Local1 = 0x0200
                    }

                }

                If ((Local1 != Zero))
                {
                    MPAL = Local1
                }

                Local0 = GETV (0x46)
                MAPM = Local0
                Local0 = GETV (0x4B)
                ASPM = Local0
            }

            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x10))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A0E0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x0A060000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x23000000,         // Address Base
                    0x03000000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x38000000,         // Address Base
                    0x00100000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001D8,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001D9,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001DA,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001DB,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001DC,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E2,
                }
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0030,             // Range Minimum
                    0x005F,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0030,             // Length
                    ,, )
                DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x00000000,         // Granularity
                    0x38100000,         // Range Minimum
                    0x381FFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00100000,         // Length
                    ,, , TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x38200000,         // Range Minimum
                    0x3FFFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x07E00000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000000C00000000, // Range Minimum
                    0x0000000FFFFFFFFF, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000400000000, // Length
                    ,, , AddressRangeMemory, TypeStatic)
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_pcie_x1_1_rc", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0005
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x0F)
                {
                    Package (0x02)
                    {
                        "device_type", 
                        "pci"
                    }, 

                    Package (0x02)
                    {
                        "vendor-id", 
                        0x1F6C
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "bus-range", 
                        Package (0x02)
                        {
                            0x30, 
                            0x5F
                        }
                    }, 

                    Package (0x02)
                    {
                        "max-link-speed", 
                        MLKS
                    }, 

                    Package (0x02)
                    {
                        "num-lanes", 
                        NUML
                    }, 

                    Package (0x02)
                    {
                        "cdns,no-inbound-bar", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "sky1,pcie-ctrl-id", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "sky1,aer-uncor-panic", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pcie-phy", 
                        ^PCP2.PX11
                    }, 

                    Package (0x02)
                    {
                        "max-payload", 
                        MPAL
                    }, 

                    Package (0x02)
                    {
                        "max-aspm-support", 
                        MAPM
                    }, 

                    Package (0x02)
                    {
                        "aspm", 
                        ASPM
                    }, 

                    Package (0x02)
                    {
                        "reset-gpios", 
                        Package (0x04)
                        {
                            PRC3, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "vcc-pcie-supply", 
                        PVC4
                    }
                }
            })
            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01DD
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01DE
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01DF
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01E0
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0xAF, 
                    "axi_clk", 
                    PRC3
                }, 

                Package (0x03)
                {
                    0xA6, 
                    "apb_clk", 
                    PRC3
                }, 

                Package (0x03)
                {
                    0xE1, 
                    "refclk_b", 
                    PRC3
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x32, 
                    PRC3, 
                    "pcie_reset"
                }
            })
            Name (DLKL, Package (0x02)
            {
                Package (0x03)
                {
                    PCP2, 
                    PRC3, 
                    Zero
                }, 

                Package (0x03)
                {
                    PVC4, 
                    PRC3, 
                    Zero
                }
            })
            Name (RSNL, Package (0x0A)
            {
                Package (0x04)
                {
                    PRC3, 
                    0x0200, 
                    Zero, 
                    "reg"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0200, 
                    One, 
                    "rcsu"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0200, 
                    0x02, 
                    "cfg"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0200, 
                    0x03, 
                    "msg"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0400, 
                    Zero, 
                    "aer_c"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0400, 
                    One, 
                    "aer_f"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0400, 
                    0x02, 
                    "aer_nf"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0400, 
                    0x03, 
                    "local"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0400, 
                    0x04, 
                    "phy_int"
                }, 

                Package (0x04)
                {
                    PRC3, 
                    0x0400, 
                    0x05, 
                    "phy_sta"
                }
            })
        }

        Device (PRC4)
        {
            Name (_HID, "CIXH2020")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_STR, Unicode ("PCIe 4 Device"))  // _STR: Description String
            Name (_SEG, Zero)  // _SEG: PCI Segment
            Name (_BBN, Zero)  // _BBN: BIOS Bus Number
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (MLKS, 0x04)
            Name (NUML, One)
            Name (MPAL, 0x0200)
            Name (MAPM, 0x03)
            Name (ASPM, Zero)
            Method (_INI, 0, Serialized)  // _INI: Initialize
            {
                Local0 = GETV (0x3D)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = One
                    }
                    Case (One)
                    {
                        Local1 = 0x02
                    }
                    Case (0x02)
                    {
                        Local1 = 0x03
                    }
                    Case (0x03)
                    {
                        Local1 = 0x04
                    }

                }

                If ((Local1 != Zero))
                {
                    MLKS = Local1
                }

                Local0 = GETV (0x42)
                Local1 = Zero
                Switch (ToInteger (Local0))
                {
                    Case (Zero)
                    {
                        Local1 = 0x80
                    }
                    Case (One)
                    {
                        Local1 = 0x0100
                    }
                    Case (0x02)
                    {
                        Local1 = 0x0200
                    }

                }

                If ((Local1 != Zero))
                {
                    MPAL = Local1
                }

                Local0 = GETV (0x47)
                MAPM = Local0
                Local0 = GETV (0x4C)
                ASPM = Local0
            }

            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x11))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A0D0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x0A060000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x20000000,         // Address Base
                    0x03000000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x30000000,         // Address Base
                    0x00100000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001CF,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001D0,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001D1,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001D2,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001D3,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E1,
                }
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x002F,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0030,             // Length
                    ,, )
                DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x00000000,         // Granularity
                    0x30100000,         // Range Minimum
                    0x301FFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00100000,         // Length
                    ,, , TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x30200000,         // Range Minimum
                    0x37FFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x07E00000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x0000000000000000, // Granularity
                    0x0000000800000000, // Range Minimum
                    0x0000000BFFFFFFFF, // Range Maximum
                    0x0000000000000000, // Translation Offset
                    0x0000000400000000, // Length
                    ,, , AddressRangeMemory, TypeStatic)
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_pcie_x1_0_rc", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI4", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0002
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x0F)
                {
                    Package (0x02)
                    {
                        "device_type", 
                        "pci"
                    }, 

                    Package (0x02)
                    {
                        "vendor-id", 
                        0x1F6C
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "bus-range", 
                        Package (0x02)
                        {
                            Zero, 
                            0x2F
                        }
                    }, 

                    Package (0x02)
                    {
                        "max-link-speed", 
                        MLKS
                    }, 

                    Package (0x02)
                    {
                        "num-lanes", 
                        NUML
                    }, 

                    Package (0x02)
                    {
                        "cdns,no-inbound-bar", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "sky1,pcie-ctrl-id", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "sky1,aer-uncor-panic", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pcie-phy", 
                        ^PCP2.PX10
                    }, 

                    Package (0x02)
                    {
                        "max-payload", 
                        MPAL
                    }, 

                    Package (0x02)
                    {
                        "max-aspm-support", 
                        MAPM
                    }, 

                    Package (0x02)
                    {
                        "aspm", 
                        ASPM
                    }, 

                    Package (0x02)
                    {
                        "reset-gpios", 
                        Package (0x04)
                        {
                            PRC4, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "vcc-pcie-supply", 
                        PVC3
                    }
                }
            })
            Name (_PRT, Package (0x04)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    Zero, 
                    0x01D4
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    Zero, 
                    0x01D5
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    Zero, 
                    0x01D6
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    Zero, 
                    0x01D7
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0xAE, 
                    "axi_clk", 
                    PRC4
                }, 

                Package (0x03)
                {
                    0xA5, 
                    "apb_clk", 
                    PRC4
                }, 

                Package (0x03)
                {
                    0xE0, 
                    "refclk_b", 
                    PRC4
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x31, 
                    PRC4, 
                    "pcie_reset"
                }
            })
            Name (DLKL, Package (0x02)
            {
                Package (0x03)
                {
                    PCP2, 
                    PRC4, 
                    Zero
                }, 

                Package (0x03)
                {
                    PVC3, 
                    PRC4, 
                    Zero
                }
            })
            Name (RSNL, Package (0x0A)
            {
                Package (0x04)
                {
                    PRC4, 
                    0x0200, 
                    Zero, 
                    "reg"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0200, 
                    One, 
                    "rcsu"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0200, 
                    0x02, 
                    "cfg"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0200, 
                    0x03, 
                    "msg"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0400, 
                    Zero, 
                    "aer_c"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0400, 
                    One, 
                    "aer_f"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0400, 
                    0x02, 
                    "aer_nf"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0400, 
                    0x03, 
                    "local"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0400, 
                    0x04, 
                    "phy_int"
                }, 

                Package (0x04)
                {
                    PRC4, 
                    0x0400, 
                    0x05, 
                    "phy_sta"
                }
            })
        }

        Device (PCP2)
        {
            Name (_HID, "CIXH2023")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x0F))
                {
                    Return (0x0F)
                }
                ElseIf (GETV (0x10))
                {
                    Return (0x0F)
                }
                ElseIf (GETV (0x11))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x0A0F0000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0xA9, 
                    "pclk", 
                    PCP2
                }, 

                Package (0x03)
                {
                    0xE4, 
                    "refclk", 
                    PCP2
                }
            })
            Device (PX10)
            {
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Return (0x0F)
                }

                Name (_ADR, Zero)  // _ADR: Address
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
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
                            "num-lanes", 
                            One
                        }
                    }
                })
            }

            Device (PX11)
            {
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Return (0x0F)
                }

                Name (_ADR, One)  // _ADR: Address
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
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
                            "num-lanes", 
                            One
                        }
                    }
                })
            }

            Device (PX2P)
            {
                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Return (0x0F)
                }

                Name (NUML, 0x02)
                Method (_INI, 0, Serialized)  // _INI: Initialize
                {
                    Local0 = GETV (0x36)
                    Local1 = Zero
                    Switch (ToInteger (Local0))
                    {
                        Case (Zero)
                        {
                            Local1 = One
                        }
                        Case (One)
                        {
                            Local1 = 0x02
                        }

                    }

                    If ((Local1 != Zero))
                    {
                        NUML = Local1
                    }
                }

                Name (_ADR, 0x02)  // _ADR: Address
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "reg", 
                            0x02
                        }, 

                        Package (0x02)
                        {
                            "num-lanes", 
                            NUML
                        }
                    }
                })
            }
        }

        Device (VPU0)
        {
            Name (_HID, "CIXH3010")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14230000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14240000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000166,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "power-domains", 
                        Package (0x02)
                        {
                            ^SCMI.DVFS, 
                            0x09
                        }
                    }, 

                    Package (0x02)
                    {
                        "power-domain-names", 
                        Package (0x01)
                        {
                            "perf"
                        }
                    }
                }
            })
            PowerResource (PPRS, 0x00, 0x0000)
            {
                OperationRegion (OPR0, SystemMemory, 0x1423021C, 0x04)
                Field (OPR0, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.VPU0.PPRS.MSK0 */
                    Local0 &= 0x1000
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.VPU0.PPRS.MSK0 */
                    Local0 = ((Local0 | 0x1000) | 0x0FFC)
                    MSK0 = Local0
                    DMRP (One, 0x08, 0x14230000, One)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.VPU0.PPRS.MSK0 */
                    Local0 &= 0xFFFFFFFFFFFFEFFF
                    MSK0 = Local0
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PPRS
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PPRS
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x43, 
                    "vpu_clk", 
                    VPU0
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x0E, 
                    VPU0, 
                    "vpu_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x8E, 
                    VPU0, 
                    "vpu_rcsu_reset"
                }
            })
            Device (CRE0)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Name (_STA, 0x0B)  // _STA: Status
                PowerResource (PRS0, 0x00, 0x0000)
                {
                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Return (Zero)
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        DMRP (One, 0x08, 0x14230000, 0x02)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                    }
                }

                Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
                {
                    PRS0
                })
                Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
                {
                    PRS0
                })
                Method (REPR, 0, Serialized)
                {
                    DMRP (One, 0x08, 0x14230000, 0x02)
                }
            }

            Device (CRE1)
            {
                Name (_ADR, One)  // _ADR: Address
                Name (_STA, 0x0B)  // _STA: Status
                PowerResource (PRS1, 0x00, 0x0000)
                {
                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Return (Zero)
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        DMRP (One, 0x08, 0x14230000, 0x04)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                    }
                }

                Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
                {
                    PRS1
                })
                Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
                {
                    PRS1
                })
                Method (REPR, 0, Serialized)
                {
                    DMRP (One, 0x08, 0x14230000, 0x04)
                }
            }

            Device (CRE2)
            {
                Name (_ADR, 0x02)  // _ADR: Address
                Name (_STA, 0x0B)  // _STA: Status
                PowerResource (PRS2, 0x00, 0x0000)
                {
                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Return (Zero)
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        DMRP (One, 0x08, 0x14230000, 0x08)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                    }
                }

                Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
                {
                    PRS2
                })
                Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
                {
                    PRS2
                })
                Method (REPR, 0, Serialized)
                {
                    DMRP (One, 0x08, 0x14230000, 0x08)
                }
            }

            Device (CRE3)
            {
                Name (_ADR, 0x03)  // _ADR: Address
                Name (_STA, 0x0B)  // _STA: Status
                PowerResource (PRS3, 0x00, 0x0000)
                {
                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Return (Zero)
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        DMRP (One, 0x08, 0x14230000, 0x10)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                    }
                }

                Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
                {
                    PRS3
                })
                Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
                {
                    PRS3
                })
                Method (REPR, 0, Serialized)
                {
                    DMRP (One, 0x08, 0x14230000, 0x10)
                }
            }
        }

        Device (VDP0)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU0, 
                            "pipepline0", 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
        }

        Device (VDP1)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU0, 
                            "pipepline1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
        }

        Device (VDP2)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU1, 
                            "pipepline0", 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
        }

        Device (VDP3)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU1, 
                            "pipepline1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
        }

        Device (VDP4)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU2, 
                            "pipeline@0", 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
        }

        Device (VDP5)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU2, 
                            "pipeline@1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
        }

        Device (VDP6)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU3, 
                            "pipepline0", 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
        }

        Device (VDP7)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU3, 
                            "pipepline1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
        }

        Device (VDP8)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x08)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU4, 
                            "pipepline0", 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
        }

        Device (VDP9)
        {
            Name (_HID, "CIXH503F")  // _HID: Hardware ID
            Name (_UID, 0x09)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                        Package (0x04)
                        {
                            DPU4, 
                            "pipepline1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
        }

        Device (DP00)
        {
            Name (_HID, "CIXH502F")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x23))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14064000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14068000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x1406FF00,         // Address Base
                    0x00000100,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14050000,         // Address Base
                    0x00000304,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000016C,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "dp_phy", 
                        ^UCP0.UDPP
                    }, 

                    Package (0x02)
                    {
                        "edp-panel", 
                        ""
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
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
                        Package (0x04)
                        {
                            DPU0, 
                            "pipeline@0", 
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
                        "endpoint@1", 
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
                        Package (0x04)
                        {
                            DPU0, 
                            "pipeline@1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x31, 
                    "vid_clk0", 
                    DP00
                }, 

                Package (0x03)
                {
                    0x32, 
                    "vid_clk1", 
                    DP00
                }, 

                Package (0x03)
                {
                    0x3B, 
                    "apb_clk", 
                    DP00
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x18, 
                    DP00, 
                    "dp_reset"
                }
            })
        }

        Device (DP01)
        {
            Name (_HID, "CIXH502F")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x24))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x140D4000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x140D8000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x140DFF00,         // Address Base
                    0x00000100,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x140C0000,         // Address Base
                    0x00000304,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000016D,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "dp_phy", 
                        ^UCP1.UDPP
                    }, 

                    Package (0x02)
                    {
                        "edp-panel", 
                        ""
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
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
                        Package (0x04)
                        {
                            DPU1, 
                            "pipeline@0", 
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
                        "endpoint@1", 
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
                        Package (0x04)
                        {
                            DPU1, 
                            "pipeline@1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x33, 
                    "vid_clk0", 
                    DP01
                }, 

                Package (0x03)
                {
                    0x34, 
                    "vid_clk1", 
                    DP01
                }, 

                Package (0x03)
                {
                    0x3C, 
                    "apb_clk", 
                    DP01
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x19, 
                    DP01, 
                    "dp_reset"
                }
            })
        }

        Device (DP02)
        {
            Name (_HID, "CIXH502F")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x25))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14144000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14148000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x1414C000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14130000,         // Address Base
                    0x00000320,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000016E,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "dp_phy", 
                        ""
                    }, 

                    Package (0x02)
                    {
                        "edp-panel", 
                        EDP0
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
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
                        Package (0x04)
                        {
                            DPU2, 
                            "pipeline@0", 
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
                        "endpoint@1", 
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
                        Package (0x04)
                        {
                            DPU2, 
                            "pipeline@1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x35, 
                    "vid_clk0", 
                    DP02
                }, 

                Package (0x03)
                {
                    0x36, 
                    "vid_clk1", 
                    DP02
                }, 

                Package (0x03)
                {
                    0x3D, 
                    "apb_clk", 
                    DP02
                }
            })
            Name (RSTL, Package (0x03)
            {
                Package (0x04)
                {
                    RST0, 
                    0x1A, 
                    DP02, 
                    "dp_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x1D, 
                    DP02, 
                    "phy_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x6B, 
                    DP02, 
                    "dp_rcsu_reset"
                }
            })
            Name (DLKL, Package (0x01)
            {
                Package (0x03)
                {
                    EDP0, 
                    DP02, 
                    Zero
                }
            })
        }

        Device (DP03)
        {
            Name (_HID, "CIXH502F")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x26))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x141B4000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x141B8000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x141BFF00,         // Address Base
                    0x00000100,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x141A0000,         // Address Base
                    0x00000304,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000016F,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "dp_phy", 
                        ^UCP2.UDPP
                    }, 

                    Package (0x02)
                    {
                        "edp-panel", 
                        ""
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
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
                        Package (0x04)
                        {
                            DPU3, 
                            "pipeline@0", 
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
                        "endpoint@1", 
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
                        Package (0x04)
                        {
                            DPU3, 
                            "pipeline@1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x37, 
                    "vid_clk0", 
                    DP03
                }, 

                Package (0x03)
                {
                    0x38, 
                    "vid_clk1", 
                    DP03
                }, 

                Package (0x03)
                {
                    0x3E, 
                    "apb_clk", 
                    DP03
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x1B, 
                    DP03, 
                    "dp_reset"
                }
            })
        }

        Device (DP04)
        {
            Name (_HID, "CIXH502F")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x27))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14224000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14228000,         // Address Base
                    0x00004000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x1422FF00,         // Address Base
                    0x00000100,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14210000,         // Address Base
                    0x00000304,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000170,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "dp_phy", 
                        ^UCP3.UDPP
                    }, 

                    Package (0x02)
                    {
                        "edp-panel", 
                        ""
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
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
                        Package (0x04)
                        {
                            DPU4, 
                            "pipeline@0", 
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
                        "endpoint@1", 
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
                        Package (0x04)
                        {
                            DPU4, 
                            "pipeline@1", 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x39, 
                    "vid_clk0", 
                    DP04
                }, 

                Package (0x03)
                {
                    0x3A, 
                    "vid_clk1", 
                    DP04
                }, 

                Package (0x03)
                {
                    0x3F, 
                    "apb_clk", 
                    DP04
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x1C, 
                    DP04, 
                    "dp_reset"
                }
            })
        }

        Device (DPU0)
        {
            Name (_HID, "CIXH5010")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x23))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14010000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x0000015C,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "aclk_freq_fixed", 
                        0x2FAF0800
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "pipeline@0", 
                        "PIP0"
                    }, 

                    Package (0x02)
                    {
                        "pipeline@1", 
                        "PIP1"
                    }
                }
            })
            Name (PIP0, Package (0x04)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x10)
                {
                    Package (0x02)
                    {
                        "reg", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_aoutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_boutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ben", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_arqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_outstdcapb", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_awqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_l0_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l1_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l2_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l3_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_lw_arcache", 
                        0x03
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                            DP00, 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
            Name (PIP1, Package (0x04)
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
                        "port@1", 
                        "PRT1"
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
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "endpoint@1", 
                        "EP10"
                    }
                }
            })
            Name (EP10, Package (0x02)
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
                            DP00, 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            PowerResource (PRS0, 0x00, 0x0000)
            {
                OperationRegion (OPR0, SystemMemory, 0x14000210, 0x04)
                Field (OPR0, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.DPU0.PRS0.MSK0 */
                    Local0 &= 0x02
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.DPU0.PRS0.MSK0 */
                    Local0 = ((Local0 | 0x02) | 0x0FFC)
                    MSK0 = Local0
                    DMRP (One, 0x03, 0x14000000, One)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.DPU0.PRS0.MSK0 */
                    Local0 &= 0xFFFFFFFFFFFFFFFD
                    MSK0 = Local0
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PRS0
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PRS0
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x2C, 
                    "aclk", 
                    DPU0
                }, 

                Package (0x03)
                {
                    0x21, 
                    "pipeline@0", 
                    DPU0
                }, 

                Package (0x03)
                {
                    0x22, 
                    "pipeline@1", 
                    DPU0
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x6E, 
                    DPU0, 
                    "rcsu_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x13, 
                    DPU0, 
                    "ip_reset"
                }
            })
        }

        Device (DPU1)
        {
            Name (_HID, "CIXH5010")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x24))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14080000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x0000015E,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "aclk_freq_fixed", 
                        0x2FAF0800
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        One
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "pipeline@0", 
                        "PIP0"
                    }, 

                    Package (0x02)
                    {
                        "pipeline@1", 
                        "PIP1"
                    }
                }
            })
            Name (PIP0, Package (0x04)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x10)
                {
                    Package (0x02)
                    {
                        "reg", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_aoutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_boutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ben", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_arqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_outstdcapb", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_awqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_l0_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l1_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l2_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l3_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_lw_arcache", 
                        0x03
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                            DP01, 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
            Name (PIP1, Package (0x04)
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
                        "port@1", 
                        "PRT1"
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
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "endpoint@1", 
                        "EP10"
                    }
                }
            })
            Name (EP10, Package (0x02)
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
                            DP01, 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            PowerResource (PRS1, 0x00, 0x0000)
            {
                OperationRegion (OPR1, SystemMemory, 0x14070210, 0x04)
                Field (OPR1, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.DPU1.PRS1.MSK0 */
                    Local0 &= 0x02
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.DPU1.PRS1.MSK0 */
                    Local0 = ((Local0 | 0x02) | 0x0FFC)
                    MSK0 = Local0
                    DMRP (One, 0x03, 0x14000000, 0x02)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.DPU1.PRS1.MSK0 */
                    Local0 &= 0xFFFFFFFFFFFFFFFD
                    MSK0 = Local0
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PRS1
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PRS1
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x2D, 
                    "aclk", 
                    DPU1
                }, 

                Package (0x03)
                {
                    0x23, 
                    "pipeline@0", 
                    DPU1
                }, 

                Package (0x03)
                {
                    0x24, 
                    "pipeline@1", 
                    DPU1
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x6F, 
                    DPU1, 
                    "rcsu_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x14, 
                    DPU1, 
                    "ip_reset"
                }
            })
        }

        Device (DPU2)
        {
            Name (_HID, "CIXH5010")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x25))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x140F0000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000160,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "aclk_freq_fixed", 
                        0x2FAF0800
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        0x02
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "pipeline@0", 
                        "PIP0"
                    }, 

                    Package (0x02)
                    {
                        "pipeline@1", 
                        "PIP1"
                    }
                }
            })
            Name (PIP0, Package (0x04)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x10)
                {
                    Package (0x02)
                    {
                        "reg", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_aoutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_boutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ben", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_arqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_outstdcapb", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_awqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_l0_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l1_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l2_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l3_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_lw_arcache", 
                        0x03
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                            DP02, 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
            Name (PIP1, Package (0x04)
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
                        "port@1", 
                        "PRT1"
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
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "endpoint@1", 
                        "EP10"
                    }
                }
            })
            Name (EP10, Package (0x02)
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
                            DP02, 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            PowerResource (PRS2, 0x00, 0x0000)
            {
                OperationRegion (OPR2, SystemMemory, 0x140E0210, 0x04)
                Field (OPR2, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.DPU2.PRS2.MSK0 */
                    Local1 = MSK0 /* \_SB_.DPU2.PRS2.MSK0 */
                    Local0 &= 0x02
                    Debug = Concatenate (Concatenate (Concatenate (Concatenate ("CIX Debug: DPU2 get current state=", Local0), ":"), Local1
                        ), "\n")
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.DPU2.PRS2.MSK0 */
                    Debug = Concatenate (Concatenate ("CIX Debug: DPU2 power on, mask1=", Local0), "\n")
                    Local0 = ((Local0 | 0x02) | 0x0FFC)
                    MSK0 = Local0
                    Debug = Concatenate (Concatenate ("CIX Debug: DPU2 power on, mask2=", MSK0), "\n")
                    DMRP (One, 0x03, 0x14000000, 0x04)
                    Debug = "CIX Debug: Call do_mem_repair end.\n"
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.DPU2.PRS2.MSK0 */
                    Debug = Concatenate (Concatenate ("CIX Debug: DPU2 power off, mask1=", Local0), "\n")
                    Local0 &= 0xFFFFFFFFFFFFFFFD
                    MSK0 = Local0
                    Debug = Concatenate (Concatenate ("CIX Debug: DPU2 power off, mask2=", MSK0), "\n")
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PRS2
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PRS2
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x2E, 
                    "aclk", 
                    DPU2
                }, 

                Package (0x03)
                {
                    0x25, 
                    "pipeline@0", 
                    DPU2
                }, 

                Package (0x03)
                {
                    0x26, 
                    "pipeline@1", 
                    DPU2
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x70, 
                    DPU2, 
                    "rcsu_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x15, 
                    DPU2, 
                    "ip_reset"
                }
            })
        }

        Device (DPU3)
        {
            Name (_HID, "CIXH5010")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x26))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14160000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000162,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "aclk_freq_fixed", 
                        0x2FAF0800
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        0x03
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "pipeline@0", 
                        "PIP0"
                    }, 

                    Package (0x02)
                    {
                        "pipeline@1", 
                        "PIP1"
                    }
                }
            })
            Name (PIP0, Package (0x04)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x10)
                {
                    Package (0x02)
                    {
                        "reg", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_aoutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_boutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ben", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_arqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_outstdcapb", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_awqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_l0_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l1_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l2_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l3_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_lw_arcache", 
                        0x03
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                            DP03, 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
            Name (PIP1, Package (0x04)
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
                        "port@1", 
                        "PRT1"
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
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "endpoint@1", 
                        "EP10"
                    }
                }
            })
            Name (EP10, Package (0x02)
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
                            DP03, 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            PowerResource (PRS3, 0x00, 0x0000)
            {
                OperationRegion (OPR3, SystemMemory, 0x14150210, 0x04)
                Field (OPR3, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.DPU3.PRS3.MSK0 */
                    Local0 &= 0x02
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.DPU3.PRS3.MSK0 */
                    Local0 = ((Local0 | 0x02) | 0x0FFC)
                    MSK0 = Local0
                    DMRP (One, 0x03, 0x14000000, 0x08)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.DPU3.PRS3.MSK0 */
                    Local0 &= 0xFFFFFFFFFFFFFFFD
                    MSK0 = Local0
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PRS3
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PRS3
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x2F, 
                    "aclk", 
                    DPU3
                }, 

                Package (0x03)
                {
                    0x27, 
                    "pipeline@0", 
                    DPU3
                }, 

                Package (0x03)
                {
                    0x28, 
                    "pipeline@1", 
                    DPU3
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x71, 
                    DPU3, 
                    "rcsu_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x16, 
                    DPU3, 
                    "ip_reset"
                }
            })
        }

        Device (DPU4)
        {
            Name (_HID, "CIXH5010")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x27))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x141D0000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000164,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "aclk_freq_fixed", 
                        0x2FAF0800
                    }, 

                    Package (0x02)
                    {
                        "enabled_by_gop", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "device-id", 
                        0x04
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "pipeline@0", 
                        "PIP0"
                    }, 

                    Package (0x02)
                    {
                        "pipeline@1", 
                        "PIP1"
                    }
                }
            })
            Name (PIP0, Package (0x04)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x10)
                {
                    Package (0x02)
                    {
                        "reg", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_aoutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_boutstdcapb", 
                        0x20
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ben", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_arqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_raxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_outstdcapb", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_burstlen", 
                        0x10
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_awqos", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "lpu_waxi_ord", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "lpu_l0_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l1_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l2_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_l3_arcache", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "lpu_lw_arcache", 
                        0x03
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                            DP04, 
                            "port@0", 
                            "endpoint@0"
                        }
                    }
                }
            })
            Name (PIP1, Package (0x04)
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
                        "port@1", 
                        "PRT1"
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
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "endpoint@1", 
                        "EP10"
                    }
                }
            })
            Name (EP10, Package (0x02)
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
                            DP04, 
                            "port@1", 
                            "endpoint@1"
                        }
                    }
                }
            })
            PowerResource (PRS4, 0x00, 0x0000)
            {
                OperationRegion (OPR4, SystemMemory, 0x141C0210, 0x04)
                Field (OPR4, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.DPU4.PRS4.MSK0 */
                    Local0 &= 0x02
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.DPU4.PRS4.MSK0 */
                    Local0 = ((Local0 | 0x02) | 0x0FFC)
                    MSK0 = Local0
                    DMRP (One, 0x03, 0x14000000, 0x10)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.DPU4.PRS4.MSK0 */
                    Local0 &= 0xFFFFFFFFFFFFFFFD
                    MSK0 = Local0
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PRS4
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PRS4
            })
            Name (CLKT, Package (0x03)
            {
                Package (0x03)
                {
                    0x30, 
                    "aclk", 
                    DPU4
                }, 

                Package (0x03)
                {
                    0x29, 
                    "pipeline@0", 
                    DPU4
                }, 

                Package (0x03)
                {
                    0x2A, 
                    "pipeline@1", 
                    DPU4
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x72, 
                    DPU4, 
                    "rcsu_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x17, 
                    DPU4, 
                    "ip_reset"
                }
            })
        }

        Device (AEU0)
        {
            Name (_HID, "CIXH5011")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Return (Zero)
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14030000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000015D,
                }
            })
        }

        Device (AEU1)
        {
            Name (_HID, "CIXH5011")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Return (Zero)
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x140A0000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000015F,
                }
            })
        }

        Device (AEU2)
        {
            Name (_HID, "CIXH5011")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Return (Zero)
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14110000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000161,
                }
            })
        }

        Device (AEU3)
        {
            Name (_HID, "CIXH5011")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Return (Zero)
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14180000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000163,
                }
            })
        }

        Device (AEU4)
        {
            Name (_HID, "CIXH5011")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Return (Zero)
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x141F0000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000165,
                }
            })
        }

        Device (DPBL)
        {
            Name (_HID, "CIXH5041")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI3", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x000F
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "enable-gpios", 
                        Package (0x04)
                        {
                            DPBL, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "pwms", 
                        Package (0x03)
                        {
                            PWM0, 
                            Zero, 
                            0x000186A0
                        }
                    }, 

                    Package (0x02)
                    {
                        "default-brightness-level", 
                        0xC8
                    }, 

                    Package (0x02)
                    {
                        "brightness-levels", 
                        Package (0xFF)
                        {
                            Zero, 
                            One, 
                            0x02, 
                            0x03, 
                            0x04, 
                            0x05, 
                            0x06, 
                            0x07, 
                            0x08, 
                            0x09, 
                            0x0A, 
                            0x0B, 
                            0x0C, 
                            0x0D, 
                            0x0E, 
                            0x0F, 
                            0x10, 
                            0x11, 
                            0x12, 
                            0x13, 
                            0x14, 
                            0x15, 
                            0x16, 
                            0x17, 
                            0x18, 
                            0x19, 
                            0x1A, 
                            0x1B, 
                            0x1C, 
                            0x1D, 
                            0x1E, 
                            0x1F, 
                            0x20, 
                            0x21, 
                            0x22, 
                            0x23, 
                            0x24, 
                            0x25, 
                            0x26, 
                            0x27, 
                            0x28, 
                            0x29, 
                            0x2A, 
                            0x2B, 
                            0x2C, 
                            0x2D, 
                            0x2E, 
                            0x2F, 
                            0x30, 
                            0x31, 
                            0x32, 
                            0x33, 
                            0x34, 
                            0x35, 
                            0x36, 
                            0x37, 
                            0x38, 
                            0x39, 
                            0x3A, 
                            0x3B, 
                            0x3C, 
                            0x3D, 
                            0x3E, 
                            0x3F, 
                            0x40, 
                            0x41, 
                            0x42, 
                            0x43, 
                            0x44, 
                            0x45, 
                            0x46, 
                            0x47, 
                            0x48, 
                            0x49, 
                            0x4A, 
                            0x4B, 
                            0x4C, 
                            0x4D, 
                            0x4E, 
                            0x4F, 
                            0x50, 
                            0x51, 
                            0x52, 
                            0x53, 
                            0x54, 
                            0x55, 
                            0x56, 
                            0x57, 
                            0x58, 
                            0x59, 
                            0x5A, 
                            0x5B, 
                            0x5C, 
                            0x5D, 
                            0x5E, 
                            0x5F, 
                            0x60, 
                            0x61, 
                            0x62, 
                            0x63, 
                            0x64, 
                            0x65, 
                            0x66, 
                            0x67, 
                            0x68, 
                            0x69, 
                            0x6A, 
                            0x6B, 
                            0x6C, 
                            0x6D, 
                            0x6E, 
                            0x6F, 
                            0x70, 
                            0x71, 
                            0x72, 
                            0x73, 
                            0x74, 
                            0x75, 
                            0x76, 
                            0x77, 
                            0x78, 
                            0x79, 
                            0x7A, 
                            0x7B, 
                            0x7C, 
                            0x7D, 
                            0x7E, 
                            0x7F, 
                            0x80, 
                            0x81, 
                            0x82, 
                            0x83, 
                            0x84, 
                            0x85, 
                            0x86, 
                            0x87, 
                            0x88, 
                            0x89, 
                            0x8A, 
                            0x8B, 
                            0x8C, 
                            0x8D, 
                            0x8E, 
                            0x8F, 
                            0x90, 
                            0x91, 
                            0x92, 
                            0x93, 
                            0x94, 
                            0x95, 
                            0x96, 
                            0x97, 
                            0x98, 
                            0x99, 
                            0x9A, 
                            0x9B, 
                            0x9C, 
                            0x9D, 
                            0x9E, 
                            0x9F, 
                            0xA0, 
                            0xA1, 
                            0xA2, 
                            0xA3, 
                            0xA4, 
                            0xA5, 
                            0xA6, 
                            0xA7, 
                            0xA8, 
                            0xA9, 
                            0xAA, 
                            0xAB, 
                            0xAC, 
                            0xAD, 
                            0xAE, 
                            0xAF, 
                            0xB0, 
                            0xB1, 
                            0xB2, 
                            0xB3, 
                            0xB4, 
                            0xB5, 
                            0xB6, 
                            0xB7, 
                            0xB8, 
                            0xB9, 
                            0xBA, 
                            0xBB, 
                            0xBC, 
                            0xBD, 
                            0xBE, 
                            0xBF, 
                            0xC0, 
                            0xC1, 
                            0xC2, 
                            0xC3, 
                            0xC4, 
                            0xC5, 
                            0xC6, 
                            0xC7, 
                            0xC8, 
                            0xC9, 
                            0xCA, 
                            0xCB, 
                            0xCC, 
                            0xCD, 
                            0xCE, 
                            0xCF, 
                            0xD0, 
                            0xD1, 
                            0xD2, 
                            0xD3, 
                            0xD4, 
                            0xD5, 
                            0xD6, 
                            0xD7, 
                            0xD8, 
                            0xD9, 
                            0xDA, 
                            0xDB, 
                            0xDC, 
                            0xDD, 
                            0xDE, 
                            0xDF, 
                            0xE0, 
                            0xE1, 
                            0xE2, 
                            0xE3, 
                            0xE4, 
                            0xE5, 
                            0xE6, 
                            0xE7, 
                            0xE8, 
                            0xE9, 
                            0xEA, 
                            0xEB, 
                            0xEC, 
                            0xED, 
                            0xEE, 
                            0xEF, 
                            0xF0, 
                            0xF1, 
                            0xF2, 
                            0xF3, 
                            0xF4, 
                            0xF5, 
                            0xF6, 
                            0xF7, 
                            0xF8, 
                            0xF9, 
                            0xFA, 
                            0xFB, 
                            0xFC, 
                            0xFD, 
                            0xFE
                        }
                    }
                }
            })
            Name (DLKL, Package (0x01)
            {
                Package (0x03)
                {
                    PWM0, 
                    DPBL, 
                    Zero
                }
            })
        }

        Device (EDP0)
        {
            Name (_HID, "CIXH5040")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_edp0", ResourceConsumer, ,)
                GpioIo (Exclusive, PullNone, 0x0000, 0x0000, IoRestrictionOutputOnly,
                    "\\_SB.GPI3", 0x00, ResourceConsumer, ,
                    )
                    {   // Pin list
                        0x0010
                    }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "prepare-delay-ms", 
                        0x78
                    }, 

                    Package (0x02)
                    {
                        "enable-delay-ms", 
                        0x78
                    }, 

                    Package (0x02)
                    {
                        "unprepare-delay-ms", 
                        0x01F4
                    }, 

                    Package (0x02)
                    {
                        "disable-delay-ms", 
                        0x78
                    }, 

                    Package (0x02)
                    {
                        "width-mm", 
                        0x81
                    }, 

                    Package (0x02)
                    {
                        "height-mm", 
                        0xAB
                    }, 

                    Package (0x02)
                    {
                        "enable-gpios", 
                        Package (0x04)
                        {
                            EDP0, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "backlight", 
                        DPBL
                    }
                }
            })
            Name (DLKL, Package (0x01)
            {
                Package (0x03)
                {
                    DPBL, 
                    EDP0, 
                    Zero
                }
            })
        }

        Device (CGFX)
        {
            Name (_HID, "CIXH5050")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (_DEP, Package (0x06)  // _DEP: Dependencies
            {
                PEP0, 
                DP00, 
                DP01, 
                DP02, 
                DP03, 
                DP04
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14010000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14080000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x140F0000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14160000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x141D0000,         // Address Base
                    0x00020000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x0000015C,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x0000015E,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000160,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000162,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000164,
                }
            })
        }

        Device (PMA)
        {
            Name (_HID, "CIXHA012")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0xBCE00000,         // Address Base
                    0x01000000,         // Address Length
                    )
            })
        }

        Device (PMGM)
        {
            Name (_HID, "CIXHA013")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x03)  // _STA: Status
        }

        Device (GPUP)
        {
            Name (_HID, "CIXH5001")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            PowerResource (PPRS, 0x00, 0x0000)
            {
                OperationRegion (OPR0, SystemMemory, 0x15000218, 0x04)
                Field (OPR0, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.GPUP.PPRS.MSK0 */
                    Local0 &= 0x1000
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.GPUP.PPRS.MSK0 */
                    Local0 = ((Local0 | 0x1000) | 0x0FFC)
                    MSK0 = Local0
                    Stall (0x05)
                    DMRP (One, 0x04, 0x15000000, One)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.GPUP.PPRS.MSK0 */
                    Local0 &= 0xFFFFFFFFFFFFEFFF
                    MSK0 = Local0
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PPRS
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PPRS
            })
        }

        Device (GPU)
        {
            Name (_HID, "CIXH5000")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, One)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x15000000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x15010000,         // Address Base
                    0x00480000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000010D,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000010E,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x0000010F,
                }
            })
            Name (_DSD, Package (0x04)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "protected-memory-allocator", 
                        PMA
                    }, 

                    Package (0x02)
                    {
                        "physical-memory-group-manager", 
                        PMGM
                    }, 

                    Package (0x02)
                    {
                        "power-domains", 
                        Package (0x02)
                        {
                            ^SCMI.DVFS, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "power-domain-names", 
                        Package (0x01)
                        {
                            "perf"
                        }
                    }, 

                    Package (0x02)
                    {
                        "gpu-microvolt", 
                        Package (0x01)
                        {
                            0x000C8320
                        }
                    }, 

                    Package (0x02)
                    {
                        "tzgt", 
                        TZGT
                    }, 

                    Package (0x02)
                    {
                        "power-supply", 
                        GPUP
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "pbha", 
                        "IIOR"
                    }, 

                    Package (0x02)
                    {
                        "power_model", 
                        "PWRM"
                    }
                }
            })
            Name (IIOR, Package (0x02)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "int_id_override", 
                        Package (0x12)
                        {
                            0x02, 
                            0x23, 
                            0x04, 
                            0x23, 
                            0x10, 
                            0x22, 
                            0x11, 
                            0x32, 
                            0x12, 
                            0x52, 
                            0x15, 
                            0x32, 
                            0x16, 
                            0x52, 
                            0x18, 
                            0x22, 
                            0x1C, 
                            0x32
                        }
                    }
                }
            })
            Name (PWRM, Package (0x02)
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "static-coefficient", 
                        "2427750"
                    }, 

                    Package (0x02)
                    {
                        "dynamic-coefficient", 
                        "4687"
                    }, 

                    Package (0x02)
                    {
                        "ts", 
                        Package (0x04)
                        {
                            "20000", 
                            "2000", 
                            "-20", 
                            "2"
                        }
                    }, 

                    Package (0x02)
                    {
                        "thermal-zone", 
                        "tzgt"
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x1F, 
                    "gpu_clk_core", 
                    GPU
                }, 

                Package (0x03)
                {
                    0x20, 
                    "gpu_clk_stacks", 
                    GPU
                }, 

                Package (0x03)
                {
                    0x0110, 
                    "gpu_clk_200M", 
                    GPU
                }, 

                Package (0x03)
                {
                    0x1E, 
                    "gpu_clk_400M", 
                    GPU
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x09, 
                    GPU, 
                    "gpu_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x77, 
                    GPU, 
                    "gpu_rcsu_reset"
                }
            })
        }

        Device (NPU0)
        {
            Name (_HID, "CIXH4000")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                Local0 = GETV (0x22)
                DerefOf (DerefOf (_DSD [One]) [0x02]) [One]
                     = Local0
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14260000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000167,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "cluster-partition", 
                        Package (0x02)
                        {
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "gm-policy", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "core_mask", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "power-domains", 
                        Package (0x02)
                        {
                            ^SCMI.DVFS, 
                            0x08
                        }
                    }, 

                    Package (0x02)
                    {
                        "power-domain-names", 
                        Package (0x01)
                        {
                            "perf"
                        }
                    }
                }
            })
            PowerResource (PPRS, 0x00, 0x0000)
            {
                OperationRegion (OPRT, SystemMemory, 0x1425020C, 0x04)
                Field (OPRT, DWordAcc, NoLock, Preserve)
                {
                    TMSK,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = TMSK /* \_SB_.NPU0.PPRS.TMSK */
                    Local0 &= One
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = TMSK /* \_SB_.NPU0.PPRS.TMSK */
                    Local0 = ((Local0 | One) | 0x0FFC)
                    TMSK = Local0
                    DMRP (One, 0x05, 0x14250000, One)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    TGSP (0x2F, 0x4E20)
                    Local0 = TMSK /* \_SB_.NPU0.PPRS.TMSK */
                    Local0 &= 0xFFFFFFFFFFFFFFFE
                    TMSK = Local0
                    RLSP (0x2F)
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PPRS
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PPRS
            })
            Device (CRE0)
            {
                Name (_HID, "CIXH4010")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_STA, 0x0B)  // _STA: Status
                PowerResource (PRS0, 0x00, 0x0000)
                {
                    OperationRegion (OPR0, SystemMemory, 0x14250200, 0x04)
                    Field (OPR0, DWordAcc, NoLock, Preserve)
                    {
                        MSK0,   32
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Local0 = MSK0 /* \_SB_.NPU0.CRE0.PRS0.MSK0 */
                        Local0 &= One
                        If ((Local0 > Zero))
                        {
                            Return (One)
                        }
                        Else
                        {
                            Return (Zero)
                        }
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        Local0 = MSK0 /* \_SB_.NPU0.CRE0.PRS0.MSK0 */
                        Local0 = ((Local0 | One) | 0x0FFC)
                        MSK0 = Local0
                        DMRP (One, 0x05, 0x14250000, 0x02)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                        TGSP (0x2F, 0x4E20)
                        Local0 = MSK0 /* \_SB_.NPU0.CRE0.PRS0.MSK0 */
                        Local0 &= 0xFFFFFFFFFFFFFFFE
                        MSK0 = Local0
                        RLSP (0x2F)
                    }
                }

                Name (_PR0, Package (0x02)  // _PR0: Power Resources for D0
                {
                    PPRS, 
                    PRS0
                })
                Name (_PR3, Package (0x02)  // _PR3: Power Resources for D3hot
                {
                    PPRS, 
                    PRS0
                })
            }

            Device (CRE1)
            {
                Name (_HID, "CIXH4010")  // _HID: Hardware ID
                Name (_UID, One)  // _UID: Unique ID
                Name (_STA, 0x0B)  // _STA: Status
                PowerResource (PRS1, 0x00, 0x0000)
                {
                    OperationRegion (OPR1, SystemMemory, 0x14250204, 0x04)
                    Field (OPR1, DWordAcc, NoLock, Preserve)
                    {
                        MSK1,   32
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Local0 = MSK1 /* \_SB_.NPU0.CRE1.PRS1.MSK1 */
                        Local0 &= One
                        If ((Local0 > Zero))
                        {
                            Return (One)
                        }
                        Else
                        {
                            Return (Zero)
                        }
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        Local0 = MSK1 /* \_SB_.NPU0.CRE1.PRS1.MSK1 */
                        Local0 = ((Local0 | One) | 0x0FFC)
                        MSK1 = Local0
                        DMRP (One, 0x05, 0x14250000, 0x04)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                        TGSP (0x2F, 0x4E20)
                        Local0 = MSK1 /* \_SB_.NPU0.CRE1.PRS1.MSK1 */
                        Local0 &= 0xFFFFFFFFFFFFFFFE
                        MSK1 = Local0
                        RLSP (0x2F)
                    }
                }

                Name (_PR0, Package (0x02)  // _PR0: Power Resources for D0
                {
                    PPRS, 
                    PRS1
                })
                Name (_PR3, Package (0x02)  // _PR3: Power Resources for D3hot
                {
                    PPRS, 
                    PRS1
                })
            }

            Device (CRE2)
            {
                Name (_HID, "CIXH4010")  // _HID: Hardware ID
                Name (_UID, 0x02)  // _UID: Unique ID
                Name (_STA, 0x0B)  // _STA: Status
                PowerResource (PRS2, 0x00, 0x0000)
                {
                    OperationRegion (OPR2, SystemMemory, 0x14250208, 0x04)
                    Field (OPR2, DWordAcc, NoLock, Preserve)
                    {
                        MSK2,   32
                    }

                    Method (_STA, 0, Serialized)  // _STA: Status
                    {
                        Local0 = MSK2 /* \_SB_.NPU0.CRE2.PRS2.MSK2 */
                        Local0 &= One
                        If ((Local0 > Zero))
                        {
                            Return (One)
                        }
                        Else
                        {
                            Return (Zero)
                        }
                    }

                    Method (_ON, 0, Serialized)  // _ON_: Power On
                    {
                        Local0 = MSK2 /* \_SB_.NPU0.CRE2.PRS2.MSK2 */
                        Local0 = ((Local0 | One) | 0x0FFC)
                        MSK2 = Local0
                        DMRP (One, 0x05, 0x14250000, 0x08)
                    }

                    Method (_OFF, 0, Serialized)  // _OFF: Power Off
                    {
                        TGSP (0x2F, 0x4E20)
                        Local0 = MSK2 /* \_SB_.NPU0.CRE2.PRS2.MSK2 */
                        Local0 &= 0xFFFFFFFFFFFFFFFE
                        MSK2 = Local0
                        RLSP (0x2F)
                    }
                }

                Name (_PR0, Package (0x02)  // _PR0: Power Resources for D0
                {
                    PPRS, 
                    PRS2
                })
                Name (_PR3, Package (0x02)  // _PR3: Power Resources for D3hot
                {
                    PPRS, 
                    PRS2
                })
            }
        }

        Device (I2S0)
        {
            Name (_HID, "CIXH6010")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07020000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000FB,
                }
                FixedDMA (0x0020, 0x00FF, Width32bit, )
                FixedDMA (0x0021, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s0", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "id", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x02)
                        {
                            "tx", 
                            "rx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,mclk-idx", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S0
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S0
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    Zero, 
                    I2S0, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S0, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S0, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S0, 
                    Zero
                }
            })
        }

        Device (I2S1)
        {
            Name (_HID, "CIXH6010")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07030000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000FC,
                }
                FixedDMA (0x0022, 0x00FF, Width32bit, )
                FixedDMA (0x0023, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s1", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x02)
                        {
                            "tx", 
                            "rx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S1
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S1
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    One, 
                    I2S1, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S1, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S1, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S1, 
                    Zero
                }
            })
        }

        Device (I2S2)
        {
            Name (_HID, "CIXH6010")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07040000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000FD,
                }
                FixedDMA (0x0024, 0x00FF, Width32bit, )
                FixedDMA (0x0025, 0x00FF, Width32bit, )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x03)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x02
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "rx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S2
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S2
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x02, 
                    I2S2, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S2, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S2, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S2, 
                    Zero
                }
            })
        }

        Device (I2S3)
        {
            Name (_HID, "CIXH6011")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07050000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000FE,
                }
                FixedDMA (0x0026, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s2", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x06)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "tx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-out-num", 
                        0x06
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-rx-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-tx-mask", 
                        0x3C
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S3
                }, 

                Package (0x03)
                {
                    0x4D, 
                    "audio_clk1", 
                    I2S3
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S3
                }, 

                Package (0x03)
                {
                    0x4F, 
                    "audio_clk3", 
                    I2S3
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x03, 
                    I2S3, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S3, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S3, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S3, 
                    Zero
                }
            })
        }

        Device (I2S4)
        {
            Name (_HID, "CIXH6011")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07060000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000000FF,
                }
                FixedDMA (0x0029, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s3", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x06)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "rx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-out-num", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-rx-mask", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-tx-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S4
                }, 

                Package (0x03)
                {
                    0x4D, 
                    "audio_clk1", 
                    I2S4
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S4
                }, 

                Package (0x03)
                {
                    0x4F, 
                    "audio_clk3", 
                    I2S4
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x04, 
                    I2S4, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S4, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S4, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S4, 
                    Zero
                }
            })
        }

        Device (I2S5)
        {
            Name (_HID, "CIXH6011")  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((One && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07070000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000100,
                }
                FixedDMA (0x002A, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s5_dbg", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x05
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "tx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-out-num", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-rx-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-tx-mask", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }, 

                    Package (0x02)
                    {
                        "dp_pair_id", 
                        Zero
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S5
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S5
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x05, 
                    I2S5, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S5, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S5, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S5, 
                    Zero
                }
            })
        }

        Device (I2S6)
        {
            Name (_HID, "CIXH6011")  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((One && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07080000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000101,
                }
                FixedDMA (0x002C, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s6_dbg", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x06
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "tx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-out-num", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-rx-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-tx-mask", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }, 

                    Package (0x02)
                    {
                        "dp_pair_id", 
                        One
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S6
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S6
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x06, 
                    I2S6, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S6, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S6, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S6, 
                    Zero
                }
            })
        }

        Device (I2S7)
        {
            Name (_HID, "CIXH6011")  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x07090000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000102,
                }
                FixedDMA (0x002E, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s7_dbg", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "tx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-out-num", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-rx-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-tx-mask", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }, 

                    Package (0x02)
                    {
                        "dp_pair_id", 
                        0x02
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S7
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S7
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x07, 
                    I2S7, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S7, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S7, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S7, 
                    Zero
                }
            })
        }

        Device (I2S8)
        {
            Name (_HID, "CIXH6011")  // _HID: Hardware ID
            Name (_UID, 0x08)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((Zero && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x070A0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000103,
                }
                FixedDMA (0x0030, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s8_dbg", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x08
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "tx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-out-num", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-rx-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-tx-mask", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }, 

                    Package (0x02)
                    {
                        "dp_pair_id", 
                        0x03
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S8
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S8
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x08, 
                    I2S8, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S8, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S8, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S8, 
                    Zero
                }
            })
        }

        Device (I2S9)
        {
            Name (_HID, "CIXH6011")  // _HID: Hardware ID
            Name (_UID, 0x09)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((One && GETV (0x28)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x070B0000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000104,
                }
                FixedDMA (0x0032, 0x00FF, Width32bit, )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX0", 0x00,
                    "pinctrl_substrate_i2s9_dbg", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x09
                    }, 

                    Package (0x02)
                    {
                        "dma-names", 
                        Package (0x01)
                        {
                            "tx"
                        }
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-out-num", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-rx-mask", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cdns,pin-tx-mask", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "cdns,cru-ctrl", 
                        ACRU
                    }, 

                    Package (0x02)
                    {
                        "dp_pair_id", 
                        0x04
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x4C, 
                    "audio_clk0", 
                    I2S9
                }, 

                Package (0x03)
                {
                    0x4E, 
                    "audio_clk2", 
                    I2S9
                }
            })
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    ^ADSS.ARST, 
                    0x09, 
                    I2S9, 
                    "i2s"
                }
            })
            Name (DLKL, Package (0x03)
            {
                Package (0x03)
                {
                    ^ADSS.ACLK, 
                    I2S9, 
                    Zero
                }, 

                Package (0x03)
                {
                    ^ADSS.ARST, 
                    I2S9, 
                    Zero
                }, 

                Package (0x03)
                {
                    DMA1, 
                    I2S9, 
                    Zero
                }
            })
        }

        Device (XHC0)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((GETV (0x12) && (GETV (0x1C) == Zero)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x09018000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000126,
                    }
                })
                Return (RBUF) /* \_SB_.XHC0._CRS.RBUF */
            }
        }

        Device (XHC1)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x13))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x09088000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x0000012C,
                    }
                })
                Return (RBUF) /* \_SB_.XHC1._CRS.RBUF */
            }
        }

        Device (XHC2)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x16))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x090F8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000132,
                    }
                })
                Return (RBUF) /* \_SB_.XHC2._CRS.RBUF */
            }
        }

        Device (XHC3)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x15))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x09168000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000138,
                    }
                })
                Return (RBUF) /* \_SB_.XHC3._CRS.RBUF */
            }
        }

        Device (XHC4)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((GETV (0x17) && (GETV (0x1D) == Zero)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x091D8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x0000011C,
                    }
                })
                Return (RBUF) /* \_SB_.XHC4._CRS.RBUF */
            }
        }

        Device (XHC5)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((GETV (0x18) && (GETV (0x1E) == Zero)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x091E8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000121,
                    }
                })
                Return (RBUF) /* \_SB_.XHC5._CRS.RBUF */
            }
        }

        Device (USB0)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x14))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x09268000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000110,
                    }
                })
                Return (RBUF) /* \_SB_.USB0._CRS.RBUF */
            }
        }

        Device (USB1)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x1B))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x09298000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000113,
                    }
                })
                Return (RBUF) /* \_SB_.USB1._CRS.RBUF */
            }
        }

        Device (USB2)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x08)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x1A))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x092C8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000116,
                    }
                })
                Return (RBUF) /* \_SB_.USB2._CRS.RBUF */
            }
        }

        Device (USB3)
        {
            Name (_HID, "PNP0D10" /* XHCI USB Controller with debug */)  // _HID: Hardware ID
            Name (_UID, 0x09)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x19))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0x092F8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                    {
                        0x00000119,
                    }
                })
                Return (RBUF) /* \_SB_.USB3._CRS.RBUF */
            }
        }

        Device (SUB0)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x12))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09000310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x09000400,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb0", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x06)
                {
                    Package (0x02)
                    {
                        "id", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }, 

                    Package (0x02)
                    {
                        "oc-gpio", 
                        Package (0x04)
                        {
                            SUB0, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x83, 
                    "sof_clk", 
                    SUB0
                }, 

                Package (0x03)
                {
                    0x68, 
                    "usb_aclk", 
                    SUB0
                }, 

                Package (0x03)
                {
                    0x8D, 
                    "lpm_clk", 
                    SUB0
                }, 

                Package (0x03)
                {
                    0x69, 
                    "usb_pclk", 
                    SUB0
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x47, 
                    SUB0, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x4D, 
                    SUB0, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    SUB0, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    SUB0, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB0)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x09010000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09014000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09018000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000126,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000126,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000127,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000126,
                    }
                })
                Name (_DSD, Package (0x06)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "super-speed-plus"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "otg"
                        }, 

                        Package (0x02)
                        {
                            "cdnsp,usb3-phy", 
                            ^^UCP0.USBP
                        }
                    }, 

                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "usb-role-switch", 
                            Zero
                        }
                    }, 

                    ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                    Package (0x01)
                    {
                        Package (0x02)
                        {
                            "port@0", 
                            "PRT0"
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
                            Package (0x04)
                            {
                                ^^I2C5.PD10, 
                                "usbc_con0", 
                                "port@0", 
                                "endpoint@0"
                            }
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        SUB0, 
                        CUB0, 
                        Zero
                    }
                })
            }
        }

        Device (U2P4)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x41, 
                    U2P4, 
                    "preset"
                }
            })
        }

        Device (UCP0)
        {
            Name (_HID, "CIXH2033")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09030000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (_DSD, Package (0x06)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "id", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "cix,usbphy_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "svid", 
                        0xFF01
                    }, 

                    Package (0x02)
                    {
                        "default_conf", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "phy-status", 
                        "usb"
                    }
                }, 

                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "orientation-switch", 
                        Zero
                    }, 

                    Package (0x02)
                    {
                        "mode-switch", 
                        Zero
                    }
                }, 

                ToUUID ("dbb8e3e6-5886-4ba6-8795-1319f52a966b") /* Hierarchical Data Extension */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "port@0", 
                        "PRT0"
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
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "endpoint@0", 
                        "EP00"
                    }, 

                    Package (0x02)
                    {
                        "endpoint@1", 
                        "EP01"
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
                        Package (0x04)
                        {
                            ^I2C5.PD10, 
                            "usbc_con0", 
                            "port@1", 
                            "endpoint@0"
                        }
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
                        One
                    }, 

                    Package (0x02)
                    {
                        "remote-endpoint", 
                        Package (0x03)
                        {
                            ^I2C5.PD10, 
                            "port@2", 
                            "endpoint@0"
                        }
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x6B, 
                    "pclk", 
                    UCP0
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x33, 
                    UCP0, 
                    "preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x37, 
                    UCP0, 
                    "reset"
                }
            })
            Device (USBP)
            {
                Name (_ADR, Zero)  // _ADR: Address
            }

            Device (UDPP)
            {
                Name (_ADR, One)  // _ADR: Address
            }
        }

        Device (SUB1)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x13))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09070310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x09070400,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb1", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }, 

                    Package (0x02)
                    {
                        "oc-gpio", 
                        Package (0x04)
                        {
                            SUB1, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "u3-port-disable", 
                        One
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x84, 
                    "sof_clk", 
                    SUB1
                }, 

                Package (0x03)
                {
                    0x6C, 
                    "usb_aclk", 
                    SUB1
                }, 

                Package (0x03)
                {
                    0x8E, 
                    "lpm_clk", 
                    SUB1
                }, 

                Package (0x03)
                {
                    0x6D, 
                    "usb_pclk", 
                    SUB1
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x48, 
                    SUB1, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x4E, 
                    SUB1, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    SUB1, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    SUB1, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB1)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, One)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x09080000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09084000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09088000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000012C,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000012C,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000012D,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000012C,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "super-speed-plus"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }, 

                        Package (0x02)
                        {
                            "cdnsp,usb3-phy", 
                            ^^UCP1.USBP
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        SUB1, 
                        CUB1, 
                        Zero
                    }
                })
            }
        }

        Device (U2P5)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x42, 
                    U2P5, 
                    "preset"
                }
            })
        }

        Device (UCP1)
        {
            Name (_HID, "CIXH2033")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x090A0000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "id", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "cix,usbphy_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "default_conf", 
                        0x02
                    }, 

                    Package (0x02)
                    {
                        "phy-status", 
                        "usb"
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x6F, 
                    "pclk", 
                    UCP1
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x34, 
                    UCP1, 
                    "preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x38, 
                    UCP1, 
                    "reset"
                }
            })
            Device (USBP)
            {
                Name (_ADR, Zero)  // _ADR: Address
            }

            Device (UDPP)
            {
                Name (_ADR, One)  // _ADR: Address
            }
        }

        Device (SUB2)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x16))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x090E0310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x090E0400,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb2", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x06)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x02
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }, 

                    Package (0x02)
                    {
                        "oc-gpio", 
                        Package (0x04)
                        {
                            SUB2, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x85, 
                    "sof_clk", 
                    SUB2
                }, 

                Package (0x03)
                {
                    0x70, 
                    "usb_aclk", 
                    SUB2
                }, 

                Package (0x03)
                {
                    0x8F, 
                    "lpm_clk", 
                    SUB2
                }, 

                Package (0x03)
                {
                    0x71, 
                    "usb_pclk", 
                    SUB2
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x4B, 
                    SUB2, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x51, 
                    SUB2, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    SUB2, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    SUB2, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB2)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, 0x02)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x090F0000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x090F4000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x090F8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000132,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000132,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000133,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000132,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "super-speed-plus"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }, 

                        Package (0x02)
                        {
                            "cdnsp,usb3-phy", 
                            ^^UCP2.USBP
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        SUB2, 
                        CUB2, 
                        Zero
                    }
                })
            }
        }

        Device (U2P8)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x08)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x45, 
                    U2P8, 
                    "preset"
                }
            })
        }

        Device (UCP2)
        {
            Name (_HID, "CIXH2033")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09110000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x02
                    }, 

                    Package (0x02)
                    {
                        "cix,usbphy_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "default_conf", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "phy-status", 
                        "usb"
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x73, 
                    "pclk", 
                    UCP2
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x35, 
                    UCP2, 
                    "preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x39, 
                    UCP2, 
                    "reset"
                }
            })
            Device (USBP)
            {
                Name (_ADR, Zero)  // _ADR: Address
            }

            Device (UDPP)
            {
                Name (_ADR, One)  // _ADR: Address
            }
        }

        Device (SUB3)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x15))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09150310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x09150400,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb3", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x07)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }, 

                    Package (0x02)
                    {
                        "oc-gpio", 
                        Package (0x04)
                        {
                            SUB3, 
                            Zero, 
                            Zero, 
                            Zero
                        }
                    }, 

                    Package (0x02)
                    {
                        "u3-port-disable", 
                        One
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x86, 
                    "sof_clk", 
                    SUB3
                }, 

                Package (0x03)
                {
                    0x74, 
                    "usb_aclk", 
                    SUB3
                }, 

                Package (0x03)
                {
                    0x90, 
                    "lpm_clk", 
                    SUB3
                }, 

                Package (0x03)
                {
                    0x75, 
                    "usb_pclk", 
                    SUB3
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x4C, 
                    SUB3, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x52, 
                    SUB3, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    SUB3, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    SUB3, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB3)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, 0x03)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x09160000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09164000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09168000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000138,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000138,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000139,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000138,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "super-speed-plus"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }, 

                        Package (0x02)
                        {
                            "cdnsp,usb3-phy", 
                            ^^UCP3.USBP
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        SUB3, 
                        CUB3, 
                        Zero
                    }
                })
            }
        }

        Device (U2P9)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x09)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x46, 
                    U2P9, 
                    "preset"
                }
            })
        }

        Device (UCP3)
        {
            Name (_HID, "CIXH2033")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0F)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09180000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x04)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x03
                    }, 

                    Package (0x02)
                    {
                        "cix,usbphy_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "default_conf", 
                        0x02
                    }, 

                    Package (0x02)
                    {
                        "phy-status", 
                        "usb"
                    }
                }
            })
            Name (CLKT, Package (0x01)
            {
                Package (0x03)
                {
                    0x77, 
                    "pclk", 
                    UCP3
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x36, 
                    UCP3, 
                    "preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x3A, 
                    UCP3, 
                    "reset"
                }
            })
            Device (USBP)
            {
                Name (_ADR, Zero)  // _ADR: Address
            }

            Device (UDPP)
            {
                Name (_ADR, One)  // _ADR: Address
            }
        }

        Device (SUB4)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x17))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x091C0314,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x091C0400,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb4", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x04
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x87, 
                    "sof_clk", 
                    SUB4
                }, 

                Package (0x03)
                {
                    0x78, 
                    "usb_aclk", 
                    SUB4
                }, 

                Package (0x03)
                {
                    0x91, 
                    "lpm_clk", 
                    SUB4
                }, 

                Package (0x03)
                {
                    0x79, 
                    "usb_pclk", 
                    SUB4
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x49, 
                    SUB4, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x4F, 
                    SUB4, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    SUB4, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    SUB4, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB4)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, 0x04)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x091D0000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x091D4000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x091D8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000011C,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000011C,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000011D,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000011C,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "super-speed-plus"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }, 

                        Package (0x02)
                        {
                            "cdnsp,usb3-phy", 
                            ^^U3P4.USB0
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB4, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB4, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB4, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB4, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB4, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB4, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB4, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        SUB4, 
                        CUB4, 
                        Zero
                    }
                })
            }
        }

        Device (SUB5)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x18))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x091C0324,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x091C0410,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb5", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x05
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x88, 
                    "sof_clk", 
                    SUB5
                }, 

                Package (0x03)
                {
                    0x7B, 
                    "usb_aclk", 
                    SUB5
                }, 

                Package (0x03)
                {
                    0x92, 
                    "lpm_clk", 
                    SUB5
                }, 

                Package (0x03)
                {
                    0x7C, 
                    "usb_pclk", 
                    SUB5
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x4A, 
                    SUB5, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x50, 
                    SUB5, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    SUB5, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    SUB5, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB5)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, 0x05)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x091E0000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x091E4000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x091E8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000121,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000121,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000122,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000121,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x03)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "super-speed-plus"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }, 

                        Package (0x02)
                        {
                            "cdnsp,usb3-phy", 
                            ^^U3P4.USB1
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB5, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB5, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB5, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB5, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB5, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB5, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB5, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        SUB5, 
                        CUB5, 
                        Zero
                    }
                })
            }
        }

        Device (U2P6)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x43, 
                    U2P6, 
                    "preset"
                }
            })
        }

        Device (U2P7)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x44, 
                    U2P7, 
                    "preset"
                }
            })
        }

        Device (U3P4)
        {
            Name (_HID, "CIXH2034")  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09210000,         // Address Base
                    0x00040000,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x01)
                {
                    Package (0x02)
                    {
                        "cix,usbphy_syscon", 
                        CRU0
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x7E, 
                    "apb_clk", 
                    U3P4
                }, 

                Package (0x03)
                {
                    0xA1, 
                    "ref_clk", 
                    U3P4
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x3B, 
                    U3P4, 
                    "preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x3C, 
                    U3P4, 
                    "reset"
                }
            })
            Device (USB0)
            {
                Name (_ADR, Zero)  // _ADR: Address
            }

            Device (USB1)
            {
                Name (_ADR, One)  // _ADR: Address
            }
        }

        Device (HUB0)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x14))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09250310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x09250400,         // Address Base
                    0x00000004,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x06
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x7F, 
                    "sof_clk", 
                    HUB0
                }, 

                Package (0x03)
                {
                    0x5C, 
                    "usb_aclk", 
                    HUB0
                }, 

                Package (0x03)
                {
                    0x89, 
                    "lpm_clk", 
                    HUB0
                }, 

                Package (0x03)
                {
                    0x5D, 
                    "usb_pclk", 
                    HUB0
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x53, 
                    HUB0, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x57, 
                    HUB0, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    HUB0, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    HUB0, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB0)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x09260000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09264000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09268000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000110,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000110,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000111,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000110,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "high-speed"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB0, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        HUB0, 
                        CUB0, 
                        Zero
                    }
                })
            }
        }

        Device (HUB1)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x1B))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x09280310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x09280400,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb7", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x80, 
                    "sof_clk", 
                    HUB1
                }, 

                Package (0x03)
                {
                    0x5E, 
                    "usb_aclk", 
                    HUB1
                }, 

                Package (0x03)
                {
                    0x8A, 
                    "lpm_clk", 
                    HUB1
                }, 

                Package (0x03)
                {
                    0x5F, 
                    "usb_pclk", 
                    HUB1
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x54, 
                    HUB1, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x58, 
                    HUB1, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    HUB1, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    HUB1, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB1)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, One)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x09290000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09294000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x09298000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000113,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000113,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000114,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000113,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "high-speed"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB1, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        HUB1, 
                        CUB1, 
                        Zero
                    }
                })
            }
        }

        Device (U2P0)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x3D, 
                    U2P0, 
                    "preset"
                }
            })
        }

        Device (U2P1)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x3E, 
                    U2P1, 
                    "preset"
                }
            })
        }

        Device (HUB2)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x08)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x1A))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x092B0310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x092B0400,         // Address Base
                    0x00000004,         // Address Length
                    )
                PinGroupFunction (Exclusive, 0x0000, "\\_SB.MUX1", 0x00,
                    "pinctrl_usb8", ResourceConsumer, ,)
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x08
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x81, 
                    "sof_clk", 
                    HUB2
                }, 

                Package (0x03)
                {
                    0x60, 
                    "usb_aclk", 
                    HUB2
                }, 

                Package (0x03)
                {
                    0x8B, 
                    "lpm_clk", 
                    HUB2
                }, 

                Package (0x03)
                {
                    0x61, 
                    "usb_pclk", 
                    HUB2
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x55, 
                    HUB2, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x59, 
                    HUB2, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    HUB2, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    HUB2, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB2)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, 0x02)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x092C0000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x092C4000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x092C8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000116,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000116,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000117,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000116,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "high-speed"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB2, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        HUB2, 
                        CUB2, 
                        Zero
                    }
                })
            }
        }

        Device (U2P2)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x3F, 
                    U2P2, 
                    "preset"
                }
            })
        }

        Device (HUB3)
        {
            Name (_HID, "CIXH2030")  // _HID: Hardware ID
            Name (_UID, 0x09)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (GETV (0x19))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x092E0310,         // Address Base
                    0x00000004,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x092E0400,         // Address Base
                    0x00000004,         // Address Length
                    )
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x05)
                {
                    Package (0x02)
                    {
                        "id", 
                        0x09
                    }, 

                    Package (0x02)
                    {
                        "axi_bmax_value", 
                        0x07
                    }, 

                    Package (0x02)
                    {
                        "cix,usb_syscon", 
                        CRU0
                    }, 

                    Package (0x02)
                    {
                        "sof_clk_freq", 
                        0x007A1200
                    }, 

                    Package (0x02)
                    {
                        "lpm_clk_freq", 
                        0x7D00
                    }
                }
            })
            Name (CLKT, Package (0x04)
            {
                Package (0x03)
                {
                    0x82, 
                    "sof_clk", 
                    HUB3
                }, 

                Package (0x03)
                {
                    0x62, 
                    "usb_aclk", 
                    HUB3
                }, 

                Package (0x03)
                {
                    0x8C, 
                    "lpm_clk", 
                    HUB3
                }, 

                Package (0x03)
                {
                    0x63, 
                    "usb_pclk", 
                    HUB3
                }
            })
            Name (RSTL, Package (0x02)
            {
                Package (0x04)
                {
                    RST0, 
                    0x56, 
                    HUB3, 
                    "usb_preset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x5A, 
                    HUB3, 
                    "usb_reset"
                }
            })
            Name (RSNL, Package (0x02)
            {
                Package (0x04)
                {
                    HUB3, 
                    0x0200, 
                    Zero, 
                    "axi_property"
                }, 

                Package (0x04)
                {
                    HUB3, 
                    0x0200, 
                    One, 
                    "controller_status"
                }
            })
            Device (CUB3)
            {
                Name (_HID, "CIXH2031")  // _HID: Hardware ID
                Name (_UID, 0x03)  // _UID: Unique ID
                Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0B)
                }

                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    Memory32Fixed (ReadWrite,
                        0x092F0000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x092F4000,         // Address Base
                        0x00004000,         // Address Length
                        )
                    Memory32Fixed (ReadWrite,
                        0x092F8000,         // Address Base
                        0x00008000,         // Address Length
                        )
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000119,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000119,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x0000011A,
                    }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, ExclusiveAndWake, 0x00, "\\_SB.PDC0", )
                    {
                        0x00000119,
                    }
                })
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "maximum-speed", 
                            "high-speed"
                        }, 

                        Package (0x02)
                        {
                            "dr_mode", 
                            "host"
                        }
                    }
                })
                Name (RSNL, Package (0x07)
                {
                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        Zero, 
                        "host"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        One, 
                        "peripheral"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        0x02, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0400, 
                        0x03, 
                        "wakeup"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0200, 
                        Zero, 
                        "otg"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0200, 
                        One, 
                        "dev"
                    }, 

                    Package (0x04)
                    {
                        CUB3, 
                        0x0200, 
                        0x02, 
                        "xhci"
                    }
                })
                Name (DLKL, Package (0x01)
                {
                    Package (0x03)
                    {
                        HUB3, 
                        CUB3, 
                        Zero
                    }
                })
            }
        }

        Device (U2P3)
        {
            Name (_HID, "CIXH2032")  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_STA, 0x0B)  // _STA: Status
            Name (RSTL, Package (0x01)
            {
                Package (0x04)
                {
                    RST0, 
                    0x40, 
                    U2P3, 
                    "preset"
                }
            })
        }

        Device (V4L2)
        {
            Name (_HID, "CIXH3020")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x29))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000168,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000169,
                }
            })
        }

        Device (ISP0)
        {
            Name (_HID, "CIXH3021")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x29))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x14340000,         // Address Base
                    0x00010000,         // Address Length
                    )
                Memory32Fixed (ReadWrite,
                    0x14360000,         // Address Base
                    0x00050000,         // Address Length
                    )
            })
        }

        Device (ISP1)
        {
            Name (_HID, "CIXH3022")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
        }

        Device (ISP2)
        {
            Name (_HID, "CIXH3022")  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
        }

        Device (ISP3)
        {
            Name (_HID, "CIXH3022")  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_STA, Zero)  // _STA: Status
        }

        Device (ISPM)
        {
            Name (_HID, "CIXH3025")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x29))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x08)
                {
                    Package (0x02)
                    {
                        "ahb-pmctrl-res-base", 
                        0x16000404
                    }, 

                    Package (0x02)
                    {
                        "ahb-pmctrl-res-size", 
                        One
                    }, 

                    Package (0x02)
                    {
                        "ahb-rcsuisp0-res-base", 
                        0x14330000
                    }, 

                    Package (0x02)
                    {
                        "ahb-rcsuisp0-res-size", 
                        0x1000
                    }, 

                    Package (0x02)
                    {
                        "ahb-rcsuisp1-res-base", 
                        0x14350000
                    }, 

                    Package (0x02)
                    {
                        "ahb-rcsuisp1-res-size", 
                        0x1000
                    }, 

                    Package (0x02)
                    {
                        "qos-read-priority", 
                        0x0F
                    }, 

                    Package (0x02)
                    {
                        "qos-write-priority", 
                        0x0F
                    }
                }
            })
            Name (CLKT, Package (0x02)
            {
                Package (0x03)
                {
                    0x44, 
                    "isp_aclk", 
                    ISPM
                }, 

                Package (0x03)
                {
                    0x45, 
                    "isp_sclk", 
                    ISPM
                }
            })
            Name (RSTL, Package (0x05)
            {
                Package (0x04)
                {
                    RST0, 
                    0x0F, 
                    ISPM, 
                    "isp_sreset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x10, 
                    ISPM, 
                    "isp_areset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x11, 
                    ISPM, 
                    "isp_hreset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x12, 
                    ISPM, 
                    "isp_gdcreset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x78, 
                    ISPM, 
                    "rcsu_reset"
                }
            })
            PowerResource (PRS0, 0x00, 0x0000)
            {
                OperationRegion (OPR0, SystemMemory, 0x14330020, 0x04)
                Field (OPR0, DWordAcc, NoLock, Preserve)
                {
                    MSK0,   32
                }

                Method (_STA, 0, Serialized)  // _STA: Status
                {
                    Local0 = MSK0 /* \_SB_.ISPM.PRS0.MSK0 */
                    Local0 &= One
                    If ((Local0 > Zero))
                    {
                        Return (One)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }

                Method (_ON, 0, Serialized)  // _ON_: Power On
                {
                    Local0 = MSK0 /* \_SB_.ISPM.PRS0.MSK0 */
                    Local0 = ((Local0 | One) | 0x0FFC)
                    MSK0 = Local0
                    DMRP (One, 0x07, 0x14330000, One)
                }

                Method (_OFF, 0, Serialized)  // _OFF: Power Off
                {
                    Local0 = MSK0 /* \_SB_.ISPM.PRS0.MSK0 */
                    Local0 &= 0xFFFFFFFFFFFFFFFE
                    MSK0 = Local0
                }
            }

            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                PRS0
            })
            Name (_PR3, Package (0x01)  // _PR3: Power Resources for D3hot
            {
                PRS0
            })
        }

        Device (VIHW)
        {
            Name (_HID, "CIXH3026")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If (GETV (0x29))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CCA, Zero)  // _CCA: Cache Coherency Attribute
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E4,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E5,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E6,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E7,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E8,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001E9,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001EA,
                }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x000001EB,
                }
            })
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x18)
                {
                    Package (0x02)
                    {
                        "ahb-dphy0-base", 
                        0x142A0000
                    }, 

                    Package (0x02)
                    {
                        "ahb-dphy0-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-dphy1-base", 
                        0x14300000
                    }, 

                    Package (0x02)
                    {
                        "ahb-dphy1-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi0-base", 
                        0x14280000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi0-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi1-base", 
                        0x14290000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi1-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi2-base", 
                        0x142E0000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi2-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi3-base", 
                        0x142F0000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csi3-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma0-base", 
                        0x142B0000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma0-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma1-base", 
                        0x142C0000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma1-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma2-base", 
                        0x14310000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma2-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma3-base", 
                        0x14320000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csidma3-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csircsu0-base", 
                        0x14270000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csircsu0-size", 
                        0x00010000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csircsu1-base", 
                        0x142D0000
                    }, 

                    Package (0x02)
                    {
                        "ahb-csircsu1-size", 
                        0x00010000
                    }
                }
            })
            Name (CLKT, Package (0x1A)
            {
                Package (0x03)
                {
                    0x19, 
                    "phy0_psmclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x1A, 
                    "phy1_psmclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x1B, 
                    "phy0_apbclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x1C, 
                    "phy1_apbclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x11, 
                    "csi0_pclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x12, 
                    "csi1_pclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x13, 
                    "csi2_pclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x14, 
                    "csi3_pclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB0, 
                    "csi0_sclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB1, 
                    "csi1_sclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB2, 
                    "csi2_sclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB3, 
                    "csi3_sclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB4, 
                    "csi0_p0clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB5, 
                    "csi0_p1clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB6, 
                    "csi0_p2clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB7, 
                    "csi0_p3clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB8, 
                    "csi1_p0clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xB9, 
                    "csi2_p0clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xBA, 
                    "csi2_p1clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xBB, 
                    "csi2_p2clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xBC, 
                    "csi2_p3clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0xBD, 
                    "csi3_p0clk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x15, 
                    "dma0_pclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x16, 
                    "dma1_pclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x17, 
                    "dma2_pclk", 
                    VIHW
                }, 

                Package (0x03)
                {
                    0x18, 
                    "dma3_pclk", 
                    VIHW
                }
            })
            Name (RSTL, Package (0x0E)
            {
                Package (0x04)
                {
                    RST0, 
                    0x20, 
                    VIHW, 
                    "phy0_prst"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x21, 
                    VIHW, 
                    "phy0_cmnrst"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x23, 
                    VIHW, 
                    "phy1_prst"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x24, 
                    VIHW, 
                    "phy1_cmnrst"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x5D, 
                    VIHW, 
                    "rcsu0_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x5E, 
                    VIHW, 
                    "rcsu1_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x22, 
                    VIHW, 
                    "csi0_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x25, 
                    VIHW, 
                    "csi1_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x26, 
                    VIHW, 
                    "csi2_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x27, 
                    VIHW, 
                    "csi3_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x28, 
                    VIHW, 
                    "csibridge0_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x29, 
                    VIHW, 
                    "csibridge1_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x2A, 
                    VIHW, 
                    "csibridge2_reset"
                }, 

                Package (0x04)
                {
                    RST0, 
                    0x2B, 
                    VIHW, 
                    "csibridge3_reset"
                }
            })
        }

        Name (GNVA, 0xFFFE0000)
        Name (GNVL, 0x004D)
        OperationRegion (S5R1, SystemMemory, 0x16000504, 0x04)
        Field (S5R1, DWordAcc, NoLock, Preserve)
        {
            S5MK,   32
        }

        Method (GETV, 1, Serialized)
        {
            If ((Arg0 >= 0x4D))
            {
                Return (Zero)
            }

            Local0 = (Arg0 + GNVA) /* \_SB_.GNVA */
            OperationRegion (GPNV, SystemMemory, Local0, One)
            Field (GPNV, ByteAcc, NoLock, Preserve)
            {
                VARV,   8
            }

            ToInteger (VARV, Local0)
            Return (Local0)
        }

        Method (MVCK, 1, Serialized)
        {
            Local0 = Arg0
            Local1 = S5MK /* \_SB_.S5MK */
            Local1 = ((Local1 >> Local0) & One)
            Debug = Concatenate (Concatenate (Concatenate (Concatenate ("ACPI debug:arg0=", Arg0), ", MVCK.valid = "), Local1
                ), "\n")
            Return (Local1)
        }

        Method (DMRP, 4, Serialized)
        {
            Debug = Concatenate (Concatenate (Concatenate (Concatenate (Concatenate (Concatenate (Concatenate (Concatenate ("ACPI debug: Arg0:Arg1:Arg2:Arg3 = ", Arg0
                ), ":"), Arg1), ":"), Arg2), ":"), Arg3), 
                "\n")
            If ((Arg0 && MVCK (Arg1)))
            {
                OperationRegion (PDRG, SystemMemory, Arg2, 0x20)
                Field (PDRG, DWordAcc, NoLock, Preserve)
                {
                    Offset (0x10), 
                    PASS,   32, 
                    ENBL,   32, 
                    BUSY,   32
                }

                Local0 = 0x00989680
                Local1 = BUSY /* \_SB_.DMRP.BUSY */
                Local1 = ((Local1 >> 0x10) & 0xFFFF)
                While (((Local1 != Zero) && (Local0 != Zero)))
                {
                    Local0--
                    If ((Local0 == Zero))
                    {
                        Debug = Concatenate (Concatenate ("Do memory busy, status = ", Local1), "!\n")
                    }

                    Local1 = BUSY /* \_SB_.DMRP.BUSY */
                    Local1 = ((Local1 >> 0x10) & 0xFFFF)
                }

                ENBL = Arg3
                Debug = Concatenate (Concatenate ("group_en = 0x", ENBL), "!\n")
                Local1 = PASS /* \_SB_.DMRP.PASS */
                Local1 = ((Local1 >> One) & 0x03)
                While (((Local1 != 0x03) && (Local0 != Zero)))
                {
                    Local0--
                    If ((Local0 == Zero))
                    {
                        Debug = Concatenate (Concatenate ("Done and pass failed, status = ", Local1), "!\n")
                    }

                    Local1 = PASS /* \_SB_.DMRP.PASS */
                    Local1 = ((Local1 >> One) & 0x03)
                }

                ENBL = Zero
                Debug = Concatenate (Concatenate ("group_en = 0x", ENBL), "!\n")
                Return (ENBL) /* \_SB_.DMRP.ENBL */
            }

            Return (Zero)
        }

        Method (TGSP, 2, Serialized)
        {
            If ((Arg0 >= 0x64))
            {
                Return (Zero)
            }

            Local0 = (0x06510000 + (0x0900 + (0x04 * Arg0)))
            Local1 = Arg1
            OperationRegion (HMEM, SystemMemory, Local0, 0x04)
            Field (HMEM, DWordAcc, NoLock, Preserve)
            {
                HLCK,   32
            }

            While (One)
            {
                HLCK = One
                If ((One == (HLCK & 0xFF)))
                {
                    Return (One)
                }

                If (Local1)
                {
                    Local1--
                    If ((Local1 == Zero))
                    {
                        Return (Zero)
                    }
                }
            }

            Return (Zero)
        }

        Method (RLSP, 1, Serialized)
        {
            If ((Arg0 >= 0x64))
            {
                Return (Zero)
            }

            Local0 = (0x06510000 + (0x0900 + (0x04 * Arg0)))
            OperationRegion (HMEM, SystemMemory, Local0, 0x04)
            Field (HMEM, DWordAcc, NoLock, Preserve)
            {
                HLCK,   32
            }

            If (((HLCK & 0xFF) == One))
            {
                HLCK = One
            }

            Return (Zero)
        }

        Device (TEE0)
        {
            Name (_HID, "CIXHA022")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CID, "PRP0001")  // _CID: Compatible ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                Package (0x02)
                {
                    Package (0x02)
                    {
                        "compatible", 
                        "linaro,optee-tz"
                    }, 

                    Package (0x02)
                    {
                        "method", 
                        "smc"
                    }
                }
            })
        }

        OperationRegion (IMTX, SystemMemory, 0x06510900, 0x0400)
        Field (IMTX, DWordAcc, NoLock, Preserve)
        {
            Offset (0x120), 
            IMX0,   32, 
            IMX1,   32, 
            IMX2,   32, 
            IMX3,   32, 
            IMX4,   32, 
            IMX5,   32, 
            IMX6,   32, 
            IMX7,   32
        }

        Method (GMTX, 1, Serialized)
        {
            Local0 = Zero
            Switch (ToInteger (Arg0))
            {
                Case (0x48)
                {
                    Local0 = IMX0 /* \_SB_.IMX0 */
                }
                Case (0x49)
                {
                    Local0 = IMX1 /* \_SB_.IMX1 */
                }
                Case (0x4A)
                {
                    Local0 = IMX2 /* \_SB_.IMX2 */
                }
                Case (0x4B)
                {
                    Local0 = IMX3 /* \_SB_.IMX3 */
                }
                Case (0x4C)
                {
                    Local0 = IMX4 /* \_SB_.IMX4 */
                }
                Case (0x4D)
                {
                    Local0 = IMX5 /* \_SB_.IMX5 */
                }
                Case (0x4E)
                {
                    Local0 = IMX6 /* \_SB_.IMX6 */
                }
                Case (0x4F)
                {
                    Local0 = IMX7 /* \_SB_.IMX7 */
                }

            }

            Return (Local0)
        }

        Method (SMTX, 2, Serialized)
        {
            Switch (ToInteger (Arg0))
            {
                Case (0x48)
                {
                    IMX0 = Arg1
                }
                Case (0x49)
                {
                    IMX1 = Arg1
                }
                Case (0x4A)
                {
                    IMX2 = Arg1
                }
                Case (0x4B)
                {
                    IMX3 = Arg1
                }
                Case (0x4C)
                {
                    IMX4 = Arg1
                }
                Case (0x4D)
                {
                    IMX5 = Arg1
                }
                Case (0x4E)
                {
                    IMX6 = Arg1
                }
                Case (0x4F)
                {
                    IMX7 = Arg1
                }

            }
        }

        Method (AMTX, 2, Serialized)
        {
            If ((Arg0 == 0xFF))
            {
                Return (Zero)
            }

            If ((GMTX (Arg0) == Arg1))
            {
                Return (One)
            }

            Local0 = 0x01F4
            While (((GMTX (Arg0) != Arg1) && Local0))
            {
                SMTX (Arg0, Arg1)
                Local1 = 0x2710
                While (Local1)
                {
                    Local1--
                }

                Local0--
            }

            If ((Local0 == Zero))
            {
                Return (One)
            }

            Return (Zero)
        }

        Method (RMTX, 2, Serialized)
        {
            If ((Arg0 == 0xFF))
            {
                Return (Zero)
            }

            If ((GMTX (Arg0) == Zero))
            {
                Return (One)
            }

            If ((GMTX (Arg0) != Arg1))
            {
                Return (One)
            }

            Local0 = 0x01F4
            While (((GMTX (Arg0) == Arg1) && Local0))
            {
                SMTX (Arg0, Arg1)
                Local2 = 0x2710
                While (Local2)
                {
                    Local2--
                }

                Local0--
            }

            If ((Local0 == Zero))
            {
                Return (One)
            }

            Return (Zero)
        }

        Device (DTPM)
        {
            Name (_HID, "MSFT0101" /* TPM 2.0 Security Device */)  // _HID: Hardware ID
            Name (_CID, "MSFT0101" /* TPM 2.0 Security Device */)  // _CID: Compatible ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, 0x0F)  // _STA: Status
            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, ResourceTemplate ()
                {
                    SpiSerialBusV2 (0x0000, PolarityLow, FourWireMode, 0x08,
                        ControllerInitiated, 0x0007A120, ClockPolarityLow,
                        ClockPhaseFirst, "\\_SB.SPI0",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                })
                Return (RBUF) /* \_SB_.DTPM._CRS.RBUF */
            }

            OperationRegion (TPMC, SystemMemory, 0x85F01000, 0x0C)
            Field (TPMC, DWordAcc, NoLock, Preserve)
            {
                PPIO,   32, 
                PPIR,   32, 
                PPIS,   32
            }

            Name (PKG2, Package (0x02)
            {
                Zero, 
                Zero
            })
            Name (PKG3, Package (0x03)
            {
                Zero, 
                Zero, 
                Zero
            })
            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If ((Arg0 == ToUUID ("3dddfaa6-361b-4eb4-a424-8d10089d1653") /* Physical Presence Interface */))
                {
                    Switch (ToInteger (Arg2))
                    {
                        Case (Zero)
                        {
                            Return (Buffer (0x02)
                            {
                                 0xFF, 0x01                                       // ..
                            })
                        }
                        Case (One)
                        {
                            Return ("1.3")
                        }
                        Case (0x02)
                        {
                            Return (One)
                        }
                        Case (0x03)
                        {
                            PKG2 [Zero] = Zero
                            PKG2 [One] = PPIO /* \_SB_.DTPM.PPIO */
                            Return (PKG2) /* \_SB_.DTPM.PKG2 */
                        }
                        Case (0x04)
                        {
                            Return (0x02)
                        }
                        Case (0x05)
                        {
                            PKG3 [Zero] = Zero
                            PKG3 [One] = PPIR /* \_SB_.DTPM.PPIR */
                            PKG3 [0x02] = PPIS /* \_SB_.DTPM.PPIS */
                            Return (PKG3) /* \_SB_.DTPM.PKG3 */
                        }
                        Case (0x06)
                        {
                            Return (0x03)
                        }
                        Case (0x07)
                        {
                            Local0 = DerefOf (Arg3 [Zero])
                            PPIO = Local0
                            Return (Zero)
                        }
                        Case (0x08)
                        {
                            Return (0x04)
                        }

                    }
                    Return (Buffer (One)
                    {
                         0x00
                    })
                }
                Else
                {
                    Return (Buffer (One)
                    {
                         0x00
                    })
                }
            }
        }

        Device (TREE)
        {
            Name (_HID, "CIXHA023")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (RBUF, Buffer (0x02)
                {
                     0x79, 0x00                                       // y.
                })
                Return (RBUF) /* \_SB_.TREE._CRS.RBUF */
            }

            Name (SVCS, Package (0x03)
            {
                One, 
                Package (0x05)
                {
                    /**** Is ResourceTemplate, but EndTag not at buffer end ****/ ToUUID ("36deaa79-c5dd-447c-95e6-b3859589291a") /* Unknown UUID */, 
                    One, 
                    Zero, 
                    Package (0x00){}, 
                    Package (0x00){}
                }, 

                Package (0x05)
                {
                    ToUUID ("b1cc44ae-b9af-4aaa-8bc1-54c49b24d5ad") /* Unknown UUID */, 
                    One, 
                    Zero, 
                    Package (0x00){}, 
                    Package (0x00){}
                }
            })
            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If ((Arg0 == ToUUID ("418e2da4-7089-4ddb-aaca-a7e2377dbece") /* Unknown UUID */))
                {
                    Switch (ToInteger (Arg2))
                    {
                        Case (Zero)
                        {
                            Return (Buffer (One)
                            {
                                 0x03                                             // .
                            })
                        }
                        Case (One)
                        {
                            Return (SVCS) /* \_SB_.TREE.SVCS */
                        }
                        Default
                        {
                            Return (Buffer (One)
                            {
                                 0x40                                             // @
                            })
                        }

                    }
                }
                Else
                {
                    Return (Buffer (One)
                    {
                         0x00                                             // .
                    })
                }
            }
        }

        Device (PEP0)
        {
            Name (_HID, "CIXHA026")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }
        }
    }
}
