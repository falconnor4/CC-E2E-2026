-- Neural interface auto-eat and auto-attack
-- Attach a Neural Interface to this computer.

local AUTO_EAT_THRESHOLD = 20
local REFRESH_SECONDS = 0.25

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

local autoEatEnabled = true

local function formatBiome(biome)
  if not biome or not biome.name then return "?" end
  return biome.name
end

local function draw()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)

  local info = neural.getMetaOwner() or {}
  local pos = info.position or {}
  local food = info.food or {}
  local health = info.health or {}
  local armor = info.armor or {}
  local biome = info.biome or {}

  print("Neural Interface Dashboard")
  print(string.rep("-", 26))
  print("Auto-eat: " .. (autoEatEnabled and "ON" or "OFF"))
  print("Food slot: " .. FOOD_SLOT .. "  Threshold: " .. AUTO_EAT_THRESHOLD)
  print("Health: " .. (health.hp or "?") .. "/" .. (health.maxHp or "?"))
  print("Armor: " .. (armor.value or "?"))
  print("Hunger: " .. (food.level or "?") .. "/20")
  print("Pos: " .. math.floor(pos.x or 0) .. ", " .. math.floor(pos.y or 0) .. ", " .. math.floor(pos.z or 0))
  print("Biome: " .. formatBiome(biome))
  print("")
  print("Keys: [E] Toggle auto-eat  [Q] Quit")
end

local function handleKeys(key)
  if key == keys.e then
    autoEatEnabled = not autoEatEnabled
    say("Auto-eat " .. (autoEatEnabled and "enabled" or "disabled"))
    return true
  end
  if key == keys.q then
    return false
  end
  return true
end

say("Neural auto-eat active")
draw()

local refreshTimer = os.startTimer(REFRESH_SECONDS)
while true do
  local event, p1 = os.pullEvent()
  if event == "key" then
    if not handleKeys(p1) then
      term.setCursorPos(1, 1)
      term.clear()
      break
    end
    draw()
  elseif event == "timer" and p1 == refreshTimer then
    if autoEatEnabled then
      tryEat()
    end
    draw()
    refreshTimer = os.startTimer(REFRESH_SECONDS)
  end
end
