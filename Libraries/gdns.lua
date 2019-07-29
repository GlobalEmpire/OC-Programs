local gert = require("GERTiClient")
local event = require("event")
local gdns = {}
local mainServer = nil
local altServer = nil

local function waitForData(socket)
    event.pull("GERTData")
    local buf = socket:read()
    while #buf == 0 do
        os.sleep(0.1)
        buf = socket:read()
    end
    return buf
end

function gdns.getMainServer()
    return mainServer
end

function gdns.getAltServer()
    return altServer
end

function gdns.setMainServer(main)
    mainServer = main
end

function gdns.setAltServer(alt)
    altServer = alt
end

function gdns.resolve(domain, server)
    if not server then
        if not mainServer and not altServer then
            return nil, "no server defined"
        end
        server = mainServer or altServer
    end
    local socket = gert.openSocket(server)
    if not socket then
        if server == altServer then
            return nil, "neither main or alt server are opened"
        end
        return gdns.resolve(domain, altServer)
    end
    socket:write(domain)
    local data = waitForData(socket)[1]
    if data == -1.0 then
        return nil, ""
    else
        return data
    end
end

return gdns
