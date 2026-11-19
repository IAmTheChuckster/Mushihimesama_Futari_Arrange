# Extracting アレンジモード from the Xbox 360 GOD package

How to cut the アレンジモード (Arrange Mode) label out of the owner's own Xbox 360 **Mushihimesama**
Games-on-Demand package and turn it into the arcade-sized picture the Mushihimesama Matsuri Arrange patch
uploads to VRAM. Everything here was worked out and verified in the Mushihimesama Matsuri Arrange project
(`patch.py` `banner_glyph()`, `index.html` `buildGlyph()`); the script at the end is a standalone copy.

**Never ship the result.** The picture is Cave art: cut it from the user's own package at patch time, keep it
out of git, the patchers and any release (`roms/`, `.images/` and `*.zip` are git-ignored in the project).

## Result

- 8 x 64 pixels, ARGB1555, **stored sideways** like all CV1000 VRAM art (64 rows along the text, 8 columns
  across it). Rotate 90 degrees counter-clockwise to read it upright (64 wide x 8 tall).
- Packed for the patch as 1040 bytes: `ARG1` + 12 zero bytes + 512 big-endian 16-bit words, row by row
  (row i = 0..63 along the text, column j = 0..7 across).
- Check values from the owner's package (`435A07E3.zip`): 166 opaque pixels, CRC32 of the 1040-byte block
  `e58f8581`, CRC32 of the 1024 pixel bytes `e0bf898e`. Takes about a second.

## The chain

```
GOD zip/7z (any name, any folder)
 └ 5F9DF6331EAE85814989            STFS/LIVE header (only checked for presence)
 └ 5F9DF6331EAE85814989.data/Data0000, Data0001, Data0002   the disc image, wrapped in hash blocks
     └ XDVDFS disc image
         └ /res/DISKDATA/C/h20.bin  Cave "CA" archive (4 entries)
             └ .\0_00_B.tga         entry 0, Cave LZSS compressed
                 └ 4096x4096 TGA, ARGB1555, bottom-up
                     └ アレンジモード at x 3153-3168, y 2708-2829 (sideways)
                         └ halved with the 2x2 rule -> 8 x 61 px inside an 8 x 64 picture
```

The title ID of the package is 435A07E3. (Don't confuse it with DoDonPachi SaiDaiOuJou, 435A07E7, which uses
a different file layout: `CA0220xx.bin` archives.)

## 1. Data files -> disc image

Each `DataNNNN` file is made of 0x1000-byte blocks: block 0 is a master hash block, then 203 groups of
(1 sub-hash block + 204 data blocks). Only data blocks belong to the image. Image block `n` lives at

```
file  = n // (203 * 204)
b     = n %  (203 * 204)
group, inner = divmod(b, 204)
offset in that DataNNNN = (1 + group * 205 + 1 + inner) * 0x1000
```

Zip members are deflated: read them as forward streams and reopen when a read goes backwards (all reads below
go forward, so each file is streamed once).

## 2. XDVDFS

- Volume descriptor at image offset 0x10000: the 20 bytes `MICROSOFT*XBOX*MEDIA`, then the root directory
  sector (u32 LE) and size (u32 LE). Sectors are 0x800 bytes. For this package the descriptor is at base 0.
- A directory is a binary tree of 4-byte-aligned entries: `left u16, right u16` (in 4-byte units),
  `sector u32, size u32, attributes u8, name length u8, name`. `left == 0xFFFF` means empty. Attribute bit 0x10
  marks a subdirectory: read its sector/size and walk it the same way. Names compare case-insensitively.
- Walk `res` -> `DISKDATA` -> `C` -> `h20.bin`.

Useful listing: `/res/DISKDATA/A` system sheets (`sys360.bin`: fonts and menu art), `B` sound and voices
(`mv.bin` holds the voices, e.g. `yatta4`), `C` (`h01-h20.bin`) and `D` (`c01-c20.bin`) the sprite sheets.

## 3. Cave CA archive (h20.bin)

Big-endian header: magic `0xC0090117`, total size, data start, entry count. Entry table at 0x24, stride
0x114: `+8 size (u32 BE)`, `+12 offset from the archive start (u32 BE)`, `+16 name (ASCII, NUL-terminated)`.
h20.bin entries: `.\0_00_B.tga` (offset 0x474, 14,865,364 bytes), `.\laser00_B.tga`, `.\dl01_02_B.tga`,
`.\mb3g18_B.tga`. Find the entry by name ending in `0_00_B.tga`.

## 4. Cave LZSS

```
+0   u32 BE 0x00080012
+4   u32 BE token count N
+8   u32 BE offset T of the token data
+12  flag bits, MSB first: 1 = copy, 0 = literal
```

A literal is one byte from the token data. A copy is a big-endian u16 `v` from the token data: length
`(v & 0x1F) + 3`, distance `v >> 5`, copied byte by byte (overlaps allowed). You only need to decompress until
the rows you want (about 11.4 MB of the 32 MB output).

## 5. The sheet

TGA header (18 bytes, little-endian): width 4096 at +12, height 4096 at +14, bpp 16 at +16, descriptor at +17.
Descriptor low 4 bits = 1 means ARGB1555 (bit 15 = opaque); bit 0x20 clear means rows are stored bottom-up, so
picture row y is file row `4095 - y`. Pixel (x, y) = little-endian u16 at `18 + (row * 4096 + x) * 2`.

The opaque pixels of the label are greys (red 14-31 of 31; R = G = B). The sheet is the 360's 2x version of
the arcade sheet, also stored sideways. アレンジモード sits on the same line as オリジナルモード, after it:

- source rectangle: **x 3153..3168 (16 px, across the text), y 2708..2829 (122 px, along the text)**
- neighbours: the column of mode names (マニアックモード, ウルトラモード, ORIGINAL, MANIAC, ULTRA,
  ARRANGE) beside the DEMONSTRATION text, at about x 3100-3180, y 2600-2900.

## 6. Halving (the 2x2 rule)

For output row i (0..60) and column j (0..7) take the four source pixels
`(3153 + 2j + b, 2708 + 2i + a)`, a, b in {0, 1}:
- opaque when 2 or more of the 4 are opaque, otherwise transparent (0);
- grey = integer average of the red channel of the opaque ones; word = `0x8000 | g<<10 | g<<5 | g`.

Rows 61..63 stay transparent. The rule is integer-only on purpose, so a Python and a JavaScript patcher give
byte-identical results (and the same patched-u4 CRC). Threshold 1 gives a heavier label (209 opaque pixels),
threshold 2 is closest to the arcade's own ウルトラモード (148).

## 7. How the patch uses it (Mushihimesama Matsuri Arrange)

- Stored in the u4 at natural offset `0x1FF000` (CPU `0xA01FF000`); the u4 file stores 16-bit words
  byte-swapped, so the patchers write each word low byte first (`ARG1` becomes `RA1G` in the file).
- The arcade's ウルトラモード label is VRAM 1304-1311 x 768-831 (8 x 64, sideways); the free spot used for
  アレンジモード is 1320-1327 x 840-903, right after オリジナルモード, the same place the 360 sheet puts it.
- Blitter upload op: `2000 0000 9999 9999 x y w-1 h-1` then the w*h pixels. Upload widths must be a multiple
  of 8 (the MiSTer core froze on other widths), which 8 x 64 satisfies.

## Standalone script

Python 3 standard library only; reads a GOD **.zip** (for .7z use the readers in the project's `patch.py`,
copied from the Muchi Muchi Pork! patcher). Writes the 1040-byte block and, with `--png`, an upright preview
enlarged 4x.

```python
#!/usr/bin/env python3
"""extract_arrange.py GOD.zip OUT.bin [--png preview.png]  -> アレンジモード picture (see god.md)"""
import re, struct, sys, zipfile, zlib

GOD_ID = '5F9DF6331EAE85814989'
PATH = ('res', 'DISKDATA', 'C', 'h20.bin')
X0, Y0, W, L = 3153, 2708, 16, 122           # source rectangle in 0_00_B.tga (sideways)
BLK, PER_FILE = 0x1000, 203 * 204


class Stream:                                 # forward-only reader over one zip member
    def __init__(self, z, name):
        self.z, self.name, self.fh, self.pos = z, name, None, 0

    def read_at(self, off, n):
        if self.fh is None or off < self.pos:
            self.fh, self.pos = self.z.open(self.name), 0
        while self.pos < off:
            k = len(self.fh.read(min(off - self.pos, 1 << 20)))
            if not k:
                raise ValueError('a GOD data file is shorter than expected')
            self.pos += k
        d = self.fh.read(n)
        self.pos += len(d)
        return d


def open_disc(path):
    z = zipfile.ZipFile(path)
    rx = re.compile(r'(^|/)' + GOD_ID + r'\.data/Data(\d{4})$', re.I)
    names = [n for n in z.namelist() if rx.search(n.replace('\\', '/'))]
    names.sort(key=lambda n: int(rx.search(n.replace('\\', '/')).group(2)))
    if not names or not any(n.replace('\\', '/').split('/')[-1].upper() == GOD_ID for n in z.namelist()):
        raise ValueError('not the Mushihimesama GOD package (%s and %s.data not found)' % (GOD_ID, GOD_ID))
    streams = [Stream(z, n) for n in names]

    def read(off, size):
        out = bytearray()
        while size > 0:
            block, inner = divmod(off, BLK)
            f, b = divmod(block, PER_FILE)
            group, k = divmod(b, 204)
            n = min(size, BLK - inner)
            out += streams[f].read_at((1 + group * 205 + 1 + k) * BLK + inner, n)
            off += n
            size -= n
        return bytes(out)
    return read


def find(read, path):
    if read(0x10000, 20) != b'MICROSOFT*XBOX*MEDIA':
        raise ValueError('no Xbox disc image in the package')
    sec, size = struct.unpack('<II', read(0x10014, 8))
    for depth, name in enumerate(path):
        data, stack, hit = read(sec * 0x800, size), [0], None
        while stack:
            o = stack.pop()
            if o * 4 + 14 > len(data):
                continue
            l, r, s, sz, attr, nl = struct.unpack_from('<HHIIBB', data, o * 4)
            if l == 0xFFFF:
                continue
            if data[o * 4 + 14:o * 4 + 14 + nl].decode('latin-1').lower() == name.lower():
                hit = (s, sz, attr)
                break
            stack += [x for x in (l, r) if x]
        if hit is None or bool(hit[2] & 0x10) == (depth == len(path) - 1):
            raise ValueError('/'.join(path) + ' not found')
        sec, size = hit[0], hit[1]
    return sec, size


def lzss(e, need):
    n, p = struct.unpack_from('>II', e, 4)
    out = bytearray()
    for i in range(n):
        if len(out) >= need:
            break
        if (e[12 + (i >> 3)] >> (7 - (i & 7))) & 1:
            v = (e[p] << 8) | e[p + 1]
            p += 2
            d, k = v >> 5, (v & 31) + 3
            if d >= k:
                out += out[len(out) - d:len(out) - d + k]
            else:
                for _ in range(k):
                    out.append(out[-d])
        else:
            out.append(e[p])
            p += 1
    if len(out) < need:
        raise ValueError('sheet shorter than expected')
    return out


def arrange_glyph(god_path):
    read = open_disc(god_path)
    sec, size = find(read, PATH)
    arc = read(sec * 0x800, min(size, 0x10000))
    if struct.unpack_from('>I', arc, 0)[0] != 0xC0090117:
        raise ValueError('h20.bin is not a Cave archive')
    for k in range(struct.unpack_from('>I', arc, 12)[0]):
        o = 0x24 + k * 0x114
        esize, eoff = struct.unpack_from('>II', arc, o + 8)
        if arc[o + 16:o + 272].split(b'\0')[0].endswith(b'0_00_B.tga'):
            break
    else:
        raise ValueError('0_00_B.tga not in h20.bin')
    e = read(sec * 0x800 + eoff, esize)
    w, h, bpp, desc = struct.unpack_from('<HHBB', lzss(e, 18), 12)
    if (w, h, bpp, desc & 15) != (4096, 4096, 16, 1):
        raise ValueError('unexpected sheet format')
    top = bool(desc & 0x20)
    t = lzss(e, 18 + ((Y0 + L - 1 if top else 4095 - Y0) + 1) * w * 2)

    def px(x, y):
        return struct.unpack_from('<H', t, 18 + ((y if top else 4095 - y) * w + x) * 2)[0]
    out = bytearray(b'ARG1' + bytes(12))
    for i in range(64):
        for j in range(8):
            v = 0
            if i < L // 2:
                q = [px(X0 + 2 * j + b, Y0 + 2 * i + a) for a in (0, 1) for b in (0, 1)]
                op = [x for x in q if x & 0x8000]
                if len(op) >= 2:
                    g = sum((x >> 10) & 31 for x in op) // len(op)
                    v = 0x8000 | (g << 10) | (g << 5) | g
            out += struct.pack('>H', v)
    return bytes(out)


def write_png(path, glyph, scale=4):       # upright preview (64 x 8), opaque grey on dark
    words = struct.unpack('>512H', glyph[16:])
    rows = []
    for y in range(8 * scale):
        line = bytearray(b'\0')
        for x in range(64 * scale):
            v = words[(x // scale) * 8 + (7 - y // scale)]     # rotate 90 degrees counter-clockwise
            g = ((v >> 10) & 31) * 8 if v & 0x8000 else 40
            line += bytes((g, g, g))
        rows.append(bytes(line))
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 64 * scale, 8 * scale, 8, 2, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(b''.join(rows))) + chunk(b'IEND', b'')
    open(path, 'wb').write(png)


if __name__ == '__main__':
    g = arrange_glyph(sys.argv[1])
    open(sys.argv[2], 'wb').write(g)
    print('opaque %d, crc32 %08x (expected 166, e58f8581)'
          % (sum(1 for v in struct.unpack('>512H', g[16:]) if v & 0x8000), zlib.crc32(g)))
    if '--png' in sys.argv:
        write_png(sys.argv[sys.argv.index('--png') + 1], g)
```
