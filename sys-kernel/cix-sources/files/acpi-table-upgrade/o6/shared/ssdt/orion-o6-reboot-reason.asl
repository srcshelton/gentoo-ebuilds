/** @file
  Describe the CIX Sky1 reboot-reason registers as an ACPI PRP0001 device.

  The first register address matches the CIX firmware PcdRebootReasonRegisterAddr.
  The second register reports the hardware reset source.

  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

DefinitionBlock ("", "SSDT", 2, "RADXA", "O6RBRR", 0x00000001)
{
    Scope (\_SB)
    {
        Device (RBRR)
        {
            Name (_HID, "PRP0001")
            Name (_UID, Zero)
            Name (_DSD, Package ()
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package ()
                {
                    Package () { "compatible", "cix,sky1-reboot-reason" }
                }
            })
            Name (_CRS, ResourceTemplate ()
            {
                Memory32Fixed (ReadOnly, 0x16000500, 0x00000004)
                Memory32Fixed (ReadOnly, 0x16000218, 0x00000004)
            })
        }
    }
}
