--- Auto-eat + entity minimap (Plethora)

local scanInterval = 0.2
local renderInterval = 0.05
local scannerRange = 8
local maxEntities = 40

local size = 0.5
local cellSize = 16
local offsetX = 75
local offsetY = 75

local modules = peripheral.find("manipulator") or peripheral.find("neuralInterface")
if not modules then error("Must have neural interface or manipulator", 0) end

if not modules.hasModule("plethora:sensor") then error("The entity sensor is missing", 0) end
if not modules.hasModule("plethora:introspection") then error("The introspection module is missing", 0) end
if not modules.hasModule("plethora:glasses") then error("The overlay glasses are missing", 0) end

local inv = modules.getInventory()
local cachedSlot = false

local canvas = modules.canvas()
canvas.clear()

local entityText = {}
for i = 1, maxEntities do
  entityText[i] = canvas.addText({ 0, 0 }, " ", 0xFFFFFFFF, size)
end

canvas.addText({ offsetX, offsetY }, "^", 0xFFFFFFFF, size * 2)

local function healthColor(current, max)
  if not current then return 0xFFFFFF end
  local ratio = max and max > 0 and (current / max) or (current / 20)
  if ratio >= 0.66 then return 0x00FF00 end
  if ratio >= 0.33 then return 0xFFFF00 end
  return 0xFF0000
end

local function autoEat()
  while true do
    local data = modules.getMetaOwner()
    while data.food and data.food.hungry do
      local item
      if cachedSlot then
        local slotItem = inv.getItem(cachedSlot)
        if slotItem and slotItem.consume then
          item = slotItem
        else
          cachedSlot = nil
        end
      end

      if not item then
        for slot, _ in pairs(inv.list()) do
          local slotItem = inv.getItem(slot)
          if slotItem and slotItem.consume then
            item = slotItem
            cachedSlot = slot
            break
          end
        end
      end

      if item then
        item.consume()
      else
        break
      end

      data = modules.getMetaOwner()
    end

    sleep(5)
  end
end

local entities = {}

local function scan()
  while true do
    local sensed = modules.sense()
    local list = {}

    if sensed then
      for _, entity in pairs(sensed) do
        if entity.name and entity.name ~= "minecraft:player" then
          local pos = entity.position or entity
          local health = entity.health and (entity.health.hp or entity.health) or entity.hp
          local maxHealth = entity.health and (entity.health.maxHp or entity.health.max) or entity.maxHp
          table.insert(list, {
            name = entity.name,
            position = pos,
            health = health,
            maxHealth = maxHealth,
          })
        end
      end
    end

    entities = list
    sleep(scanInterval)
  end
end

local function render()
  while true do
    local meta = modules.getMetaOwner and modules.getMetaOwner()
    local angle = meta and math.rad(-meta.yaw % 360) or math.rad(180)
    local playerPos = meta and meta.position or { x = 0, y = 0, z = 0 }

    for i = 1, maxEntities do
      entityText[i].setText(" ")
    end

    local idx = 1
    for _, entity in ipairs(entities) do
      if idx > maxEntities then break end
      local pos = entity.position or {}
      local dx = (pos.x or 0) - (playerPos.x or 0)
      local dz = (pos.z or 0) - (playerPos.z or 0)

      if math.abs(dx) <= scannerRange and math.abs(dz) <= scannerRange then
        local px = math.cos(angle) * -dx - math.sin(angle) * -dz
        local py = math.sin(angle) * -dx + math.cos(angle) * -dz

        local sx = math.floor(px * size * cellSize)
        local sy = math.floor(py * size * cellSize)
        local text = entityText[idx]
        text.setPosition(offsetX + sx, offsetY + sy)
        if entity.health then
          text.setText(tostring(math.floor(entity.health + 0.5)))
          text.setColor(healthColor(entity.health, entity.maxHealth))
        else
          text.setText("o")
          text.setColor(0xFFFFFF)
        end
        idx = idx + 1
      end
    end
    sleep(renderInterval)
  end
end

parallel.waitForAll(render, scan, autoEat)
