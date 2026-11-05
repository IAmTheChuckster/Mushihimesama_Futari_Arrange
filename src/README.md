# Source

- `menu.s` - the title menu routine (SH-3). Called every frame instead of the "PRESS 1P OR 2P START" text draw; reads P1 input from `0x0C05C474`, draws ORIGINAL ARCADE / ARRANGE MODE with the game's own text routine (`0x0C05CBD8`) and the colour word at `0x0C05CB50`.
- `patch.s` - patcher (runs once at boot from RAM, installs the hook at `0x0C092128` / literal `0x0C092138`, then starts the game at `0x0C002A30`), includes `menu.s`.
- `hyper.s` - Hyper Bomb: in ARRANGE MODE the bomb's blast spawner (literal `0x0C06BC80` -> `0x0C10EB90`) is replaced by the game's bullet cancel `0x0C06E620` with gem type 1 (big gems); the bombing flag (word +12 of the bomb-stock object) is cleared so gems can spawn, and the bomb invulnerability (literal `0x0C06BC88` -> `0x0C068AA0`) is set to 120 frames. The voice is played by the caller and is kept.
- `chain.s` - chain cancel: a jump at the start of the enemy-remove routine `0x0C0764C0` (literal at `0x0C07650C`) runs `enemy_kill` in ARRANGE MODE; enemy position is in the actor at enemy+0x900 (+8 x, +0xC y, 16.16). Bullets (list at manager `@0x0C27DE48` + 0x48440, +0x14/+0x18 position) within 24 px are put into the game's cancel state with gem type 0 (small), queued (0x0C7BF000, max 512) and each queued bullet cancels others within 16 px.
- `meter.s` - hyper meter: `gem_hook` replaces the gem-collect call `0x0C06B730` (literal `0x0C0951AC`; r4 = bomb-stock object, P1 = `0x0C383A1C`, r5 = item type 0 small / 1 big), value at `0x0C7BFF18`, full = extra bomb via `0x0C06BBD0`. `player_hook` replaces the per-frame player update call `0x0C067B60` (literal `0x0C069B64`) and queues `meter_draw` in the game's draw list (`0x0C05C394`, priority 510; bucket 511 is never drawn). `meter_draw` appends blitter sprites at `@0x0C05100C`: the bar uses the HUD gauge block tile `0x03F800B8` tinted red, the digits use the score font (tile `0x04F80080 + 8*digit`). Positions must add the framebuffer origin at `0x0C051004`/`0x0C051008` (double-buffered).
- `stub.s` - tiny ROM stub in the free tail of u4 (file offset `0x1F8000`); the u4 header entry (`0x1C4`) points to it. It copies the patch to RAM `0x0C7C0000`.
- `build.py` - builds the patched u4 from your own `futariblj.zip`.
- `update_patchers.py` - embeds the changed bytes into `futari_patch.py`, `index.html` and the `.mra`.

Build 1 gives `futariarr_u4` CRC `dd259279`.

Notes: a PC-relative `mov.l` must not sit in a branch delay slot (illegal on real SH-3). The yellow tint word is `0x80FFFF00` (neutral is `0x80808080`).
