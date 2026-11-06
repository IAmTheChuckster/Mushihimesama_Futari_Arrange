#!/usr/bin/env python3
"""
Mushihimesama Futari Arrange (Cave CV1000) - patch build 1

Usage:
    python3 futari_patch.py futariblj.zip              -> writes futariarr_u4 next to the zip
    python3 futari_patch.py futariblj.zip --zip        -> also writes futariarr.zip (the set with u4 replaced by futariarr_u4)
    python3 futari_patch.py futariblj.zip --mra        -> also writes "Mushihimesama Futari Arrange.mra" (MiSTer)
    python3 futari_patch.py futariblj.zip -o OUT       -> writes the patched futariarr_u4 to OUT
    python3 futari_patch.py u4                      -> a loose original u4 works too (no --zip)

The original u4 must have CRC32 b9467b6d; the result is checked to be 58eb6923.
Only the Python standard library is used.
"""
import argparse, base64, os, sys, zipfile, zlib

ORIG_CRC = 0xB9467B6D
PATCHED_CRC = 0x58EB6923
U4_SIZE = 0x200000
OUT_NAME = "futariarr_u4"
SET_NAME = "futariarr.zip"
MRA_NAME = "Mushihimesama Futari Arrange.mra"

# Patch blocks: (offset in the u4 file as stored in the MAME set, bytes)
PATCHES = [
    (0x1C4, base64.b64decode("H4AAgA==")),
    (0x1F8000, base64.b64decode(
    "BdEG0gbTFmACIgRyEEP6iwTQK0AJAAkAH4AogHysAAAAAMEBfAwAAB7RAOACIQERHdFBkAEhHdEd"
    "0AIhINEi0AIhINEh0AIhIdEi0AIhNZASgSHRIdACISHRItACISLRItACISLRI9ACISbHA2Ii0Trj"
    "JGAAIRBD+48BcTDHA2Ie0T2TJGAAIRBD+48BcQXRAeACEQDgAxEPkAQRBdArQAkACQB7rAD/Cawo"
    "IQmsOCF8DNgCAAwwKgPQeAAJAAkABqyAvAasiLx8DOwDfAwUBAeswGQS0CtAB6wMZXwMXAQJrKxR"
    "fAyEBQasZJt8DNIFEKyMRXwMRAQdrEgoHayEKcABCQAgICAgRiBUVVJBIElSQUFSR04gRSAgICAA"
    "AAAAICAgICAgICAgIDAyNjIxLi4xIDYgICAgICAgICAgCQAgIFQgSUggU1JQSk9DRSBUU0lVIE9O"
    "RkZDSUFJIEwAACAgQSBETkkgIFNPTiBURkFJRklMVEFERVcgVEksSAAAICBFIEROUk9FUyBEWUIg"
    "LFJPQSBUVU9ISVJFWiBEAAAgIEIgIFlBQ0VWIC5MQSBMSVJIR1NUVCAgT0hUIEUAACAgTyBJUklH"
    "QU4gTEFHRU1BIEROSSBTVCAgICAgIAAAICBBIFNTQ09BSUVUIEROSUVUTExDRVVUTEEgICAgAAAg"
    "IFAgT1JFUFRSIFlFUkFNTklXIFRJIEhIVElFIFIAACAgUiBTRUVQVENWSSBFSVJIR1NUSCBMT0VE"
    "U1IgLgAAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAgICAgICAgIEggVkEgRVVGIU4h"
    "ISAgICAgICAgICAAACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAICAgICAgICAgICAg"
    "ICAgICAgICAgICAgICAgICAgAAAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAACAgMiAy"
    "MC82MTE2L0YgVFVSQSBJUkFBUkdOIEUgIAAAIk+GL5Yvpi8r2C7QAmGBUhEYJ2IpIYJpE2AByACJ"
    "AOkCyACJAemSKCXRQpCYKQCJQJABIQDgIdECISPaomAGLwDgADkDiyLSJ9MCoAkAIdIm0yIqLuQg"
    "1TNnKZYb0AtACQA85BzVHtcilhjQC0AJAAHgADkDixbSG9MCoAkAFdIa0yIqOuQV1TNnEZYP0AtA"
    "CQBI5BHVE9cKlgzQC0AJAPZgAir2avZp9mgmTwsACQD6AArnAecJAHsMAP97DBj/EAxgJQUMdMQF"
    "DFDLBQzYy/+AAP+AgICAAADYAAAA6AB8DMgDfAzYA3wM5QN8DOcDUk9HSU5JTEFBIENSREEARVJB"
    "QVJHTiBFT01FRD4AIAAAAAkADtACYAggAosQ0CtACQAA4EaBIk8K1EJkCtVSZQzQC0AJACZPCwAB"
    "4ATQAmAIIAGJBdVSZQfQK0AJAAkAewwA/3sMCP97DAz/ewwQ/xAMkOsGDCDmBgygigTQAmAIIACJ"
    "AuUB0CtACQAGDCCFewwA/z/QAmAIICqJhi+WL6Yvti/GL9YvRi8iT3CQTgEYIRaJElkTWjnbN9wA"
    "4AIsHLAJAADtwmADPQqJM9HTYAhAHgEVWRZaMtsPsAkA8q8BfSZP9mT2bfZs9mv2avZp9mjmLy/Q"
    "MNErQQJjIk8q0AJgCCBAiSnRHDACaIgoO4mIhP9wDGAB4RYwM4mFUpgyEUIAiStisjIsiYZSqDIR"
    "QgCJK2KyMiWJg2F8cRRUHNALQAkAh4UDZwDgi4CDYSpxACEB4v9xICH/cSAhc2CGgYNhfHEA4AQR"
    "AxED4IiAwmAPkRMwBokJ0QNiCEIsMYIhAXACLMKvgmgmTwsACQAJAAAJAAJ7DAD/ewwU/3sMAPAY"
    "AAAAEAAAACcMSN4EAECEBgywR0cM/FIHDMZkP9ACYAggH4k/0AA0HItTYACIA40B4QGIFosK4TnS"
    "ImMcM2uREzMPjzIiAOMyIiJPRi9WL2Yvdi800AtACQD2Z/Zm9mX2ZCZPMdArQAkAIk8w0AtACQAq"
    "0AJgCCAFiS/UAOVMlizQC0AJACZPCwAJAIYvK9ACZyvQBmQCYAw0IdACaCrQBTgKARghE4ko1Uw1"
    "KMcDYwTiNmACJzZgARdSFzDQAxc2YAQXEEL0jxR3EEHujxF1LtZMNgXjL9VVOAoCCUIBQiNhCEEs"
    "MRwxg2AYMCNoCEAMMCTRHDAT0RInARdiFyLQAxcj0AQXFHcQQ+WP+XYL0HIgCwD2aAkA4C7+AXsM"
    "AP97DBj/OAwcOgYM0LsGDDC3BgxgewUMlMN8DPQFBQwMEAUMBBAAEQAAIACcxP7/hQAAE//A4Ajw"
    "AIAAgIAAF8P/wAjwAFQAVFQAE5//EAfgAGAAYGAAE4f/AAfwAHgAeHgPAA8A+ASAAAcABwAUAOYA"
    "gACAgMzMzcwGALmN")),
]


# MiSTer MRA (the futariarr_u4 CRC is filled in from PATCHED_CRC when written)
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
        <part name="futariarr_u4" crc="58eb6923"/>
        <part name="futariarr_u4" crc="58eb6923"/>
    </rom>

    <buttons names="Focus Shot,Bomb,Rapid Shot,B4,Start,Coin,Test,Service,Save State" default="A,B,X,Y,Start,R,L,Select"/>
</misterromdescription>
"""


def find_u4(zf):
    for name in zf.namelist():
        if os.path.basename(name).lower() in ("futariblk_u4", "u4", OUT_NAME):
            return name
    return None


def apply_patch(data):
    if len(data) != U4_SIZE:
        raise ValueError("u4 is %d bytes, expected %d" % (len(data), U4_SIZE))
    crc = zlib.crc32(data) & 0xFFFFFFFF
    if crc == PATCHED_CRC:
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
    return out


def mra_text():
    import re
    return re.sub(r'(<part name="futariarr_u4" crc=")[0-9a-fA-F]{8}', lambda m: m.group(1) + "%08x" % PATCHED_CRC, MRA_TEMPLATE)


def main():
    ap = argparse.ArgumentParser(description="Patch Muchi Muchi Pork u4 into futariarr_u4 (Futari Arrange, build 1)")
    ap.add_argument("input", help="futariblj.zip or a loose original u4 file")
    ap.add_argument("-o", "--output", help="where to write futariarr_u4")
    ap.add_argument("--zip", action="store_true", help="also write futariarr.zip (input must be a zip)")
    ap.add_argument("--mra", action="store_true", help="also write the MiSTer .mra")
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
        patched = apply_patch(data)
    except ValueError as e:
        sys.exit("error: %s" % e)

    folder = os.path.dirname(os.path.abspath(a.input))
    out = a.output or os.path.join(folder, OUT_NAME)
    with open(out, "wb") as f:
        f.write(patched)
    print("original u4 CRC %08x OK" % ORIG_CRC)
    print("wrote %s (CRC %08x)" % (out, PATCHED_CRC))

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
            f.write(mra_text())
        print("wrote %s" % mout)
    print("Back up your original u4 before flashing real hardware.")


if __name__ == "__main__":
    main()
