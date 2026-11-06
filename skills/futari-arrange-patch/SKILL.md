---
name: futari-arrange-patch
description: Use when building, testing, or releasing the Mushihimesama Futari Arrange (futariblj, Cave CV1000) ROM patch: boot-hook routines, MAME test runs, patchers, and git release steps.
---

# Futari Arrange patch

Repo: IAmTheChuckster/Mushihimesama_Futari_Arrange (public, GitHub Pages at iamthechuckster.github.io/Mushihimesama_Futari_Arrange/). Never commit ROM data; only source and changed-byte tables.

## Rules
- ORIGINAL ARCADE (first title entry) stays unpatched. All gameplay changes go in ARRANGE MODE only. Mode word 0x0C7BFF00: 0 original, 1 arrange.
- Patch at boot. MAME's DRC ignores runtime patches to compiled code, and saved states keep old patch code, so test from a fresh save built with the same build.
- Do not edit, build or push until the user says ok, when they have said they want to confirm first.
- Commit messages and PRs need the attribution lines the session gives you.

## Source layout
- src/patch.s: boot installer (literal and instruction patches, warning and boot text, includes the other .s files).
- src/meter.s: gem and score hooks, player_hook (per-frame ARRANGE logic), meter_draw (hyper swirls).
- src/hyper.s: hyper bomb, cash-out at x99999, invulnerability.
- src/menu.s: title menu, title sprite filter, NOT FOR SALE line.
- src/chain.s, src/modesel.s, src/p2off.s, src/stub.s, src/build.py, src/update_patchers.py.
- docs/futariblj-mechanics.md: running notes per build. Add a bullet for every build.

## Build
1. `python3 -I src/build.py /mnt/user-data/uploads/futariblj.zip OUT.zip` (needs sh-elf binutils).
2. `python3 -I src/update_patchers.py /mnt/user-data/uploads/futariblj.zip OUT.zip` regenerates index.html, futari_patch.py and the MiSTer .mra, and bumps the build number.
3. For MAME, the ROM dir needs futariblj.zip with the built u4 renamed futariblk_u4.

## MAME test env
- /root/cv1k/cv1k_testenv: `GAME=futariblj ROMPATH=<dir> HARNESS=lua/futari_harness.lua scripts/run.sh <frames>`, run in the background with nohup and poll with short sleeps.
- Harness variables: BT_SCHED (input schedule), BT_SNAP (screenshots every N frames to work/snap/futariblj), BT_RAMSNAP (RAM dump at frame), BT_POKE (every frame from a frame), BT_POKE1 (once), BT_WATCH (CSV to work/watch.csv), BT_SAVE and BT_LOADSTATE (use BT_LOADSTATE, not STATE).
- Invulnerability poke: `3500:c38340c:7ffffffe:4`.
- Breakpoints (debugger bpset) do not fire under the DRC. Use RAM dumps and watch CSVs instead.
- The EEPROM and NVRAM keep accepted codes between runs. Move work/nvram/futariblj aside to get a clean run.

## Release
1. Test in MAME (screenshot or watch CSV) before committing.
2. Commit with the session's attribution lines, then push to main.
3. Check that the GitHub Pages site still loads.

## Known addresses
- Player object 0x0C383398; player state word 0x0C3833A8 (18 playing, 0 tally or game over).
- Stock object 0x0C383A1C, bombs at +6 (0x0C383A22). Lives candidate 0x0C383A21 (not confirmed).
- x counter 0x0C383AC4 (stock +168), cap 99999 in arrange.
- Mode word 0x0C3833E8 (0 original, 1 maniac, 2 God).
- HUD slide word 0x0C38333C. Cash-out window 0x0C7BFF2C. Hyper meter 0x0C7BFF18. Latch 0x0C7BFF30, previous slide 0x0C7BFF34.
- Spiritual Larsa: the per-game word 0x0C383354, set to 1 every frame in arrange.

## Open items
- Death or life-loss hit routine not found. Counter reset on death is untested (see build 28 history).
- Ship death penalty in God mode is the game's own (x2686 to x1790, about 2/3).
