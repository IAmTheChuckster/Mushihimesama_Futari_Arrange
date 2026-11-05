# Source

- `menu.s` - the title menu routine (SH-3). Called every frame instead of the "PRESS 1P OR 2P START" text draw; reads P1 input from `0x0C05C474`, draws ORIGINAL MODE / ARRANGE MODE with the game's own text routine (`0x0C05CBD8`) and the colour word at `0x0C05CB50`.
- `patch.s` - patcher (runs once at boot from RAM, installs the hook at `0x0C092128` / literal `0x0C092138`, then starts the game at `0x0C002A30`), includes `menu.s`.
- `stub.s` - tiny ROM stub in the free tail of u4 (file offset `0x1F8000`); the u4 header entry (`0x1C4`) points to it. It copies the patch to RAM `0x0C7C0000`.
- `build.py` - builds the patched u4 from your own `futariblj.zip`.
- `update_patchers.py` - embeds the changed bytes into `futari_patch.py`, `index.html` and the `.mra`.

Build 1 gives `futariarr_u4` CRC `dc7aac44`.

Notes: a PC-relative `mov.l` must not sit in a branch delay slot (illegal on real SH-3). The yellow tint word is `0x80FFFF00` (neutral is `0x80808080`).
