# Mushihime-Sama Futari Black Label (futariblj) - mechanics notes (work in progress)

Status: partial. Verified items are marked VERIFIED; everything else is open. No ROM data is included here, only findings.

## Set / board
- MAME set `futariblj` (clone of `futaribl`). Files in the set: futariblk_u2, futariblk_u4 (2 MB), u23, u24.
- u4 is 2 MB, so the board is most likely CV1000-B (8 MB RAM at 0x0C000000-0x0C7FFFFF). Not yet checked against the MAME machine definition.
- Test environment: https://github.com/IAmTheChuckster/mame0.289_claude (MAME 0.289). Extra tools for this project are in `tools/mame/`.

## Menu path (frames from a fresh third boot, headless, -nothrottle)
- Memory check ends ~frame 1500; the attract/title loop follows.
- Coin (K) at 2600, 1P start (S) at 2700. Inserting a coin jumps straight to the title screen.
- Mode Select shows: Original / Maniac / God (God = down, down, A). Character Select: lever left/right, A to confirm.
- Gameplay (stage 1) starts ~frame 3500 after the intro art.
- `-state` hangs headless; load save states from Lua instead (`BT_LOADSTATE`, see `tools/mame/`).

## Controls
| Button | Role | Seen on screen |
|---|---|---|
| A (button 1) | Focus shot (must be HELD; slows the ship) | two columns of blue shots |
| B (button 2) | Bomb | large cyan blast clearing the screen |
| C (button 3) | Rapid shot (no slowdown) | narrow stream with orange tips |
| Q (button 4) | none | no visible effect |

## Movement speed (VERIFIED from X at 0x0C383A68, per frame)
- Normal, or C held (rapid): 3 px/frame.
- A held (focus): the slowdown begins about 19 frames after A is pressed, drops to 2 px/frame within roughly 10 more frames, and a long hold settles at about 1.5 px/frame (alternating 2 and 1 px), half of normal speed.
- When A is already held before the stick moves, the ship moves at the slow speed straight away.
- Left edge stops at X = 8. Right edge reached at least 232.
- Fire rates, hold-vs-tap behaviour and bomb/hyper counts are NOT measured yet.

## Player struct (VERIFIED by poke)
- X: 16-bit big-endian at 0x0C383A68. Starts at 120 (screen centre). Poking 60 moved the ship left.
- Y: 16-bit at 0x0C383A6C. Starts at 132, larger = higher on screen (poking 200 moved the ship up). Up speed measured 3 px/frame; down speed looked like 2 px/frame (not re-checked).
- Nearby words that changed with movement: 0x0C383A36, 0x0C383A70, 0x0C383A74 (small tilt or velocity-like values).
- Copies of X exist at 0x0C49146C and 0x0C4D75DC (poking them did not move the ship, so they are derived).

## Title screen text (for the ARCADE / ARRANGE menu)
Design agreed with the owner: after a coin, ARCADE then ARRANGE replace the "PRESS 1P OR 2P START" line, in the same white-with-grey-shadow text as "CREDITS:", the selected item in yellow with a right-pointing arrow, no box.
- VERIFIED: the small system-font lines are real ASCII strings in the game's data, found in the running game's RAM between 0x0C1D2900 and 0x0C1D2F60 (for example "PRESS 1P OR 2P START" at 0x0C1D2DE4, "CREDITS:", "RANK  (NORMAL)", "INSERT COIN", "GOD:", "MANIAC:", "ORIGINAL:"). New menu text can be added through the same text routine; the letters A R C D E N G all exist in that font.
- A table of pointers to these strings sits near 0x0C092180-0x0C0921A8, just before the code that draws them.
- NOT FOUND as ASCII: the "SALE BY AMI" and copyright lines. They are most likely pre-drawn images. Strong evidence, not proof (debugger watchpoints do not fire in this build and Lua write taps crash).

## Not yet found
- Score variable: it is not a plain 32-bit binary or BCD word that steps 0 -> HUD value.
- Gem creation rules, scoring rules, rank counters.
- Palm: the saved Palm run looked identical to Reco's, so it is NOT confirmed that Palm was selected.

## Next
1. Find the title screen routine and the start-button check to hook the menu.
2. Find the focus timer (the variable counting frames of A held, slowdown near 19 frames).
3. Find the score-add routine, gem rules and rank counters.
4. Confirm Palm selection.

## Title menu patch (build 1, DONE - pushed to GitHub)
- Hook: PRESS-line draw at 0x0C092128 (`mov.l @(0x16),r0` = word d016) is changed to `d003`; the literal at 0x0C092138 (nop padding) holds our routine. The existing `jsr @r0` then calls our menu every frame.
- Text routine T = 0x0C05CBD8 (r4 = x, r5 = y, r7 = string). Screen is 240x320 (portrait). Items at y 216 and 232; ORIGINAL MODE x=68, ARRANGE MODE x=72; arrow ">" 14 px left.
- Colour word is global 0x0C05CB50, copied to the text slot; default 0x80808080 (white). Yellow = 0x80FFFF00 (RGB order). Restore the old value after drawing.
- Input: held bits for P1 at 0x0C05C474 (also 0x0C05C468): Up 0x01, Down 0x02, A 0x10, Start 0x8000. The menu does its own edge detection.
- Mode variable at 0x0C7BFF00 (0 original, 1 arrange); previous-input at 0x0C7BFF04. Free RAM from 0x0C7B0000 to 0x0C7FFE9F (stack above).
- Boot: u4 header entry at file offset 0x1C4 (word-swapped file) was 0x0C002A30; now points at a ROM stub at 0x801F8000 (file 0x1F8000, free tail starts 0x1F2800) which copies the 284-byte blob to 0x0C7C0000, installs the hook, jumps to 0x0C002A30.
- Pitfall found: a PC-relative mov.l in a branch delay slot gave wrong colours in MAME (and is illegal on SH-3). Avoid.
- Patched u4 CRC 287ad6f2 (original b9467b6d). Python patcher == web patcher == build output. Verified in MAME: menu shows, Up/Down toggles, Start goes to Mode Select, mode var = 1 after choosing ARRANGE.
- Input: Start edge words 0x0C05C478/47C hold newly-pressed bits for one frame.
- Not done: menu shows wherever the PRESS line shows (title and any screen with credits), not only the title; not tested on MiSTer/real PCB.
