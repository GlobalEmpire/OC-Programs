-- AUGM V2 Patch 1
local component = require("component")
if component.filesystem.isReadOnly() then 
    return 
end
if not(component.isAvailable("internet")) then
    local errorfile = io.open("/GMAUError", "a")
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
        local GERTiMNCVersionRequest = internet.request("https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/Update%20Data/GERTiMNC%20Stable%20Release.txt")
        local RequestString = ""
        for element in GERTiMNCVersionRequest do
            RequestString = RequestString .. element
        end
        local Glines = {}
        for s in RequestString:gmatch("[^\n]+") do
            table.insert(Glines, s)
        end
        if fs.exists("/etc/rc.d/GERTiMNC.lua") then
            local GERTiMNC = io.open("/etc/rc.d/GERTiMNC.lua", "r")
            local GERTiMNCVersion = GERTiMNC:read("*l")
            GERTiMNC:close()
            if GERTiMNCVersion == Glines[1] then
                return true
            end
        end
        local GERTiMNCRequest = internet.request(Glines[2])
        local GERTiMNC = io.open("/etc/rc.d/GERTiMNC.lua", "w")
        for element in GERTiMNCRequest do
            GERTiMNC:write(element)
        end
        GERTiMNC:close()
        event.push("ProgramUpdate","GERTiMNC",not(not(Glines[3])))
        return
    end):detach()
    thread.create(function()
        local GMAUVR = internet.request("https://raw.githubusercontent.com/Leothehero/OC-Programs/master/Programs/AutoUpdaters/Tonatsi/Version%20Files/GERTi/GMAUS.txt")
        local RequestString = ""
        for element in GMAUVR do
            RequestString = RequestString .. element
        end
        local AUlines = {}
        for s in RequestString:gmatch("[^\n]+") do
            table.insert(AUlines, s)
        end
        local AUGM = io.open("/lib/AutoUpdateGERTiMNC.lua", "r")
        local AUGMV = AUGM:read("*l")
        AUGM:close()
        if AUGMV == AUlines[1] then
            return true
        end
        local AUGMR = internet.request(AUlines[2])
        local AUGM = io.open("/lib/AutoUpdateGERTiMNC.lua", "w")
        for element in AUGMR do
            AUGM:write(element)
        end
        AUGM:close()
        event.push("ProgramUpdate","AUGM",not(not(AUlines[3])))
        return
    end):detach()
end
update()
local UpdateTimer = event.timer(86400, update, math.huge)
local function updateReboot(EventName,ProgramName,Reboot)
    if ProgramName == "AUGM" and Reboot then 
        event.cancel(UpdateTimer)
        os.execute("/lib/AutoUpdateGERTiMNC.lua")
        return false
    end
end
event.listen("ProgramUpdate",updateReboot)