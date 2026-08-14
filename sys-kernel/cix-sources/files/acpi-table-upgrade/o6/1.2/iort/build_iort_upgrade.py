#!/usr/bin/env python3
"""Build optional Radxa Orion O6 IORT table-upgrade variants."""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


ACPI_HEADER_LEN = 36
ACPI_SIG_IORT = b"IORT"
IORT_NODE_ITS_GROUP = 0
IORT_NODE_SMMU_V3 = 4
IORT_NODE_PMCG = 5
IORT_ID_MAPPING_LEN = 20
SMMU_V3_FLAG_COHACC = 1 << 0
SMMU_V3_FLAG_HTTU_MASK = 3 << 1
SMMU_V3_FLAG_HTTU_AD = 2 << 1
SMMU_V3_FLAG_DEVICEID_VALID = 1 << 4
IORT_ID_SINGLE_MAPPING = 1 << 0
SKY1_PCIE_SMMU_BASE = 0x0B010000
SKY1_PLATFORM_SMMU_BASE = 0x0B1B0000
SKY1_SMMU_MSI_BASES = (SKY1_PCIE_SMMU_BASE, SKY1_PLATFORM_SMMU_BASE)
SKY1_SMMU_DOWNSTREAM_MSI_ID_COUNT = 0xFFFF


def u8(data: bytearray, off: int) -> int:
    return data[off]


def u16(data: bytearray, off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def u32(data: bytearray, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def u64(data: bytearray, off: int) -> int:
    return struct.unpack_from("<Q", data, off)[0]


def put_u8(data: bytearray, off: int, value: int) -> None:
    data[off] = value & 0xff


def put_u16(data: bytearray, off: int, value: int) -> None:
    struct.pack_into("<H", data, off, value)


def put_u32(data: bytearray, off: int, value: int) -> None:
    struct.pack_into("<I", data, off, value)


def bump_oem_revision(data: bytearray) -> None:
    oem_revision = u32(data, 24)
    if oem_revision == 0xffffffff:
        raise ValueError("IORT OEM revision cannot be incremented")
    put_u32(data, 24, oem_revision + 1)


def validate_header(data: bytearray) -> None:
    if len(data) < ACPI_HEADER_LEN:
        raise ValueError("IORT input is shorter than an ACPI header")
    if data[:4] != ACPI_SIG_IORT:
        raise ValueError("input table is not IORT")
    length = u32(data, 4)
    if length != len(data):
        raise ValueError(f"IORT length field {length} does not match file size {len(data)}")
    if sum(data) & 0xff:
        raise ValueError("IORT input checksum is invalid")


def iter_nodes(data: bytearray):
    node_count = u32(data, 36)
    node_offset = u32(data, 40)
    off = node_offset
    for index in range(node_count):
        if off + 16 > len(data):
            raise ValueError(f"IORT node {index} header extends past end of table")
        node_type = u8(data, off)
        node_len = u16(data, off + 1)
        node_rev = u8(data, off + 3)
        mappings = u32(data, off + 8)
        mapping_offset = u32(data, off + 12)
        if node_len < 16 or off + node_len > len(data):
            raise ValueError(f"IORT node {index} has invalid length {node_len}")
        yield index, off, node_type, node_len, node_rev, mappings, mapping_offset
        off += node_len


def update_checksum(data: bytearray) -> None:
    data[9] = 0
    data[9] = (-sum(data)) & 0xff
    if sum(data) & 0xff:
        raise RuntimeError("failed to recompute IORT checksum")


def enable_httu(data: bytearray) -> int:
    changed = 0
    for _index, off, node_type, _node_len, _node_rev, _mappings, _mapping_offset in iter_nodes(data):
        if node_type != IORT_NODE_SMMU_V3:
            continue
        flags_off = off + 24
        flags = u32(data, flags_off)
        new_flags = (flags & ~SMMU_V3_FLAG_HTTU_MASK) | SMMU_V3_FLAG_COHACC | SMMU_V3_FLAG_HTTU_AD
        if new_flags != flags:
            put_u32(data, flags_off, new_flags)
            changed += 1
    return changed


def find_single_its_group(data: bytearray) -> int:
    its_groups = [
        off for _index, off, node_type, *_rest in iter_nodes(data)
        if node_type == IORT_NODE_ITS_GROUP
    ]

    if len(its_groups) != 1:
        raise ValueError(f"expected exactly one ITS group node, found {len(its_groups)}")

    return its_groups[0]


def update_references_after_insert(data: bytearray, insert_off: int, delta: int) -> int:
    changed = 0

    for _index, off, node_type, _node_len, _node_rev, mappings, mapping_offset in iter_nodes(data):
        for mapping_index in range(mappings):
            mapping = off + mapping_offset + mapping_index * IORT_ID_MAPPING_LEN
            if mapping + IORT_ID_MAPPING_LEN > len(data):
                raise ValueError(f"IORT mapping {mapping_index} extends past table")
            output_ref = u32(data, mapping + 12)
            if output_ref >= insert_off:
                put_u32(data, mapping + 12, output_ref + delta)
                changed += 1

        if node_type == IORT_NODE_PMCG:
            node_ref_off = off + 24
            node_ref = u32(data, node_ref_off)
            if node_ref >= insert_off:
                put_u32(data, node_ref_off, node_ref + delta)
                changed += 1

    return changed


def mapping_tuple(data: bytearray, mapping: int) -> tuple[int, int, int, int, int]:
    return struct.unpack_from("<IIIII", data, mapping)


def pack_mapping(mapping: tuple[int, int, int, int, int]) -> bytes:
    return struct.pack("<IIIII", *mapping)


def insert_smmu_mappings(data: bytearray, off: int, insert_off: int, mappings: list[bytes]) -> None:
    delta = len(mappings) * IORT_ID_MAPPING_LEN

    update_references_after_insert(data, insert_off, delta)
    data[insert_off:insert_off] = b"".join(mappings)
    put_u32(data, 4, u32(data, 4) + delta)
    put_u16(data, off + 1, u16(data, off + 1) + delta)


def add_empty_smmu_msi_mappings(data: bytearray, off: int, node_len: int, its_ref: int) -> int:
    insert_off = off + node_len
    mapping_ref = its_ref + (2 * IORT_ID_MAPPING_LEN) if its_ref >= insert_off else its_ref
    special_mapping = pack_mapping((0, 0, 0, mapping_ref, IORT_ID_SINGLE_MAPPING))
    downstream_mapping = pack_mapping((0, SKY1_SMMU_DOWNSTREAM_MSI_ID_COUNT, 0, mapping_ref, 0))

    insert_smmu_mappings(data, off, insert_off, [special_mapping, downstream_mapping])
    put_u32(data, off + 8, 2)
    put_u32(data, off + 12, node_len)
    put_u32(data, off + 64, 0)

    return 2


def add_smmu_special_msi_mapping(data: bytearray, off: int, mapping_offset: int, its_ref: int) -> int:
    insert_off = off + mapping_offset
    mapping_ref = its_ref + IORT_ID_MAPPING_LEN if its_ref >= insert_off else its_ref
    special_mapping = pack_mapping((0, 0, 0, mapping_ref, IORT_ID_SINGLE_MAPPING))

    insert_smmu_mappings(data, off, insert_off, [special_mapping])
    put_u32(data, off + 8, u32(data, off + 8) + 1)
    put_u32(data, off + 64, 0)

    return 1


def smmu_has_downstream_msi_mapping(data: bytearray, off: int, mappings: int, mapping_offset: int, its_ref: int) -> bool:
    for mapping_index in range(mappings):
        mapping = off + mapping_offset + mapping_index * IORT_ID_MAPPING_LEN
        input_base, id_count, output_base, output_ref, flags = mapping_tuple(data, mapping)

        if flags & IORT_ID_SINGLE_MAPPING:
            continue
        if output_ref != its_ref:
            continue
        if input_base == 0 and output_base == 0 and id_count >= SKY1_SMMU_DOWNSTREAM_MSI_ID_COUNT:
            return True

    return False


def enable_sky1_smmu_msi_domains(data: bytearray) -> int:
    changed = 0
    found_bases = set()
    its_ref = find_single_its_group(data)

    for base in SKY1_SMMU_MSI_BASES:
        smmu_node = None
        for node in iter_nodes(data):
            _index, off, node_type, node_len, node_rev, mappings, mapping_offset = node
            if node_type == IORT_NODE_SMMU_V3 and u64(data, off + 16) == base:
                smmu_node = node
                break

        if smmu_node is None:
            continue

        index, off, _node_type, node_len, node_rev, mappings, mapping_offset = smmu_node
        found_bases.add(base)

        if mappings == 0:
            changed += add_empty_smmu_msi_mappings(data, off, node_len, its_ref)
            index, off, _node_type, node_len, node_rev, mappings, mapping_offset = next(
                node for node in iter_nodes(data)
                if node[2] == IORT_NODE_SMMU_V3 and u64(data, node[1] + 16) == base
            )

        if mappings == 0:
            raise ValueError(f"Sky1 SMMUv3 node at {base:#x} still has no ID mappings")

        id_mapping_index = u32(data, off + 64)
        if id_mapping_index >= mappings:
            raise ValueError(
                f"Sky1 SMMUv3 node at {base:#x} ID mapping index "
                f"{id_mapping_index} outside mapping count {mappings}"
            )
        mapping = off + mapping_offset + id_mapping_index * IORT_ID_MAPPING_LEN
        if mapping + IORT_ID_MAPPING_LEN > off + u16(data, off + 1):
            raise ValueError(f"Sky1 SMMUv3 node at {base:#x} mapping {id_mapping_index} extends past node {index}")
        output_ref = u32(data, mapping + 12)
        if output_ref >= len(data) or u8(data, output_ref) != IORT_NODE_ITS_GROUP:
            raise ValueError(f"Sky1 SMMUv3 node at {base:#x} ID mapping does not target an ITS group node")
        mapping_flags = u32(data, mapping + 16)
        if not (mapping_flags & IORT_ID_SINGLE_MAPPING):
            changed += add_smmu_special_msi_mapping(data, off, mapping_offset, its_ref)
            index, off, _node_type, node_len, node_rev, mappings, mapping_offset = next(
                node for node in iter_nodes(data)
                if node[2] == IORT_NODE_SMMU_V3 and u64(data, node[1] + 16) == base
            )
            id_mapping_index = u32(data, off + 64)
            mapping = off + mapping_offset + id_mapping_index * IORT_ID_MAPPING_LEN

        if not smmu_has_downstream_msi_mapping(data, off, mappings, mapping_offset, its_ref):
            raise ValueError(f"Sky1 SMMUv3 node at {base:#x} has no downstream ITS mapping for requester IDs")
        if node_rev < 5:
            put_u8(data, off + 3, 5)
            changed += 1
        flags = u32(data, off + 24)
        new_flags = flags | SMMU_V3_FLAG_DEVICEID_VALID
        if new_flags != flags:
            put_u32(data, off + 24, new_flags)
            changed += 1
        mapping_flags = u32(data, mapping + 16)
        new_mapping_flags = mapping_flags | IORT_ID_SINGLE_MAPPING
        if new_mapping_flags != mapping_flags:
            put_u32(data, mapping + 16, new_mapping_flags)
            changed += 1

    missing = sorted(set(SKY1_SMMU_MSI_BASES) - found_bases)
    if missing:
        raise ValueError(
            "Sky1 SMMUv3 node(s) were not found: "
            + ", ".join(f"{base:#x}" for base in missing)
        )

    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--httu", action="store_true", help="enable SMMUv3 hardware access/dirty-table updates")
    parser.add_argument("--msi", action="store_true", help="mark Sky1 SMMUv3 nodes as ITS/MSI-capable")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    if not args.httu and not args.msi:
        parser.error("at least one of --httu or --msi is required")

    data = bytearray(args.input.read_bytes())
    validate_header(data)

    changed = 0
    if args.httu:
        changed += enable_httu(data)
    if args.msi:
        changed += enable_sky1_smmu_msi_domains(data)
    if changed == 0:
        raise ValueError("requested IORT options did not change the table")

    bump_oem_revision(data)
    update_checksum(data)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(data)
    return 0


if __name__ == "__main__":
    sys.exit(main())
