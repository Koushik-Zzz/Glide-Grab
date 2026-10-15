"""Bundle production telemetry with lexical service mocks; never contacts Roblox.

With no argument, write the bundle for Studio Edit execution. An optional first
argument runs the bundle with an already installed official Luau CLI.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
module = (ROOT / "scripts/progression/EconomyTelemetry.lua").read_text(encoding="utf-8-sig")
tests = (ROOT / "tests/economy-telemetry.luau").read_text(encoding="utf-8-sig")
target = ROOT / "tmp/economy-telemetry-bundle.luau"
target.parent.mkdir(exist_ok=True)
target.write_text("local function createTelemetry(game, task, Enum, typeof)\n" + module + "\nend\n" + tests,
                  encoding="utf-8")
if len(sys.argv) > 1:
    subprocess.run([sys.argv[1], str(target)], cwd=ROOT, check=True)
else:
    print(target)
