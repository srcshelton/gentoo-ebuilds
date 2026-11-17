#!/usr/bin/env python3
"""Exercise the CI compiler wrapper without building a kernel."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


WRAPPER = Path(__file__).resolve().parent / "strict-iasl/iasl"


class StrictIaslTests(unittest.TestCase):
    def test_diagnostics(self):
        with tempfile.TemporaryDirectory(prefix="cix-iasl-test-") as directory:
            compiler = Path(directory) / "fake-iasl"
            compiler.write_text(
                "#!/bin/sh\n"
                'printf "%s\\n" "$TEST_OUTPUT" >&2\n'
                'exit "$TEST_STATUS"\n',
                encoding="utf-8",
            )
            compiler.chmod(0o755)
            for diagnostic, errors, warnings, remarks, compiler_status, expected in (
                ("", 0, 0, 0, 0, 0),
                ("Warning  3144 -  Method Local is set but never used", 0, 1, 0, 0, 1),
                ("Remark   2146 -  Method Argument is never used", 0, 0, 1, 0, 1),
                ("Error    6126 -  syntax error", 1, 0, 0, 1, 1),
                ("Error    6126 -  syntax error", 1, 0, 0, 0, 1),
                ("missing summary", 0, 0, 0, 0, 1),
            ):
                with self.subTest(diagnostic=diagnostic, compiler_status=compiler_status):
                    status = "failed" if errors else "successful"
                    summary = (
                        f"Compilation {status}. {errors} Errors, {warnings} Warnings, "
                        f"{remarks} Remarks, 0 Optimizations"
                    )
                    output = diagnostic
                    if diagnostic != "missing summary":
                        output += f"\n{summary}"
                    env = {
                        **os.environ, "CIX_REAL_IASL": str(compiler),
                        "TEST_OUTPUT": output, "TEST_STATUS": str(compiler_status),
                    }
                    result = subprocess.run(
                        [WRAPPER, "-p", "DSDT", "-tc", "fixture.asl"],
                        env=env, capture_output=True, text=True, check=False,
                    )
                    self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
                    self.assertIn(output, result.stdout)
                    if expected:
                        self.assertIn("fixture.asl", result.stderr)

    def test_version_query_passes_through(self):
        result = subprocess.run(
            [WRAPPER, "-v"], env={**os.environ, "CIX_REAL_IASL": "/bin/echo"},
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "-v\n")


if __name__ == "__main__":
    unittest.main()
