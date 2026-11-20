#!/bin/bash
# Build the patch from src/ and install a MAME test set (run inside WSL):
#   bash tools/wsl/build.sh
# Needs ~/mame (MAME 0.289 test env) with your own futariblj.zip in ~/mame/roms, and roms/435A07E3.zip (your own
# 360 GOD package) in the repo. Writes ~/mame/work/futariarr_new.zip (build.py output) and
# ~/mame/roms_arr/futariblj.zip: the patched u4 under the original name, with the ARRANGE banner picture added,
# so `GAME=futariblj ROMPATH=$HOME/mame/roms_arr` runs it. Nothing is written to the repo's roms/.
set -e
R=$(cd "$(dirname "$0")/../.." && pwd)
M=$HOME/mame
mkdir -p "$M/work/s" "$M/roms_arr"
cp "$R"/tools/mame/futari_harness.lua "$M/lua/"
cp "$R"/tools/mame/schedules/*.txt "$M/work/s/"
grep -q 'HARNESS:-' "$M/scripts/run.sh" || sed -i 's#-autoboot_script lua/harness.lua#-autoboot_script ${HARNESS:-lua/harness.lua}#' "$M/scripts/run.sh"
cd "$M/work"
python3 "$R/src/build.py" "$M/roms/futariblj.zip" "$M/work/futariarr_new.zip"
python3 - "$R" <<'EOF'
import os, sys, zipfile, zlib
R = sys.argv[1]; sys.path.insert(0, R)
import patch
pic = patch.banner_picture(patch.god_label(os.path.join(R, 'roms', '435A07E3.zip')))
sw = bytearray(pic); sw[0::2], sw[1::2] = pic[1::2], pic[0::2]
s = zipfile.ZipFile(os.path.expanduser('~/mame/work/futariarr_new.zip'))
u4 = bytearray(s.read('futariarr_u4')); u4[patch.BANNER_OFF:patch.BANNER_OFF + len(sw)] = sw
o = zipfile.ZipFile(os.path.expanduser('~/mame/roms_arr/futariblj.zip'), 'w', zipfile.ZIP_STORED)
for n in ('futariblk_u2', 'u23', 'u24'):
    o.writestr(n, s.read(n))
o.writestr('futariblk_u4', bytes(u4)); o.close()
print('test set ~/mame/roms_arr/futariblj.zip, u4 with banner %08x' % zlib.crc32(bytes(u4)))
EOF
find "$R" -name __pycache__ -type d -prune -exec rm -r {} +
