local component = require("component")
if component.filesystem.isReadOnly() then 
    return 
end
local fs = require("filesystem")
if not(component.isAvailable("internet")) then
    if not(fs.exists("/GERTiMNCautoUpdateError")) then
        local errorfile = io.open("/GERTiMNCautoUpdateError", "w")
        errorfile:write("No Internet Card Found, aborting auto update process until this file is deleted.")
        errorfile:close() 
    end
end
if not(fs.exists("/GERTiMNCautoUpdateError")) then    
    local internet = require("internet")
    if fs.exists("/etc/rc.d/GERTiMNC.lua") then
        local GERTiMNCVersionRequest = internet.request("https://raw.githubusercontent.com/leothehero/OC-Programs/AutoUpdaters/Programs/AutoUpdaters/Tonatsi/GERTiMNC-latestStableVersion.txt")
        local GERTiMNCLatestVersion = GERTiMNCVersionRequest()
        local GERTiMNC = io.open("/etc/rc.d/GERTiMNC.lua", "r")
        local GERTiMNCVersion = GERTiMNC:read("*l")
        if GERTiMNCVersion == GERTiMNCLatestVersion then
            return
        end
    end
    local GERTiMNCRequest = internet.request("https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/GERTiMNC.lua")
    local GERTiMNC = io.open("/etc/rc.d/GERTiMNC.lua", "w")
    for element in GERTiMNCRequest do
        GERTiMNC:write(element)
    end
    GERTiMNC:close()
end
