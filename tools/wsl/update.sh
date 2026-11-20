#!/bin/bash
# After a tested build (tools/wsl/build.sh), update the patchers and check them (run inside WSL):
#   bash tools/wsl/update.sh
# Runs src/update_patchers.py (patch.py, index.html, mister/*.mra; build number from src/BUILD), then runs
# patch.py --god into ~/mame/work/verify and checks that both patchers give exactly the tested u4.
set -e
R=$(cd "$(dirname "$0")/../.." && pwd)
M=$HOME/mame
python3 "$R/src/update_patchers.py" "$M/roms/futariblj.zip" "$M/work/futariarr_new.zip"
W=$M/work/verify; mkdir -p "$W"; cd "$W"
cp "$M/roms/futariblj.zip" .
python3 -I "$R/patch.py" futariblj.zip --god "$R/roms/435A07E3.zip" --zip --mra
python3 -I - "$R" <<'EOF'
import sys, re, zipfile, zlib, base64, os
R = sys.argv[1]
tested = zipfile.ZipFile(os.path.expanduser('~/mame/roms_arr/futariblj.zip')).read('futariblk_u4')
u4 = zipfile.ZipFile('futariarr.zip').read('futariarr_u4')
print('patch.py   %08x  same as the tested u4: %s' % (zlib.crc32(u4), u4 == tested))
built = zipfile.ZipFile(os.path.expanduser('~/mame/work/futariarr_new.zip')).read('futariarr_u4')
h = open(os.path.join(R, 'index.html'), encoding='utf-8').read()
p = bytearray(zipfile.ZipFile('futariblj.zip').read('futariblk_u4'))
a = base64.b64decode(re.search(r'\[0x1C4, "([^"]*)"\]', h).group(1)); b = base64.b64decode(re.search(r'\[0x1F8000, "([^"]*)"\]', h).group(1))
p[0x1C4:0x1C4 + len(a)] = a; p[0x1F8000:0x1F8000 + len(b)] = b
print('index.html %08x  same as the build (before the banner): %s' % (zlib.crc32(bytes(p)), bytes(p) == built))
EOF
find "$R" -name __pycache__ -type d -prune -exec rm -r {} +
