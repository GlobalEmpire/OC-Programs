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
local UNKNOWNERROR = 0
local FILENOTFOUND = 1
local INVALIDCREDENTIALS = 2
local INVALIDFILELOCATION = 3
local INVALIDSERVERADDRESS = 4
local NILSERVERADDRESS = 5
local INCOMPATIBLESERVER = 6
local UNEXPECTEDRESPONSE = 7
local TIMEOUT = 8
local MISSINGHARDWARE = 9
local FILEEXISTS = 10
local NOSPACE = 11
local USERMODIFICATIONERROR = 12
local USEREXISTS = 13
local USERDOESNOTEXIST = 14
local CONFIGDIRECTORYISFILE = 20


local ServerSideErrors = []
ServerSideErrors["Ready"] = UNKNOWNERROR
ServerSideErrors["FileExists"] = FILEEXISTS
ServerSideErrors["InvalidCredentials"] = INVALIDCREDENTIALS
ServerSideErrors["InsufficientSpace"] = NOSPACE
ServerSideErrors["UserModificationError"] = USERMODIFICATIONERROR
ServerSideErrors["UserExists"] = USEREXISTS
ServerSideErrors["UserDoesNotExist"] = USERDOESNOTEXIST



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
                return false, INCOMPATIBLESERVER
            end
        else
            return false, INVALIDSERVERADDRESS
        end
    else
        return false, NILSERVERADDRESS
    end
end

local function VerifyCredentials(Password,User)

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

function RequestFile(FileName,GivenServer,Password,User) -- This function Requests a file from the user. Params 3 and 4 are Username and Password respectively, leave blank to request a public file.
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
                            if FileTable["State"] == "Ready" then
                                if FileTable["FileName"] == FileName then
                                    local SharedSecret = DC.ecdh(PrKey, DC.deserializeKey(FileTable["PuKey"]))
                                    local TruncatedSHA256Key = string.sub(DC.sha256(SharedSecret),1,16)
                                    local File = io.open("OpenFTPLIB/Downloads/" .. tostring(FileName), "w") --Overwrites any existing file. This is intentional
                                    File:write(DC.decrypt(FileTable["Content"],TruncatedSHA256Key,1))
                                    File:close()
                                    return true, "OpenFTPLIB/Downloads/" .. tostring(FileName)
                                else
                                    return false, FILENOTFOUND
                                end
                            else
                                return false, ServerSideErrors[FileTable["State"]]
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

function SendFile(FilePath,GivenServer,Password,User)
    GivenServer = GivenServer or DefaultServer
    if FilePath then
        local VerSer, code = VerifyServer(GivenServer, Compatibility)
        if VerSer then
            local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
            local CID = 0 --Wait for server to open back
            while CID ~= PCID do
                _, _, CID = event.pull("GERTConnectionID")
            end
            SendData["Mode"] = "SendPrivateFile" --setup data to send
            SendData["Name"] = fs.name(FilePath)
            SendData["User"] = User or "Public"
            local PuKey, PrKey = DC.generateKeyPair()
            SendData["PasswordSignature"] = ecdsa(Password or "Default",PrKey)
            SendData["PuKey"] = PuKey.serialize()
            SendData["Size"] = fs.size(FilePath)
            local SendingData = SRL.serialize(SendData)
            local Sending = true
            local FileData = io.open(FilePath, "r")
            local EncodedFileData = ""
            while Sending do
                OpenSockets[GivenServer]:write(SendingData)
                local originAddress = 0.0
                local NoError = ""
                while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                    NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
                end
                if NoError then
                    local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                    if ServerResponse["State"] == "Ready" then
                        if SendData["Content"] == nil then
                            local SharedSecret = DC.ecdh("PrKey", DC.deserializeKey(ServerResponse["PuKey"]))
                            local TruncatedSHA256Key = string.sub(DC.sha256(SharedSecret),1,16)
                            SendData = []
                            SendData["Content"] = DC.encrypt(FileData:read(),TruncatedSHA256Key,1)
                            FileData:close()
                            SendData["Name"] = fs.name(FilePath)
                            SendingData = SRL.serialize(SendData)
                        end
                        if string.len(SendingData) > m.maxPacketSize() - 512 then
                            local tempSend = string.sub(SendingData,1,m.maxPacketSize()-512)
                            SendingData = string.sub(SendingData,m.maxPacketSize()-512)
                            OpenSockets[GivenServer]:write(tempSend)
                        else
                            OpenSockets[GivenServer]:write(SendingData)
                            OpenSockets[GivenServer]:close()
                            Sending = false
                            return true, 0
                        end
                    else
                        Sending = false
                        FileData:close()
                        OpenSockets[GivenServer]:close()
                        return false, ServerSideErrors[ServerResponse["State"]]    
                    end
                else
                    Sending = false
                    FileData:close()
                    OpenSockets[GivenServer]:close()
                    return false, TIMEOUT
                end
            end
        else
            return false, INVALIDSERVERADDRESS
        end
    else
        return false, FILENOTFOUND
    end
end

function CreateRemoteUser(GivenServer,Password,User)
    GivenServer = GivenServer or DefaultServer
    if Password and user then
        local VerSer, code = VerifyServer(GivenServer, Compatibility)
        if VerSer then
            local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
            local CID = 0 --Wait for server to open back
            while CID ~= PCID do
                _, _, CID = event.pull("GERTConnectionID")
            end
            SendData["Mode"] = "CreateUser" --setup data to send
            local PuKey, PrKey = DC.generateKeyPair()
            SendData["PuKey"] = PuKey.serialize()
            local SendingData = SRL.serialize(SendData)
            local Sending = true
            while Sending do
                OpenSockets[GivenServer]:write(SendingData)
                local originAddress = 0.0
                local NoError = ""
                while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                    NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
                end
                if NoError then
                    local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                    if ServerResponse["State"] == "Ready" then
                        local SharedSecret = DC.ecdh(PrKey, DC.deserializeKey(ServerResponse["PuKey"]))
                        local TruncatedSHA256Key = string.sub(DC.sha256(SharedSecret),1,16)
                        SendData["User"] = DC.encrypt(User,TruncatedSHA256Key,1)
                        SendData["Password"] = DC.encrypt(Password,TruncatedSHA256Key,2)
                        SendingData = SRL.serialize(SendData)
                        OpenSockets[GivenServer]:write(SendingData)
                        local originAddress = 0.0
                        local NoError = ""
                        while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                            NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
                        end
                        if NoError then
                            local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                            if ServerResponse["State"] == "Ready" then
                                OpenSockets[GivenServer]:close()
                                return true, 0
                            else
                                OpenSockets[GivenServer]:close()
                                return false, ServerSideErrors[ServerResponse["State"]] 
                            end
                        else
                            OpenSockets[GivenServer]:close()
                            return false, TIMEOUT
                        end
                    else
                        return false, ServerSideErrors[ServerResponse["State"]]
                    end
                else
                    return false, TIMEOUT
                end
            end
        else
            return false, INVALIDSERVERADDRESS
        end
    else
        return false, INVALIDCREDENTIALS
    end
end

function DeleteRemoteUser(GivenServer,Password,User)
    GivenServer = GivenServer or DefaultServer
    if Password and user then
        local VerSer, code = VerifyServer(GivenServer, Compatibility)
        if VerSer then
            local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
            local CID = 0 --Wait for server to open back
            while CID ~= PCID do
                _, _, CID = event.pull("GERTConnectionID")
            end
            SendData["Mode"] = "DeleteUser" --setup data to send
            local PuKey, PrKey = DC.generateKeyPair()
            SendData["PuKey"] = PuKey.serialize()
            local SendingData = SRL.serialize(SendData)
            local Sending = true
            while Sending do
                OpenSockets[GivenServer]:write(SendingData)
                local originAddress = 0.0
                local NoError = ""
                while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                    NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
                end
                if NoError then
                    local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                    if ServerResponse["State"] == "Ready" then
                        SendData["User"] = User
                        SendData["PasswordSignature"] = DC.ecdsa(Password,PrKey)
                        SendingData = SRL.serialize(SendData)
                        OpenSockets[GivenServer]:write(SendingData)
                        local originAddress = 0.0
                        local NoError = ""
                        while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                            NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
                        end
                        if NoError then
                            local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                            if ServerResponse["State"] == "Ready" then
                                OpenSockets[GivenServer]:close()
                                return true, 0
                            else
                                OpenSockets[GivenServer]:close()
                                return false, ServerSideErrors[ServerResponse["State"]] 
                            end
                        else
                            OpenSockets[GivenServer]:close()
                            return false, TIMEOUT
                        end
                    else
                        return false, ServerSideErrors[ServerResponse["State"]]
                    end
                else
                    return false, TIMEOUT
                end
            end
        else
            return false, INVALIDSERVERADDRESS
        end
    else
        return false, INVALIDCREDENTIALS
    end
end

function DeleteRemoteFile(FilePath,GivenServer,Password,User)
    GivenServer = GivenServer or DefaultServer
    if Password and user then
        local VerSer, code = VerifyServer(GivenServer, Compatibility)
        if VerSer then
            local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
            local CID = 0 --Wait for server to open back
            while CID ~= PCID do
                _, _, CID = event.pull("GERTConnectionID")
            end
            SendData["Mode"] = "DeleteFile" --setup data to send
            SendData["User"] = User or "Public"
            local PuKey, PrKey = DC.generateKeyPair()
            SendData["PasswordSignature"] = ecdsa(Password or "Default",PrKey)
            SendData["PuKey"] = PuKey.serialize()
            local SendingData = SRL.serialize(SendData)
            local Sending = true
            while Sending do
                OpenSockets[GivenServer]:write(SendingData)
                local originAddress = 0.0
                local NoError = ""
                while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                    NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
                end
                if NoError then
                    local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                    if ServerResponse["State"] == "Ready" then
                        local SharedSecret = DC.ecdh(PrKey, DC.deserializeKey(ServerResponse["PuKey"]))
                        local TruncatedSHA256Key = string.sub(DC.sha256(SharedSecret),1,16)
                        SendData["Name"] = DC.encrypt(FilePath,TruncatedSHA256Key,1)
                        SendingData = SRL.serialize(SendData)
                        OpenSockets[GivenServer]:write(SendingData)
                        local originAddress = 0.0
                        local NoError = ""
                        while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                            NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
                        end
                        if NoError then
                            local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                            if ServerResponse["State"] == "Ready" then
                                OpenSockets[GivenServer]:close()
                                return true, 0
                            else
                                OpenSockets[GivenServer]:close()
                                return false, ServerSideErrors[ServerResponse["State"]] 
                            end
                        else
                            OpenSockets[GivenServer]:close()
                            return false, TIMEOUT
                        end
                    else
                        return false, ServerSideErrors[ServerResponse["State"]]
                    end
                else
                    return false, TIMEOUT
                end
            end
        else
            return false, INVALIDSERVERADDRESS
        end
    else
        return false, INVALIDCREDENTIALS
    end
end

function GetFiles(GivenServer,Password,User)
    GivenServer = GivenServer or DefaultServer
    local VerSer, code = VerifyServer(GivenServer, Compatibility)
    if VerSer then
        local OpenSockets[GivenServer] = GERTi.openSocket(GivenServer, true, PCID) --Open Server Connection
        local CID = 0 --Wait for server to open back
        while CID ~= PCID do
            _, _, CID = event.pull("GERTConnectionID")
        end
        SendData["Mode"] = "GetFiles" --setup data to send
        SendData["User"] = User or "Public"
        local PuKey, PrKey = DC.generateKeyPair()
        SendData["PasswordSignature"] = ecdsa(Password or "Default",PrKey)
        SendData["PuKey"] = PuKey.serialize()
        local SendingData = SRL.serialize(SendData)
        local Sending = true
        while Sending do
            OpenSockets[GivenServer]:write(SendingData)
            local originAddress = 0.0
            local NoError = ""
            while NoError and originAddress ~= GivenServer do --Make sure that it only stops when the function times out or we get a response from the server
                NoError, originAddress, _ = event.pullFiltered(15, FilterResponse)
            end
            if NoError then
                local ServerResponse = SRL.unserialize(OpenSockets[GivenServer]:read())
                if ServerResponse["State"] == "Ready" then
                    if User then
                        local SharedSecret = DC.ecdh(PrKey, DC.deserializeKey(ServerResponse["PuKey"]))
                        local TruncatedSHA256Key = string.sub(DC.sha256(SharedSecret),1,16)
                        ServerResponse["FileList"] = DC.decrypt(ServerResponse["FileList"],TruncatedSHA256Key,1)
                    end
                    OpenSockets[GivenServer]:close()
                    return true, SRL.unserialize(ServerResponse["FileList"])
                else
                    return false, ServerSideErrors[ServerResponse["State"]]
                end
            else
                return false, TIMEOUT
            end
        end
    else
        return false, INVALIDSERVERADDRESS
    end
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