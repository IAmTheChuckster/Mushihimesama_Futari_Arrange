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

## Title screen text (for the ORIGINAL ARCADE / ARRANGE MODE menu)
Design agreed with the owner: after a coin, ORIGINAL ARCADE then ARRANGE MODE replace the "PRESS 1P OR 2P START" line, in the same white-with-grey-shadow text as "CREDITS:", the selected item in yellow with a right-pointing arrow, no box.
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
- Text routine T = 0x0C05CBD8 (r4 = x, r5 = y, r7 = string). Screen is 240x320 (portrait). Items at y 216 and 232; ORIGINAL ARCADE x=60, ARRANGE MODE x=72; arrow ">" 14 px left.
- Colour word is global 0x0C05CB50, copied to the text slot; default 0x80808080 (white). Yellow = 0x80FFFF00 (RGB order). Restore the old value after drawing.
- Input: held bits for P1 at 0x0C05C474 (also 0x0C05C468): Up 0x01, Down 0x02, A 0x10, Start 0x8000. The menu does its own edge detection.
- Mode variable at 0x0C7BFF00 (0 original, 1 arrange); previous-input at 0x0C7BFF04. Free RAM from 0x0C7B0000 to 0x0C7FFE9F (stack above).
- Boot: u4 header entry at file offset 0x1C4 (word-swapped file) was 0x0C002A30; now points at a ROM stub at 0x801F8000 (file 0x1F8000, free tail starts 0x1F2800) which copies the 288-byte blob to 0x0C7C0000, installs the hook, jumps to 0x0C002A30.
- Pitfall found: a PC-relative mov.l in a branch delay slot gave wrong colours in MAME (and is illegal on SH-3). Avoid.
- Patched u4 CRC 7dab016a (original b9467b6d). Python patcher == web patcher == build output. Verified in MAME: menu shows, Up/Down toggles, Start goes to Mode Select, mode var = 1 after choosing ARRANGE.
- Input: Start edge words 0x0C05C478/47C hold newly-pressed bits for one frame.
- Not done: menu shows wherever the PRESS line shows (title and any screen with credits), not only the title; not tested on MiSTer/real PCB.

## Bomb research (Arrange Mode: bomb cancels bullets into big gems) - in progress, nothing patched yet
- Input: B = bit 0x20 in the P1 input words (0x0C05C468 / 0x0C05C474); C = 0x40. The player struct copy of the input is at 0x0C383A34.
- Method: run the same state twice (deterministic), once with B pressed, once without, and diff RAM and instruction traces (`BT_DCMD="299:trace file,0,noloop;302:trace off"` in `tools/mame/futari_harness.lua`, MAME needs `-debug -debugger none -nodrc`).
- Words that change when the bomb starts: 0x0C38340C 0 -> 0x7FFFFFFE (looks like the invulnerability timer), 0x0C38342C 0 -> 0x3F, 0x0C3834BC 0 -> 1, 0x0C4DA3D0 7 -> 6 and 0x0C4DA3A4 0 -> 7 (bomb stock / used count, not confirmed). New effect objects are linked in at 0x0C3655xx and 0x0C51C5xx.
- Bomb-only code: input handling 0x0C05C774, player state machine 0x0C07A0xx-0x0C07B1xx (state switch near 0x0C07B0C0), effect spawners 0x0C064CA0 and 0x0C10C0E0-0x0C10F19A. The bomb itself does not loop over bullets in the first frames, so bullets are cancelled later by something else (probably the blast area).
- Object pool: 84-byte records (stride 0x54) around 0x0C510010-0x0C530000 hold enemies, bullets and more. Fields: +0 x and +4 y (16.16), +8/+0xC velocity, +0x10/+0x14 type pair (for example bullets 0x9E/0x12, enemies 0x8D or 0x80 / 0x0C). Behaviour is script driven (pointers to data at 0x0C28xxxx), so bullets cannot just be edited in place.
- A normal mass cancel happens in the Reco stage 1 run at frame 499 after the state load (bullet-type records 58 -> 17). Gem creation code and the cancel path are not located yet.
- Still to do: find the gem (item) spawn function and the item record format, find the routine that removes a bullet, then loop the pool on bomb start in Arrange Mode only.

## Hyper Bomb (DONE, ARRANGE MODE only)
- Bullet cancel routine: `0x0C06E620(r4 = gem type, r5 = extra item arg)`. Walks the bullet list (manager pointer at 0x0C27DE48, list at +0x48440) and puts every live bullet (state byte +8 = 1/2) into state 3 (the pink ring). When the ring ends (`0x0C06E6D0`, state-3 update), each bullet spawns an item with `0x0C094800(type, x, y, 125, arg)`. r4 = -1 gives no gems (the normal bomb and deaths use that). Wrappers: 0x0C06DDD0, 0x0C06DE20, 0x0C06DE70, 0x0C06DEA0 (enemy kill, uses the type at manager+0x48450).
- Item types (class table 0x0C2847D4): 0 small gem, 1 big gold gem, 2 and 3 coins. Hyper Bomb uses 1.
- Items are refused while `0x0C0691E0(player)` is true: word +12 of the bomb-stock objects (player+0x684 / +0x750), set to 1 at bomb start and cleared when the blast ends.
- Bomb start (player state code 0x0C07B0C0): `0x0C06C680(stock, 1)` (bombing flag), then `0x0C06BBF0(stock, kind)`: checks stock byte +6, cooldown (player+0x7C+24, 64 frames), calls the blast spawner `0x0C10EB90` (literal 0x0C06BC80), stock--, cooldown = 64, invulnerability `0x0C068AA0(player, 0x7FFFFFFF)` (literal 0x0C06BC88; counter at 0x0C38340C). On success the caller plays the voice through `0x0C10D170` and friends (-> 0x0C10E7A0).
- Gem multiplier (the "x367" on the HUD) is player+0x9C (0x0C383AC4), added in 0x0C06B730 when a gem is collected. The normal blast resets it to 1; Hyper Bomb keeps it.
- MAME harness: `BT_DCMD` runs debugger commands at given frames (one per frame number); `bpset`/`wpset` actions print nothing in this build, but `trace file,0,noloop,{tracelog "%08x ",r4}` works and logs registers.

## Chain cancel (DONE, ARRANGE MODE only)
- Enemy slots: 128 x 0x920 bytes from about 0x0C414620; slot +0 active, +0x70 set to 1 when removed, +0x900 actor pointer (actor +8 x, +0xC y, 16.16, same space as bullets).
- `0x0C0764C0(enemy)`: enemy-remove routine called by the enemy scripts when an enemy is destroyed (sets +0x70, appends to the list at 0x0C475300). Hooked at its start.
- Per-bullet cancel, copied from 0x0C06E680: free the bullet's hit node (`0x0C0647B0(@(bullet+0x7C+0x10))`), +0xB = 0, +0x2A = gem type, +0x29 = 1, +0xC = word +0xE, +0x28 = 1, +0x7C+0x10 = 0, +0x7C+0xC = arg, state +8 = 3. Live bullets have state 1 or 2.
- Tested in MAME: chains of 50-85 bullets in stage 1; ORIGINAL ARCADE gives byte-identical player/multiplier traces to the unpatched game.
