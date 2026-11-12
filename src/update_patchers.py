"""Write the patchers and the MiSTer .mra from an original zip and a built zip.

    python3 update_patchers.py ORIGINAL_futariblj.zip PATCHED.zip [BUILD]

Embeds only the changed bytes (no ROM data) into futari_patch.py and index.html and fixes the CRC in
the .mra. Run once after every build.
BUILD is the number shown by the patchers ("Matches build N"). Left out (or "auto"), it keeps the number the
patchers already carry when the u4 CRC is unchanged and adds 1 when the CRC changed.
"""
import sys, os, re, zipfile, zlib, base64, json

orig_zip, new_zip = sys.argv[1], sys.argv[2]
build = sys.argv[3] if len(sys.argv) > 3 else 'auto'
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, '..')
o = zipfile.ZipFile(orig_zip).read('futariblk_u4')
p = zipfile.ZipFile(new_zip).read('futariarr_u4')
assert zlib.crc32(o) == 0xB9467B6D, 'original u4 CRC is not b9467b6d'
crc = zlib.crc32(p)
if build == 'auto':
    cur = open(os.path.join(root, 'futari_patch.py')).read()
    old_crc = int(re.search(r'PATCHED_CRC = 0x([0-9A-Fa-f]{8})', cur).group(1), 16)
    old_build = int(re.search(r'patch build (\d+)', cur).group(1))
    build = str(old_build if old_crc == crc else old_build + 1)
diff = [i for i in range(len(o)) if o[i] != p[i]]
assert all(0x1C4 <= i < 0x1C8 or 0x1F8000 <= i < 0x200000 for i in diff), 'unexpected changes'
end = (max(diff) + 4) // 4 * 4
b1 = base64.b64encode(p[0x1C4:0x1C8]).decode()
b2 = base64.b64encode(p[0x1F8000:end]).decode()
lines = '\n'.join('    "%s"' % b2[k:k + 76] for k in range(0, len(b2), 76))

py = os.path.join(root, 'futari_patch.py'); s = open(py).read()
s = re.sub(r'PATCHED_CRC = 0x[0-9A-Fa-f]{8}', 'PATCHED_CRC = 0x%08X' % crc, s)
s = re.sub(r'checked to be [0-9a-f]{8}', 'checked to be %08x' % crc, s)
s = re.sub(r'build \d+', 'build %s' % build, s)
s = re.sub(r'(<part name="futariarr_u4" crc=")[0-9a-f]{8}', lambda m: m.group(1) + '%08x' % crc, s)
i = s.index('PATCHES = ['); j = s.index(']', s.index('(0x1F8000', i))
s = s[:i] + 'PATCHES = [\n    (0x1C4, base64.b64decode("%s")),\n    (0x1F8000, base64.b64decode(\n%s)),\n' % (b1, lines) + s[j:]
open(py, 'w', newline='\n').write(s)

ht = os.path.join(root, 'index.html'); h = open(ht).read()
old = re.search(r'PATCHED_CRC = 0x([0-9a-f]{8})', h).group(1)
h = h.replace(old, '%08x' % crc)
h = re.sub(r'build \d+', 'build %s' % build, h)
h = re.sub(r'(<part name=\\"futariarr_u4\\" crc=\\")[0-9a-f]{8}', lambda m: m.group(1) + '%08x' % crc, h)  # embedded MRA
h = re.sub(r'\[0x1C4, "[^"]*"\]', '[0x1C4, "%s"]' % b1, h)
h = re.sub(r'\[0x1F8000, "[^"]*"\]', '[0x1F8000, "%s"]' % b2, h)
open(ht, 'w', newline='\n').write(h)

mra = os.path.join(root, 'mister', 'Mushihimesama Futari Arrange.mra'); m = open(mra).read()
m = re.sub(r'(<part name="futariarr_u4" crc=")[0-9a-f]{8}', lambda x: x.group(1) + '%08x' % crc, m)
open(mra, 'w', newline='\n').write(m)
print('build', build, 'u4 CRC %08x' % crc, '(%d bytes at 0x1F8000)' % (end - 0x1F8000))
