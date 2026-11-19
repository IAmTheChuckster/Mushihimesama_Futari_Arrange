"""Write the patchers and the MiSTer .mra from an original zip and a built zip.

    python3 update_patchers.py ORIGINAL_futariblj.zip PATCHED.zip [BUILD] [--god 435A07E3.zip]

Embeds only the changed bytes (no ROM data) into patch.py and index.html and fixes the CRCs in them and in the
.mra. Run once after every build.
PATCHED_CRC is the u4 with the patch code only; FINAL_CRC is the finished futariarr_u4, with the アレンジモード
banner cut from the owner's GOD package (default: roms/435A07E3.zip; no Cave art is stored in the repo, only the
CRCs). The .mra, the download table and the README use FINAL_CRC.
BUILD is the number shown by the patchers ("Matches build N"); left out, it is read from src/BUILD, the same number
build.py puts on the boot screen ("auto" keeps the old number when the CRC is unchanged, else adds 1).
Raise src/BUILD by one before each new build.
"""
import sys, os, re, zipfile, zlib, base64

args = sys.argv[1:]
god = None
if '--god' in args:
    k = args.index('--god'); god = args[k + 1]; del args[k:k + 2]
orig_zip, new_zip = args[0], args[1]
build = args[2] if len(args) > 2 else open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'BUILD')).read().split()[0]
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, '..')
god = god or os.path.join(root, 'roms', '435A07E3.zip')
sys.path.insert(0, root)
import patch                                    # god_label / banner_picture / BANNER_OFF

o = zipfile.ZipFile(orig_zip).read('futariblk_u4')
p = zipfile.ZipFile(new_zip).read('futariarr_u4')
assert zlib.crc32(o) == 0xB9467B6D, 'original u4 CRC is not b9467b6d'
crc = zlib.crc32(p)
pic = patch.banner_picture(patch.god_label(god))
assert zlib.crc32(pic) == patch.BANNER_CRC, 'banner picture CRC %08x is not the expected %08x' % (zlib.crc32(pic), patch.BANNER_CRC)
sw = bytearray(pic); sw[0::2], sw[1::2] = pic[1::2], pic[0::2]
full = bytearray(p); assert full[patch.BANNER_OFF:patch.BANNER_OFF + len(sw)] == b'\xff' * len(sw), 'banner area not empty'
full[patch.BANNER_OFF:patch.BANNER_OFF + len(sw)] = sw
final = zlib.crc32(bytes(full))
if build == 'auto':
    cur = open(os.path.join(root, 'patch.py'), encoding='utf-8').read()
    old_crc = int(re.search(r'PATCHED_CRC = 0x([0-9A-Fa-f]{8})', cur).group(1), 16)
    old_build = int(re.search(r'patch build (\d+)', cur).group(1))
    build = str(old_build if old_crc == crc else old_build + 1)
diff = [i for i in range(len(o)) if o[i] != p[i]]
assert all(0x1C4 <= i < 0x1C8 or 0x1F8000 <= i < patch.BANNER_OFF for i in diff), 'unexpected changes'
end = (max(diff) + 4) // 4 * 4
b1 = base64.b64encode(p[0x1C4:0x1C8]).decode()
b2 = base64.b64encode(p[0x1F8000:end]).decode()
lines = '\n'.join('    "%s"' % b2[k:k + 76] for k in range(0, len(b2), 76))
part = lambda t, c: re.sub(r'(<part name=\\?"futariarr_u4\\?" crc=\\?")[0-9a-f]{8}', lambda m: m.group(1) + '%08x' % c, t)

py = os.path.join(root, 'patch.py'); s = open(py, encoding='utf-8').read()
s = re.sub(r'PATCHED_CRC = 0x[0-9A-Fa-f]{8}', 'PATCHED_CRC = 0x%08X' % crc, s)
s = re.sub(r'FINAL_CRC = 0x[0-9A-Fa-f]{8}', 'FINAL_CRC = 0x%08X' % final, s)
s = re.sub(r'checked to be [0-9a-f]{8}', 'checked to be %08x' % crc, s)
s = re.sub(r'futariarr_u4 is [0-9a-f]{8}', 'futariarr_u4 is %08x' % final, s)
s = re.sub(r'build \d+', 'build %s' % build, s)
s = part(s, final)
i = s.index('PATCHES = ['); j = s.index(']', s.index('(0x1F8000', i))
s = s[:i] + 'PATCHES = [\n    (0x1C4, base64.b64decode("%s")),\n    (0x1F8000, base64.b64decode(\n%s)),\n' % (b1, lines) + s[j:]
open(py, 'w', newline='\n', encoding='utf-8').write(s)

ht = os.path.join(root, 'index.html'); h = open(ht, encoding='utf-8').read()
h = re.sub(r'PATCHED_CRC = 0x[0-9a-f]{8}', 'PATCHED_CRC = 0x%08x' % crc, h)
h = re.sub(r'FINAL_CRC = 0x[0-9a-f]{8}', 'FINAL_CRC = 0x%08x' % final, h)
h = re.sub(r'<td class="mono">[0-9a-f]{8}</td><td class="mono" id="outcrc">', '<td class="mono">%08x</td><td class="mono" id="outcrc">' % final, h)
h = re.sub(r'build \d+', 'build %s' % build, h)
h = part(h, final)
h = re.sub(r'\[0x1C4, "[^"]*"\]', '[0x1C4, "%s"]' % b1, h)
h = re.sub(r'\[0x1F8000, "[^"]*"\]', '[0x1F8000, "%s"]' % b2, h)
open(ht, 'w', newline='\n', encoding='utf-8').write(h)

mra = os.path.join(root, 'mister', 'Mushihimesama Futari Arrange.mra'); m = open(mra, encoding='utf-8').read()
open(mra, 'w', newline='\n', encoding='utf-8').write(part(m, final))
print('build', build, 'patch CRC %08x, futariarr_u4 with banner %08x' % (crc, final), '(%d bytes at 0x1F8000)' % (end - 0x1F8000))
