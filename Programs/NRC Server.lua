local GERT = require("GERTiClient")
local event = require("event")
local component = require("component")
local programArgs, ops = require("shell").parse(...)
local doLoop = (ops.async or ops.a) == true
local silent = ops.silent or ops.s
local doLog = not silent
local clients = {}
local channels = { -- example channels
  ["general"] = {
    clients = {},
    messages = {"<Server> Server: OK!"}
  },
  ["gert"] = {
    clients = {},
    messages = {"<Server> This channel is about GERTi/GERTe"}
  },
  ["global-empire"] = {
    clients = {},
    messages = {"<Server> Here it's everything about GlobalEmpire"}
  }
}
local motd = {
"-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-",
"Welcome to NRC Server.",
"You are connected to address " .. GERT.getAddress(),
"The word of today is 'setup'",
"Change this MOTD as much as you like",
"=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
}

function string.split(str, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for part in string.gmatch(str, "([^"..sep.."]+)") do
    table.insert(t, part)
  end
  return t
end

local function incoming(_, origin, id)
  if doLog then print("Connection attempted from " .. origin) end
  if clients[origin] then
    if doLog then print("Cancelled connection from " .. origin) end
    return
  end
  if doLog then print("Connection from " .. origin .. " accepted") end
  clients[origin] = {}
  local sock = GERT.openSocket(origin, true, id)
  clients[origin] = {
    username = nil,
    channel = nil,
    socket = sock
  }
  for k, v in pairs(motd) do
    sock:write(v)
  end
end

local function data(_, origin, id)
  os.sleep(0.1)
  local cl = clients[origin]
  local sock = cl.socket
  local data = sock:read()[1]
  local split = string.split(data)
  local ok, err = pcall(function()
    if not cl.username then
      if split[1] == "USERNAME" then
        cl.username = data:sub(10, data:len())
        if doLog then print(origin .. " connected as " .. cl.username) end
      end
    else
      if split[1] == "SAY" and cl.channel then
        if not channels[cl.channel] then
          channels[cl.channel] = {
            messages = {"<Server> Channel didn't existed before, created right now by " .. cl.username},
            clients = {}
          }
        end
        local amsg = data:sub(5, data:len())
        if amsg == "/list" then
          cl.socket:write("Channel List:")
          for k, ch in pairs(channels) do
            cl.socket:write("  - " .. k)
            cl.socket:write("    - Players connected:")
            for _, cli in pairs(ch.clients) do
              cl.socket:write("      - " .. cli.username)
            end
          end
          return
        end
        local msg = "<" .. cl.username .. "> " .. amsg
        if doLog then print("#" .. cl.channel .. " " .. msg) end
        table.insert(channels[cl.channel].messages, msg)
        if #channels[cl.channel].messages > 30 then -- not more than 30 messages in history
          table.remove(channels[cl.channel].messages, 1)
        end
        for _, client in pairs(channels[cl.channel].clients) do
          client.socket:write(msg)
        end
      end
      if split[1] == "CHANNEL" then
        if cl.channel then
          channels[cl.channel].clients[origin] = nil
        end
        cl.channel = split[2]
        if not channels[cl.channel] then
          channels[cl.channel] = {
            messages = {"<Server> Newly created channel"},
            clients = {}
          }
        end
        channels[cl.channel].clients[origin] = cl
        -- Send history
        cl.socket:write("History of channel " .. cl.channel)
        for _, msg in pairs(channels[cl.channel].messages) do
          cl.socket:write(msg)
        end
      end
    end
  end)
  if not ok then
    print(err)
  end
end

local function close(_, origin, _, id)
  if clients[origin].closing then return end
  if clients[origin].username then
    if doLog then print(clients[origin].username .. " disconnected") end 
  else
    if doLog then print(origin .. " disconnected") end
  end
  clients[origin].closing = true
  clients[origin].socket:close()
  clients[origin] = nil
end

event.listen("GERTData", data)
event.listen("GERTConnectionClose", close)
event.listen("GERTConnectionID", incoming)

print("NRC Server v1.0 (for GERTi 1.1)")
print("Server Address: " .. GERT.getAddress())

if doLoop then
  print("Use Ctrl+C to quit")
  while true do
    local id = event.pull()
    if id == "interrupted" then
      break
    end
  end
  
  for _, v in pairs(clients) do
    v.socket:close()
  end
  event.ignore("GERTData", data)
  event.ignore("GERTConnectionClose", close)
  event.ignore("GERTConnectionID", incoming)
else
  print("Launched in background")
end
