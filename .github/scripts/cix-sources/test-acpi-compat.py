#!/usr/bin/env python3
"""Check generated Orion profiles against AML extracted from stock releases.

Pass a prepared kernel tree and a stock directory containing
{board}/{release}/DSDT-SKY1EDK2.aml and SSDT-ORIONO6[N].aml.
Requires ACPICA acpiexec. Run with Python assertions enabled.
"""

import argparse
import re
import struct
import subprocess
import tempfile
from pathlib import Path

BOARDS = ("o6", "o6n")
RELEASES = ("1.2.4", "1.3.0", "1.3.1", "1.3.2")
PORTS = (r"\_SB.I2C1.PD10", r"\_SB.I2C1.PD11")
SETTINGS = (r"\_SB.SCMS", r"\_SB.GNVA", r"\_SB.GNVL")
STATUS = (r"\_SB.SCMI.DVFS._STA", r"\_SB.SCMI.CLKS._STA")
FAN_MODE = r"\_SB.ECFM"
GPU_CRIT = r"\_SB.TZGT._CRT"


def header(table):
    data = table.read_bytes()
    sig, size, _, _, oem, name, revision = struct.unpack_from("<4sIBB6s8sI", data)
    assert size == len(data) and sum(data) % 256 == 0, table
    return (sig, oem, name), revision


def stock_tables(root, board, release):
    directory = root / board / release
    dsdt = directory / "DSDT-SKY1EDK2.aml"
    ssdt = directory / f"SSDT-ORION{board.upper()}.aml"
    assert header(dsdt) == ((b"DSDT", b"CIXTEK", b"SKY1EDK2"), 1)
    assert header(ssdt) == (
        (b"SSDT", b"RADXA\0", f"ORION{board.upper()}".encode().ljust(8, b"\0")),
        1,
    )
    return dsdt, ssdt


def profile_tables(kernel, board, family, full):
    directory = kernel / "cix-acpi-table-upgrade" / board / family
    name = "initramfs-dsdt" if full else "initramfs"
    prefix = "/kernel/firmware/acpi/"
    tables = {}
    identities = set()
    for line in (directory / f"{name}.list").read_text().splitlines():
        if not line.startswith("file "):
            continue
        _, dest, source, mode, uid, gid = line.split()
        assert (mode, uid, gid) == ("0644", "0", "0"), line
        path = Path(source)
        assert dest == prefix + path.name and path.name not in tables, line
        assert path == directory / name / dest.lstrip("/"), line
        identity, _ = header(path)
        assert identity not in identities, (identity, line)
        identities.add(identity)
        tables[path.name] = path

    expected = {"S1AUD", "S1DMACLK", "S1DMAR"}
    if board == "o6":
        expected |= {"O6BPERF", "O6DSUP", "O6ECTZ", "O6RBRR", "O6RTS", "O6SCMI", "O6TZSNS"}
        if family == "1.2":
            expected.add("O6GCRT")
    else:
        expected |= {"O6NBPERF", "O6NDSUP", "O6NRBRR", "O6NSCMI"}
    if full:
        expected |= {"DSDT", "S1XHCSCT"}
        if board == "o6":
            expected.add("ORIONO6")
        if family == "1.2":
            expected |= {"PPTT", "IORT"}
            if re.search(r"^VERSION = 7$", (kernel / "Makefile").read_text(), re.M):
                expected.add("MPAM")
    assert set(tables) == {f"{item}.aml" for item in expected}, (directory, name, tables)
    return tables


def execute(tables, commands):
    result = subprocess.run(
        ["acpiexec", "-di", "-dt", "-b", "; ".join(commands), *map(str, tables)],
        check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        timeout=30,
    ).stdout
    assert "ACPI AML tables successfully acquired and loaded" in result, result
    assert "ACPI Error:" not in result and "ACPI BIOS Error" not in result, result
    return result


def evaluate(tables, paths):
    output = execute(tables, [f"evaluate {path}" for path in paths])
    results = re.findall(r"\[Integer\] = ([0-9A-F]+)", output)
    assert len(results) == len(paths), output
    return tuple(int(value, 16) for value in results)


def port_resources(tables, port, initialise=False):
    commands = [f"evaluate {port}._CRS"]
    if initialise:
        commands.insert(0, f"evaluate {port}._INI")
    output = execute(tables, commands)
    assert f"Evaluation of {port}._CRS returned object" in output, output
    rows = re.findall(r"^\s+[0-9A-F]{4}: ([0-9A-F ]+)\s+//", output, re.M)
    return bytes.fromhex(" ".join(rows))


def shared_rts(resources, address, shared):
    # ACPICA serial-bus and GPIO large resource descriptors. Preserve all
    # bytes except the GPIO descriptor's interrupt-sharing flag (bit 3).
    assert resources[0] == 0x8E and resources[5] == 1, resources.hex()
    assert not resources[6] & 4, resources.hex()
    assert struct.unpack_from("<H", resources, 16)[0] == address
    gpio = 3 + struct.unpack_from("<H", resources, 1)[0]
    assert resources[gpio] == 0x8C and resources[gpio + 4] == 0
    irq_flags = gpio + 7
    assert resources[irq_flags] == (0x0A if shared else 0x02), resources.hex()
    pins = gpio + struct.unpack_from("<H", resources, gpio + 14)[0]
    source = gpio + struct.unpack_from("<H", resources, gpio + 17)[0]
    assert resources[pins:source] == b"\x08\x00"
    assert resources[source:].startswith(b"\\_SB.GPI4\0")
    return resources[:irq_flags] + b"\x0a" + resources[irq_flags + 1:]


def simulate_ready_to_boot(source, target, replacements):
    data = bytearray(source.read_bytes())
    for name, (old, new) in replacements.items():
        marker = b"\x08" + name + old
        assert len(old) == len(new) and data.count(marker) == 1, (source, marker)
        index = data.index(marker) + 5
        data[index:index + len(old)] = new
    data[9] = 0
    data[9] = -sum(data) % 256
    target.write_bytes(data)
    return target


def check_profiles(kernel, stock):
    for board in BOARDS:
        profiles = {family: profile_tables(kernel, board, family, False)
                    for family in ("1.2", "1.3")}
        assert not (kernel / "cix-acpi-table-upgrade/o6n/1.3/initramfs-dsdt.list").exists()
        for release in RELEASES:
            family = release.rsplit(".", 1)[0]
            dsdt, ssdt = stock_tables(stock, board, release)
            overlays = list(profiles[family].values())
            base = [dsdt, ssdt]
            effective = base + overlays
            if board == "o6":
                for index, port in enumerate(PORTS):
                    before = port_resources(base, port)
                    expected = shared_rts(before, 0x30 + index, release == "1.3.2")
                    assert port_resources(effective, port, initialise=True) == expected
                assert evaluate(effective, [GPU_CRIT]) == (3712,)

            # Simulate the stock ReadyToBoot hooks before AML is loaded.
            # Stock ECFM is ZeroOp, so the firmware updater supports 0 and 1.
            with tempfile.TemporaryDirectory() as tmp:
                for value in (0, 1):
                    dsdt_live = simulate_ready_to_boot(dsdt, Path(tmp) / dsdt.name, {
                        b"SCMS": (b"\0", bytes([value])),
                        b"GNVA": (b"\x0c\xff\xff\xff\xff", b"\x0c\0\0\xf0\xfe"),
                        b"GNVL": (b"\x0b\x55\xaa", b"\x0b\x4d\0"),
                    })
                    ssdt_live = ssdt
                    paths = SETTINGS + STATUS
                    expected = (value, 0xFEF00000, 0x4D, 0xB * value, 0xB * value)
                    if board == "o6":
                        ssdt_live = simulate_ready_to_boot(ssdt, Path(tmp) / ssdt.name, {
                            b"ECFM": (b"\0", bytes([value])),
                        })
                        paths += (FAN_MODE,)
                        expected += (value,)
                    assert evaluate([dsdt_live, ssdt_live, *overlays], paths) == expected

            # Only compare the full payload to releases with a matching
            # baseline. 1.3.0 has different native DSDT and board resources.
            if family == "1.3" and (board == "o6n" or release == "1.3.0"):
                continue
            full = profile_tables(kernel, board, family, True)
            active = [full["DSDT.aml"], full.get("ORIONO6.aml", ssdt)]
            for stock_table, replacement in zip(base, active):
                old_id, old_rev = header(stock_table)
                new_id, new_rev = header(replacement)
                assert old_id == new_id and (new_rev > old_rev or stock_table == replacement)
            assert evaluate(active, SETTINGS + STATUS) == (1, 0xFFFE0000, 0x4D, 0xB, 0xB)
            full_overlays = [path for path in full.values()
                             if header(path)[0][0] == b"SSDT" and path not in active]
            if board == "o6":
                assert evaluate(active, [FAN_MODE]) == (0,)
                assert evaluate(active + full_overlays, [GPU_CRIT]) == (3712,)
                for index, port in enumerate(PORTS):
                    before = port_resources(active, port)
                    expected = shared_rts(before, 0x30 + index, family == "1.3")
                    assert port_resources(active + full_overlays, port, initialise=True) == expected
            else:
                execute(active + full_overlays, ["evaluate " + SETTINGS[0]])


def check_scmi_status_quirk(kernel):
    acpi = kernel / "drivers/acpi"
    quirk = (acpi / "sta_quirk.c").read_text()
    bus = (acpi / "bus.c").read_text()
    start = bus.index("int acpi_bus_get_status(")
    end = bus.index("\n}\n", start) + 3
    with tempfile.TemporaryDirectory() as tmp:
        scratch = Path(tmp)
        (scratch / "scmi-sta-under-test.c").write_text(
            "\n".join(line for line in quirk.splitlines() if not line.startswith("#include"))
            + "\n" + bus[start:end]
        )
        binary = scratch / "scmi-sta-test"
        subprocess.run(
            ["cc", "-std=c11", "-Wall", "-Wextra", "-Werror", "-I", tmp,
             str(Path(__file__).with_name("scmi-sta-test.c")), "-o", str(binary)],
            check=True,
        )
        subprocess.run([str(binary)], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kernel", type=Path)
    parser.add_argument("stock", type=Path)
    args = parser.parse_args()
    check_scmi_status_quirk(args.kernel.resolve())
    check_profiles(args.kernel.resolve(), args.stock.resolve())
    print("Orion AML profiles and simulated ReadyToBoot settings passed")


if __name__ == "__main__":
    main()
