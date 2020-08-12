--Small clone of a certain colours game you may recall from your childhood.
--Made by AshleighTheCutie, with parts of code contributed by Ocawesome101.
--This requires Computronics to be installed alongside OC.

local component = require("component")
local event = require("event")
local patternEntry = "1234321234" --This was for testing the patterns onto the lights before I had a random number generator. Can be safely removed, but I just don't find it necessary.
local startDifficulty = "3" -- Change this to increase the starting difficulty.
local difficulty = tonumber(startDifficulty)

local function init()
  component.switch_board.setActive(1,true)
  component.switch_board.setActive(2,true)
  component.switch_board.setActive(3,true)
  component.switch_board.setActive(4,true)
  os.sleep(1)
  component.switch_board.setActive(1,false)
  component.switch_board.setActive(2,false)
  component.switch_board.setActive(3,false)
  component.switch_board.setActive(4,false)
  os.sleep(1)
  component.light_board.setColor(1,0xFF0000)
  component.light_board.setColor(2,0x00FF00)
  component.light_board.setColor(3,0x0000FF)
  component.light_board.setColor(4,0xFFFF00)
  component.light_board.setActive(1,true)
  component.light_board.setActive(2,true)
  component.light_board.setActive(3,true)
  component.light_board.setActive(4,true)
  os.sleep(1)
  component.light_board.setActive(1,false)
  component.light_board.setActive(2,false)
  component.light_board.setActive(3,false)
  component.light_board.setActive(4,false)
end

local function readSwitchBoard()
  local type,address,number,value = event.pull("switch_flipped")
  os.sleep(0.5)
  component.switch_board.setActive(number,false)
  event.pull("switch_flipped")
  return number
end

local function setLightPattern(pattern)
  for i = string.len(pattern),1,-1 do
    local number = tonumber(string.sub(pattern, i, i))
    component.light_board.setActive(number, true)
    os.sleep(1)
    component.light_board.setActive(number, false)
    os.sleep(0.5)
  end
end

local function mkrand(n) -- contributed by Ocawesome101
  local r = ""
  for i=1,n,1 do
    r = r .. math.floor(math.random(1, 4) // 1)
  end
  return r
end

local function comparatorInputGen(pattern)
  local r = ""
  for i=tonumber(string.len(pattern)), 1, -1 do
    --print("Hello from before the math operation!")
    r = r .. math.floor(readSwitchBoard())
    --print("Hello from after the math operation!")
  end
  return r
end

local function comparator(generatedPattern,userPattern)
  if generatedPattern == userPattern then do
    difficulty = difficulty + 1
    print("Correct!")
    component.light_board.setColor(1,0x00FF00)
    component.light_board.setColor(2,0x00ff00)
    component.light_board.setColor(3,0x00ff00)
    component.light_board.setColor(4,0x00ff00)
    component.light_board.setActive(1,true)
    component.light_board.setActive(2,true)
    component.light_board.setActive(3,true)
    component.light_board.setActive(4,true)
    os.sleep(0.5)
    component.light_board.setActive(1,false)
    component.light_board.setActive(2,false)
    component.light_board.setActive(3,false)
    component.light_board.setActive(4,false)
    os.sleep(0.5)
    component.light_board.setActive(1,true)
    component.light_board.setActive(2,true)
    component.light_board.setActive(3,true)
    component.light_board.setActive(4,true)
    os.sleep(0.5)
    component.light_board.setActive(1,false)
    component.light_board.setActive(2,false)
    component.light_board.setActive(3,false)
    component.light_board.setActive(4,false)
    component.light_board.setColor(1,0xFF0000)
    component.light_board.setColor(2,0x00FF00)
    component.light_board.setColor(3,0x0000FF)
    component.light_board.setColor(4,0xFFFF00)
    os.sleep(0.25)
  end
  else
    component.light_board.setColor(1,0xff0000)
    component.light_board.setColor(2,0xff0000)
    component.light_board.setColor(3,0xff0000)
    component.light_board.setColor(4,0xff0000)
    component.light_board.setActive(1,true)
    component.light_board.setActive(2,true)
    component.light_board.setActive(3,true)
    component.light_board.setActive(4,true)
    os.sleep(0.5)
    component.light_board.setActive(1,false)
    component.light_board.setActive(2,false)
    component.light_board.setActive(3,false)
    component.light_board.setActive(4,false)
    os.sleep(0.5)
    component.light_board.setActive(1,true)
    component.light_board.setActive(2,true)
    component.light_board.setActive(3,true)
    component.light_board.setActive(4,true)
    os.sleep(0.5)
    component.light_board.setActive(1,false)
    component.light_board.setActive(2,false)
    component.light_board.setActive(3,false)
    component.light_board.setActive(4,false)
    component.light_board.setColor(1,0xFF0000)
    component.light_board.setColor(2,0x00FF00)
    component.light_board.setColor(3,0x0000FF)
    component.light_board.setColor(4,0xFFFF00)
    userScore = difficulty - startDifficulty 
    print("Your score was: " .. userScore)
    difficulty = startDifficulty
  end
end

init()
while true do
  local pattern1 = mkrand(tonumber(difficulty))
  --print(pattern1)
  setLightPattern(string.reverse(pattern1))
  local userResult = comparatorInputGen(pattern1)
  print(pattern1 .. " , " .. userResult)
  comparator(pattern1,userResult)
end
