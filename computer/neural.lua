-- Neural interface auto-eat and auto-attack
-- Attach a Neural Interface to this computer.

local AUTO_EAT_THRESHOLD = 20

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

if not (has("plethora:introspection") or has("introspection")) then
  error("Neural Interface missing introspection module")
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

say("Neural auto-eat active")
while true do
  tryEat()

  os.sleep(0.1)
end
