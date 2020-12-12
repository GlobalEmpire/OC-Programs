--Libraries/APIs
local shell = require("shell")
local args, opts = shell.parse(...)
--[[
Recognised Options:
-r :: Restart Listeners belonging to the profile provided in the first argument, or the default profile otherwise. It is recommended to also pass -r alongside other options, as the other options do not apply their effects until the relevent processes reload the config file, e.g.: they are restarted. 
-d :: Enable Debug mode on the profile provided in the first argument, or the default profile otherwise. Will persist until passed a second time, or the profile's config file is reset/deleted.
-l :: Loud mode, causes the profile provided in the first argument to output every event and action related to it that it can to the screen, useful for monitoring, or just making the server look cool. 
-a :: All, If launched alone, launches all existing profiles, if present alongside another option, applies its effects to all profiles, and ignores any passed profile. If multiple profiles have differing values, it will not toggle each individually, but instead activate them all. Only if all are active will it deactivate. I.E. if profile 1 debug is off and profile 2 debug is on, passing -da will always turn profile 1 on, and only when both 1 and 2 are on will it turn both of them off (Use -do in this case). Is compatible with -rdlo.
-o :: Resets all previous option states on the profile provided in the first argument, or the default profile otherwise, i.e.: it disables Debug, Loud, ... regardless of prior state. If passed with other options, it will instead reset said option in the specified profile. Compatible with -dla.

Recognised Argument patterns:
"NoGui" - Launches the program in Default mode, but without GUI. Does nothing if GUI is disabled in the Default Config File
"ForceGui" - Launches the program in Default, and ensures the the Full GUI is launched regardless of any other set parameters.
"SafeDown" - This Argument must be passed alone, with no options. This stops the program and all profiles, regardless of whatever they might be doing. This is intended to be used in the event that a shutdown is imminent, and that there is not enough time to wait for anything to complete. The program will immediately stop accepting new connections, kill all existing processes related to the program, send "SafeDown" to all open connections, to alert them to the immediate interruption of service, and then close all connections. It is preferred to use the argument "FinishAll" when circumstances allow, as it will push the "OFTPSAFE" event when finished.

I might add the following feature to Beta 4:
"Boot"[, Profile: string] - This argument can be passed with a second argument for the profile name, but simply launches the default profile otherwise. This changes the following normal behaviours of the program:
    It loads the OFTPD Config file from the specified profile. In the event the profile or the config file doesnt exist, the program will simply beep 3 times, and exit with no further exceptions. This is to allow a multiple servers with different configuration options to run on the computer without interfering, and all can easily be launched right after boot, hence the argument name.
    The OFTPD config file can be edited/created either by using the argument "ProfileEdit" (See below) or navigating to Advanced Options, then Profiles, in the normal GUI.
    The program then initialises itself as normal following the Profile Config File, but instead of the default path directly under /OpenFTPSERVER it will transpose all of its paths to "/OpenFTPSERVER/Profiles/" .. Profile.


    The Config file includes the following parameters:
        GuiMode: string -- This determines how the GUI does (or doesn't) start -- The GUI is global, and does not depend on the profile. If the GUI is launched by a profile, and a subsequent profile is launched with the GUI enabled, it will simply ignore the request to launch the GUI, since it is already open.
            Since the GUI is global, and oversees all active profiles, the GuiMode variable only exists in the Main config file, and not the Profile config files.
        OperatingCID: number -- This determines what CID the program will run and listen on
        DisabledFeatures: table -- This table contains the names of features that the server can do. Any feature that the server program has, that is in this table with the value of `true` will not be started, but instead an alternative function will be started that responds to any incoming request to utilise this feature that it has been disabled.

]]
local component = require("component")
local m = component.modem
local MPSI = m.maxPacketSize or require("DeviceInfo")
local DC = component.data
local event = require("event")
local GERTi = require("GERTiClient")
local fs = require("filesystem")
local SRL = require("serialization")


--Program Variables:
local Compatibility = "Beta3.0"
local PCID = 98 -- Make this load from config
local ConfigSettings = {}
local SendData = {}
local OpenSockets = {}
local ModeData = {}
local Processes = {}
local TimeOuts = {}
local Profile = ""

--Directory Checks:
if fs.isDirectory(".config") then -- If the config file exists, read it and load its settings
    if fs.exists(".config/.OFTPSERVER") then
        local ConfigFile = io.open("/.config/.OFTPSERVER")
		ConfigSettings = SRL.unserialize(ConfigFile:read("*a"))
		ConfigFile:close()
    end
else
    args[1] = "FirstRun"
end
if not(fs.isDirectory("OpenFTPSERVER")) then -- Ensures that the OpenFTPSERVER directory and its sub-directories exist, and create them if not. It will also rename any files that share the directories' names to name.oldFile, to allow the directory to be placed.
    if fs.exists("OpenFTPSERVER") then
        fs.rename("OpenFTPSERVER", "OpenFTPSERVER.oldFile")
    end
    fs.makeDirectory("OpenFTPSERVER")
end
if not(fs.isDirectory("OpenFTPSERVER/Packages")) then
    if fs.exists("OpenFTPSERVER/Packages") then
        fs.rename("OpenFTPSERVER/Packages", "OpenFTPSERVER/Packages.oldFile")
    end
    fs.makeDirectory("OpenFTPSERVER/Packages")
end
if not(fs.isDirectory("OpenFTPSERVER/Public")) then
    if fs.exists("OpenFTPSERVER/Public") then
        fs.rename("OpenFTPSERVER/Public", "OpenFTPSERVER/Public.oldFile")
    end
    fs.makeDirectory("OpenFTPSERVER/Public")
end
if not(fs.isDirectory("OpenFTPSERVER/Users")) then
    if fs.exists("OpenFTPSERVER/Users") then
        fs.rename("OpenFTPSERVER/Users", "OpenFTPSERVER/Users.oldFile")
    end
    fs.makeDirectory("OpenFTPSERVER/Users")
end
if not(fs.isDirectory("OpenFTPSERVER/Profiles")) then
    if fs.exists("OpenFTPSERVER/Profiles") then
        fs.rename("OpenFTPSERVER/Profiles", "OpenFTPSERVER/Profiles.oldFile")
    end
    fs.makeDirectory("OpenFTPSERVER/Profiles")
end

--Local Functions
local function ReturnSocket(EventName, OriginAddress, CID)
	OpenSockets[OriginAddress] = GERTi.openSocket(OriginAddress, true, PCID)
end

local function CloseSocket(EventName, OriginAddress, DestinationAddress, CID)
    if TimeOuts[OriginAddress] and CID == PCID then
        event.cancel(TimeOuts[OriginAddress])
        TimeOuts[OriginAddress] = nil
    end	
    if OpenSockets[OriginAddress] and CID == PCID then 
        OpenSockets[OriginAddress]:close()
        OpenSockets[OriginAddress] = nil
        ModeData[OriginAddress] = nil
    end
end

local function TimeOutConnection(Address,CID) 
    return function() 
        CloseSocket("GERTConnectionClose",Address,GERTi.getAddress(),CID)
    end
end

Processes["RequestPackage"] = function (OriginAddress)
    if not(ModeData[OriginAddress]["SendData"]) and fs.exists("OpenFTPSERVER/"..Profile.."Packages/"..ModeData[OriginAddress]["Name"]) and not(fs.isDirectory("OpenFTPSERVER/"..Profile.."Packages/"..ModeData[OriginAddress]["Name"])) then
        local Package = io.open("/OpenFTPSERVER/"..Profile.."Packages/"..ModeData[OriginAddress]["Name"],"r")--SECURITY BREACH, get the true form to make sure it never goes up a directory
        ModeData[OriginAddress]["SendData"] = {}
        ModeData[OriginAddress]["SendData"]["PackageName"] = ModeData[OriginAddress]["Name"]
        ModeData[OriginAddress]["SendData"]["Package"] = Package:read("*a")
        Package:close()
    elseif not(ModeData[OriginAddress]["SendData"]) then
        ModeData[OriginAddress]["SendData"] = {}
    else
        local readData = SRL.unserialize(OpenSockets[OriginAddress]:read()[1])
        for k,v in pairs(readData) do
            if k ~= "SendData" and k ~= "SerialData" and k ~= "SerialSendData" then
                ModeData[OriginAddress][k] = v
            end
        end
    end
    if not(ModeData[OriginAddress]["SerialData"]) then
        ModeData[OriginAddress]["SerialData"] = SRL.serialize(ModeData[OriginAddress]["SendData"])
    end
    if string.len(ModeData[OriginAddress]["SerialData"]) > m.maxPacketSize() - 512 then
        ModeData[OriginAddress]["SerialSendData"] = string.sub(ModeData[OriginAddress]["SerialData"],1,m.maxPacketSize()-511)
        ModeData[OriginAddress]["SerialData"] = string.sub(ModeData[OriginAddress]["SerialData"],m.maxPacketSize()-510)
    else
        ModeData[OriginAddress]["SerialSendData"] = ModeData[OriginAddress]["SerialData"]
    end
    OpenSockets[OriginAddress]:write(ModeData[OriginAddress]["SerialSendData"])
    if TimeOuts[OriginAddress] then
        event.cancel(TimeOuts[OriginAddress])
    end
    TimeOuts[OriginAddress] = event.timer(15,TimeOutConnection(Address,PCID))
end

Processes["RequestPublicFile"] = function (OriginAddress)
    if not(ModeData[OriginAddress]["SendData"]) and fs.exists("OpenFTPSERVER/"..Profile.."Public/"..ModeData[OriginAddress]["Name"]) and not(fs.isDirectory("OpenFTPSERVER/"..Profile.."Public/"..ModeData[OriginAddress]["Name"])) then
        local Package = io.open("/OpenFTPSERVER/"..Profile.."Public/"..ModeData[OriginAddress]["Name"],"r") --SECURITY BREACH, get the true form to make sure it never goes up a directory
        ModeData[OriginAddress]["SendData"] = {}
        ModeData[OriginAddress]["SendData"]["FileName"] = ModeData[OriginAddress]["Name"]
        ModeData[OriginAddress]["SendData"]["Content"] = Package:read("*a")
        Package:close()
    elseif not(ModeData[OriginAddress]["SendData"]) then
        ModeData[OriginAddress]["SendData"] = {}
    else
        local readData = SRL.unserialize(OpenSockets[OriginAddress]:read()[1])
        for k,v in pairs(readData) do
            if k ~= "SendData" and k ~= "SerialData" and k ~= "SerialSendData" then
                ModeData[OriginAddress][k] = v
            end
        end
    end
    if not(ModeData[OriginAddress]["SerialData"]) then
        ModeData[OriginAddress]["SerialData"] = SRL.serialize(ModeData[OriginAddress]["SendData"])
    end
    if string.len(ModeData[OriginAddress]["SerialData"]) > m.maxPacketSize() - 512 then
        ModeData[OriginAddress]["SerialSendData"] = string.sub(ModeData[OriginAddress]["SerialData"],1,m.maxPacketSize()-511)
        ModeData[OriginAddress]["SerialData"] = string.sub(ModeData[OriginAddress]["SerialData"],m.maxPacketSize()-510)
    else
        ModeData[OriginAddress]["SerialSendData"] = ModeData[OriginAddress]["SerialData"]
    end
    OpenSockets[OriginAddress]:write(ModeData[OriginAddress]["SerialSendData"])
    if TimeOuts[OriginAddress] then
        event.cancel(TimeOuts[OriginAddress])
    end
    TimeOuts[OriginAddress] = event.timer(15,TimeOutConnection(Address,PCID))
end

if DC.generateKeyPair then
    Processes["RequestPrivateFile"] = function (OriginAddress)
        if not(ModeData[OriginAddress]["PasswordSignature"] and ModeData[OriginAddress]["User"]) then
            OpenSockets[OriginAddress]:write(SRL.serialize("{State=\"InvalidCredentials\"}"))
            TimeOuts[OriginAddress] = event.timer(15,TimeOutConnection(Address,PCID))
        end
        if not(ModeData[OriginAddress]["SendData"]) and fs.exists("OpenFTPSERVER/"..Profile.."User/"..ModeData[OriginAddress]["Name"]) and not(fs.isDirectory("OpenFTPSERVER/"..Profile.."Public/"..ModeData[OriginAddress]["Name"])) then
            local Package = io.open("/OpenFTPSERVER/"..Profile.."Public/"..ModeData[OriginAddress]["Name"],"r") --SECURITY BREACH, get the true form to make sure it never goes up a directory
            ModeData[OriginAddress]["SendData"] = {}
            ModeData[OriginAddress]["SendData"]["FileName"] = ModeData[OriginAddress]["Name"]
            ModeData[OriginAddress]["SendData"]["Content"] = Package:read("*a")
            Package:close()
        elseif not(ModeData[OriginAddress]["SendData"]) then
            ModeData[OriginAddress]["SendData"] = {}
        else
            local readData = SRL.unserialize(OpenSockets[OriginAddress]:read()[1])
            for k,v in pairs(readData) do
                if k ~= "SendData" and k ~= "SerialData" and k ~= "SerialSendData" then
                    ModeData[OriginAddress][k] = v
                end
            end
        end
        if not(ModeData[OriginAddress]["SerialData"]) then
            ModeData[OriginAddress]["SerialData"] = SRL.serialize(ModeData[OriginAddress]["SendData"])
        end
        if string.len(ModeData[OriginAddress]["SerialData"]) > m.maxPacketSize() - 512 then
            ModeData[OriginAddress]["SerialSendData"] = string.sub(ModeData[OriginAddress]["SerialData"],1,m.maxPacketSize()-511)
            ModeData[OriginAddress]["SerialData"] = string.sub(ModeData[OriginAddress]["SerialData"],m.maxPacketSize()-510)
        else
            ModeData[OriginAddress]["SerialSendData"] = ModeData[OriginAddress]["SerialData"]
        end
        OpenSockets[OriginAddress]:write(ModeData[OriginAddress]["SerialSendData"])
        if TimeOuts[OriginAddress] then
            event.cancel(TimeOuts[OriginAddress])
        end
        TimeOuts[OriginAddress] = event.timer(15,TimeOutConnection(Address,PCID))
    end
end

local function SetMode(OriginAddress)
    ModeData[OriginAddress] = {}
    ModeData[OriginAddress] = SRL.unserialize(OpenSockets[OriginAddress]:read()[1])
    if ModeData[OriginAddress]["SendData"] then
        OpenSockets[OriginAddress]:write(SRL.serialize("{State=\"InvalidProvidedData\"}"))
        ModeData[OriginAddress] = nil
    elseif Processes[ModeData[OriginAddress]["Mode"]] then
        if not(ConfigSettings["DisabledFeatures"][ModeData[OriginAddress]["Mode"]]["disabled"]) then
            Processes[ModeData[OriginAddress]["Mode"]](OriginAddress)
        else
            OpenSockets[OriginAddress]:write(SRL.serialize("{State=\"Disabled\"}"))
            ModeData[OriginAddress] = nil
        end
    else
        OpenSockets[OriginAddress]:write(SRL.serialize("{State=\"ModeNotFound\"}"))
        ModeData[OriginAddress] = nil
    end
end

local function Decider(EventName, OriginAddress, CID, Data)
    if Data then
        if Data == "GetVersion" then
            GERTi.send(OriginAddress, Compatibility) -- Change this to use a socket instead of GERTi.send for compatibility verification
        end
    elseif CID == PCID and OpenSockets[OriginAddress] then
        if ModeData[OriginAddress] then
            Processes[ModeData[OriginAddress]["Mode"]](OriginAddress)
        else
            SetMode(OriginAddress)
        end
    end
end

local function ESafeDown()
	for address, socket in pairs(OpenSockets) do
		socket:write("{State=\"SafeDown\"}")
        socket:close()
    end
    
end

local function SafeStop()
    Compatibility = "Stopping"
    while not(SRL.serialize(OpenSockets) == "{}") do
    end
    event.push("OFTPSafeStop", PCID)
end
--Event Listeners
local Listeners = {}
local ListenerStatus = "Unverified"
if fs.exists("/tmp/.OFTPSLS"..tostring(PCID)) then 
	local EventFile = io.open("/tmp/.OFTPSLS"..tostring(PCID),"r")
	Listeners = SRL.unserialize(EventFile:read("*a"))
	EventFile:close()
else
	ListenerStatus = "Offline"
end


event.listen("GERTData",Decider)
event.listen("GERTConnectionID", ReturnSocket)
event.listen("GERTConnectionClose", CloseSocket)

--User Interface
--if opts.