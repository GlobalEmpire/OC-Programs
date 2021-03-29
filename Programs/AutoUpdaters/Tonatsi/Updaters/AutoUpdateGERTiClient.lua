-- AUGC V2
local component = require("component")
if component.filesystem.isReadOnly() then 
    return 
end
if not(component.isAvailable("internet")) then
    local errorfile = io.open("/GCAUError", "a")
    errorfile:write(str(os.time()) .. " | No Internet Card Found, aborting auto update.\n")
    errorfile:close()
    return
end
local computer = require("computer")
local thread = require("thread")
local fs = require("filesystem")
local event = require("event")
local internet = require("internet")
local function update()
    thread.create(function()
        if fs.exists("/lib/GERTiClient.lua") then
            local GERTiClientVersionRequest = internet.request("https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/Update%20Data/GERTiClient%20Stable%20Release.txt")
            local RequestString = ""
            for element in GERTiClientVersionRequest do
                RequestString = RequestString .. element
            end
            local Glines = {}
            for s in RequestString:gmatch("[^\n]+") do
                table.insert(Glines, s)
            end
            local GERTiClient = io.open("/lib/GERTiClient.lua", "r")
            local GERTiClientVersion = GERTiClient:read("*l")
            if GERTiClientVersion == Glines[1] then
                return true
            end
        end
        local GERTiClientRequest = internet.request(Glines[2])
        local GERTiClient = io.open("/lib/GERTiClient.lua", "w")
        for element in GERTiClientRequest do
            GERTiClient:write(element)
        end
        GERTiClient:close()
        event.push("ProgramUpdate","GERTiClient",not(not(Glines[3])))
        return
    end):detach()
    thread.create(function()
        local GCAUVR = internet.request("https://raw.githubusercontent.com/GlobalEmpire/OC-Programs/master/Programs/AutoUpdaters/Tonatsi/Version%20Files/GERTi/GCAUS.txt")
        local RequestString = ""
        for element in GCAUVR do
            RequestString = RequestString .. element
        end
        local AUlines = {}
        for s in RequestString:gmatch("[^\n]+") do
            table.insert(AUlines, s)
        end
        local AUGC = io.open("/lib/AutoUpdateGERTiClient.lua", "r")
        local AUGCV = AUGC:read("*l")
        if AUGCV == AUlines[1] then
            return true
        end
        local AUGCR = internet.request(AUlines[2])
        local AUGC = io.open("/lib/AutoUpdateGERTiClient.lua", "w")
        for element in AUGCR do
            AUGC:write(element)
        end
        AUGC:close()
        event.push("ProgramUpdate","AUGC",not(not(AUlines[3])))
        return
    end):detach()
end
update()
local UpdateTimer = event.timer(86400, update, math.huge)
local function updateReboot(EventName,ProgramName,Reboot)
    if ProgramName == "AUGC" and Reboot then 
        event.cancel(UpdateTimer)
        os.execute("/lib/AutoUpdateGERTiClient.lua")
        return false
    end
end
event.listen("ProgramUpdate")