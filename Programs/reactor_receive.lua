local component = require("component")
local GERTi = require("GERTiClient")
local serialize = require("serialization")
local term = require("term")
local socket = {}
-- Open socket to destination with automated destination selection to be clever
if tonumber(GERTi.getAddress()) == 0.1 then
	socket = GERTi.openSocket(0.2, false, 1)
else
	socket = GERTi.openSocket(0.1, false, 1)
end

while true do
	local info = {}
	info = socket:read()
	if info[1] ~= nil then
		info = serialize.unserialize(info[1])
		term.clear()
		term.write("Amount of fuel: "..info["fuelAmount"].." mB\n")
		term.write("Maximum fuel: "..info["fuelMax"].." mB\n")
		term.write("Amount of waste is: "..info["wasteAmount"].." mB\n")
		term.write("Core temp is: "..info["coreTemp"].." C\n")
		term.write("Casing temperature: "..info["caseTemp"].. " C\n")
		term.write("Fuel Burn Rate: "..info["burnRate"].." mB/t\n")
		term.write("Fuel Reactivity: "..info["fuelReactivity"].."\n")
		term.write("Energy Production: "..info["energyProduced"].." RF/t\n")
		term.write("Energy Stored: "..info["energyStored"].." RF\n")
		for i = 0, #info["controlLevel"], 1 do
			term.write("Control Rod "..i.." at: "..info["controlLevel"][i].." insertion.\n")
		end	
	end
	os.sleep(1)
end
