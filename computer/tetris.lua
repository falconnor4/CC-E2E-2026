-- Tetris for a 5x3 advanced monitor

local monitor = peripheral.find("monitor")
if not monitor then error("Monitor not found") end

local monitorName = peripheral.getName(monitor)

monitor.setTextScale(0.5)
term.redirect(monitor)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

local boardW, boardH = 10, 20

local pieces = {
  I = { { 0, 1 }, { 1, 1 }, { 2, 1 }, { 3, 1 } },
  O = { { 1, 0 }, { 2, 0 }, { 1, 1 }, { 2, 1 } },
  T = { { 1, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } },
  S = { { 1, 0 }, { 2, 0 }, { 0, 1 }, { 1, 1 } },
  Z = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 2, 1 } },
  J = { { 0, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } },
  L = { { 2, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } },
}

local colorsByPiece = {
  I = colors.cyan,
  O = colors.yellow,
  T = colors.purple,
  S = colors.lime,
  Z = colors.red,
  J = colors.blue,
  L = colors.orange,
}

local function newBoard()
  local b = {}
  for y = 1, boardH do
    b[y] = {}
    for x = 1, boardW do
      b[y][x] = nil
    end
  end
  return b
end

local function copyBlocks(blocks)
  local out = {}
  for i = 1, #blocks do
    out[i] = { blocks[i][1], blocks[i][2] }
  end
  return out
end

local function rotate(blocks)
  local out = {}
  for i = 1, #blocks do
    local x, y = blocks[i][1], blocks[i][2]
    out[i] = { -y, x }
  end
  return out
end

local function spawnPiece()
  local keys = { "I", "O", "T", "S", "Z", "J", "L" }
  local key = keys[math.random(#keys)]
  return {
    key = key,
    blocks = copyBlocks(pieces[key]),
    x = 4,
    y = 0,
  }
end

local function collides(board, piece, dx, dy, blocks)
  local b = blocks or piece.blocks
  for i = 1, #b do
    local x = piece.x + b[i][1] + dx
    local y = piece.y + b[i][2] + dy
    if x < 1 or x > boardW or y > boardH then
      return true
    end
    if y >= 1 and board[y][x] then
      return true
    end
  end
  return false
end

local function lockPiece(board, piece)
  for i = 1, #piece.blocks do
    local x = piece.x + piece.blocks[i][1]
    local y = piece.y + piece.blocks[i][2]
    if y >= 1 and y <= boardH and x >= 1 and x <= boardW then
      board[y][x] = colorsByPiece[piece.key]
    end
  end
end

local function clearLines(board)
  local cleared = 0
  for y = boardH, 1, -1 do
    local full = true
    for x = 1, boardW do
      if not board[y][x] then
        full = false
        break
      end
    end
    if full then
      table.remove(board, y)
      local row = {}
      for x = 1, boardW do row[x] = nil end
      table.insert(board, 1, row)
      cleared = cleared + 1
      y = y + 1
    end
  end
  return cleared
end

local function drawCell(offsetX, offsetY, x, y, color)
  term.setCursorPos(offsetX + x * 2 - 1, offsetY + y - 1)
  term.setBackgroundColor(color or colors.black)
  term.write("  ")
end

local function drawButton(x1, y1, x2, y2, label)
  for y = y1, y2 do
    term.setCursorPos(x1, y)
    term.setBackgroundColor(colors.gray)
    term.write(string.rep(" ", x2 - x1 + 1))
  end
  term.setCursorPos(x1 + 1, math.floor((y1 + y2) / 2))
  term.setTextColor(colors.black)
  term.setBackgroundColor(colors.gray)
  term.write(label)
end

local function drawBoard(board, piece, score)
  term.setBackgroundColor(colors.black)
  term.clear()

  local w, h = term.getSize()
  local boardPixelW = boardW * 2
  local boardPixelH = boardH
  local offsetX = math.max(2, math.floor((w - boardPixelW) / 2) + 1)
  local offsetY = math.max(2, math.floor((h - boardPixelH) / 2) - 1)

  term.setCursorPos(1, 1)
  term.setTextColor(colors.white)
  term.write("Tetris")
  term.setCursorPos(10, 1)
  term.write("Score " .. score)

  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.setCursorPos(offsetX - 1, offsetY - 1)
  term.write("+" .. string.rep("-", boardPixelW) .. "+")
  for y = 1, boardPixelH do
    term.setCursorPos(offsetX - 1, offsetY + y - 1)
    term.write("|")
    term.setCursorPos(offsetX + boardPixelW, offsetY + y - 1)
    term.write("|")
  end
  term.setCursorPos(offsetX - 1, offsetY + boardPixelH)
  term.write("+" .. string.rep("-", boardPixelW) .. "+")

  for y = 1, boardH do
    for x = 1, boardW do
      drawCell(offsetX, offsetY, x, y, board[y][x])
    end
  end

  for i = 1, #piece.blocks do
    local x = piece.x + piece.blocks[i][1]
    local y = piece.y + piece.blocks[i][2]
    if y >= 1 then
      drawCell(offsetX, offsetY, x, y, colorsByPiece[piece.key])
    end
  end

  local btnBaseY = h - 3
  drawButton(2, btnBaseY + 1, 6, h, "<-")
  drawButton(8, btnBaseY + 1, 12, h, "->")
  drawButton(5, btnBaseY - 1, 9, btnBaseY + 1, "^")
  drawButton(5, btnBaseY + 1, 9, h, "v")

  local aX1, aX2 = w - 8, w - 5
  local bX1, bX2 = w - 13, w - 10
  drawButton(bX1, btnBaseY + 1, bX2, h, "B")
  drawButton(aX1, btnBaseY, aX2, h - 1, "A")
end

local board = newBoard()
local piece = spawnPiece()
local score = 0
local dropDelay = 0.6
local timer = os.startTimer(dropDelay)

drawBoard(board, piece, score)

while true do
  local event, p1, p2, p3 = os.pullEvent()

  if event == "monitor_touch" and p1 == monitorName then
    local x, y = p2, p3
    local w, h = term.getSize()
    local btnBaseY = h - 3

    if y >= btnBaseY then
      if x >= 2 and x <= 6 then
        if not collides(board, piece, -1, 0) then piece.x = piece.x - 1 end
      elseif x >= 8 and x <= 12 then
        if not collides(board, piece, 1, 0) then piece.x = piece.x + 1 end
      elseif x >= 5 and x <= 9 and y <= btnBaseY + 1 then
        local rotated = rotate(piece.blocks)
        if not collides(board, piece, 0, 0, rotated) then piece.blocks = rotated end
      elseif x >= 5 and x <= 9 and y >= btnBaseY + 1 then
        if not collides(board, piece, 0, 1) then piece.y = piece.y + 1 end
      elseif x >= w - 13 and x <= w - 10 then
        if not collides(board, piece, 0, 1) then piece.y = piece.y + 1 end
      elseif x >= w - 8 and x <= w - 5 then
        while not collides(board, piece, 0, 1) do piece.y = piece.y + 1 end
      end
    end
  elseif event == "timer" and p1 == timer then
    if not collides(board, piece, 0, 1) then
      piece.y = piece.y + 1
    else
      lockPiece(board, piece)
      local cleared = clearLines(board)
      score = score + cleared * 100
      piece = spawnPiece()
      if collides(board, piece, 0, 0) then
        term.setCursorPos(1, 1)
        term.setTextColor(colors.red)
        term.write("Game Over")
        break
      end
    end
    timer = os.startTimer(dropDelay)
  end

  drawBoard(board, piece, score)
end
