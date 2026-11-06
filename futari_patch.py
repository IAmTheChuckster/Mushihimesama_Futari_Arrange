#!/usr/bin/env python3
"""
Mushihimesama Futari Arrange (Cave CV1000) - patch build 26

Usage:
    python3 futari_patch.py futariblj.zip              -> writes futariarr_u4 next to the zip
    python3 futari_patch.py futariblj.zip --zip        -> also writes futariarr.zip (the set with u4 replaced by futariarr_u4)
    python3 futari_patch.py futariblj.zip --mra        -> also writes "Mushihimesama Futari Arrange.mra" (MiSTer)
    python3 futari_patch.py futariblj.zip -o OUT       -> writes the patched futariarr_u4 to OUT
    python3 futari_patch.py u4                      -> a loose original u4 works too (no --zip)

The original u4 must have CRC32 b9467b6d; the result is checked to be 5a503a52.
Only the Python standard library is used.
"""
import argparse, base64, os, sys, zipfile, zlib

ORIG_CRC = 0xB9467B6D
PATCHED_CRC = 0x5A503A52
U4_SIZE = 0x200000
OUT_NAME = "futariarr_u4"
SET_NAME = "futariarr.zip"
MRA_NAME = "Mushihimesama Futari Arrange.mra"

# Patch blocks: (offset in the u4 file as stored in the MAME set, bytes)
PATCHES = [
    (0x1C4, base64.b64decode("H4AAgA==")),
    (0x1F8000, base64.b64decode(
    "BdEG0gbTFmACIgRyEEP6iwTQK0AJAAkAH4AogHysAAAAAHwCfAwAAC7RAOACIQERLdFhkAEhLdEt"
    "0AIhMNEy0AIhMNEx0AIhMdEy0AIhVZASgTHRMdACITHRMtACITLRN9ACITfRONACITjRQ9ACIUbH"
    "A2JC0TrjJGAAIRBD+48BcVHHA2I/0X6TJGAAIRBD+48BcTDRNtACITDRNdACIS/RNdACIS/RMdAC"
    "IS7RMdACIS7RMNACISXRJtACIRvRPJABIRvRHNACIRnRN5ABIQTRAeACEQDgAxEOkAQRBdArQAkA"
    "e6wA/wmsKCEJrDghfAxgAwAMMCoD0HgACQAJAAasgLwGrIi8fAwwBXwMeAUHrMBkEtArQAesDGV8"
    "DMwFCaysUXwM9AYJrKBRBqxotwasgscGrLzHAQCehlvRDtF8DGwHBqxkm3wMoAcQrIxFBqyAL3wM"
    "xAkQrAREEKwIRBCsDEQQrHBFEKx0RRCseEV8DJAJfAx+CXwMGAl8DLQFHaxIKB2shCnAAQkAICAg"
    "IEYgVFVSQSBJUkFBUkdOIEUgICAgAAAAACAgICAgICAgICAwMjYyMS4uMSA2ICAgICAgICAgIAkA"
    "ICBUIElIIFNSUEpPQ0UgVFNJVSBPTkZGQ0lBSSBMAAAgIEEgRE5JICBTT04gVEZBSUZJTFRBREVX"
    "IFRJLEgAACAgRSBETlJPRVMgRFlCICxST0EgVFVPSElSRVogRAAAICBCICBZQUNFViAuTEEgTElS"
    "SEdTVFQgIE9IVCBFAAAgIE8gSVJJR0FOIExBR0VNQSBETkkgU1QgICAgICAAACAgQSBTU0NPQUlF"
    "VCBETklFVExMQ0VVVExBICAgIAAAICBQIE9SRVBUUiBZRVJBTU5JVyBUSSBISFRJRSBSAAAgIFIg"
    "U0VFUFRDVkkgRUlSSEdTVEggTE9FRFNSIC4AACAgICAgICAgICAgICAgICAgICAgICAgICAgICAg"
    "IAAAICAgICAgICBIIFZBIEVVRiFOISEgICAgICAgICAgAAAgICAgICAgICAgICAgICAgICAgICAg"
    "ICAgICAgICAAACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAICAgICAgICAgICAgICAg"
    "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"
    "ESZPCwAJAAUMXMV7DAD/BQysxA==")),
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
        <part name="futariarr_u4" crc="5a503a52"/>
        <part name="futariarr_u4" crc="5a503a52"/>
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
    ap = argparse.ArgumentParser(description="Patch Mushihime-Sama Futari Black Label u4 into futariarr_u4 (Futari Arrange, build 26)")
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
