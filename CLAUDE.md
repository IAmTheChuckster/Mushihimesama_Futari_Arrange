# CLAUDE.md: CV1000 ROM patch projects

This file is the handoff for Mushihimesama Futari Arrange (`IAmTheChuckster/Mushihimesama_Futari_Arrange`, current
build 53) and the template for new CV1000 patch projects. Claude Code reads it at the start of every session in
this repo. **Keep it up to date with every build** (see "Every build" below): new findings, rules, addresses, tools.

## Three ways to use it
1. **Continue this project** (same machine): read this file and `src/README.md`, then follow "Every build".
2. **Rebuild this project on a new machine:**
   1. Install the tools in "Machine setup" (Git, Claude Code, Python; WSL Ubuntu-24.04 with SH binutils, Pillow,
      numpy; the MAME 0.289 test env from `IAmTheChuckster/mame0.289_claude` at `~/mame`).
   2. `git clone https://github.com/IAmTheChuckster/Mushihimesama_Futari_Arrange` (to `D:\GitHub\...`).
   3. Put the owner's own dumps in place (never in git): `roms/futariblj.zip` and `roms/435A07E3.zip` in the
      repo, and `futariblj.zip` also in `~/mame/roms/`.
   4. In WSL: `bash tools/wsl/build.sh` then `bash tools/wsl/update.sh`. With `src/BUILD` unchanged the patchers
      must come out unchanged (`git status` clean) and `update.sh` must print `same as the tested u4: True`.
      That proves the setup; carry on with "Every build".
3. **Start a new game project** (another CV1000 game):
   1. New repo; copy from this one: `CLAUDE.md`, `.gitignore`, `.nojekyll`, `src/stub.s`, `src/build.py`,
      `src/update_patchers.py`, `src/BUILD` (set to 1), `tools/` (harness, `tools/wsl/*`), `patch.py` and
      `index.html` as patcher templates, `mister/*.mra` as an MRA template. Start `src/patch.s` with only the
      `patcher:` entry (hook installs + jump to the real entry) and grow it.
   2. Fill in "Project" below and replace the Futari values: original u4 CRC, entry point (`0x1C4` header word),
      free tail offset of u4 (check it is all `0xFF`), set/file names, RAM layout, addresses. Everything listed
      under "Blitter / display list" and "Reverse engineering tips" is Futari-specific: find the new game's
      equivalents with the same methods (RAM dumps, literal searches, VRAM from save states).
   3. Rename this file's Futari examples as you replace them, so it stays true for the new project.

## Project (this repo; fill in for a new one)
- Game / MAME set: `futariblj` (parent `futaribl`), Mushihime-Sama Futari Black Label, CV1000-B (8 MB RAM)
- Original program ROM: `futariblk_u4`, CRC `b9467b6d`; also u2 (NAND), u23, u24 (sound) unchanged
- Output set: `futariarr.zip`, patched u4 `futariarr_u4`; MiSTer `mister/Mushihimesama Futari Arrange.mra`
- Extra input: the owner's Xbox 360 GOD package of Mushihimesama, title ID 435A07E3 (ARRANGE banner art)
- Goal: ORIGINAL ARCADE unchanged; ARRANGE MODE with the changes listed in README "Patch Notes"

## Owner and ground rules
- The owner plans and tests; Claude reverse engineers and writes the patch and patcher code.
- **No ROM data or game art in the repo, ever.** `.gitignore` excludes `*.zip`, `roms/`, `work/`, `*.bin`, ROM
  file names, `*.png`, `.images/`, `__pycache__/`. Patchers embed only the changed bytes; art from other
  packages (the 360 GOD package) is cut at patch time on the user's machine.
- **Never commit or push unless the owner says so in that moment.** Never ask or offer to push or commit. When asked
  to push: commit (with the Claude co-author line) and `git push origin main` (works from the command line
  now; GitHub Desktop is the fallback).
- **Never write build output into the repo's `roms/`** (it holds only the owner's dumps, e.g. `futariblj.zip`,
  `435A07E3.zip`). Test sets go to `~/mame/roms_arr/`, patcher checks to `~/mame/work/verify` or the scratchpad.
- **Always update everything with each change:** patchers (`patch.py`, `index.html`), the `.mra` in `mister/`,
  both READMEs (patch notes, CRCs, how to patch), `dev_notes/`, and this file.
- **Dates:** when the owner asks to change the `.mra` date, also change the boot screen date and the warning
  screen date to match, without asking.
- Ask before changing anything the owner edited by hand (for example the `.mra`); keep their edits.
- Write player-facing text (README patch notes, web patcher) in plain, short English.

## Machine setup (Windows 10 + WSL)
- Windows: Git for Windows, Claude Code native install (`%USERPROFILE%\.local\bin\claude.exe`), Python 3. No
  Node, no winget. Shells: PowerShell 5.1 and Git Bash. In PowerShell, prepend the machine + user PATH if `git`
  is not found.
- WSL `Ubuntu-24.04`: Python 3 (+ Pillow, numpy), SH binutils (`sudo apt install binutils-sh-elf`:
  `sh-elf-as`, `sh-elf-ld`, `sh-elf-objcopy`, `sh-elf-objdump`).
- MAME 0.289 headless test env at `~/mame` (`\\wsl$\Ubuntu-24.04\home\brian\mame`), from
  `IAmTheChuckster/mame0.289_claude`: `bin/cv1k`, `scripts/run.sh` (patched to use `${HARNESS:-lua/harness.lua}`),
  `lua/`, `roms/`, `work/`. Copy `tools/mame/*_harness.lua` to `~/mame/lua/` and the schedules to `work/s/`.
- WSL quirks: inline `wsl -- bash -lc '...'` mangles `$VAR` and quotes, so write a `.sh` script and run
  `wsl -d Ubuntu-24.04 -- bash /mnt/c/.../script.sh`. From Git Bash, prefix `MSYS_NO_PATHCONV=1` or `/mnt/...`
  paths get rewritten. `/tmp` is cleared between `wsl` calls; keep output under `~/mame/work/`. The repo is at
  `/mnt/d/GitHub/<repo>`. Claude Code's safety check blocks `rm` inside `bash -c '...'`; put removals in a
  script file or run them on their own.

## Repo layout (proven)
```
src/          *.s (SH-3 assembly), BUILD, build.py, update_patchers.py, README.md (addresses and hooks)
tools/wsl/    build.sh (build + MAME test set), update.sh (update and check the patchers), sheet.py (contact sheets)
tools/mame/   project harness (futari_harness.lua) and input schedules
dev_notes/    findings about the game (mechanics, RAM map), marked VERIFIED or open
mister/       MiSTer .mra (owner-edited name/date)
.claude/      god.md (360 GOD package extraction), launch.json (local server to test the web patcher)
patch.py      stdlib-only Python patcher (needs --god)
index.html    web patcher (GitHub Pages, runs in the browser, nothing uploaded)
README.md     about, to do, bugs, patch notes, how to patch, credits, disclaimer
CLAUDE.md     this file
```

## How the patch works
- Free tail of u4 (all `0xFF`, here file offset `0x1F8000`) holds a small `stub.s` plus the patch blob.
- The u4 header entry pointer (`0x1C4`, originally the game entry) is pointed at the stub. The stub copies the
  blob to free RAM (`0x0C7C0000`), the blob's `patcher` installs hooks in the unpacked program in RAM, then
  jumps to the real entry. Hooks are installed **before the game runs** because MAME's DRC does not see later
  changes to code or code literals.
- u4 is byte-swapped in the MAME set: swap 16-bit pairs before patching and back after (CPU reads big-endian).
  u4 is visible to the CPU at `0xA0000000` (e.g. file offset `0x1FF000` = `0xA01FF000`).
- Hook styles used: replace a literal-pool word a `jsr` loads (cleanest); replace a `mov.l @(d,PC),r0` so an
  existing `jsr @r0` calls our code; patch a single instruction word (for example `and #16,r0` to
  `and #0,r0`). Write through the uncached alias (`0xAC......`).
- Keep a mode variable in free RAM (`0x0C7BFF00`) so ORIGINAL plays exactly like the original game. Free RAM
  `0x0C7B0000`-`0x0C7FFE9F`.
- Build number: `src/BUILD` holds the number of the build being made; `build.py` writes the boot screen line
  `FUTARI ARRANGE B<n>` (generated `boot_title.inc`, centred) and `update_patchers.py` uses the same number for
  "Matches build N". Raise it by one for every new build.
- Two CRCs: `PATCHED_CRC` (patch code only) and `FINAL_CRC` (finished u4 including the GOD-package picture at
  `0x1FF000`). The `.mra`, README and download table show `FINAL_CRC`; both patchers check the picture CRC
  (`BANNER_CRC`) and `FINAL_CRC`.

## Blitter / display list (CV1000, Futari addresses)
- List pointers: `@0x0C051000` list start, `@0x0C05100C` write pointer, `@0x0C051004/08` framebuffer origin
  (add to dest positions; double-buffered). Several lists are in flight (double/triple buffering).
- Ops: draw `0x1xxx` = 20 bytes: header, src (x<<16|y), dest, (w-1)<<16|(h-1), tint (`0x00808080` neutral);
  upload `0x2000` = `0x20000000, 0x99999999, x<<16|y, (w-1)<<16|(h-1)`, then w*h ARGB1555 words (bit 15 =
  opaque); end `0xFFFFFFFF`. Upload widths must be a multiple of 8 (the MiSTer core froze on others).
- Screen is portrait 240x320 but art and coordinates are stored sideways: a label's text runs along VRAM y;
  +1 VRAM x = 1 pixel **up** on screen.
- Draw queue: `0x0C05C394(handler, 0, priority)` queues a handler for this frame's draw pass (bucket 511 is
  never drawn; 510 draws over the HUD).
- Frame renderer `0x0C05C3EC`: starts a list (`0x0C0512BC`), runs the queued handlers, then closes the list via
  the literal at `0x0C05C45C` -> `0x0C0512E4` (append one long) with `0xFFFFFFFF`. **Hook that literal** to
  change every list the blitter gets: draw-queue hooks miss frames during slowdown (the banner flashed).
- **Performance:** code in the list-close hook runs every frame: never scan the whole list forwards. Search backwards
  from the write pointer (HUD/banner draws are near the end) and stop when found. Measure slowdown by the frame
  the stage 1 tally starts in a fixed invulnerable run (build 43 baseline 12324; build 48 with forward scans 12913).
- An upload takes effect a few frames late: upload every frame (in the mode that needs it), not only on frames
  that draw the sprite, or the old art shows for ~3 frames.
- Unused VRAM: Futari Black Label still holds the 1.5 "Ultra Mode" label (16x64 at `0x1548,0x107`); reuse such
  leftovers instead of guessing free space.

## Every build (checklist)
1. Raise `src/BUILD` by one (it goes on the boot screen as `FUTARI ARRANGE B<n>` and into the patchers).
2. Edit `src/*.s`. In WSL: `bash tools/wsl/build.sh` (assembles, prints the build number and CRC, installs the
   test set `~/mame/roms_arr/futariblj.zip` with the banner picture).
3. Test in MAME: `cd ~/mame; GAME=futariblj ROMPATH=$HOME/mame/roms_arr HARNESS=lua/futari_harness.lua
   BT_SCHED=work/s/<schedule> BT_SNAP=N scripts/run.sh FRAMES`. Save a state (`BT_SAVE=frame:name`), load it
   from Lua (`BT_LOADSTATE`; `-state` hangs headless), snapshot every frame (`BT_SNAP=1`), make contact sheets
   (`tools/wsl/sheet.py`). `BT_POKE` forces values every frame, `BT_POKE1` once, `BT_WATCH` logs RAM per frame, `BT_RAMSNAP` dumps RAM.
   To reach a stage end, keep the ship invulnerable: `BT_POKE=3700:c38340c:7fff:4` (stage 1 tally at about frame
   12326 with `arr_play.txt`). The player state word `0x0C3833A8` is 0 on the tally; `player_hook` does not run on
   the game over screen.
   Check frame by frame (blink/flash bugs) and ORIGINAL ARCADE when the change could touch it. Compare against
   the previous build (`git archive HEAD src`) when unsure.
4. `bash tools/wsl/update.sh`: updates `patch.py`, `index.html` (patch bytes, CRCs, embedded MRA, download
   table) and the `.mra` CRC, and checks `patch.py --god` gives exactly the tested u4.
5. Update the docs, every build:
   - `README.md`: "Current build" line, Patch Notes (plain English), CRC in "Patching the game", To Do / Bugs.
   - `src/README.md`: the "Build N: patch code CRC ..., finished ... CRC ..." line and a note per new file/hook.
   - `dev_notes/futariblj-mechanics.md`: findings (VERIFIED or open) with the build number.
   - `CLAUDE.md` (this file): current build number at the top, new rules, tools, addresses, lessons.
6. Web patcher check when `index.html` logic changed: `preview_start` with `.claude/launch.json` (http.server on
   8765), `fetch('/roms/...')` the files in the page and dispatch a `drop` DragEvent with a DataTransfer on
   `#drop` / `#dropGod`; read `#outstatus`, `#outcrc`; stop the server.
7. Don't commit or push; tell the owner what changed. Push only when asked.

## Reverse engineering tips
- RAM dump (`BT_RAMSNAP`), search for ASCII strings and 32-bit big-endian pointers to them; the code that uses
  a string sits just after its literal pool. Find callers of a routine by searching for its address as a literal.
- Disassemble: `dd` a region out of the dump and run `sh-elf-objdump -D -b binary -m sh -EB --adjust-vma=0x<addr>`.
- **VRAM is readable from a MAME save state**: zlib data after the 32-byte header; the first 128 MB are VRAM as
  8192x4096 32-bit pixels (B, G, R, A; A=32 opaque). Main RAM follows later as byte-swapped 64-bit words.
  Find a sprite's VRAM source in the display list, then crop it from the state to see its pixels and colours.
- Text draw routine `0x0C05CBD8` (r4 x, r5 y, r7 string), colour word `0x0C05CB50`. Boot screen text is a
  24-char title field drawn from x 20 and a 30-char date field from x 16, 8 px per char: exact centring is not
  always possible (half-step).
- Some text (for example "SALE BY AMI") is pre-drawn sprites, not strings; handle it in the display list.
- Blinking text: the game may skip the draw call entirely on blink-off frames; a hook on that call then misses
  frames (title NOT FOR SALE flashed). Make the call happen every frame and do the blink in the hook.
- Ship (`0x0C383A68`/`6C`) and bullets (+20/+24 in the bullet list, manager `@0x0C27DE48` + `0x48440`, live = state
  byte +8 is 1 or 2) share one coordinate system: 16.16, x across, y **up** from the bottom (screen y = 320 - y).
  Plot list positions over a screenshot to confirm such things. The bullet list also holds harmless-looking
  effects (green ring bullets, kind byte +9 = 0x0F, at the stage start).
- The x counter (left) slides out to the left before the tally; anchor HUD followers on its "x" sign
  (source `0x03E800C0`, row 256, x 4), its digits change sprites with the value. Sprite crops: check edge columns for
  pixels of neighbouring art (column `0x04E7` next to the chrome digits had some).
- HUD parts move independently: the score row is fixed, but the banner bar and bomb icons drop 8 px while a boss
  gauge shows. Check which element actually moves (frame-by-frame crops) before linking.
- Colour any sprite with the tint word (0x80 per channel = as drawn, e.g. gold 0x00FFA830); scale it by another
  element's tint to keep its fades. Number fonts in VRAM: see `.images/fonts/` (score 0x04F8, chrome 0x04E7,
  x counter 0x0390, system ASCII 0x03F8).
- Linking a new HUD element to an existing one: in the list-close hook, find the game's own records for it (e.g. score
  digits: source x `0x04F8`, dest row 304) and copy their header/tint; draw nothing when they are absent.
- Score: add points with `0x0C06B120(stock 0x0C383A1C, points)`. Score-font digits: tile `0x04F80080` + 8 * digit,
  8x8, 7 px apart (see `graze_draw`).
- Debugger watchpoints do not fire in this build and Lua write taps crash; use pokes and watches instead.
- SH-3: never put a PC-relative `mov.l` in a branch delay slot (illegal on real hardware even if MAME runs it).
- 360 GOD package (Mushihimesama, title ID 435A07E3): see `.claude/god.md` for the disc image, Cave archive and
  LZSS chain; the patchers' `god_label()` / `buildGlyph()` must stay integer-only so Python and JS match.

## Targets
- MAME 0.289 (MAME warns about the checksum of the replaced u4; expected).
- MiSTer CV1k core by Raki: `.mra` loads u2 and the YMZ ROMs straight to DDR3 (`address=`), u4 last, listed
  twice (A21 mirror).
