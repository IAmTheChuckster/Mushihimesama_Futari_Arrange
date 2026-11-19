# CLAUDE.md: CV1000 ROM patch projects

Copy this file into the root of a new project and fill in the **Project** section. It holds the setup, workflow
and lessons from Mushihimesama Futari Arrange (`IAmTheChuckster/Mushihimesama_Futari_Arrange`, build 43) so a new
game patch can start where that one left off. Keep it up to date: add every new finding and rule here as you go.

## Project (fill in)
- Game / MAME set: `<set>` (parent `<parent>`), board CV1000-B (8 MB RAM) or CV1000-D (16 MB RAM)
- Original program ROM: `<u4 name>`, CRC `<crc>`
- Output set name: `<newset>`, patched u4 name `<newset>_u4`
- Goal: <what the patch changes>

## Owner and ground rules
- The owner plans and tests; Claude reverse engineers and writes the patch and patcher code.
- **No ROM data or game art in the repo, ever.** `.gitignore` excludes `*.zip`, `roms/`, `work/`, `*.bin`, ROM
  file names, `*.png`, `.images/`, `__pycache__/`. Patchers embed only the changed bytes; art from other
  packages (the 360 GOD package) is cut at patch time on the user's machine.
- **Never commit or push unless the owner says so in that moment.** Don't offer commits by default. When asked
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
- An upload takes effect a few frames late: upload every frame (in the mode that needs it), not only on frames
  that draw the sprite, or the old art shows for ~3 frames.
- Unused VRAM: Futari Black Label still holds the 1.5 "Ultra Mode" label (16x64 at `0x1548,0x107`); reuse such
  leftovers instead of guessing free space.

## Build and test loop
1. Edit `src/*.s` and raise `src/BUILD`. Build in WSL:
   `python3 src/build.py ~/mame/roms/<set>.zip ~/mame/work/<newset>_new.zip` (prints build number and CRC).
2. Test set: `~/mame/roms_arr/<set>.zip` with the patched u4 under the **original** file name (plus the GOD
   picture written at `0x1FF000`, byte-swapped); run with `ROMPATH=$HOME/mame/roms_arr`. First boot
   initialises NAND/EEPROM.
3. Run: `GAME=<set> HARNESS=lua/<proj>_harness.lua BT_SCHED=... BT_SNAP=N scripts/run.sh FRAMES`.
   Save a state (`BT_SAVE=frame:name`), load it from Lua (`BT_LOADSTATE`; `-state` hangs headless) and snapshot
   every frame (`BT_SNAP=1`). `BT_POKE` to force values (e.g. a meter), `BT_WATCH` to log RAM per frame,
   `BT_RAMSNAP` for full RAM dumps.
4. Check frame by frame: contact sheets, crops, pixel counts. Blink/flicker bugs only show frame to frame.
   Compare against the previous build (build it from `git archive HEAD src`) when unsure whether a change
   altered anything.
5. `python3 src/update_patchers.py <orig>.zip <new>.zip` (reads `src/BUILD` and `roms/435A07E3.zip`) updates
   `patch.py`, `index.html` (patch bytes, CRCs, embedded MRA, download table) and the `.mra`. Then check that
   `patch.py --god` output equals the tested ROM, update both READMEs and this file.
6. Web patcher test: `preview_start` with `.claude/launch.json` (python http.server on 8765), then in the page
   `fetch('/roms/...')` the files and dispatch a `drop` DragEvent with a DataTransfer on `#drop` / `#dropGod`;
   read `#outstatus`, `#outcrc`. Stop the server afterwards.

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
- Debugger watchpoints do not fire in this build and Lua write taps crash; use pokes and watches instead.
- SH-3: never put a PC-relative `mov.l` in a branch delay slot (illegal on real hardware even if MAME runs it).
- 360 GOD package (Mushihimesama, title ID 435A07E3): see `.claude/god.md` for the disc image, Cave archive and
  LZSS chain; the patchers' `god_label()` / `buildGlyph()` must stay integer-only so Python and JS match.

## Targets
- MAME 0.289 (MAME warns about the checksum of the replaced u4; expected).
- MiSTer CV1k core by Raki: `.mra` loads u2 and the YMZ ROMs straight to DDR3 (`address=`), u4 last, listed
  twice (A21 mirror).
