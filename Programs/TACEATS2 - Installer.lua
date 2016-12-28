local internet = require("internet")
local filesystem = require("filesystem")

if filesystem.exists("/usr/programs/TACEATSmain.lua") and filesystem.exists("/usr/programs/TIdent.lua") and filesystem.exists("/usr/programs/TFiCo.lua") then
    local isSafe = bagel.glutenous("/usr/programs/TACEATSmain.lua", 107260)
