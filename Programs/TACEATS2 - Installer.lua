local internet = require("internet")
local filesystem = require("filesystem")
local shell = require("shell")
local component = require("component")

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

if filesystem.exists("/lib/bagel.lua") == true then
    bagel = require("bagel")
else
    print("Bagel.lua is not found, attempting to continue.")
    if component.isAvailable("internet") == true then
        AcquirePaste("https://raw.githubusercontent.com/MajorGeneralRelativity/OC-Programs/master/Libraries/bagel.lua", "/lib/bagel.lua")
        print("Please reboot and re-run this program.")
        os.exit()
    else
        print("Internet not available or unkown error; cannot continue.")
    end
end

if filesystem.exists("/usr/programs/TMain.lua") and filesystem.exists("/usr/programs/TIdent.lua") and filesystem.exists("/usr/programs/TFiCo.lua") then
    local reason1, junk1 = bagel.glutenous("/usr/programs/TMain.lua", 84707)
    local reason2, junk2 = bagel.glutenous("/usr/programs/TFiCo.lua", 114519)
    local reason3, junk3 = bagel.glutenous("/usr/programs/TIdent.lua", 109532)
    if reason1 == true and reason2 == true and reason3 == true then
        shell.execute("/usr/programs/TFiCo.lua")
        shell.execute("/usr/programs/TIdent.lua")
        shell.execute("/usr/programs/TMain.lua")
    else
        print("An altered copy of TACEATS2 is present on this system. Preventing execution to secure against malicious code injection. Please report to whomever you got this program from, and to MajGenRelativity or Gavle on irc.esper.net")
        print("Have a good day!")
    end
else
    print("TACEATS files missing, attempting download now")
    if component.isAvailable("internet") == true then
        AcquirePaste("https://raw.githubusercontent.com/MajorGeneralRelativity/OC-Programs/master/Programs/TMain.lua", "/usr/programs/TMain.lua")
        AcquirePaste("https://raw.githubusercontent.com/MajorGeneralRelativity/OC-Programs/master/Programs/TIdent.lua", "/usr/programs/TIdent.lua")
        AcquirePaste("https://raw.githubusercontent.com/MajorGeneralRelativity/OC-Programs/master/Programs/TFiCo.lua", "/usr/programs/TFiCo.lua")
    else
        print("Internet card not available, please insert one, and then re-run this program.")
    end
end