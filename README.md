# Mushihimesama Futari Arrange
A gameplay patch for `Mushihime-Sama Futari Black Label (Japan, 2007/12/11 BLACK LABEL VER)`<br>
This repository holds only source, tools and notes. **No ROM data is included**; you patch your own legally owned dump.

## To Do:
1. Use Black Label ROM
2. Only use God Mode
3. Bombs are now hyper
4. in hyper bullets cancel into big stars
5. stars fill hyper

   
## About
Why did I make this? Because it's fun and for my own personal research to see the capabilities of Claude.<br>
While Claude was used I put effort in making sure there are balanced gameplay.<br>
I did all the testing and planning.

## Patch Notes
- **Title menu:** after you insert a coin the title screen shows **ORIGINAL ARCADE** and **ARRANGE MODE** where "PRESS 1P OR 2P START" was.
  - The selected item is yellow with an arrow next to it; the other is white.
  - Up and Down move the arrow, Start confirms (the game starts as usual).
  - ORIGINAL ARCADE plays the original game. ARRANGE MODE already stores the chosen mode in RAM (`0x0C7BFF00`: 0 = original, 1 = arrange) so the arrange changes from the To Do list can use it; for now it plays the same as the original.
  - Uses the game's own text style (white with a grey shadow, like "CREDITS:").
- Everything else in the game is unchanged.

## Patching the game
You need your own **futariblj.zip** (MAME set, Black Label, 2007/12/11) with the original u4 (`futariblk_u4`, CRC `b9467b6d`), u2, u23 and u24. Both patchers check the input and give identical files: `futariarr_u4` (CRC `dc7aac44`), the complete romset `futariarr.zip` (u2, u23, u24, futariarr_u4) and `Mushihimesama Futari Arrange.mra` for MiSTer.

### Web patcher
1. Open the [web patcher](https://iamthechuckster.github.io/Mushihimesama_Futari_Arrange/).
2. Load your `futariblj.zip` (or the loose u4 file). Everything runs in your browser; nothing is uploaded.
3. Check that the files are shown as OK.
4. Download what you need: **futariarr.zip** (complete romset), **Mushihimesama Futari Arrange.mra**, **futariarr_u4.zip** or **futariarr_u4**.

### Python script
Needs Python 3 only (no extra packages). Download `futari_patch.py` from this repository, then run:
```
python3 futari_patch.py futariblj.zip --zip --mra
```
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
Findings about how the game works (controls, player data, title screen text) are in [`docs/futariblj-mechanics.md`](docs/futariblj-mechanics.md). Test tools for MAME are in [`tools/mame`](tools/mame).

## Credits

- [IAmTheChuckster](https://github.com/IAmTheChuckster)  project, testing
- [Claude](https://claude.ai) (Anthropic)  reverse engineering and patcher code
- Tested on the CV1k core for the MiSTer FPGA by [Raki](https://www.patreon.com/c/ikamusume/posts)

## Disclaimer

This repository contains a fan-made patch for research and technical analysis. The repository does not intentionally distribute the original game ROM, executable, or game assets. Users must obtain their own copy of the original game. This project is unofficial and is not affiliated with, endorsed by, or authorized by CAVE. All rights to the original game and its associated intellectual property remain with their respective rights holders. No license to third-party copyrighted material is granted by this repository.
