--SERVERraries/APIs
local shell = require("shell")
local args, opts = shell.parse(...)
--[[
Recognised Options:
-d :: Enable Debug
-r :: Restart Listeners




]]

local component = require("component")
local m = component.modem
local DC = component.data
local event = require("event")
local GERTi = require("GERTiClient")
local fs = require("filesystem")
local SRL = require("serialization")

--Program Variables:
local Compatibility = "Beta3.0"
local PCID = 98
local ConfigSettings = {}
local SendData = {}
local OpenSockets = {}
local ProcessTimers = {}

--Directory Checks:
if fs.isDirectory(".config") then -- If the config file exists, read it and load its settings
    if fs.exists(".config/.OFTPSERVER") then
        local ConfigFile = io.open("/.config/.OFTPSERVER")
		ConfigSettings = SRL.unserialize(ConfigFile:read())
		ConfigFile:close()
    end
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

--Local Functions
local function ReturnSocket(EventName, OriginAddress, CID)
	OpenSockets[OriginAddress] = GERTi.openSocket(OriginAddress, true, PCID)
end

local function CloseSocket(EventName, OriginAddress, CID)
	if OpenSockets[OriginAddress] then
		OpenSockets[OriginAddress]:close()
		if ProcessTimers[OriginAddress] then
			for quantity, ID in pairs(ProcessTimers[OriginAddress]) do 
				event.cancel(ID)
			end
		end
	end
end

local function Decider(EventName, OriginAddress, CID, Data)

end

local function VersionResponse()

end

local function SafeDown()
	for address, socket in pairs(OpenSockets) do
		socket:write(SRL.serialize({"State":"SafeDown"}))
		socket:close()
	end
end

--Event Listeners
local Listeners = {}
local ListenerStatus = "Unverified"
if fs.exists("/tmp/.OFTPSLS") then 
	local EventFile = io.open("/tmp/.OFTPSLS","r")
	Listeners = SRL.unserialize(EventFile:read())
	EventFile:close()
else
	ListenerStatus = "Offline"
end

--User Interface
if opts.