-- Require our components and libraries
local component = require("component")
local event = require("event")
local GERTi = require("GERTiClient")
local serialize = require("serialization")
local reactor = component.br_reactor
local socket = {}|
-- Open socket to destination with automated destination selection to be clever
if tonumber(GERTi.getAddress()) == 0.1 then
	socket = GERTi.openSocket(0.2, false, 1)
else
	socket = GERTi.openSocket(0.1, false, 1)
end

local function sendInfo()
	local info = {}
	info["fuelAmount"] = math.ceil(reactor.getFuelAmount())
	info["fuelMax"] = reactor.getFuelAmountMax()
	info["caseTemp"] = math.ceil(reactor.getCasingTemperature())
	info["coreTemp"] = math.ceil(reactor.getFuelTemperature())
	info["burnRate"] = reactor.getFuelConsumedLastTick()
	info["wasteAmount"] = reactor.getWasteAmount()
	info["controlLevel"] = reactor.getControlRodsLevels()
	info["energyProduced"] = reactor.getEnergyProducedLastTick()
	info["energyStored"] = reactor.getEnergyStored()
	info["fuelReactivity"] = reactor.getFuelReactivity()
	socket:write(serialize.serialize(info))
end
event.timer(1, sendInfo, math.huge)