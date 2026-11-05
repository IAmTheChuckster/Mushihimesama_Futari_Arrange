-- Headless CV1000 harness for MAME 0.289.
-- Env: BT_SCHED (input schedule file), BT_SNAP (snapshot every N frames, 0=off),
--      BT_FRAMES (stop after N frames), BT_SAVE "frame:name" (save state), BT_DUMP "addr:len" (dump RAM each frame to work/dump.bin)
local sched_file = os.getenv("BT_SCHED")
local snap_every = tonumber(os.getenv("BT_SNAP") or "0")
local max_frames = tonumber(os.getenv("BT_FRAMES") or "3000")
local save_spec  = os.getenv("BT_SAVE")
local dump_spec  = os.getenv("BT_DUMP")

local map = { U={":P1","P1 Up"}, D={":P1","P1 Down"}, L={":P1","P1 Left"}, R={":P1","P1 Right"},
  A={":P1","P1 Button 1"}, B={":P1","P1 Button 2"}, C={":P1","P1 Button 3"}, Q={":P1","P1 Button 4"},
  K={":PORT_C","Coin 1"}, V={":PORT_C","Service 1"}, S={":PORT_C","1 Player Start"}, T={":PORT_C","2 Players Start"},
  X={":PORT_C","Service Mode"} }

local fields = {}
for k, v in pairs(map) do
  local port = manager.machine.ioport.ports[v[1]]
  if port then for name, f in pairs(port.fields) do if name == v[2] then fields[k] = f end end end
  if not fields[k] then
    for _, p in pairs(manager.machine.ioport.ports) do for name, f in pairs(p.fields) do if name == v[2] then fields[k] = f end end end
  end
end

local events = {}
if sched_file then
  for line in io.lines(sched_file) do
    local fr, toks = line:match("^%s*(%d+)%s+(%S+)")
    if fr then events[#events+1] = { tonumber(fr), toks } end
  end
  table.sort(events, function(a,b) return a[1] < b[1] end)
end

local save_frame, save_name
if save_spec then save_frame, save_name = save_spec:match("^(%d+):(.+)$"); save_frame = tonumber(save_frame) end
local dump_addr, dump_len, dump_fh
if dump_spec then
  local a, l = dump_spec:match("^(%x+):(%x+)$")
  dump_addr, dump_len = tonumber(a,16), tonumber(l,16)
  dump_fh = io.open("work/dump.bin", "wb")
end
local space = manager.machine.devices[":maincpu"].spaces["program"]

local ramsnap = {}
for f in (os.getenv("BT_RAMSNAP") or ""):gmatch("%d+") do ramsnap[tonumber(f)] = true end
local ram_base = tonumber(os.getenv("BT_RAMBASE") or "0c000000", 16)
local ram_len  = tonumber(os.getenv("BT_RAMLEN") or "800000", 16)
local pokes = {}
for fr, a, v, sz in (os.getenv("BT_POKE") or ""):gmatch("(%d+):(%x+):(%x+):?(%d*)") do pokes[#pokes+1] = {tonumber(fr), tonumber(a,16), tonumber(v,16), tonumber(sz) or 1} end
local watch = {}
for a, n in (os.getenv("BT_WATCH") or ""):gmatch("(%x+):(%d+)") do watch[#watch+1] = {tonumber(a,16), tonumber(n)} end
local wfh = (#watch > 0) and io.open("work/watch.csv", "w") or nil
local frame, idx, held = 0, 1, {}
local function apply(toks)
  for k, f in pairs(fields) do f:set_value(0) end
  held = {}
  if toks ~= "-" then for c in toks:gmatch(".") do if fields[c] then fields[c]:set_value(1); held[c] = true end end end
end

local dcmds = {}
for spec in (os.getenv("BT_DCMD") or ""):gmatch("[^;]+") do
  local fr, c = spec:match("^(%d+):(.*)$")
  if fr then dcmds[tonumber(fr)] = c end
end
local lua_state = os.getenv("BT_LOADSTATE")
local loaded = false
emu.register_frame_done(function()
  if lua_state and not loaded then loaded = true; manager.machine:load(lua_state); return end
  frame = frame + 1
  while idx <= #events and events[idx][1] <= frame do apply(events[idx][2]); idx = idx + 1 end
  for c in pairs(held) do fields[c]:set_value(1) end
  if snap_every > 0 and frame % snap_every == 0 then manager.machine.video:snapshot() end
  if dump_fh then
    local t = {}
    for i = 0, dump_len - 1 do t[#t+1] = string.char(space:read_u8(dump_addr + i)) end
    dump_fh:write(table.concat(t))
  end
  if dcmds[frame] and manager.machine.debugger then manager.machine.debugger:command(dcmds[frame]) end
  if ramsnap[frame] then
    local fh = io.open("work/ram_" .. frame .. ".bin", "wb")
    fh:write(space:read_range(ram_base, ram_base + ram_len - 1, 8)); fh:close()
  end
  for _, p in ipairs(pokes) do
    if p[1] <= frame then
      if p[4] == 4 then space:write_u32(p[2], p[3]) elseif p[4] == 2 then space:write_u16(p[2], p[3]) else space:write_u8(p[2], p[3]) end
    end
  end
  if wfh then
    local t = {frame}
    for _, w in ipairs(watch) do
      local v = (w[2] == 4) and space:read_u32(w[1]) or (w[2] == 2) and space:read_u16(w[1]) or space:read_u8(w[1])
      t[#t+1] = v
    end
    wfh:write(table.concat(t, ",") .. "\n")
  end
  if save_frame and frame == save_frame then manager.machine:save(save_name) end
  if frame >= max_frames then
    if dump_fh then dump_fh:close() end
    if wfh then wfh:close() end
    manager.machine:exit()
  end
end)
