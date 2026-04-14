-- Mesh node: broadcasts status over ender modem

local MESH_CHANNEL = 7676
local CONFIG_PATH = "mesh/node_config.lua"
local DEFAULT_ROLE = "unassigned"
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

local function loadConfig()
  if not fs.exists(CONFIG_PATH) then return nil end
  local ok, data = pcall(dofile, CONFIG_PATH)
  if ok and type(data) == "table" then return data end
  return nil
end

local function saveConfig(cfg)
  local handle = fs.open(CONFIG_PATH, "w")
  handle.write("return " .. textutils.serialize(cfg))
  handle.close()
end

local function promptConfig()
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)
  print("Mesh node setup")
  print("----------------")
  write("Name: ")
  local name = read()
  write("Role (e.g. mob_farm, storage, power): ")
  local role = read()
  if name == "" then name = os.getComputerLabel() or ("node-" .. os.getComputerID()) end
  if role == "" then role = DEFAULT_ROLE end

  local cfg = {
    id = name,
    role = role,
  }
  saveConfig(cfg)
  return cfg
end

local function ensureConfig()
  local cfg = loadConfig()
  if cfg then return cfg end
  return promptConfig()
end

local function getMeta(config)
  local info = {
    id = config.id,
    role = config.role,
    computerId = os.getComputerID(),
    label = os.getComputerLabel(),
    time = os.clock(),
    fuel = getFuel(),
    pos = getPosition(),
  }
  return info
end

local config = ensureConfig()

while true do
  modem.transmit(MESH_CHANNEL, MESH_CHANNEL, {
    type = "mesh_status",
    node = getMeta(config),
  })
  os.sleep(SEND_INTERVAL)
end
