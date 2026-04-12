-- Neural interface auto-eat and auto-attack
-- Attach a Neural Interface to this computer.

local AUTO_EAT_THRESHOLD = 16
local ATTACK_RANGE = 4.5
local ATTACK_COOLDOWN = 0.25

local neural = peripheral.find("neuralInterface") or peripheral.find("neural")
if not neural then
  error("Neural Interface not found")
end

local function has(module)
  return neural.hasModule and neural.hasModule(module)
end

if not (has("plethora:chat") or has("chat")) then
  -- Optional; only used for warnings
end

if not (has("plethora:sensor") or has("sensor")) then
  error("Neural Interface missing sensor module")
end

if not (has("plethora:introspection") or has("introspection")) then
  error("Neural Interface missing introspection module")
end

if not (has("plethora:laser") or has("laser")) then
  error("Neural Interface missing laser module")
end

local function say(msg)
  if has("plethora:chat") or has("chat") then
    neural.chat(msg)
  end
end

local function getHunger()
  local info = neural.getMetaOwner()
  if not info or not info.food then return nil end
  return info.food.level
end

local FOOD_SLOT = 2
local WEAPON_SLOT = 1

local function tryEat()
  local hunger = getHunger()
  if not hunger then return end
  if hunger >= AUTO_EAT_THRESHOLD then return end

  if not (neural.hasModule("plethora:inventory") or neural.hasModule("inventory")) then
    return
  end

  local items = neural.getInventory()
  local item = items and items[FOOD_SLOT]
  if item and item.name and item.count then
    local ok, consumed = pcall(neural.use, FOOD_SLOT)
    if ok and consumed then
      say("Auto-eat used slot " .. FOOD_SLOT)
    end
  end
end

local function isHostile(entity)
  if not entity or not entity.name then return false end
  if entity.name == "minecraft:player" then return false end
  if entity.name:find("plethora") then return false end
  if entity.type and entity.type == "Hostile" then return true end
  if entity.category and entity.category == "hostile" then return true end
  return false
end

local function distance(a, b)
  local dx = (a.x or 0) - (b.x or 0)
  local dy = (a.y or 0) - (b.y or 0)
  local dz = (a.z or 0) - (b.z or 0)
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function tryAttack()
  local entities = neural.sense()
  local owner = neural.getMetaOwner()
  if not entities or not owner then return end

  local closest
  local closestDist

  for _, entity in pairs(entities) do
    if isHostile(entity) then
      local dist = distance(entity.position or entity, owner.position or owner)
      if dist <= ATTACK_RANGE and (not closestDist or dist < closestDist) then
        closest = entity
        closestDist = dist
      end
    end
  end

  if closest and closest.id then
    pcall(neural.use, WEAPON_SLOT)
    neural.fire(closest.id)
  end
end

say("Neural auto-eat/attack active")

local lastAttack = 0
while true do
  tryEat()

  local now = os.clock()
  if now - lastAttack >= ATTACK_COOLDOWN then
    tryAttack()
    lastAttack = now
  end

  os.sleep(0.1)
end
