local gert = require("GERTiClient")
local event = require("event")
local serialize = require("serialization")
local computer = require("computer")
local sockets = {}
local addresses = {}

print("Address is " .. gert.getAddress())

local function incoming(_, origin, id)
  sockets[origin] = gert.openSocket(origin, true, id)
end

local function data(_, origin, id)
  local socket = sockets[origin]
  local rq = socket:read[1]
  print("Request for domain " .. rq)
  local stream = io.open("/domains.txt", "r")
  addresses = serialize.unserialize(stream:read("*a"))
  stream:close()
  if addresses[rq] then
    socket:write(addresses[rq])
  else
    socket:write(-1.0)
  end
end

event.listen("GERTConnectionID", incoming)
event.listen("GERTData", data)

if false then -- optional, blocking DNS, to get better track of info
while true do
  local id = event.pull()
  if id == "interrupted" then
    event.ignore("GERTConnectionID", incoming)
    event.ignore("GERTData", data)
  end
end
end
