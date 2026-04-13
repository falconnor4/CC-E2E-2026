-- Pseudo-Doom raycaster for Plethora overlay glasses

local renderInterval = 0.05
local fov = math.rad(66)
local maxDistance = 24

local screenW = 320
local screenH = 180
local screenX = 10
local screenY = 10
local columns = 80

local modules = peripheral.find("manipulator") or peripheral.find("neuralInterface")
if not modules then error("Must have neural interface or manipulator", 0) end

if not modules.hasModule("plethora:glasses") then error("Overlay glasses missing", 0) end
if not modules.hasModule("plethora:introspection") then error("Introspection module missing", 0) end

local canvas = modules.canvas()
canvas.clear()

local function wallColor(distance)
  local shade = math.max(40, math.floor(255 - (distance * 8)))
  return shade * 0x010101
end

local function isWall(x, z)
  if x % 12 == 0 or z % 12 == 0 then return true end
  local n = (x * 734287 + z * 912271) % 100
  return n < 8
end

local function castRay(px, pz, dirX, dirZ)
  local mapX = math.floor(px)
  local mapZ = math.floor(pz)

  local deltaDistX = (dirX == 0) and 1e30 or math.abs(1 / dirX)
  local deltaDistZ = (dirZ == 0) and 1e30 or math.abs(1 / dirZ)

  local stepX, stepZ
  local sideDistX, sideDistZ

  if dirX < 0 then
    stepX = -1
    sideDistX = (px - mapX) * deltaDistX
  else
    stepX = 1
    sideDistX = (mapX + 1.0 - px) * deltaDistX
  end

  if dirZ < 0 then
    stepZ = -1
    sideDistZ = (pz - mapZ) * deltaDistZ
  else
    stepZ = 1
    sideDistZ = (mapZ + 1.0 - pz) * deltaDistZ
  end

  local side = 0
  for _ = 1, maxDistance * 2 do
    if sideDistX < sideDistZ then
      sideDistX = sideDistX + deltaDistX
      mapX = mapX + stepX
      side = 0
    else
      sideDistZ = sideDistZ + deltaDistZ
      mapZ = mapZ + stepZ
      side = 1
    end

    if isWall(mapX, mapZ) then
      local distance
      if side == 0 then
        distance = (mapX - px + (1 - stepX) / 2) / dirX
      else
        distance = (mapZ - pz + (1 - stepZ) / 2) / dirZ
      end
      return math.abs(distance), side
    end
  end

  return maxDistance, 0
end

while true do
  local meta = modules.getMetaOwner()
  local pos = meta and meta.position or { x = 0, z = 0 }
  local angle = meta and math.rad(-meta.yaw % 360) or 0

  canvas.clear()
  canvas.addText({ screenX, screenY - 8 }, "DOOM (ish)", 0xFFFFFF, 1)

  for i = 1, columns do
    local cameraX = (2 * (i - 1) / (columns - 1)) - 1
    local rayAngle = angle + math.atan(cameraX * math.tan(fov / 2))
    local dirX = math.cos(rayAngle)
    local dirZ = math.sin(rayAngle)

    local dist, side = castRay(pos.x, pos.z, dirX, dirZ)
    if dist < 0.01 then dist = 0.01 end

    local lineHeight = math.min(screenH, math.floor(screenH / dist))
    local x = screenX + math.floor((i - 1) * (screenW / columns))
    local y1 = screenY + math.floor((screenH - lineHeight) / 2)
    local y2 = y1 + lineHeight

    local color = wallColor(dist + (side == 1 and 1.5 or 0))
    canvas.addLine({ x, y1 }, { x, y2 }, color)
  end

  sleep(renderInterval)
end
