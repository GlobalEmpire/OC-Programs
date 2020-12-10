local fs = require("filesystem")
local SRL = require("serialization")
local component = require("component")
if not(fs.exists("/tmp/.DeviceInfo")) then
    local file = io.open("/tmp/.DeviceInfo", "w")
    local computer = require("computer")
    local info = computer.getDeviceInfo()
    file:write(SRL.serialize(info))
    component.modem.maxPacketSize = function () return tonumber(info[component.modem.address].capacity) end
    file:close()
    return info
else
    local file = io.open("/tmp/.DeviceInfo","r")
    local info = SRL.unserialize(file:read())
    component.modem.maxPacketSize = function () return tonumber(info[component.modem.address].capacity) end
    return info
end
