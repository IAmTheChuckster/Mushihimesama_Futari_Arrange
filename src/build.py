#!/usr/bin/env python3
"""Build the Mushihime-Sama Futari Black Label "Arrange" u4 from an original futariblj zip.

    python3 build.py futariblj.zip OUT.zip

Needs binutils for SH (sh-elf-as, sh-elf-ld, sh-elf-objcopy). The ROM never leaves your machine; the
repo only holds source. Writes OUT.zip (futariarr set: u2/u23/u24 copied, futariarr_u4 patched) and prints
the patched u4 CRC32 and the changed bytes (for the patchers).
"""
import os, subprocess, sys, tempfile, zipfile, zlib

ORIG_U4_CRC = 0xB9467B6D
HERE = os.path.dirname(os.path.abspath(__file__))
STUB_ADDR = 0x801F8000     # ROM file offset 0x1F8000
ENTRY_OFF = 0x1C4          # u4 header: game entry pointer (original 0x0C002A30)
ORIG_ENTRY = 0x0C002A30
STUB_OFF = 0x1F8000
GEMTYPE = int(os.environ.get('GEMTYPE', '1'))
BUILD = int(open(os.path.join(HERE, 'BUILD')).read().split()[0])   # number of the build being made


def boot_title(t):
    """Boot screen first line (24-char field drawn from x 20, 8 px per char): FUTARI ARRANGE B<build>,
    centred on the 240 px screen as close as the 8 px grid allows (a half step goes left)."""
    text = 'FUTARI ARRANGE B%d' % BUILD
    left = (100 - 4 * len(text)) // 8
    line = (' ' * left + text).ljust(24)
    assert len(line) == 24, line
    open(os.path.join(t, 'boot_title.inc'), 'w').write('            .ascii "%s"' % line + chr(10))
PRI = int(os.environ.get('PRI', '510'))
INVLEN = int(os.environ.get('INVLEN', '120'))

def sh(*a):
    subprocess.run(a, check=True)

def assemble():
    t = tempfile.mkdtemp()
    boot_title(t)
    def build(src, addr, name, extra=()):
        o = os.path.join(t, name + '.o'); e = os.path.join(t, name + '.elf'); b = os.path.join(t, name + '.bin')
        sh('sh-elf-as', '-big', '-I', HERE, '-I', t, *extra, '-o', o, os.path.join(HERE, src))
        sh('sh-elf-ld', '-e', '0', '-Ttext=0x%X' % addr, '-o', e, o)
        sh('sh-elf-objcopy', '-O', 'binary', '-j', '.text', e, b)
        return open(b, 'rb').read(), e
    blob, _ = build('patch.s', 0x0C7C0000, 'blob', ['--defsym', 'GEMTYPE=%d' % GEMTYPE, '--defsym', 'INVLEN=%d' % INVLEN, '--defsym', 'PRI=%d' % PRI, '--defsym', 'FULL=%d' % int(os.environ.get('FULL','12000'))])
    open(os.path.join(t, 'blob.bin'), 'wb').write(blob)
    stub, _ = build('stub.s', STUB_ADDR, 'stub', ['--defsym', 'BLOBLEN=%d' % len(blob)])
    return stub, blob

def swap(b):
    b = bytearray(b); b[0::2], b[1::2] = b[1::2], b[0::2]; return bytes(b)

def patch_u4(u4, stub, blob):
    assert zlib.crc32(u4) == ORIG_U4_CRC, 'u4 CRC is not b9467b6d (Futari Black Label, Japan)'
    p = bytearray(swap(u4))
    assert int.from_bytes(p[ENTRY_OFF:ENTRY_OFF + 4], 'big') == ORIG_ENTRY
    assert p[STUB_OFF:].count(0xFF) == len(p) - STUB_OFF, 'stub area not empty'
    p[ENTRY_OFF:ENTRY_OFF + 4] = STUB_ADDR.to_bytes(4, 'big')
    p[STUB_OFF:STUB_OFF + len(stub) + len(blob)] = stub + blob
    return swap(bytes(p))

if __name__ == '__main__':
    zin, zout = sys.argv[1], sys.argv[2]
    z = zipfile.ZipFile(zin)
    u4 = z.read('futariblk_u4')
    stub, blob = assemble()
    new = patch_u4(u4, stub, blob)
    with zipfile.ZipFile(zout, 'w', zipfile.ZIP_DEFLATED) as o:
        for n in ('futariblk_u2', 'u23', 'u24'):
            o.writestr(n, z.read(n))
        o.writestr('futariarr_u4', new)
    print('build %d, patched u4 CRC32 %08x' % (BUILD, zlib.crc32(new)))
    print('stub %d bytes + blob %d bytes at 0x%X' % (len(stub), len(blob), STUB_OFF))
