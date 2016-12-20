local component = require("component")
local radar = component.radar
local chat = component.chat_box
local turret = component.os_energyturret
local whitelist = {}
local pTable = {}
local targets = {}
local whitelistIndex = 1
local pTableIndex = 1
local targetIndex = 1
local invader = false

local targetDistance = 1
local targetX = 1
local targetY = 1
local targetZ = 1
local XAngle = 1
local YAngle = 1
local angleOffset = 0
	
local function computeAngle()
    -- opposite is X, adjacent is Z
    -- because trig
	if targetZ < 0 then
		if targetX < 0 then
			angleOffset = 270
			targetX = -targetX
			targetZ = -targetZ
		else
			angleOffset = 0
			targetZ = -targetZ
		end
	else
		if targetX < 0 then
			angleOffset = 180
			targetX = -targetX
		else
			angleOffset = 90
		end
	end
	XAngle = math.atan((targetX/targetZ))
	YAngle = math.sin(targetY/targetDistance)
    if angleOffset == 90 or angleOffset == 270 then
	   turret.moveTo(((90-math.deg(XAngle))+angleOffset), math.deg(YAngle))
    else
        turret.moveTo((math.deg(XAngle)+angleOffset), math.deg(YAngle))
    end
end

local function compareTable()
	local tempInv = true
    while whitelistIndex <= #whitelist do
        if pTable[pTableIndex]["name"] == whitelist[whitelistIndex] then
            tempInv = false
            print("Whitelisted person recognized")
            whitelistIndex=whitelistIndex+1
            break
        else
            whitelistIndex=whitelistIndex+1
        end
    end
	if tempInv == true then
		targets[targetIndex]=pTable[pTableIndex]
		targetIndex = targetIndex+1
	end
end

local f=io.open("/usr/programs/names.txt", "r")
local entry = f:read()
local readIndex = 1
while entry ~= nil do
    whitelist[readIndex] = entry
    entry = f:read()
    readIndex = readIndex+1
end
f:close()

while true do
	targets = {}
    whitelistIndex = 1
    pTableIndex = 1
    targetIndex = 1
    os.sleep(2)
    pTable = radar.getPlayers()
    while pTableIndex <= #pTable do
        compareTable()
        pTableIndex=pTableIndex+1
    end
    if targets[1] ~= nil then
        chat.say("Vacate the area")
        targetIndex = 1
	   while targetIndex <= #targets do
            print("target is"..targets[targetIndex]["name"])
            targetDistance = targets[targetIndex]["distance"]
            targetZ = targets[targetIndex]["z"]
            targetY = targets[targetIndex]["y"]-1
            targetX = targets[targetIndex]["x"]
            computeAngle()
            turret.fire()
            targetIndex = targetIndex+1
            if targets[targetIndex] ~= nil then
                os.sleep(1.1)
            end
	   end
    end
   
end