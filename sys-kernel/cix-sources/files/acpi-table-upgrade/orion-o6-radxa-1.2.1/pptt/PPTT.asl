/*
 * Radxa Orion O6 / CIX Sky1 replacement PPTT for Linux ACPI table upgrade.
 * Cache data comes from CLIDR_EL1/CCSIDR_EL1 with FEAT_CCIDX decoding.
 */
[0004]                          Signature : "PPTT" [Processor Properties Topology Table]
[0004]                       Table Length : 00000588
[0001]                           Revision : 03
[0001]                           Checksum : 2F
[0006]                             Oem ID : "CIXTEK"
[0008]                       Oem Table ID : "SKY1EDK2"
[0004]                       Oem Revision : 01000102
[0004]                    Asl Compiler ID : "INTL"
[0004]              Asl Compiler Revision : 20200925


/* socket: offset 0x0024 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 14
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 00000001
                         Physical package : 1
                  ACPI Processor ID valid : 0
                    Processor is a thread : 0
                           Node is a leaf : 0
                 Identical Implementation : 0
[0004]                             Parent : 00000000
[0004]                  ACPI Processor ID : 00000000
[0004]            Private Resource Number : 00000000

/* cluster1: offset 0x0038 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 14
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 00000010
                         Physical package : 0
                  ACPI Processor ID valid : 0
                    Processor is a thread : 0
                           Node is a leaf : 0
                 Identical Implementation : 1
[0004]                             Parent : 00000024
[0004]                  ACPI Processor ID : 00000001
[0004]            Private Resource Number : 00000000

/* cpu0: offset 0x004C */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000038
[0004]                  ACPI Processor ID : 00000000
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 00000224
[0004]                   Private Resource : 00000240

/* cpu1: offset 0x0068 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000038
[0004]                  ACPI Processor ID : 00000001
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 00000278
[0004]                   Private Resource : 00000294

/* cluster2: offset 0x0084 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 14
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 00000010
                         Physical package : 0
                  ACPI Processor ID valid : 0
                    Processor is a thread : 0
                           Node is a leaf : 0
                 Identical Implementation : 1
[0004]                             Parent : 00000024
[0004]                  ACPI Processor ID : 00000002
[0004]            Private Resource Number : 00000000

/* cpu2: offset 0x0098 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000084
[0004]                  ACPI Processor ID : 00000002
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 000002B0
[0004]                   Private Resource : 000002CC

/* cpu3: offset 0x00B4 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000084
[0004]                  ACPI Processor ID : 00000003
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 000002E8
[0004]                   Private Resource : 00000304

/* cpu4: offset 0x00D0 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000084
[0004]                  ACPI Processor ID : 00000004
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 00000320
[0004]                   Private Resource : 0000033C

/* cpu5: offset 0x00EC */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000084
[0004]                  ACPI Processor ID : 00000005
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 00000358
[0004]                   Private Resource : 00000374

/* cluster3: offset 0x0108 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 14
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 00000010
                         Physical package : 0
                  ACPI Processor ID valid : 0
                    Processor is a thread : 0
                           Node is a leaf : 0
                 Identical Implementation : 1
[0004]                             Parent : 00000024
[0004]                  ACPI Processor ID : 00000003
[0004]            Private Resource Number : 00000000

/* cpu6: offset 0x011C */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000108
[0004]                  ACPI Processor ID : 00000006
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 000003AC
[0004]                   Private Resource : 000003C8

/* cpu7: offset 0x0138 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000108
[0004]                  ACPI Processor ID : 00000007
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 00000400
[0004]                   Private Resource : 0000041C

/* cluster4: offset 0x0154 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 14
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 00000010
                         Physical package : 0
                  ACPI Processor ID valid : 0
                    Processor is a thread : 0
                           Node is a leaf : 0
                 Identical Implementation : 1
[0004]                             Parent : 00000024
[0004]                  ACPI Processor ID : 00000004
[0004]            Private Resource Number : 00000000

/* cpu8: offset 0x0168 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000154
[0004]                  ACPI Processor ID : 00000008
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 00000454
[0004]                   Private Resource : 00000470

/* cpu9: offset 0x0184 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 00000154
[0004]                  ACPI Processor ID : 00000009
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 000004A8
[0004]                   Private Resource : 000004C4

/* cluster5: offset 0x01A0 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 14
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 00000010
                         Physical package : 0
                  ACPI Processor ID valid : 0
                    Processor is a thread : 0
                           Node is a leaf : 0
                 Identical Implementation : 1
[0004]                             Parent : 00000024
[0004]                  ACPI Processor ID : 00000005
[0004]            Private Resource Number : 00000000

/* cpu10: offset 0x01B4 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 000001A0
[0004]                  ACPI Processor ID : 0000000A
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 000004FC
[0004]                   Private Resource : 00000518

/* cpu11: offset 0x01D0 */
[0001]                      Subtable Type : 00 [Processor Hierarchy Node]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000001A
                         Physical package : 0
                  ACPI Processor ID valid : 1
                    Processor is a thread : 0
                           Node is a leaf : 1
                 Identical Implementation : 1
[0004]                             Parent : 000001A0
[0004]                  ACPI Processor ID : 0000000B
[0004]            Private Resource Number : 00000002
[0004]                   Private Resource : 00000550
[0004]                   Private Resource : 0000056C

/* l3_shared: offset 0x01EC */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000000
[0004]                               Size : 00C00000
[0004]                     Number of Sets : 00004000
[0001]                      Associativity : 0C
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu0_l2: offset 0x0208 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu0_l1d: offset 0x0224 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000208
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu0_l1i: offset 0x0240 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000208
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu1_l2: offset 0x025C */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu1_l1d: offset 0x0278 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 0000025C
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu1_l1i: offset 0x0294 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 0000025C
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu2_l1d: offset 0x02B0 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu2_l1i: offset 0x02CC */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu3_l1d: offset 0x02E8 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu3_l1i: offset 0x0304 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu4_l1d: offset 0x0320 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu4_l1i: offset 0x033C */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu5_l1d: offset 0x0358 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu5_l1i: offset 0x0374 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00008000
[0004]                     Number of Sets : 00000080
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu6_l2: offset 0x0390 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu6_l1d: offset 0x03AC */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000390
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu6_l1i: offset 0x03C8 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000390
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu7_l2: offset 0x03E4 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu7_l1d: offset 0x0400 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000003E4
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu7_l1i: offset 0x041C */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000003E4
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu8_l2: offset 0x0438 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu8_l1d: offset 0x0454 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000438
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu8_l1i: offset 0x0470 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000438
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu9_l2: offset 0x048C */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu9_l1d: offset 0x04A8 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 0000048C
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu9_l1i: offset 0x04C4 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 0000048C
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu10_l2: offset 0x04E0 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu10_l1d: offset 0x04FC */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000004E0
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu10_l1i: offset 0x0518 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000004E0
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu11_l2: offset 0x0534 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 000001EC
[0004]                               Size : 00080000
[0004]                     Number of Sets : 00000400
[0001]                      Associativity : 08
[0001]                         Attributes : 0A
                          Allocation Type : 2
                               Cache Type : 2
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu11_l1d: offset 0x0550 */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000534
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 02
                          Allocation Type : 2
                               Cache Type : 0
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000

/* cpu11_l1i: offset 0x056C */
[0001]                      Subtable Type : 01 [Cache Type]
[0001]                             Length : 1C
[0002]                           Reserved : 0000
[0004]              Flags (decoded below) : 0000007F
                               Size valid : 1
                     Number of Sets valid : 1
                      Associativity valid : 1
                    Allocation Type valid : 1
                         Cache Type valid : 1
                       Write Policy valid : 1
                          Line Size valid : 1
                           Cache ID valid : 0
[0004]                Next Level of Cache : 00000534
[0004]                               Size : 00010000
[0004]                     Number of Sets : 00000100
[0001]                      Associativity : 04
[0001]                         Attributes : 04
                          Allocation Type : 0
                               Cache Type : 1
                             Write Policy : 0
[0002]                          Line Size : 0040
[0004]                           Cache ID : 00000000
