local component = require("component")
local bagel = require("bagel")
local shell = require("shell")
local serialize = require("serialization")
local computer = require("computer")
local OS = true
local radar = nil
local index = 1
TACEATSplayers = {}
local players = {}
if component.isAvailable("os_entdetector") == false then
    radar = component.radar
    OS = false
else
    radar = component.os_entdetector
end
local function getP()
    local tempP = {}
    if OS == true then
        tempP = radar.scanPlayers(16, true)
    else
        tempP = radar.getPlayers()
    end
    return tempP
end
local condition, num = bagel.glutenous("/usr/programs/TIdent.lua", 103913)
print(num)
condition, num = bagel.glutenous("/usr/programs/TFiCo.lua", 116365)
print(num)
shell.execute("/usr/programs/TIdent.lua")
shell.execute("/usr/programs/TFiCo.lua")
while true do
    index = 1
    players = getP()
    if players ~= nil then
        if OS == false then
            while index <= #players do
                players[index]["range"] = players[index]["distance"]
                index = index + 1
            end
        end
        TACEATSplayers = players
        computer.pushSignal("TIdent")
    end
    os.sleep(2)
end