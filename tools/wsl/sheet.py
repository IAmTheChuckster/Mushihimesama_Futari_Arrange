#!/usr/bin/env python3
"""Contact sheet of MAME snapshots, each tile labelled with its file name (run inside WSL, needs Pillow):
    python3 tools/wsl/sheet.py OUT.png COLS FILE...
Use it to check frame by frame (blinking, flashing): snapshot every frame with BT_SNAP=1, then sheet a range."""
import sys
from PIL import Image, ImageDraw
out, cols, files = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
ims = [Image.open(f).convert('RGB') for f in files]
w, h = ims[0].size
rows = (len(ims) + cols - 1) // cols
sheet = Image.new('RGB', (cols * w, rows * (h + 12)), (40, 40, 40))
d = ImageDraw.Draw(sheet)
for i, (f, im) in enumerate(zip(files, ims)):
    x, y = (i % cols) * w, (i // cols) * (h + 12)
    sheet.paste(im, (x, y + 12))
    d.text((x + 2, y), f.rsplit('/', 1)[-1].split('.')[0], fill=(255, 255, 0))
sheet.save(out)
