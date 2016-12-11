local term = require("term")
local component = require("component")
local m = component.modem
local event = require("event")
m.open(1)

-- do the eventy stuffy
function unknownEvent()
  -- do nothing if the event wasn't relevant
end

--tables
local myEventHandlers = setmetatable({}, { __index = function() return unknownEvent end })

--event processor
function myEventHandlers.modem_message(_,_,_,_,_,message)
if message=="reached" then
running=false
end
end

-- event handler
function handleEvent(eventID, ...)
  if (eventID) then -- can be nil if no event was pulled for some time
    myEventHandlers[eventID](...) -- call the appropriate event handler with all remaining arguments
  end
end


event.listen("motion", function(_, _, x, y, z, dave)
local running=true
print(dave.." detected at:"..x..y..z)
x=math.ceil(x)
y=math.ceil(y)
z=math.ceil(z)
x=114.5+x
z=-134.5+z
local sendStr=x.."g"..z
m.broadcast(1,sendStr)
print(x.." "..y.." "..z)
print(sendStr)

while running do
  handleEvent(event.pull())
end
end)