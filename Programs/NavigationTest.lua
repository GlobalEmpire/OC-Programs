local component = require("component")
local nav = component.navigation
local r = require("robot")
local sides = require("sides")
local m = component.modem
local event = require("event")
local newX, newZ=0,0

local x,y,z=nav.getPosition()
local facing=nav.getFacing()
print(nav.getPosition())
print(nav.getFacing())
print(x..y..z)

m.open(1)
event.listen("modem_message", function(_,_,_,_,_,message)
print(message)
local index =string.find(message, "g")
if tonumber(index)>=1 then
local index = tonumber(index)-1
local newX = string.sub(message, 0, tonumber(index))
local index = tonumber(index)+2
local newZ = string.sub(message, tonumber(index))
print(newX)
print(newZ)
if facing ~=5 then
while facing ~=5 do
r.turnLeft()
facing=nav.getFacing()
end
end

while tonumber(newX)~=x do
x,y,z=nav.getPosition()
print(x..y..z)
if tonumber(newX) > x then
r.forward()
elseif tonumber(newX) < x then
r.back()
end
end

while tonumber(newZ) ~= z do
x,y,z=nav.getPosition()
print(x..y..z)
if tonumber(newZ) > z then
r.turnRight()
r.forward()
r.turnLeft()
elseif tonumber(newZ) < z then
r.turnLeft()
r.forward()
r.turnRight()
end
end

end
--end the function
m.broadcast(1, "reached")
end)

print(nav.getPosition())