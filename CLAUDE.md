# CLAUDE.md: CV1000 ROM patch projects

Copy this file into the root of a new project and fill in the **Project** section. It holds the setup, workflow
and lessons from Mushihimesama Futari Arrange (`IAmTheChuckster/Mushihimesama_Futari_Arrange`) so a new game
patch can start where that one left off.

## Project (fill in)
- Game / MAME set: `<set>` (parent `<parent>`), board CV1000-B (8 MB RAM) or CV1000-D (16 MB RAM)
- Original program ROM: `<u4 name>`, CRC `<crc>`
- Output set name: `<newset>`, patched u4 name `<newset>_u4`
- Goal: <what the patch changes>

## Owner and ground rules
- The owner plans and tests; Claude reverse engineers and writes the patch and patcher code.
- **No ROM data in the repo, ever.** `.gitignore` must exclude `*.zip`, `roms/`, `work/`, `*.bin`, ROM file
  names, `*.png`. Patchers embed only the changed bytes.
- Do not commit or push unless asked. The owner pushes with **GitHub Desktop** (the command-line Git has no
  GitHub sign-in on this machine).
- Ask before changing anything the owner edited by hand (for example the MiSTer `.mra`); keep their edits.
- Write player-facing text (README patch notes) in plain, short English.

## Machine setup (Windows 10 + WSL)
- Windows: Git for Windows, Claude Code native install (`%USERPROFILE%\.local\bin\claude.exe`). No Node, no
  winget. Shell is PowerShell 5.1; prepend the machine + user PATH if `git` is not found in a fresh shell.
- WSL `Ubuntu-24.04`: Python 3 (+ Pillow), SH binutils (`sudo apt install binutils-sh-elf`:
  `sh-elf-as`, `sh-elf-ld`, `sh-elf-objcopy`, `sh-elf-objdump`).
- MAME 0.289 headless test env at `~/mame` (`\\wsl$\Ubuntu-24.04\home\brian\mame`), from
  `IAmTheChuckster/mame0.289_claude`: `bin/cv1k`, `scripts/run.sh`, `lua/harness.lua`, `roms/`, `work/`.
- WSL quirks: `wsl -- bash -lc '...'` mangles `$VAR` and quotes, so write a `.sh` script and run
  `wsl -d Ubuntu-24.04 -- bash /mnt/c/.../script.sh`. `/tmp` is cleared between `wsl` calls; keep build
  output under `~/mame/work/`. The repo is at `/mnt/d/GitHub/<repo>`.

## Repo layout (proven)
```
src/          *.s (SH-3 assembly), build.py, update_patchers.py, README.md (addresses and hooks)
tools/mame/   project harness (futari_harness.lua) and input schedules
dev_notes/    findings about the game (mechanics, RAM map), marked VERIFIED or open
mister/       MiSTer .mra
patch.py      stdlib-only Python patcher
index.html    web patcher (GitHub Pages, runs in the browser, nothing uploaded)
README.md     about, to do, bugs, patch notes, how to patch, credits, disclaimer
```

## How the patch works
- Free tail of u4 (all `0xFF`, here file offset `0x1F8000`) holds a small `stub.s` plus the patch blob.
- The u4 header entry pointer (`0x1C4`, originally the game entry) is pointed at the stub. The stub copies the
  blob to free RAM (`0x0C7C0000`), the blob's `patcher` installs hooks in the unpacked program in RAM, then
  jumps to the real entry. Hooks are installed **before the game runs** because MAME's DRC does not see later
  changes to code or code literals.
- u4 is byte-swapped in the MAME set: swap 16-bit pairs before patching and back after.
- Hook styles used: replace a literal-pool word a `jsr` loads (cleanest); replace a `mov.l @(d,PC),r0` so an
  existing `jsr @r0` calls our code; patch a single instruction word (for example `and #16,r0` to
  `and #0,r0`). Write through the uncached alias (`0xAC......`).
- Keep a mode variable in free RAM (`0x0C7BFF00`) so ORIGINAL plays exactly like the original game.

## Build and test loop
1. Edit `src/*.s` and raise `src/BUILD` by one (it goes on the boot screen and into the patchers). Build in WSL: `python3 src/build.py ~/mame/roms/<set>.zip ~/mame/work/<newset>_new.zip`
   (prints the new u4 CRC).
2. For MAME, make `~/mame/roms_arr/<set>.zip` with the patched u4 under the **original** file name, and run
   with `ROMPATH=$HOME/mame/roms_arr` (keep the real set untouched). First boot initialises NAND/EEPROM.
3. Run: `GAME=<set> HARNESS=lua/<proj>_harness.lua BT_SCHED=... BT_SNAP=N scripts/run.sh FRAMES`.
   Save a state at an interesting frame (`BT_SAVE=frame:name`), then load it from Lua (`BT_LOADSTATE`,
   because `-state` hangs headless) and snapshot every frame (`BT_SNAP=1`).
4. Check results with contact sheets and pixel counts, not just single screenshots: flicker and blink bugs
   only show frame to frame.
5. When it works: `python3 src/update_patchers.py <orig>.zip <new>.zip` updates the Python patcher, the web
   patcher (including its embedded MRA) and the `.mra` CRC. Then verify that the Python patcher output and
   the web patcher's embedded bytes both equal the build, update the CRCs and notes in both READMEs, and
   copy the new set to the local `roms/` (back up the old one).

## Reverse engineering tips
- RAM dump at a frame (`BT_RAMSNAP`), search it for ASCII strings and for 32-bit big-endian pointers to them;
  the code that draws a string sits just after its literal pool.
- Disassemble a RAM region: `dd` it out and run
  `sh-elf-objdump -D -b binary -m sh -EB --adjust-vma=0x<addr>`.
- Text draw routine here was `0x0C05CBD8` (r4 x, r5 y, r7 string), colour word `0x0C05CB50`; other CV1000
  Cave games likely use the same library at different addresses.
- Some text (for example "SALE BY AMI") is pre-drawn sprites, not strings; handle it in the display list.
- Debugger watchpoints do not fire in this build and Lua write taps crash; use pokes (`BT_POKE`) and per-frame
  watches (`BT_WATCH`) instead.
- SH-3: never put a PC-relative `mov.l` in a branch delay slot (illegal on real hardware even if MAME runs it).

## Targets
- MAME 0.289 (MAME warns about the checksum of the replaced u4; expected).
- MiSTer CV1k core by Raki: `.mra` loads u2 and the YMZ ROMs straight to DDR3 (`address=`), u4 last, listed
  twice (A21 mirror).
