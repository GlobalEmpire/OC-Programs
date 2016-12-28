local internet = require("internet")
local filesystem = require("filesystem")
local shell = require("shell")
local component = require("component")
local bagel = require("bagel")

local function AcquirePaste(pasteURL, filePath)
    local wFF = io.open(filePath, 'w')
    local result, response = pcall(internet.request, pasteURL)
	   if result then
		  print("success")
		  for chunk in response do 
			wFF:write(chunk)
		  end
		wFF:close()
	end
end

if filesystem.exists("/usr/programs/TMain.lua") and filesystem.exists("/usr/programs/TIdent.lua") and filesystem.exists("/usr/programs/TFiCo.lua") then
    local reason1, junk1 = bagel.glutenous("/usr/programs/TMain.lua", 199744)
    local reason2, junk2 = bagel.glutenous("/usr/programs/TFiCo.lua", 261169)
    local reason3, junk3 = bagel.glutenous("/usr/programs/TIdent.lua", 259827)
    if reason1 == true and reason2 == true and reason3 == true then
        bagel.unToastFile("/usr/programs/TMain.lua", "/tmp/TMain.lua")
        bagel.unToastFile("/usr/programs/TIdent.lua", "/tmp/TIdent.lua")
        bagel.unToastFile("/usr/programs/TFiCo.lua", "/tmp/TFiCo.lua")
        shell.execute("/tmp/TFiCo.lua")
        shell.execute("/tmp/TIdent.lua")
        shell.execute("/tmp/TMain.lua")
    else
        print("An altered copy of TACEATS2 is present on this system. Preventing execution to secure against malicious code injection. Please report to whomever you got this program from, and to Gavle on irc.esper.net")
        print("Have a good day!")
    end
else
    print("TACEATS files missing, attempting download now")
    if component.isAvailable("internet") == true then
        AcquirePaste("https://raw.githubusercontent.com/MajorGeneralRelativity/OC-Programs/master/Programs/TACEATS2%20-%20Main.lua", "/usr/programs/TMain.lua")
        AcquirePaste("https://raw.githubusercontent.com/MajorGeneralRelativity/OC-Programs/master/Programs/TACEATS2%20-%20Target%20Identification.lua", "/usr/programs/TIdent.lua")
        AcquirePaste("https://raw.githubusercontent.com/MajorGeneralRelativity/OC-Programs/master/Programs/TACEATS2%20-%20FireControl.lua", "/usr/programs/TFiCo.lua")
    else
        print("Internet card not available, please insert one, and then re-run this program")
    end
end