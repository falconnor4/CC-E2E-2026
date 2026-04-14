-- Mesh hub: receives status broadcasts and shows them

local MESH_CHANNEL = 7676
local STALE_SECONDS = 10

local modem = peripheral.find("modem")
if not modem then error("Ender modem not found") end

local monitor = peripheral.find("monitor")
if monitor then
  monitor.setTextScale(0.5)
  term.redirect(monitor)
end

modem.open(MESH_CHANNEL)

local nodes = {}

local function fmtPos(pos)
  if not pos then return "?" end
  return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

local function draw()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
  term.write("Mesh Status")

  local now = os.clock()
  local line = 3
  for id, node in pairs(nodes) do
    if now - node.lastSeen <= STALE_SECONDS then
      term.setCursorPos(1, line)
      term.write(id)
      term.setCursorPos(18, line)
      term.write("Pos " .. fmtPos(node.pos))
      term.setCursorPos(40, line)
      term.write("Fuel " .. (node.fuel or "-"))
      line = line + 1
    end
  end
end

local function prune()
  local now = os.clock()
  for id, node in pairs(nodes) do
    if now - node.lastSeen > STALE_SECONDS * 3 then
      nodes[id] = nil
    end
  end
end

local function handleMessage(msg)
  if type(msg) ~= "table" or msg.type ~= "mesh_status" then return end
  local node = msg.node
  if not node or not node.id then return end
  nodes[node.id] = {
    id = node.id,
    pos = node.pos,
    fuel = node.fuel,
    lastSeen = os.clock(),
  }
end

while true do
  local event, _, _, _, msg = os.pullEvent("modem_message")
  handleMessage(msg)
  prune()
  draw()
end
