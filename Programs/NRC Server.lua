local GERT = require("GERTiClient")
local event = require("event")
local component = require("component")
local clients = {}
local channels = {
  ["general"] = {
    clients = {},
    messages = {"<Server> something"}
  }
}
local motd = {
"Test Server",
"Configure at your likings"
}

function string.split(str)
  local t={}
  for part in string.gmatch(str, "([^%s]+)") do table.insert(t, part) end
  return t
end

local function incoming(_, origin, id)
  clients[origin] = {}
  local sock = GERT.openSocket(origin, true, id)
  clients[origin] = {
    username = nil,
    channel = nil,
    socket = sock
  }
  for _, v in pairs(motd) do
    sock:write(v)
  end
end

local function data(_, origin, id)
  local cl = clients[origin]
  local data = cl.socket:read()[1]
  local split = string.split(data)
  pcall(function() -- to avoid some little tweakers to crash NRC server with bad syntax
    if split[1] == "USERNAME" and not cl.username then
        cl.username = split[2]
    end
    if split[1] == "CHANNEL" then
        if cl.channel ~= nil then
          channels[cl.channel].clients[origin] = nil
        end
    end
    if split[1] == "SAY" then
        
    end
  end)
end

event.listen("GERTConnectionID", data)
event.listen("GERTData", data)
