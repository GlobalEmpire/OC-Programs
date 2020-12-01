--Initialisation
local Compatibility = "3.0"
local component = require("component")
local event = require("event")
local m = component.modem
local GERTi = require("GERTiClient")
local DC = component.data
local shell = require("shell")
local args, opts = shell.parse(...)
local fs = request("filesystem")
local serialization = require("serialization")
if fs.isDirectory(".config") then
    if fs.exists(".config/.OFTPLIB") then
        local ConfigFile = io.open(".config/.OFTPLIB")
        ConfigSettings = serialization.unserialize(ConfigSettings:read())
    end
end
--Program Error Codes:
local FILENOTFOUND = 0
local INVALIDCREDENTIALS = 1
local INVALIDFILELOCATION = 2
local CONFIGDIRECTORYISFILE = 10

--Private Functions:
local function VerifyServer(address,compatibility) -- Verify that the server exists and has a sufficient compatibility level
    --Verify Server exists
    --Verify Compatibility
end

local function VerifyCredentials(User,Password)

end

--Public Functions
function RequestPackage(PackageName,GivenServer) -- This function is for requesting packages from the set FTP server.
    GivenServer = GivenServer or ConfigSettings["DefaultServer"]
    if PackageName then
        if VerifyServer(GivenServer, Compatibility) then
            --Open Server Connection
            --Request Package from server
            if ServerResponse then
                --Receive Package
                --Close server connection
                --Return package installer location
            else
                return false, FILENOTFOUND
            end
        end
    end
end

function RequestFile(FileName,GivenServer,User,Password) -- This function Requests a file from the user. Params 3 and 4 are Username and Password respectively, leave blank to request a public file.
    GivenServer = GivenServer or ConfigSettings["DefaultServer"]
    if user == nil then
        if VerifyServer(GivenServer, Compatibility) then
            --Open Server Connection
            --Request File from server
            --Receive File
            --Close server connection
            --Return package installer location

        end
    else
        if VerifyServer(GivenServer, Compatibility) then
            --Open Server Connection
            if VerifyCredentials(User,Password) then
                --Request File from server
                --Receive File
                --Close server connection
                --Return package installer location
            else
                return false, INVALIDCREDENTIALS
            end
        end
    end
end

function SendFile(FileName,GivenServer,User,Password)

end

--Make a args section with: 
--[1] = "setup", [2] = server address
if args[1] == "setup" then
    ConfigSettings["DefaultServer"] = args[2]
    if fs.exists(".config") then
        if fs.isDirectory(".config") then
            local ConfigFile = io.open(".config/.OFTPLIB", "w")
            ConfigFile:write(serialization.serialize(ConfigSettings))
        else
            print(false)
            print(CONFIGDIRECTORYISFILE)
        end
    end

end