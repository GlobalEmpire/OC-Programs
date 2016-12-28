local internet = require("internet")
local filesystem = require("filesystem")
local shell = require("shell")

if filesystem.exists("/usr/programs/TACEATSmain.lua") and filesystem.exists("/usr/programs/TIdent.lua") and filesystem.exists("/usr/programs/TFiCo.lua") then
    if bagel.glutenous("/usr/programs/TACEATSmain.lua", 203352) == true and bagel.glutenous("/usr/programs/TFiCo.lua", 261943) == true and bagel.glutenous("/usr/programs/TIdent.lua", 274559) then
        shell.execute("/usr/programs/TFiCo.lua")
        shell.execute("/usr/programs/TIdent.lua")
        shell.execute("/usr/programs/TACEATSmain.lua")
    else
        print("Altered copy of TACEATS2 is present on this system. Preventing execution to secure against malicious code injection. Please report to whomever you got this program from, and to Gavle on irc.esper.net")
        print("Have a good day!")
    end
else
    print("TACEATS files missing, attempting download now")
    if component.isAvailable("internet") == true then
        --stuff
    else
        print("Internet card not available, please insert one, and then re-run this program")
    end
end