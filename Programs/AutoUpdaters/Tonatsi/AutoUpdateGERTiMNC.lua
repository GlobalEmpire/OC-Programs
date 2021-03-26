if component.filesystem.isReadOnly() then 
    return 
end
local fs = require("filesystem")
if not(component.isAvailable("internet")) then
    if not(fs.exists("../GERTiMNCautoUpdateError")) then
        local errorfile = io.open("../GERTiMNCautoUpdateError", "w")
        errorfile:write("No Internet Card Found, aborting auto update process until this file is deleted.")
        errorfile:close() 
    end
end
if not(fs.exists("../GERTiMNCautoUpdateError")) then    
    local internet = require("internet")
    local GERTiMNCversionRequest = internet.request("https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/GERTiClient.lua")
    local Request = internet.request("https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/GERTiClient.lua")
    local testfile = io.open("/home/testfile.lua", "w")
    for element in Request do
        testfile:write(element)
    end
    testfile:close()
end
