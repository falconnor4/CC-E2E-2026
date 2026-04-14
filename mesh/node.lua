-- Mesh node: broadcasts status over ender modem

local MESH_CHANNEL = 7676
local NODE_ID = os.getComputerLabel() or ("node-" .. os.getComputerID())
local SEND_INTERVAL = 2

local modem = peripheral.find("modem")
if not modem then error("Ender modem not found") end

modem.open(MESH_CHANNEL)

local function getPosition()
  if gps and gps.locate then
    local x, y, z = gps.locate(1)
    if x then return { x = x, y = y, z = z } end
  end
  return nil
end

local function getFuel()
  if turtle and turtle.getFuelLevel then
    return turtle.getFuelLevel()
  end
  return nil
end

local function getMeta()
  local info = {
    id = NODE_ID,
    computerId = os.getComputerID(),
    label = os.getComputerLabel(),
    time = os.clock(),
    fuel = getFuel(),
    pos = getPosition(),
  }
  return info
end

while true do
  modem.transmit(MESH_CHANNEL, MESH_CHANNEL, {
    type = "mesh_status",
    node = getMeta(),
  })
  os.sleep(SEND_INTERVAL)
end
