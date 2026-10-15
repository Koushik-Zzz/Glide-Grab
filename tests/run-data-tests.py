"""Bundle pure production modules for the official Luau CLI; only service imports are injected."""
from pathlib import Path
import subprocess
import sys
ROOT = Path(__file__).resolve().parent.parent
def source(path): return (ROOT / path).read_text(encoding='utf-8-sig')
pieces = ['local guid = 0\nlocal HttpService = {GenerateGUID = function() guid += 1 return string.format("%08d-0000-0000-0000-000000000000", guid) end}\n']
config = source('scripts/collection/Config.lua')
rolls = source('scripts/collection/Rolls.lua').replace('local HttpService = game:GetService("HttpService")', '').replace('local Config = require(script.Parent.Config)', '')
schema = source('scripts/data/Schema.lua').replace('local Rolls = require(script.Parent.Parent.CollectionModules.Rolls)', '')
session = source('scripts/data/Session.lua').replace('local Schema = require(script.Parent.Schema)', '')
for name, body in [('Config', config), ('Rolls', rolls), ('Schema', schema), ('Session', session)]:
    pieces.append(f'local {name} = (function()\n{body}\nend)()\n')
pieces.append(source('tests/data-session.luau'))
target = ROOT / 'tmp/data-session-bundle.luau'
target.write_text(''.join(pieces), encoding='utf-8')
subprocess.run([sys.argv[1], str(target)], cwd=ROOT, check=True)
