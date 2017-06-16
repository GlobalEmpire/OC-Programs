local component = require("component")
local GERTi = require("GERTiClient")
local serialize = require("serialization")
local term = require("term")

local socket = GERTi.openSocket("4a64d9e9-d87d-4f00-918f-cfe01e1f8b22")

while true do
local info = {}

info = socket:read()
if info[1] ~= nil then
info = serialize.unserialize(info[1])

term.clear()
term.write("Amount of fuel: "..info["fuelAmount"].." mB\n")
term.write("Casing temperature: "..info["caseTemp"].. " C\n")
term.write("Core temperature: "..info["coreTemp"].. " C\n")
term.write("Water: "..info["curWater"].." / "..info["maxWater"].." mB\n")
term.write("Steam: "..info["curSteam"].." / "..info["maxSteam"].." mB\n")
term.write("Hot Fluid Output: "..info["hotFluid"].." mB/t\n")
term.write("Fuel Burn Rate: "..info["burnRate"].." mB/t\n")
end

os.sleep(1)
end
