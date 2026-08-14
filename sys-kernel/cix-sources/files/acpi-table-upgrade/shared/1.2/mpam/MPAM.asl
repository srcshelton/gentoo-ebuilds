/*
 * CIX Sky1 DSU-120 MPAM component for Linux ACPI table upgrade.
 *
 * The MMIO address, size, resource instance and cache relationship are
 * independently established by the Arm DSU-120 TRM, CIX TF-A and live
 * read-only identification on an Orion O6. The first table revision omits
 * interrupts to keep functional allocation qualification separate from error
 * IRQ qualification. CIX firmware source identifies the Non-secure DSU MPAM
 * error interrupt as level-high GIC ID 67.
 */
[0004]                          Signature : "MPAM" [Memory System Resource Partitioning and Monitoring Table]
[0004]                       Table Length : 00000084
[0001]                           Revision : 02
[0001]                           Checksum : 00
[0006]                             Oem ID : "CIXTEK"
[0008]                       Oem Table ID : "SKY1MPAM"
[0004]                       Oem Revision : 01000001
[0004]                    Asl Compiler ID : "INTL"
[0004]              Asl Compiler Revision : 20260408

[0002]                             Length : 0060
[0001]                     Interface type : 00
[0001]                           Reserved : 00
[0004]                         Identifier : 00000001
[0008]                       Base address : 000000000F010000
[0004]                          MMIO size : 00010000
[0004]                 Overflow interrupt : 00000000
[0004]           Overflow interrupt flags : 00000000
[0004]                          Reserved1 : 00000000
[0004]        Overflow interrupt affinity : 00000000
[0004]                    Error interrupt : 00000000
[0004]              Error interrupt flags : 00000000
[0004]                          Reserved2 : 00000000
[0004]           Error interrupt affinity : 00000000
[0004]                      MAX_NRDY_USEC : 00000000
[0008]       Hardware ID of linked device : ""
[0004]       Instance ID of linked device : 00000000
[0004]           Number of resource nodes : 00000001

[0004]                         Identifier : 00000001
[0001]                          RIS Index : 00
[0002]                          Reserved1 : 0000
[0001]                       Locator type : 00 [Processor cache]
[0008]                    Cache reference : 0000000000000001
[0004]                           Reserved : 00000000
[0004]  Number of functional dependencies : 00000000
