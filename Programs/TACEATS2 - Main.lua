local component = require("component")
local computer = require("computer")
local serialize = require("serialization")
local shell = require("shell")
local OS = true
local radar = component.os_entdetector
local index = 1
local players = {}
if radar == nil then
    radar = component.radar
    OS = false
end
local function radar.getP()
    if OS == true then
        radar.scanPlayers(16, true)
    else
        radar.getPlayers()
    end
end
shell.execute("/usr/programs/TIdent.lua")
shell.execute("/usr/programs/TFiCo.lua")
while true do
    index = 1
    players = radar.getP()
    if OS == false then
        while index <= #players do
            players[index]["range"] = players[index]["distance"]
            index = index + 1
        end
    end
    players = serialize.serialize(players)
    computer.pushSignal("TIdent", players)
end