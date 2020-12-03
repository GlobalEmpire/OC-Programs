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
local SRL = require("serialization")

--Program Variables:
local PCID = 98
local ConfigSettings = []
local SendData = []
local OpenSockets = []

--Program Error Codes:
local FILENOTFOUND = 0
local INVALIDCREDENTIALS = 1
local INVALIDFILELOCATION = 2
local INVALIDSERVERADDRESS = 3
local NILSERVERADDRESS = 4
local INCOMPATIBLESERVER = 5
local UNEXPECTEDRESPONSE = 6
local TIMEOUT = 7
local MISSINGHARDWARE = 8
local CONFIGDIRECTORYISFILE = 10

--OnRun Code:
if fs.isDirectory(".config") then -- If the config file exists, read it and load its settings
    if fs.exists(".config/.OFTPLIB") then
        local ConfigFile = io.open(".config/.OFTPLIB")
        ConfigSettings = SRL.unserialize(ConfigSettings:read())
    end
end

if fs.isDirectory("OpenFTPLIB") then -- Ensures that the OpenFTPLIB directory and its sub-directories exist, and create them if not. It will also rename any files that share the directories' names to name.oldFile, to allow the directory to be placed.
    ::makeDirectories::
    if not(fs.isDirectory("OpenFTPLIB/Packages")) then
        if fs.exists("OpenFTPLIB/Packages") then
            fs.rename("OpenFTPLIB/Packages", "OpenFTPLIB/Packages.oldFile")
        end
        fs.makeDirectory("OpenFTPLIB/Packages")
    end
    if not(fs.isDirectory("OpenFTPLIB/Downloads")) then
        if fs.exists("OpenFTPLIB/Downloads") then
            fs.rename("OpenFTPLIB/Downloads", "OpenFTPLIB/Downloads.oldFile")
        end
        fs.makeDirectory("OpenFTPLIB/Downloads")
    end
else
    if fs.exists("OpenFTPLIB") then
        fs.rename("OpenFTPLIB", "OpenFTPLIB.oldFile")
    end
    fs.makeDirectory("OpenFTPLIB")
    goto makeDirectories
end

--Private Functions:
local function FilterResponse(eventName, originAddress, connectionID) --Filters out GERTData responses that aren't responding to this program.
    if eventName == "GERTData" then
        if connectionID == PCID then
            if OpenSockets[originAddress] then
                return true
            end
        end
    end
    return false
end

local function VerifyServer(address,compatibility) -- Verify that the server exists and has a sufficient compatibility level
    if address then --Verify that the default address or given address isnt nil 
        --Verify Server exists:
        GERTi.send(FTPaddress, "GetVersion")
        local _, _, _, ServerVersion = event.pull(15, "GERTData") --This is a sub-optimal implementation, as it triggers on the first received message, and ignores future messages. This could/will be bad on computers that directly receive high traffic through GERT. When possible, implement a system that checks that it was a response from the server you asked. -- Idea: Use event.pullFiltered()
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
        local VerSer, code = VerifyServer(GivenServer, Compatibility)
        if VerSer then
            local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
            local CID = 0 --Wait for server to open back
            while CID ~= PCID do
                _, _, CID = event.pull("GERTConnectionID")
            end
            SendData["Mode"] = "RequestPackage" --setup data to send
            SendData["Name"] = tostring(PackageName)
            local receiving = true --setup the while loop
            local ReceivedData = ""
            while receiving do 
                OpenSockets[GivenServer]:write(SRL.serialize(SendData)) --send serialized table of what we want
                local originAddress = 0.0
                local NoError = ""
                local ServerResponse = ""
                while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                    NoError, originAddress, _, ServerResponse = event.pullFiltered(15, FilterResponse)
                end
                if NoError then --if it didnt time out:
                    local TempData =  tostring(OpenSockets[GivenServer]:read())
                    ReceivedData = ReceivedData .. TempData
                    if string.len(TempData) <= m.maxPacketSize() - 512 then --Make sure you received the whole table, if not, resend the request and obtain the next part until it has everything (to dynamically adapt to modem message size limitations, -512 for GERTi overhead)
                        receiving = false --Tidy up
                        OpenSockets[GivenServer]:close()
                        if SRL.unserialize(ReceivedData)["PackageName"] == nil then
                            return false, FILENOTFOUND
                        end
                        local packageFile = io.open("OpenFTPLIB/Packages/" .. tostring(PackageName), "w") --Overwrites any existing file. This is intentional
                        packageFile:write(ReceivedData)
                        packageFile:close()
                        return true, "OpenFTPLIB/Packages/" .. tostring(PackageName)
                    end
                else
                    OpenSockets[GivenServer]:close()
                    return false, TIMEOUT
                end
            end
        else
            return VerSer, code
        end
    else
        return false, FILENOTFOUND
    end
end

function RequestFile(FileName,GivenServer,User,Password) -- This function Requests a file from the user. Params 3 and 4 are Username and Password respectively, leave blank to request a public file.
    GivenServer = GivenServer or ConfigSettings["DefaultServer"]
    if user == nil then
        if FileName then
            local VerSer, code = VerifyServer(GivenServer, Compatibility)
            if VerSer then
                local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
                local CID = 0 --Wait for server to open back
                while CID ~= PCID do
                    _, _, CID = event.pull("GERTConnectionID")
                end
                SendData["Mode"] = "RequestPublicFile" --setup data to send
                SendData["Name"] = tostring(FileName)
                local receiving = true --setup the while loop
                local ReceivedData = ""
                while receiving do 
                    OpenSockets[GivenServer]:write(SRL.serialize(SendData)) --send serialized table of what we want
                    local originAddress = 0.0
                    local NoError = ""
                    local ServerResponse = ""
                    while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                        NoError, originAddress, _, ServerResponse = event.pullFiltered(15, FilterResponse)
                    end
                    if NoError then --if it didnt time out:
                        local TempData =  tostring(OpenSockets[GivenServer]:read())
                        ReceivedData = ReceivedData .. TempData
                        if string.len(TempData) <= m.maxPacketSize() - 512 then --Make sure you received the whole table, if not, resend the request and obtain the next part until it has everything (to dynamically adapt to modem message size limitations, -512 for GERTi overhead)
                            receiving = false --Tidy up
                            OpenSockets[GivenServer]:close()
                            local FileTable = SRL.unserialize(ReceivedData)
                            if FileTable["FileName"] == FileName then
                                local File = io.open("OpenFTPLIB/Downloads/" .. tostring(FileName), "w") --Overwrites any existing file. This is intentional
                                File:write(FileTable["Content"])
                                File:close()
                                return true, "OpenFTPLIB/Downloads/" .. tostring(FileName)
                            else
                                return false, FILENOTFOUND
                            end
                        end
                    else
                        OpenSockets[GivenServer]:close()
                        return false, TIMEOUT
                    end
                end
            else
                return VerSer, code
            end
        else
            return false, FILENOTFOUND
        end
    else
        if DC.generateKeyPair == nil then 
            return false, MISSINGHARDWARE
        end
        if FileName then
            local VerSer, code = VerifyServer(GivenServer, Compatibility)
            if VerSer then
                local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
                local CID = 0 --Wait for server to open back
                while CID ~= PCID do
                    _, _, CID = event.pull("GERTConnectionID")
                end
                SendData["Mode"] = "RequestPrivateFile" --setup data to send
                SendData["Name"] = tostring(FileName)
                SendData["User"] = User
                local PuKey, PrKey = DC.generateKeyPair()
                SendData["PasswordSignature"] = ecdsa(Password,PrKey)
                SendData["PuKey"] = PuKey.serialize()
                local receiving = true --setup the while loop
                local ReceivedData = ""
                while receiving do 
                    OpenSockets[GivenServer]:write(SRL.serialize(SendData)) --send serialized table of what we want
                    local originAddress = 0.0
                    local NoError = ""
                    local ServerResponse = ""
                    while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                        NoError, originAddress, _, ServerResponse = event.pullFiltered(15, FilterResponse)
                    end
                    if NoError then --if it didnt time out:
                        local TempData =  tostring(OpenSockets[GivenServer]:read())
                        ReceivedData = ReceivedData .. TempData
                        if string.len(TempData) <= m.maxPacketSize() - 512 then --Make sure you received the whole table, if not, resend the request and obtain the next part until it has everything (to dynamically adapt to modem message size limitations, -512 for GERTi overhead)
                            receiving = false --Tidy up
                            OpenSockets[GivenServer]:close()
                            local FileTable = SRL.unserialize(ReceivedData)
                            if FileTable["UserValid"] then
                                if FileTable["FileName"] == FileName then
                                    local SharedSecret = DC.ecdh(PrKey, FileTable["PuKey"])
                                    local TruncatedSHA256Key = string.sub(DC.sha256(SharedSecret),1,16)
                                    local File = io.open("OpenFTPLIB/Downloads/" .. tostring(FileName), "w") --Overwrites any existing file. This is intentional
                                    File:write(DC.decrypt(FileTable["Content"],TruncatedSHA256Key,1))
                                    File:close()
                                    return true, "OpenFTPLIB/Downloads/" .. tostring(FileName)
                                else
                                    return false, FILENOTFOUND
                                end
                            else
                                return false, INVALIDCREDENTIALS
                            end
                        end
                    else
                        OpenSockets[GivenServer]:close()
                        return false, TIMEOUT
                    end
                end
            else
                return VerSer, code
            end
        else
            return false, FILENOTFOUND
        end
    end
end

function SendFile(FileName,GivenServer,User,Password)
    GivenServer = GivenServer or DefaultServer
    if FileName then
        local VerSer, code = VerifyServer(GivenServer, Compatibility)
        if VerSer then
            local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
            local CID = 0 --Wait for server to open back
            while CID ~= PCID do
                _, _, CID = event.pull("GERTConnectionID")
            end
            SendData["Mode"] = "SendPrivateFile" --setup data to send
            SendData["Name"] = tostring(FileName)
            SendData["User"] = User
            local PuKey, PrKey = DC.generateKeyPair()
            SendData["PasswordSignature"] = ecdsa(Password,PrKey)
            SendData["PuKey"] = PuKey.serialize()
            local SendingData = SRL.serialize(SendData)
            local Sending = true
            while Sending do
                if string.len(SendingData) > m.maxPacketSize() - 512 then
                    local tempSend = string.sub(SendingData,1,m.maxPacketSize()-512)
                    SendingData = string.sub(SendingData,m.maxPacketSize())
                    OpenSockets[GivenServer]:write(tempSend)
                else
                    OpenSockets[GivenServer]:write(SendingData)
                    OpenSockets[GivenServer]:close()
                end
            end
        else
            return false, INVALIDSERVERADDRESS
        end
    end
end

function CreateRemoteUser(User,Password)

end

function DeleteRemoteUser(User,Password)

end

function DeleteRemoteFile(FileName,User,Password)

end

--For manual execution, or .shrc
if args[1] == "setup" then
    ConfigSettings["DefaultServer"] = args[2]
    if fs.exists(".config") then
        if fs.isDirectory(".config") then
            local ConfigFile = io.open(".config/.OFTPLIB", "w")
            ConfigFile:write(SRL.serialize(ConfigSettings))
            ConfigFile:close()
        else
            print(false)
            print(CONFIGDIRECTORYISFILE)
        end
    else
        fs.makeDirectory(".config")
        local ConfigFile = io.open(".config/.OFTPLIB", "w")
        ConfigFile:write(SRL.serialize(ConfigSettings))
        ConfigFile:close()
    end
end