# MAME test tools

Used with the headless CV1000 MAME 0.289 test environment: https://github.com/IAmTheChuckster/mame0.289_claude

No ROM data is in this folder. Put your own `futariblj.zip` in the test environment's `roms/` folder.

- `futari_harness.lua`: the test environment's `lua/harness.lua` plus these extra environment variables:
  - `BT_LOADSTATE=<name>`: load a save state from inside Lua (MAME's `-state` option hangs in headless runs).
  - `BT_RAMSNAP=f1,f2,...`: write the 8 MB work RAM to `work/ram_<frame>.bin` at those frames.
  - `BT_POKE=frame:addr:value:size,...`: write a value to RAM from that frame on (size 1, 2 or 4 bytes).
  - `BT_WATCH=addr:size,...`: log those RAM values every frame to `work/watch.csv`.
- `schedules/`: input schedules (`frame tokens`; `U D L R` stick, `A B C` buttons, `K` coin, `S` 1P start).

Run, from the test environment folder:

```sh
export GAME=futariblj ROMPATH=$PWD/roms HARNESS=lua/futari_harness.lua
BT_SCHED=work/s/god_mode_reco_start.txt BT_SAVE=3560:reco_s1 scripts/run.sh 3565
BT_LOADSTATE=reco_s1 BT_SCHED=work/s/focus_slowdown_test.txt BT_WATCH="c383a68:2,c383a6c:2" scripts/run.sh 150
```

(`scripts/run.sh` in the test environment needs `${HARNESS:-lua/harness.lua}` in place of the fixed harness path.)
