-- Mesh hub updater: broadcasts update command

local MESH_CHANNEL = 7676
local BASE_URL = "https://raw.githubusercontent.com/falconnor4/CC-E2E-2026/main/"
local FILES = { "mesh/node.lua", "mesh/hub.lua" }

local modem = peripheral.find("modem")
if not modem then error("Ender modem not found") end

modem.open(MESH_CHANNEL)

local args = { ... }
local target = args[1]

modem.transmit(MESH_CHANNEL, MESH_CHANNEL, {
  type = "mesh_command",
  cmd = "update",
  target = target,
  baseUrl = BASE_URL,
  files = FILES,
})

print("Update broadcast sent" .. (target and (" to " .. target) or ""))
