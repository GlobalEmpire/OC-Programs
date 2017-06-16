-- Require our components and libraries
local component = require("component")
local GERTi = require("GERTiClient")
local serialize = require("serialization")
local reactor = component.br_reactor

-- Open socket to destination
local socket = GERTi.openSocket("61d98b9e-a7fb-4695-a276-0a119f159763")
-- The main loop
while true do
-- Amount of fuel in reactor
local fuelAmount = math.ceil(reactor.getFuelAmount())
print("Amount of fuel: "..fuelAmount.." mB")
-- Casing Temperature
local caseTemp = math.ceil(reactor.getCasingTemperature())
print("Casing temperature: "..caseTemp.. " C")
-- Core Temperature (Fuel)
local coreTemp = math.ceil(reactor.getFuelTemperature())
print("Core temperature: "..coreTemp.. " C")
-- Amount of water
local curWater = math.ceil(reactor.getCoolantAmount())
local maxWater = math.ceil(reactor.getCoolantAmountMax())
print("Water: "..curWater.." / "..maxWater.." mB")
-- Amount of steam
local curSteam = math.ceil(reactor.getHotFluidAmount())
local maxSteam = math.ceil(reactor.getHotFluidAmountMax())
print("Steam: "..curSteam.." / "..maxSteam.." mB")
-- Amount of hot fluid output
local hotFluid = reactor.getHotFluidProducedLastTick()
print("Hot Fluid Output: "..hotFluid.." mB/t")
-- Fuel burn rate
local burnRate = reactor.getFuelConsumedLastTick()
print("Fuel Burn Rate: "..burnRate.." mB/t")

-- Wrap all the variables into a table
local info = {}
info["fuelAmount"] = fuelAmount
info["caseTemp"] = caseTemp
info["coreTemp"] = coreTemp
info["curWater"] = curWater
info["maxWater"] = maxWater
info["curSteam"] = curSteam
info["maxSteam"] = maxSteam
info["hotFluid"] = hotFluid
info["burnRate"] = burnRate

-- serialize table and send it off

socket:write(serialize.serialize(info))

os.sleep(1)
end
