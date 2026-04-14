-- Pong for a 5x3 advanced monitor

local monitor = peripheral.find("monitor")
if not monitor then error("Monitor not found") end

local monitorName = peripheral.getName(monitor)
monitor.setTextScale(0.5)
term.redirect(monitor)

local tickRate = 0.05
local paddleSize = 4
local cpuSpeed = 1

local function getSize()
  local w, h = term.getSize()
  return w, h
end

local function clamp(v, min, max)
  if v < min then return min end
  if v > max then return max end
  return v
end

local w, h = getSize()
local playTop = 3
local playBottom = h

local leftY = math.floor((playTop + playBottom) / 2)
local rightY = leftY
local ballX = math.floor(w / 2)
local ballY = math.floor((playTop + playBottom) / 2)
local ballDX = 1
local ballDY = 1
local scoreL = 0
local scoreR = 0
local cpuL = false
local cpuR = false

local function resetBall(direction)
  ballX = math.floor(w / 2)
  ballY = math.floor((playTop + playBottom) / 2)
  ballDX = direction or (math.random(0, 1) == 0 and -1 or 1)
  ballDY = math.random(0, 1) == 0 and -1 or 1
end

local function draw()
  w, h = getSize()
  playTop = 3
  playBottom = h

  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()

  term.setCursorPos(1, 1)
  term.write("L " .. scoreL .. "  PONG  " .. scoreR .. " R")

  local leftLabel = cpuL and "L:CPU" or "L:HUM"
  local rightLabel = cpuR and "R:CPU" or "R:HUM"

  term.setCursorPos(1, 2)
  term.setTextColor(colors.gray)
  term.write(leftLabel)
  term.setCursorPos(w - #rightLabel + 1, 2)
  term.write(rightLabel)

  local paddleTopL = clamp(leftY - math.floor(paddleSize / 2), playTop, playBottom - paddleSize + 1)
  local paddleTopR = clamp(rightY - math.floor(paddleSize / 2), playTop, playBottom - paddleSize + 1)

  for i = 0, paddleSize - 1 do
    term.setCursorPos(2, paddleTopL + i)
    term.write("|")
    term.setCursorPos(w - 1, paddleTopR + i)
    term.write("|")
  end

  term.setCursorPos(ballX, ballY)
  term.write("o")
end

local function cpuMove()
  if cpuL then
    if ballY < leftY then leftY = leftY - cpuSpeed
    elseif ballY > leftY then leftY = leftY + cpuSpeed end
  end
  if cpuR then
    if ballY < rightY then rightY = rightY - cpuSpeed
    elseif ballY > rightY then rightY = rightY + cpuSpeed end
  end
  leftY = clamp(leftY, playTop, playBottom)
  rightY = clamp(rightY, playTop, playBottom)
end

local function step()
  cpuMove()

  local nextX = ballX + ballDX
  local nextY = ballY + ballDY

  if nextY <= playTop then
    nextY = playTop
    ballDY = 1
  elseif nextY >= playBottom then
    nextY = playBottom
    ballDY = -1
  end

  local paddleTopL = clamp(leftY - math.floor(paddleSize / 2), playTop, playBottom - paddleSize + 1)
  local paddleTopR = clamp(rightY - math.floor(paddleSize / 2), playTop, playBottom - paddleSize + 1)

  if nextX <= 2 then
    if nextY >= paddleTopL and nextY <= paddleTopL + paddleSize - 1 then
      ballDX = 1
      nextX = 3
    else
      scoreR = scoreR + 1
      resetBall(1)
      return
    end
  elseif nextX >= w - 1 then
    if nextY >= paddleTopR and nextY <= paddleTopR + paddleSize - 1 then
      ballDX = -1
      nextX = w - 2
    else
      scoreL = scoreL + 1
      resetBall(-1)
      return
    end
  end

  ballX = nextX
  ballY = nextY
end

draw()
local timer = os.startTimer(tickRate)

while true do
  local event, p1, p2, p3 = os.pullEvent()

  if event == "timer" and p1 == timer then
    step()
    draw()
    timer = os.startTimer(tickRate)
  elseif event == "monitor_touch" and p1 == monitorName then
    local x, y = p2, p3
    if y == 2 then
      if x <= 5 then cpuL = not cpuL
      elseif x >= w - 4 then cpuR = not cpuR end
    elseif y >= playTop then
      if x <= math.floor(w / 2) then
        leftY = clamp(y, playTop, playBottom)
      else
        rightY = clamp(y, playTop, playBottom)
      end
    end
    draw()
  end
end
