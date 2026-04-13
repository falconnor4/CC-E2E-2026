-- Energy cube monitor dashboard (comparator-based)
-- Wire a comparator from the cube into the computer's right side.

local REFRESH_SECONDS = 0.5
local TITLE = "Base Power"
local SIGNAL_SIDE = "right"

local monitor = peripheral.find("monitor")
if not monitor then
  error("Monitor not found")
end

monitor.setTextScale(0.5)

local function drawBar(x, y, width, pct)
  local fill = math.floor(width * pct)
  monitor.setCursorPos(x, y)
  monitor.write("[" .. string.rep("=", fill) .. string.rep("-", width - fill) .. "]")
end

local function draw()
  monitor.setBackgroundColor(colors.black)
  monitor.setTextColor(colors.white)
  monitor.clear()

  local w = monitor.getSize()
  local signal = redstone.getAnalogInput(SIGNAL_SIDE)
  local pct = math.max(0, math.min(1, (signal or 0) / 15))

  monitor.setCursorPos(1, 1)
  monitor.write(TITLE)
  monitor.setCursorPos(1, 2)
  monitor.write(string.rep("-", math.min(w, #TITLE)))

  monitor.setCursorPos(1, 4)
  monitor.write("Signal: " .. tostring(signal) .. "/15")
  monitor.setCursorPos(1, 5)
  monitor.write("Charge: " .. string.format("%.0f", pct * 100) .. "%")
  drawBar(1, 6, math.min(w - 2, 30), pct)
  monitor.setCursorPos(1, 8)
  monitor.write("Side: " .. SIGNAL_SIDE)
end

while true do
  draw()
  os.sleep(REFRESH_SECONDS)
end
