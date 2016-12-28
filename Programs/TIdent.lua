local event = require("event")
local computer = require("computer")
local serialize = require("serialization")

local whitelist = {}
local targets = {}
local pTable = {}
local targetIndex = 1
local whitelistIndex = 1
local pTableIndex = 1

-- read whitelist
local f=io.open("/usr/programs/names.txt", "r")
local entry = f:read()
local readIndex = 1
while entry ~= nil do
    whitelist[readIndex] = entry
    entry = f:read()
    readIndex = readIndex+1
end
f:close()
-- compare table
local function compareTable(_, players)
    pTable = {}
    targets = {}
    whitelistIndex = 1
    pTable = serialize.unserialize(players)
    pTableIndex = 1
    while pTableIndex <= #pTable do
        targetIndex = 1
        whitelistIndex = 1
        local tempInv = true
        while whitelistIndex <= #whitelist do
            if pTable[pTableIndex]["name"] == whitelist[whitelistIndex] then
                tempInv = false
                print("Whitelisted person recognized")
                break
            else
                whitelistIndex=whitelistIndex+1
            end
        end
        if tempInv == true then
            targets[targetIndex]=pTable[pTableIndex]
            targetIndex = targetIndex+1
        end
        pTableIndex = pTableIndex+1
    end
    computer.pushSignal("TSelected", serialize.serialize(targets))
end
event.listen("TIdent", compareTable)