# Mushihimesama Futari Arrange
A gameplay patch for `Mushihime-Sama Futari Black Label (Japan, 2007/12/11 BLACK LABEL VER)`<br>
This repository holds only source, tools and notes. **No ROM data is included**; you patch your own legally owned dump.

## To Do:
1. Use Black Label ROM
2. Only use God Mode
3. Bombs are now hyper
4. in hyper bullets cancel into big stars
5. stars fill hyper
6. **Title menu:** after a coin, show **ARCADE** and **ARRANGE** on the title screen (in progress)

   
## About
Why did I make this? Because it's fun and for my own personal research to see the capabilities of Claude.<br>
While Claude was used I put effort in making sure there are balanced gameplay.<br>
I did all the testing and planning.

## Patch Notes
- **Title menu (in development, not released yet):** after you insert a coin the title screen shows **ARCADE** and **ARRANGE** where "PRESS 1P OR 2P START" was.
  - The selected item is yellow with an arrow next to it; the other is white.
  - Up and Down move the arrow, Start confirms.
  - ARCADE is meant to play the original game; ARRANGE is meant to use the arrange changes from the To Do list.
  - Uses the game's own text style (white with a grey shadow, like "CREDITS:").
- **Patchers:** a web patcher and a Python patcher will be added with the first release.

## Patching the game

### With the web patcher (easiest)
Open the **[Web Patcher](https://iamthechuckster.github.io/Akai_Katana_Unlimited/)** (`index.html`) and drop in your `rom.zip`. It checks the file names and CRCs, builds the patched files automatically, and lets you download just the patched files or a complete `rom.zip` romset. Everything runs in your browser; nothing is uploaded.

### With Python
Coming with the first release.


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
