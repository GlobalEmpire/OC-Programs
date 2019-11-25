local GERT = require("GERTiClient")
local event = require("event")
local term = require("term")
local component = require("component")
local shell = require("shell")
local gpu = component.gpu
local width, height = gpu.getResolution()
local name = "zenith391"
local channel = "none"
local args, ops = shell.parse(...)

if #args < 1 then
  io.stderr:write("Usage: nrc [server]\n")
  return
end

local server = args[1]
if tonumber(server) == nil then
  local ok = pcall(function()
    server = require("GDNS").resolve(server)
    if server == false then
      io.stderr:write("Invalid domain: " .. args[1] .. "\n")
      return
    end
  end)
  if not ok then
    io.stderr:write("Please install GDNS to resolve domains")
  end
end

local socket = nil
local y = 2

local socketOpened(_, origin, id)
  print(origin)
  socket:write("USERNAME " .. name)
end

local function message(_, origin, id)
  os.sleep(0.1)
  local tab = socket:read()
  for _, data in pairs(tab) do
    local _, row = term.getCursor()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    if y == 40 then
      gpu.fill(1, 1, 160, 20, " ")
      gpu.set(1, 1, "Channel: " .. channel)
      gpu.copy(1, 20, 160, 20, 0, -19)
      gpu.fill(1, 20, 160, 20, " ")
      y = 20
    end
    gpu.set(1, y, data)
    y = y + 1
  end
end

event.listen("GERTConnectionID", socketOpened)
event.listen("GERTData", message)
socket = GERT.openSocket(tonumber(server), true, 80)
gpu.fill(1, 1, 160, 50, " ")
gpu.set(1, 1, "Channel: none")
while true do
  gpu.setBackground(0x000000)
  gpu.fill(1, 48, 160, 2, " ")
  term.setCursor(1, 49)
  io.write(">")
  local msg = term.read()
  if type(msg) ~= "boolean" then
    msg = msg:sub(1, msg:len()-1)
  end
  if type(msg) == "boolean" or msg == "/quit" then
    socket:close()
    event.ignore("GERTConnectionID", socketOpened)
    event.ignore("GERTData", message)
    break
  end
  if msg:len() > 0 then
    if msg:sub(1, 1) == "/" and msg:len() > 5 and msg:sub(1, 5) == "/join" then
      if msg:sub(1, 5) == "/join" then
        local cha = msg:sub(7, msg:len())
        socket:write("CHANNEL " .. cha)
        channel = cha
        gpu.set(1, 1, "Channel: #" .. channe)
      end
    else
      socket:write("SAY " .. msg)
    end
  end
end

gpu.setResolution(width, height)
