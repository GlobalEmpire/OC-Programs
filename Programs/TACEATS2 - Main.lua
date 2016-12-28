local component = require("component")
local bagel = require("bagel")
local shell = require("shell")
local serialize = require("serialization")
local computer = require("computer")
local turret = component.os_energyturret
turret.powerOn()
turret.setArmed(true)
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
while true do
    index = 1
    players = getP()
    if players ~= nil then
        if OS == true then
            while index <= #players do
                players[index]["distance"] = players[index]["range"]
                index = index + 1
            end
        end
        TACEATSplayers = players
        computer.pushSignal("TIdent")
    end
    os.sleep(5)
end