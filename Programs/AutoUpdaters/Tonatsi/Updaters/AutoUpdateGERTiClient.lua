local component = require("component")
if component.filesystem.isReadOnly() then 
    return 
end
local fs = require("filesystem")
if not(component.isAvailable("internet")) then
    if not(fs.exists("/GERTiClientAutoUpdateError")) then
        local errorfile = io.open("/GERTiClientAutoUpdateError", "w")
        errorfile:write("No Internet Card Found, aborting auto update process until this file is deleted.")
        errorfile:close() 
    end
end
local event = require("event")
local function update()
    if not(fs.exists("/GERTiClientAutoUpdateError")) then    
        local internet = require("internet")
        if fs.exists("/lib/GERTiClient.lua") then
            local GERTiClientVersionRequest = internet.request("https://raw.githubusercontent.com/leothehero/OC-Programs/AutoUpdaters/Programs/AutoUpdaters/Tonatsi/GERTiClient-latestStableVersion.txt")
            local GERTiClientLatestVersion = GERTiClientVersionRequest()
            local GERTiClient = io.open("/lib/GERTiClient.lua", "r")
            local GERTiClientVersion = GERTiClient:read("*l")
            if GERTiClientVersion == GERTiClientLatestVersion then
                return
            end
        end
        local GERTiClientRequest = internet.request("https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/GERTiClient.lua")
        local GERTiClient = io.open("/lib/GERTiClient.lua", "w")
        for element in GERTiClientRequest do
            GERTiClient:write(element)
        end
        GERTiClient:close()
        local function beep()
            computer.beep(2000)
            os.sleep(0.5)
            computer.beep(1000)
        end
        event.timer(15,beep,math.huge)
    end
end
update()
event.timer(900, update, math.huge)