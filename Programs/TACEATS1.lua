local component = require("component")
local radar = component.radar
local chat = component.chat_box
local whitelist = {}
local pTable = {}
local whitelistIndex = 1
local pTableIndex = 1
local invader = true

local function compareTable()
    while whitelistIndex <= #whitelist do
        if pTable[pTableIndex]["name"] == whitelist[whitelistIndex] then
            invader=false
            print("Whitelisted person recognized")
            break
        else
            whitelistIndex=whitelistIndex+1
        end
    end
end

local f=io.open("/usr/programs/names.txt", "r")
local entry = f:read()
local readIndex = 1
while entry ~= nil do
    whitelist[readIndex] = entry
    entry = f:read()
end
f:close()

while true do
    whitelistIndex=1
    pTableIndex=1
    os.sleep(2)
    pTable = radar.getPlayers()
    while pTableIndex <= #pTable do
        compareTable()
        if invader == false then
            break
        end
        pTableIndex=pTableIndex+1
    end
    if invader == true then
            chat.say("Vacate the area")
    end
   
end

