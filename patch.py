#!/usr/bin/env python3
"""
Mushihimesama Futari Arrange (Cave CV1000) - patch build 54

Usage:
    python3 patch.py futariblj.zip --god 435A07E3.zip         -> writes futariarr_u4 next to the zip
    python3 patch.py futariblj.zip --god 435A07E3.zip --zip   -> also writes futariarr.zip (u4 replaced by futariarr_u4)
    python3 patch.py futariblj.zip --god 435A07E3.zip --mra   -> also writes "Mushihimesama Futari Arrange.mra" (MiSTer)
    python3 patch.py futariblj.zip --god 435A07E3.zip -o OUT  -> writes the patched futariarr_u4 to OUT
    python3 patch.py u4 --god 435A07E3.zip                    -> a loose original u4 works too (no --zip)

--god is required: your own Xbox 360 Games-on-Demand package of Mushihimesama (title ID 435A07E3, .zip). The
ARRANGE MODE banner (アレンジモード) is cut from it.

The original u4 must have CRC32 b9467b6d; the patch is checked to be e95eca2c before the banner
picture (checked too) goes into the free tail; the finished futariarr_u4 is b030814e.
Only the Python standard library is used.
"""
import argparse, base64, os, re, struct, sys, zipfile, zlib

ORIG_CRC = 0xB9467B6D
PATCHED_CRC = 0xE95ECA2C        # u4 with the patch code, before the banner picture
FINAL_CRC = 0xB030814E          # finished futariarr_u4 with the banner from the 435A07E3 package
U4_SIZE = 0x200000
OUT_NAME = "futariarr_u4"
SET_NAME = "futariarr.zip"
MRA_NAME = "Mushihimesama Futari Arrange.mra"

# Patch blocks: (offset in the u4 file as stored in the MAME set, bytes)
PATCHES = [
    (0x1C4, base64.b64decode("H4AAgA==")),
    (0x1F8000, base64.b64decode(
    "BdEG0gbTFmACIgRyEEP6iwTQK0AJAAkAH4AogHysAAAAAP0CfAwAADPRAOACIQERMtFrkAEhMtEy"
    "0AIhNdE30AIhNdE20AIhNtE30AIhX5ASgTbRNtACITbRN9ACITfRPNACITzRPdACIT3RStACIVDH"
    "A2JJ0TrjJGAAIRBD+48BcVvHA2JG0YyTJGAAIRBD+48BcTfRPdACITfRPNACITbRPNACITbRONAC"
    "ITXRONACITXRN9ACISrRK9ACISDRRpABISDRIdACIR7RQZABISbRJ9ACITXRNdACITLRYpABIQXR"
    "AeACEQDgAxEPkAQRBdArQAkACQB7rAD/CawoIQmsOCF8DIgDAAwwKgPQeAAJAAkABqyAvAasiLx8"
    "DAQGfAxgBgeswGQS0CtAB6wMZXwMuAYJrKxRfAzgBwmsoFEGrGi3BqyCxwasvMcBAJ6GW9EO0XwM"
    "bAgGrGSbfAygCBCsjEUGrIAvfAzkCgmshCF8DAAFEKwERBCsCEQQrAxEEKxwRRCsdEUQrHhFfAyw"
    "CnwMngp8DDgKfAygBh2sSCgdrIQpwAEAyQmstCAFrFzEfAwQCyAgRiBUVVJBIElSQUFSR04gRTVC"
    "IDQgIAAAAAAgICAgICAgIDAyNjIxLi4xMDIgICAgICAgICAgICAJACAgVCBJSCBTUlBKT0NFIFRT"
    "SVUgT05GRkNJQUkgTAAAICBBIEROSSAgU09OIFRGQUlGSUxUQURFVyBUSSxIAAAgIEUgRE5ST0VT"
    "IERZQiAsUk9BIFRVT0hJUkVaIEQAACAgQiAgWUFDRVYgLkxBIExJUkhHU1RUICBPSFQgRQAAICBP"
    "IElSSUdBTiBMQUdFTUEgRE5JIFNUICAgICAgAAAgIEEgU1NDT0FJRVQgRE5JRVRMTENFVVRMQSAg"
    "ICAAACAgUCBPUkVQVFIgWUVSQU1OSVcgVEkgSEhUSUUgUgAAICBSIFNFRVBUQ1ZJIEVJUkhHU1RI"
    "IExPRURTUiAuAAAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAACAgICAgICAgSCBWQSBF"
    "VUYhTiEhICAgICAgICAgIAAAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAgICAgICAg"
    "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"
    "ABAAAACAOBVgAUAVYAEHAD8ADwCn/w==")),
]


# MiSTer MRA (the futariarr_u4 CRC is FINAL_CRC)
MRA_TEMPLATE = """<!--
  ikacore_CV1k MRA - Mushihimesama Futari Black Label Arrange.
  Same layout as the other CV1k arrange MRAs (DDR3-direct delivery).

  DELIVERY: the NAND and YMZ images do not stream over the ioctl/SPI
  lane.  Both roms carry an `address=` attribute, so Main_MiSTer
  assembles them and memcpys them straight into DDR3; the fabric sees
  only a download pulse for those two.  Only u4 streams, so the ioctl
  lane carries 4 MiB instead of the old 152 MiB.  Needs a Main_MiSTer
  that parses `address` (2021 or later).  Rationale and evidence:
  docs/mra_ddr3_direct_upload_plan.md.

  Rom order is deliberate - DDR3 first, index 0 LAST.  Index 0's download
  is what finally releases the CPU, so every image is in place before the
  core runs, and any spurious run in an inter-rom gap is wiped by the u4
  download's own reset hold.

    <rom index="1">  DDR3 0x34400000  u2  NAND dump incl. spare (132 MiB,
                                          exact size)
    <rom index="2">  DDR3 0x3C800000  u23 YMZ chip 0, zero-padded to the
                                          8 MiB slot
                     DDR3 0x3D000000  u24 YMZ chip 1, zero-padded to the
                                          8 MiB slot
    <rom index="0">  ioctl stream     u4  program NOR x2 (2 MiB file listed
                                          twice = the undecoded-A21 mirror
                                          the boot ROM expects)
-->
<misterromdescription>
    <about author="ika-musume" source="https://github.com/ika-musume/ikacore_CV1k"/>
    <name>Mushihimesama Futari Black Label Arrange</name>
    <setname>futariarr</setname>
    <year>2026</year>
    <manufacturer>Cave</manufacturer>
    <category>Shooter</category>
    <rbf>ikacore_CV1k</rbf>

    <rom index="1" address="0x34400000" zip="futariarr.zip" md5="none">
        <part name="futariblk_u2" crc="08c6fd62"/>
    </rom>

    <rom index="2" address="0x3C800000" zip="futariarr.zip" md5="none">
        <part name="u23" crc="39f1e1f4"/>
        <part repeat="0x400000">00</part>
        <part name="u24" crc="c631a766"/>
        <part repeat="0x400000">00</part>
    </rom>

    <nvram index="3" size="135680"/>

    <rom index="0" zip="futariarr.zip" md5="none">
        <part name="futariarr_u4" crc="b030814e"/>
        <part name="futariarr_u4" crc="b030814e"/>
    </rom>

    <buttons names="Focus Shot,Bomb,Rapid Shot,B4,Start,Coin,Test,Service,Save State" default="A,B,X,Y,Start,R,L,Select"/>
</misterromdescription>
"""


# ---------------------------------------------------------------- ARRANGE banner from the 360 GOD package
# アレンジモード is cut from the user's own Xbox 360 Mushihimesama GOD package (see .claude/god.md): disc image ->
# /res/DISKDATA/C/h20.bin (Cave archive) -> 0_00_B.tga (Cave LZSS) -> 16 x 122 px at 3153,2708 (sideways) ->
# halved with the 2x2 rule to 8 x 61 grey pixels. banner_picture() colours it like the game's "God Mode" label
# (red text, dark brown drop shadow) into a 16 x 64 picture: 'ARG2' + 12 zero bytes + 1024 big-endian ARGB1555
# words, row i along the text, column x across. It goes into the u4 at 0x1FF000 (src/banner.s). Integer-only, so
# index.html gives byte-identical results. No Cave art is stored in this file.
GOD_ID = "5F9DF6331EAE85814989"
GOD_PATH = ("res", "DISKDATA", "C", "h20.bin")
GOD_BLK, GOD_PER_FILE = 0x1000, 203 * 204
BANNER_OFF = 0x1FF000
BANNER_CRC = 0x4B1F2F16        # CRC32 of the 2064-byte picture from the owner's package (435A07E3.zip)


class _Stream:                 # forward-only reader over one zip member
    def __init__(self, z, name):
        self.z, self.name, self.fh, self.pos = z, name, None, 0

    def read_at(self, off, n):
        if self.fh is None or off < self.pos:
            self.fh, self.pos = self.z.open(self.name), 0
        while self.pos < off:
            k = len(self.fh.read(min(off - self.pos, 1 << 20)))
            if not k:
                raise ValueError("a GOD data file is shorter than expected")
            self.pos += k
        d = self.fh.read(n)
        self.pos += len(d)
        return d


def _god_disc(path):
    z = zipfile.ZipFile(path)
    rx = re.compile(r"(^|/)" + GOD_ID + r"\.data/Data(\d{4})$", re.I)
    names = [n for n in z.namelist() if rx.search(n.replace("\\", "/"))]
    names.sort(key=lambda n: int(rx.search(n.replace("\\", "/")).group(2)))
    if not names or not any(n.replace("\\", "/").split("/")[-1].upper() == GOD_ID for n in z.namelist()):
        raise ValueError("not the Mushihimesama GOD package (%s and %s.data not found)" % (GOD_ID, GOD_ID))
    streams = [_Stream(z, n) for n in names]

    def read(off, size):
        out = bytearray()
        while size > 0:
            block, inner = divmod(off, GOD_BLK)
            f, b = divmod(block, GOD_PER_FILE)
            group, k = divmod(b, 204)
            n = min(size, GOD_BLK - inner)
            if f >= len(streams):
                raise ValueError("the GOD package is missing data files")
            out += streams[f].read_at((1 + group * 205 + 1 + k) * GOD_BLK + inner, n)
            off += n
            size -= n
        return bytes(out)
    return read


def _god_find(read, path):
    if read(0x10000, 20) != b"MICROSOFT*XBOX*MEDIA":
        raise ValueError("no Xbox disc image in the GOD package")
    sec, size = struct.unpack("<II", read(0x10014, 8))
    for depth, name in enumerate(path):
        data, stack, hit = read(sec * 0x800, size), [0], None
        while stack:
            o = stack.pop()
            if o * 4 + 14 > len(data):
                continue
            l, r, s, sz, attr, nl = struct.unpack_from("<HHIIBB", data, o * 4)
            if l == 0xFFFF:
                continue
            if data[o * 4 + 14:o * 4 + 14 + nl].decode("latin-1").lower() == name.lower():
                hit = (s, sz, attr)
                break
            stack += [x for x in (l, r) if x]
        if hit is None or bool(hit[2] & 0x10) == (depth == len(path) - 1):
            raise ValueError("/".join(path) + " not found in the GOD package. Is it Mushihimesama?")
        sec, size = hit[0], hit[1]
    return sec, size


def _lzss(e, need):
    n, p = struct.unpack_from(">II", e, 4)
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
        raise ValueError("the sheet in the GOD package is shorter than expected")
    return out


def god_label(god_path):
    """8 x 64 grey アレンジモード label (64 rows of 8 ARGB1555 words) from the GOD package."""
    X0, Y0, L = 3153, 2708, 122
    read = _god_disc(god_path)
    sec, size = _god_find(read, GOD_PATH)
    arc = read(sec * 0x800, min(size, 0x10000))
    if struct.unpack_from(">I", arc, 0)[0] != 0xC0090117:
        raise ValueError("h20.bin in the GOD package is not a Cave archive")
    for k in range(struct.unpack_from(">I", arc, 12)[0]):
        o = 0x24 + k * 0x114
        esize, eoff = struct.unpack_from(">II", arc, o + 8)
        if arc[o + 16:o + 272].split(b"\0")[0].endswith(b"0_00_B.tga"):
            break
    else:
        raise ValueError("0_00_B.tga not in h20.bin")
    e = read(sec * 0x800 + eoff, esize)
    w, h, bpp, desc = struct.unpack_from("<HHBB", _lzss(e, 18), 12)
    if (w, h, bpp, desc & 15) != (4096, 4096, 16, 1):
        raise ValueError("unexpected sheet format in the GOD package")
    top = bool(desc & 0x20)
    t = _lzss(e, 18 + ((Y0 + L - 1 if top else 4095 - Y0) + 1) * w * 2)

    def px(x, y):
        return struct.unpack_from("<H", t, 18 + ((y if top else 4095 - y) * w + x) * 2)[0]
    rows = []
    for i in range(64):
        row = []
        for j in range(8):
            v = 0
            if i < L // 2:
                q = [px(X0 + 2 * j + b, Y0 + 2 * i + a) for a in (0, 1) for b in (0, 1)]
                op = [x for x in q if x & 0x8000]
                if len(op) >= 2:
                    g = sum((x >> 10) & 31 for x in op) // len(op)
                    v = 0x8000 | (g << 10) | (g << 5) | g
            row.append(v)
        rows.append(row)
    return rows


def banner_picture(label):
    """Colour the grey label like "God Mode": 16 x 64, text in columns 7-14, shadow one column lower, one row on."""
    pic = [[0] * 16 for _ in range(64)]
    shadow = 0x8000 | (12 << 10) | (6 << 5)
    for i in range(63):
        for j in range(8):
            if label[i][j] & 0x8000:
                pic[i + 1][j + 6] = shadow
    for i in range(64):
        for j in range(8):
            v = label[i][j]
            if v & 0x8000:
                t = max(0, min(17, ((v >> 10) & 31) - 14))
                r, g = 25 + t * 6 // 17, 2 + t * 9 // 17
                pic[i][j + 7] = 0x8000 | (r << 10) | (g << 5) | g
    return b"ARG2" + bytes(12) + b"".join(struct.pack(">H", v) for row in pic for v in row)


def find_u4(zf):
    for name in zf.namelist():
        if os.path.basename(name).lower() in ("futariblk_u4", "u4", OUT_NAME):
            return name
    return None


def apply_patch(data, picture=None):
    if len(data) != U4_SIZE:
        raise ValueError("u4 is %d bytes, expected %d" % (len(data), U4_SIZE))
    crc = zlib.crc32(data) & 0xFFFFFFFF
    if crc in (PATCHED_CRC, FINAL_CRC):
        raise ValueError("this u4 is already patched (CRC %08x)" % crc)
    if crc != ORIG_CRC:
        raise ValueError("u4 CRC is %08x, expected the original %08x" % (crc, ORIG_CRC))
    out = bytearray(data)
    for off, blob in PATCHES:
        out[off:off + len(blob)] = blob
    out = bytes(out)
    crc = zlib.crc32(out) & 0xFFFFFFFF
    if crc != PATCHED_CRC:
        raise ValueError("patched CRC is %08x, expected %08x" % (crc, PATCHED_CRC))
    if picture:                # big-endian words, stored byte-swapped like the rest of the u4
        sw = bytearray(picture)
        sw[0::2], sw[1::2] = picture[1::2], picture[0::2]
        if out[BANNER_OFF:BANNER_OFF + len(sw)] != b"\xff" * len(sw):
            raise ValueError("the banner area of the u4 is not empty")
        out = out[:BANNER_OFF] + bytes(sw) + out[BANNER_OFF + len(sw):]
    return out


def mra_text(crc=FINAL_CRC):
    return re.sub(r'(<part name="futariarr_u4" crc=")[0-9a-fA-F]{8}', lambda m: m.group(1) + "%08x" % crc, MRA_TEMPLATE)


def main():
    ap = argparse.ArgumentParser(description="Patch Mushihime-Sama Futari Black Label u4 into futariarr_u4 (Futari Arrange, build 54)")
    ap.add_argument("input", help="futariblj.zip or a loose original u4 file")
    ap.add_argument("-o", "--output", help="where to write futariarr_u4")
    ap.add_argument("--zip", action="store_true", help="also write futariarr.zip (input must be a zip)")
    ap.add_argument("--mra", action="store_true", help="also write the MiSTer .mra")
    ap.add_argument("--god", required=True, help="your own Xbox 360 Mushihimesama GOD package, title ID 435A07E3 (.zip): ARRANGE MODE banner")
    a = ap.parse_args()

    is_zip = zipfile.is_zipfile(a.input)
    if is_zip:
        with zipfile.ZipFile(a.input) as zf:
            name = find_u4(zf)
            if not name:
                sys.exit("error: no u4 inside %s" % a.input)
            data = zf.read(name)
    else:
        with open(a.input, "rb") as f:
            data = f.read()

    try:
        picture = banner_picture(god_label(a.god))
        pc = zlib.crc32(picture) & 0xFFFFFFFF
        print("banner from the GOD package: CRC %08x%s" % (pc, " OK" if pc == BANNER_CRC else ", expected %08x" % BANNER_CRC))
        if pc != BANNER_CRC:
            raise ValueError("the banner cut from the GOD package is not the expected picture")
        patched = apply_patch(data, picture)
    except (ValueError, zipfile.BadZipFile) as e:
        sys.exit("error: %s" % e)
    final_crc = zlib.crc32(patched) & 0xFFFFFFFF
    if final_crc != FINAL_CRC:
        sys.exit("error: futariarr_u4 came out with CRC %08x, expected %08x" % (final_crc, FINAL_CRC))

    folder = os.path.dirname(os.path.abspath(a.input))
    out = a.output or os.path.join(folder, OUT_NAME)
    with open(out, "wb") as f:
        f.write(patched)
    print("original u4 CRC %08x OK" % ORIG_CRC)
    print("wrote %s (CRC %08x)" % (out, final_crc))

    if a.zip:
        if not is_zip:
            sys.exit("error: --zip needs futariblj.zip as input")
        zout = os.path.join(folder, SET_NAME)
        with zipfile.ZipFile(a.input) as zi, zipfile.ZipFile(zout, "w", zipfile.ZIP_DEFLATED) as zo:
            for info in zi.infolist():
                if info.filename == name:
                    zo.writestr(OUT_NAME, patched)
                else:
                    zo.writestr(info.filename, zi.read(info.filename))
        print("wrote %s (u4 replaced by %s)" % (zout, OUT_NAME))
    if a.mra:
        mout = os.path.join(folder, MRA_NAME)
        with open(mout, "w", newline="\n") as f:
            f.write(mra_text(final_crc))
        print("wrote %s" % mout)
    print("Back up your original u4 before flashing real hardware.")


if __name__ == "__main__":
    main()
