--Initialisation
local Compatibility = "3.0"
local component = require("component")
local event = require("event")
local m = component.modem
local GERTi = require("GERTiClient")
local DC = component.data
--if DC.generateKeyPair == nil then print("This service requires a T3 data card to be installed. There is no T3 data card detected by this program. Please ensure that you have a ///T3/// datacard installed, or install the no-encryption version of this program if it exists.") return end
local shell = require("shell")
local args, opts = shell.parse(...)
local fs = request("filesystem")
local serialization = require("serialization")
--Program Variables:
local ConfigSettings = []
local SendData = []



--Program Error Codes:
local FILENOTFOUND = 0
local INVALIDCREDENTIALS = 1
local INVALIDFILELOCATION = 2
local INVALIDSERVERADDRESS = 3
local NILSERVERADDRESS = 4
local INCOMPATIBLESERVER = 5
local CONFIGDIRECTORYISFILE = 10


--OneTimeRun Code:

if fs.isDirectory(".config") then
    if fs.exists(".config/.OFTPLIB") then
        local ConfigFile = io.open(".config/.OFTPLIB")
        ConfigSettings = serialization.unserialize(ConfigSettings:read())
    end
end

--Private Functions:
local function VerifyServer(address,compatibility) -- Verify that the server exists and has a sufficient compatibility level
    if address then
        --Verify Server exists:
        GERTi.send(FTPaddress, "GetVersion")
        local _, _, _, ServerVersion = event.pull(15, "GERTData") --This is a sub-optimal implementation, as it triggers on the first received message, and ignores future messages. This could/will be bad on computers that directly receive high traffic through GERT. When possible, implement a system that checks that it was a response from the server you asked.
        --Verify Compatibility:
        if ServerVersion then 
            if ServerVersion >= compatibility then
                return true, 0
            else
                return false, INVALIDSERVERADDRESS
            end
        else
            return false, INCOMPATIBLESERVER
        end
    else
        return false, NILSERVERADDRESS
    end
end

local function VerifyCredentials(User,Password)

end

--Public Functions
function RequestPackage(PackageName,GivenServer) -- This function is for requesting packages from the set FTP server. Packages are always public.
    GivenServer = GivenServer or ConfigSettings["DefaultServer"]
    if PackageName then
        VerSer, code = VerifyServer(GivenServer, Compatibility)
        if VerSer then
            local FTPSocket = GERTi.openSocket(GivenServer, true, 98) --Open Server Connection
            local CID = 0 --Wait for server to open back
            while CID ~= 98 do
                _, _, CID = event.pull("GERTConnectionID")
            end
            SendData["Mode"] = "RequestPackage"
            SendData["Name"] = tostring(PackageName)
            if ServerResponse then
                --Receive Package
                --Close server connection
                --Return package installer location
            else
                return false, FILENOTFOUND
            end
        else
            return VerSer, code
        
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

--For manual execution, or .shrc
if args[1] == "setup" then
    ConfigSettings["DefaultServer"] = args[2]
    if fs.exists(".config") then
        if fs.isDirectory(".config") then
            local ConfigFile = io.open(".config/.OFTPLIB", "w")
            ConfigFile:write(serialization.serialize(ConfigSettings))
            ConfigFile:close()
        else
            print(false)
            print(CONFIGDIRECTORYISFILE)
        end
    else
        fs.makeDirectory(".config")
        local ConfigFile = io.open(".config/.OFTPLIB", "w")
        ConfigFile:write(serialization.serialize(ConfigSettings))
        ConfigFile:close()
    end
end