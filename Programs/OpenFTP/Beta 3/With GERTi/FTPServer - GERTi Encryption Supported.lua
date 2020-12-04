--Initialisation
local shell = require("shell")
local args, opts = shell.parse(...)
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

--Directory Checks:
if fs.isDirectory(".config") then -- If the config file exists, read it and load its settings
    if fs.exists(".config/.OFTPLIBSERVER") then
        local ConfigFile = io.open("/.config/.OFTPLIBSERVER")
        ConfigSettings = SRL.unserialize(ConfigSettings:read())
    end
end
if not(fs.isDirectory("OpenFTPLIB")) then -- Ensures that the OpenFTPLIB directory and its sub-directories exist, and create them if not. It will also rename any files that share the directories' names to name.oldFile, to allow the directory to be placed.
    if fs.exists("OpenFTPLIB") then
        fs.rename("OpenFTPLIB", "OpenFTPLIB.oldFile")
    end
    fs.makeDirectory("OpenFTPLIB")
end
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