#!/usr/bin/env python3
"""Compile all Luau, exercise the shared economy and build a Studio place."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from bake_map import bake

root = Path(__file__).resolve().parents[1]
def tool(name, folder):
    override = os.environ.get(name.upper().replace('-', '_') + '_BIN')
    candidate = override or shutil.which(name) or f'/workspace/tools/{folder}/{name}'
    if not Path(candidate).is_file():
        raise SystemExit(f'{name} missing: run bash tools/bootstrap.sh or set its *_BIN variable')
    return candidate

compiler = tool('luau-compile', 'luau')
files = sorted(root.glob('**/*.luau'))
for file in files:
    result = subprocess.run([compiler, str(file)], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if result.returncode:
        raise SystemExit(result.stderr.decode(errors='replace'))
print(f'PASS: {len(files)} Luau files compile', flush=True)
subprocess.run([tool('luau', 'luau'), str(root / 'tests/economy.spec.luau')], check=True)
subprocess.run([sys.executable, str(root / 'tests/studio_startup.py'), tool('luau', 'luau')], check=True)
subprocess.run([sys.executable, str(root / 'tests/gameplay.py'), tool('luau', 'luau')], check=True)
output = root / 'UniverseMiner.rbxlx'
subprocess.run([tool('rojo', 'rojo'), 'build', str(root / 'default.project.json'), '-o', str(output)], check=True)
bake(output, tool('luau', 'luau'), tool('rojo', 'rojo'))
place = ET.parse(output)
classes = [x.attrib.get('class') for x in place.iter('Item')]
assert classes.count('Script') == 1 and classes.count('LocalScript') == 1
assert classes.count('ModuleScript') == 12
print('PASS: place includes the server, client and 12 modules')
