local fs = require("filesystem")
local component = require("component")
local event = require("event")
local m = component.modem
m.open(123)
local _, _, from, port, _, message = event.pull("modem_message")
print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
fs.copy("/data/usr/programs/modemReceiveTest.lua", "/mnt/34d/modemReceiveTest.lua")