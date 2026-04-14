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

local function primarySignal(signals)
  if not signals then return 0 end
  local best = 0
  for _, value in pairs(signals) do
    if value and value > best then best = value end
  end
  return best
end

local function drawBar(x, y, width, pct)
  local fill = math.floor(width * pct)
  term.setCursorPos(x, y)
  term.write("[" .. string.rep("=", fill) .. string.rep("-", width - fill) .. "]")
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
      local pct
      if node.fuel and node.fuelLimit and node.fuelLimit > 0 then
        pct = node.fuel / node.fuelLimit
      else
        pct = primarySignal(node.signals) / 15
      end

      term.setCursorPos(40, line)
      drawBar(40, line, 14, math.max(0, math.min(1, pct or 0)))
      if node.fuel then
        term.setCursorPos(57, line)
        term.write("Fuel " .. node.fuel)
      end
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
    signals = node.signals,
    fuelLimit = node.fuelLimit,
    lastSeen = os.clock(),
  }
end

while true do
  local event, _, _, _, msg = os.pullEvent("modem_message")
  handleMessage(msg)
  prune()
  draw()
end
