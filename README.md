# Mushihimesama Futari Arrange
A gameplay patch for `Mushihime-Sama Futari Black Label (Japan, 2007/12/11 BLACK LABEL VER)`<br>
**Current build: 53**<br>
This repository holds only source, tools and notes. **No ROM data is included**; you patch your own legally owned dump.

## About
Why did I make this? Because it's fun and for my own personal research to see the capabilities of Claude.<br>
While Claude was used I put effort in making sure there are balanced gameplay.<br>
I did all the testing and planning.

## To Do
1. Add Character swaps in-game<br>
   a. Reco-to-Palm uses 0xB6<br>
   b. Palm-to-Reco uses 0xDE<br>

   
## Bugs to fix
None known.

## Patch Notes
- **Title menu:** after you insert a coin the title screen shows **ORIGINAL ARCADE** and **ARRANGE MODE** where "PRESS 1P OR 2P START" was.
  - The selected item is yellow with an arrow next to it; the other is white.
  - Up and Down move the arrow, Start confirms (the game starts as usual).
  - ORIGINAL ARCADE plays the original game. ARRANGE MODE already stores the chosen mode in RAM (`0x0C7BFF00`: 0 = original, 1 = arrange) and turns on the arrange changes below.
  - Uses the game's own text style (white with a grey shadow, like "CREDITS:").
- **Title screen:** the "SALE BY AMI" line is replaced by a red NOT FOR SALE, both before and after the first coin. It no longer flashes back to SALE BY AMI while INSERT COIN blinks.
- **Hyper Bomb (ARRANGE MODE only):** pressing bomb no longer fires the normal blast. Instead every bullet on screen is cancelled into big gems, using the game's own bullet-cancel (the same one you see when a big enemy dies). The character's bomb voice still plays, a bomb is still used, the gem multiplier is kept, and you are invulnerable for 2 seconds. ORIGINAL ARCADE keeps the normal bomb.
- **Chain cancel (ARRANGE MODE only):** when an enemy is destroyed, every bullet within 48 px of it is cancelled into a small gem, and every bullet within 32 px of a cancelled bullet is cancelled too, so dense bullet clusters chain away.
- **Hyper meter (ARRANGE MODE only):** the six empty 2P boxes at the bottom right fill from right to left, one box per 2000. Reco shows the red P2 bomb icon and Palm shows Reco's green swirl. Every gem fills it by its size: the four gem sizes give 1, 5, 10 and 15. At 12000 you get an extra bomb (up to the game's maximum) with a voice (Reco plays voice 0xF0, Palm plays 0xC8), every bullet on the screen is cancelled into big gems, and the boxes start again from empty. Reset on the title screen. The swirls slide down with the bottom bar when the stage ends, like the game's own bomb icons, and are hidden on the score tally and game over screens.
- **x99999 multiplier and cash out (ARRANGE MODE only):** the gem multiplier (the x counter) now goes up to 99999 instead of 30000. While it is at the 99999 cap every gem and every bullet cancelled into a gem pays a flat 99999 points. **Cash out:** pressing the bomb button at x99999 cancels every bullet on the screen into big (gold) gems, each worth 99999 for the next 10 seconds, and the multiplier resets to 0. A bomb below the cap works as before. ORIGINAL ARCADE keeps the 30000 cap.
- **God Mode only (ARRANGE MODE):** ARRANGE MODE always plays God Mode. The Mode Select screen steps ORIGINAL, MANIAC, GOD by itself and lands on God; your buttons are ignored there, so the mode cannot be chosen by hand.
- **ARRANGE MODE banner:** the red "God Mode" banner under the score reads **アレンジモード** instead, in the same red with a dark brown shadow, from the stage intro on. The label is cut from your own Xbox 360 Mushihimesama package when you patch (see below). ORIGINAL ARCADE keeps its own banners.
- **Grazing (ARRANGE MODE only):** every enemy bullet within 24 px of the centre of your ship counts as a graze, every frame it stays that close, also while you are invulnerable. Each graze is worth 100 points and adds 1 to the graze counter: gold digits just above the x counter on the left, left-justified like it. The counter only counts up, stops at 99999 and goes back to 0 after each stage (on the score tally) and on the title screen. It follows the x counter on the left: it shows, fades and moves up or down with it, and slides out to the left with it at the end of a stage.
- **1P only (ARRANGE MODE):** 2P is disabled: 2P START and the 2P controls are ignored. ORIGINAL ARCADE still lets two players play.
- **Boot screen:** the memory-check screen now reads FUTARI ARRANGE B<build> (for example B42) and 2026.11.20, centred.
- **Warning screen:** the "for use in Japan only" notice is replaced by an unofficial-project disclaimer, HAVE FUN!!! and 2026/11/20 FUTARI ARRANGE.
- Everything else in the game is unchanged; ORIGINAL ARCADE plays exactly like the original.

## Patching the game
You need:
- your own **futariblj.zip** (MAME set, Black Label, 2007/12/11) with the original u4 (`futariblk_u4`, CRC `b9467b6d`), u2, u23 and u24;
- your own **Xbox 360 Games-on-Demand package of Mushihimesama**, title ID **435A07E3** (a .zip, any file name, containing `5F9DF6331EAE85814989` and `5F9DF6331EAE85814989.data`). The アレンジモード banner is cut from it on your machine; it is required.

Both patchers check the input and give identical files: `futariarr_u4` (CRC `771f2bc1`), the complete romset `futariarr.zip` (futariblk_u2, u23, u24, futariarr_u4) and `Mushihimesama Futari Arrange.mra` for MiSTer.

### Web Patcher
1. Open the [web patcher](https://iamthechuckster.github.io/Mushihimesama_Futari_Arrange/).
2. Load your `futariblj.zip` (or the loose u4 file). Everything runs in your browser; nothing is uploaded.
3. Load your Mushihimesama 360 GOD package (`435A07E3`, .zip or .7z).
4. Check that the files are shown as OK.
5. Download **futariarr.zip** (complete romset) and, for MiSTer, **Mushihimesama Futari Arrange.mra**.

### Python script
Needs Python 3 only (no extra packages). Download `patch.py` from this repository, then run:
```
python3 patch.py futariblj.zip --god 435A07E3.zip --zip --mra
```
- `--god` (required) is your Mushihimesama 360 GOD package (`435A07E3`, .zip).
- `--zip` also writes `futariarr.zip` (the input must be the zip).
- `--mra` also writes `Mushihimesama Futari Arrange.mra`.
- `-o FILE` sets where `futariarr_u4` is written.

### Using the patched files
- **MAME:** MAME doesn't know the `futariarr` set, so make a copy of your futariblj set (keep the original safe), replace its `futariblk_u4` with `futariarr_u4` renamed to `futariblk_u4`, and run `mame futariblj`. MAME will warn about a wrong checksum; that is expected.
- **MiSTer (CV1k core):** copy `futariarr.zip` to your `games/mame` folder and the `.mra` to `_Arcade`.

### Building from source
`src/build.py futariblj.zip OUT.zip` assembles `src/*.s` (needs SH binutils: `sh-elf-as`, `sh-elf-ld`, `sh-elf-objcopy`), then `src/update_patchers.py` embeds the changed bytes into the patchers. See [`src/README.md`](src/README.md).

## Testing
This patch was tested with MAME 0.289 and [CV1k core for the MiSTer FPGA by Raki](https://www.patreon.com/c/ikamusume/posts)<br>
It may even work on a PCB but do so on your own risk.

## Notes
Findings about how the game works (controls, player data, title screen text) are in [`dev_notes/futariblj-mechanics.md`](dev_notes/futariblj-mechanics.md). Test tools for MAME are in [`tools/mame`](tools/mame) and [`tools/wsl`](tools/wsl) (build and check scripts). [`CLAUDE.md`](CLAUDE.md) has the setup and workflow for continuing this project or starting a new CV1000 patch.

## Credits

- [IAmTheChuckster](https://github.com/IAmTheChuckster)  project, testing
- [Claude](https://claude.ai) (Anthropic)  reverse engineering and patcher code
- Tested on the CV1k core for the MiSTer FPGA by [Raki](https://www.patreon.com/c/ikamusume/posts)

## Disclaimer

This repository contains a fan-made patch for research and technical analysis. The repository does not intentionally distribute the original game ROM, executable, or game assets. Users must obtain their own copy of the original game. This project is unofficial and is not affiliated with, endorsed by, or authorized by CAVE. All rights to the original game and its associated intellectual property remain with their respective rights holders. No license to third-party copyrighted material is granted by this repository.
