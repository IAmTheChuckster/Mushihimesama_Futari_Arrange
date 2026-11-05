# Source

- `menu.s` - the title menu routine (SH-3). Called every frame instead of the "PRESS 1P OR 2P START" text draw; reads P1 input from `0x0C05C474`, draws ORIGINAL ARCADE / ARRANGE MODE with the game's own text routine (`0x0C05CBD8`) and the colour word at `0x0C05CB50`.
- `patch.s` - patcher (runs once at boot from RAM, installs the hook at `0x0C092128` / literal `0x0C092138`, then starts the game at `0x0C002A30`), includes `menu.s`.
- `hyper.s` - Hyper Bomb: in ARRANGE MODE the bomb's blast spawner (literal `0x0C06BC80` -> `0x0C10EB90`) is replaced by the game's bullet cancel `0x0C06E620` with gem type 1 (big gems); the bombing flag (word +12 of the bomb-stock object) is cleared so gems can spawn, and the bomb invulnerability (literal `0x0C06BC88` -> `0x0C068AA0`) is set to 120 frames. The voice is played by the caller and is kept.
- `stub.s` - tiny ROM stub in the free tail of u4 (file offset `0x1F8000`); the u4 header entry (`0x1C4`) points to it. It copies the patch to RAM `0x0C7C0000`.
- `build.py` - builds the patched u4 from your own `futariblj.zip`.
- `update_patchers.py` - embeds the changed bytes into `futari_patch.py`, `index.html` and the `.mra`.

Build 1 gives `futariarr_u4` CRC `175a9700`.

Notes: a PC-relative `mov.l` must not sit in a branch delay slot (illegal on real SH-3). The yellow tint word is `0x80FFFF00` (neutral is `0x80808080`).
