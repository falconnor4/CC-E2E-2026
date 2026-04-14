-- Tetris for a 5x3 advanced monitor

local monitor = peripheral.find("monitor")
if not monitor then error("Monitor not found") end

local monitorName = peripheral.getName(monitor)

monitor.setTextScale(0.5)
term.redirect(monitor)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

local boardW, boardH = 10, 20
local offsetX, offsetY = 2, 2

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

local function drawCell(x, y, color)
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

  term.setCursorPos(1, 1)
  term.setTextColor(colors.white)
  term.write("Tetris")
  term.setCursorPos(10, 1)
  term.write("Score " .. score)

  for y = 1, boardH do
    for x = 1, boardW do
      drawCell(x, y, board[y][x])
    end
  end

  for i = 1, #piece.blocks do
    local x = piece.x + piece.blocks[i][1]
    local y = piece.y + piece.blocks[i][2]
    if y >= 1 then
      drawCell(x, y, colorsByPiece[piece.key])
    end
  end

  local w, h = term.getSize()
  local btnY = h - 2
  drawButton(1, btnY, 6, h, "LEFT")
  drawButton(8, btnY, 13, h, "RIGHT")
  drawButton(15, btnY, 20, h, "ROT")
  drawButton(22, btnY, 27, h, "DOWN")
  drawButton(29, btnY, math.min(w, 34), h, "DROP")
end

local board = newBoard()
local piece = spawnPiece()
local score = 0
local dropDelay = 0.6
local lastDrop = os.clock()

drawBoard(board, piece, score)

while true do
  local event, p1, p2, p3 = os.pullEvent()

  if event == "monitor_touch" and p1 == monitorName then
    local x, y = p2, p3
    local w, h = term.getSize()
    local btnY = h - 2
    if y >= btnY then
      if x >= 1 and x <= 6 then
        if not collides(board, piece, -1, 0) then piece.x = piece.x - 1 end
      elseif x >= 8 and x <= 13 then
        if not collides(board, piece, 1, 0) then piece.x = piece.x + 1 end
      elseif x >= 15 and x <= 20 then
        local rotated = rotate(piece.blocks)
        if not collides(board, piece, 0, 0, rotated) then piece.blocks = rotated end
      elseif x >= 22 and x <= 27 then
        if not collides(board, piece, 0, 1) then piece.y = piece.y + 1 end
      elseif x >= 29 and x <= math.min(w, 34) then
        while not collides(board, piece, 0, 1) do piece.y = piece.y + 1 end
      end
    end
  end

  local now = os.clock()
  if now - lastDrop >= dropDelay then
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
    lastDrop = now
  end

  drawBoard(board, piece, score)
end
