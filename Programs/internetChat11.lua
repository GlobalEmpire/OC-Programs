local term = require("term")
local component = require("component")
local event = require("event")
local m = component.modem
local str="0"

-- determine if modem is wireless
if m.isWireless() then
term.write("Modem initialized for network communications \n")
m.setStrength(400)
else
term.write("Modem is not wireless, messages may not work as intended \n")
end

-- determine what channel people want to listen on
term.write("What channel do you want to chat on? \n")
local channel=io.read()
while tonumber(channel) < 1 or tonumber(channel) > 10 do
term.write("Channel must be 1 through 10 \n")
channel=io.read()
end
m.open(tonumber(channel))
-- begin event
event.listen("modem_message", function(_,_,from,port,_,message)

-- decipher, and print
local cipher = "1234567890qwertyuiopasdfghjklzxcvbnm"
local function decrypt(str)
        str = str:gsub("%d",function(a) return string.char(cipher:find(a,nil,true)+47) end)
        str = str:gsub("%l",function(a) return string.char(cipher:find(a,nil,true)+86) end)
        return str
end
if string.sub(tostring(message), 1, 9)=="encrypted" then
str=tostring(message)
message=decrypt(str)
local strlngth=string.len(tostring(message))
message=string.sub(tostring(message), 10, strlngth)
print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))

else
print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
end
end)

-- send a message
term.write("is this going to be encrypted? \n")

-- register cipher
local cipher = "1234567890qwertyuiopasdfghjklzxcvbnm"

local function encrypt(str)
  str = str:gsub("%d",function(a) a=a:byte()-47 return cipher:sub(a,a) end)
  str = str:gsub("%l",function(a) a=a:byte()-86 return cipher:sub(a,a) end)
  return str
end
-- determine whether encryption should be used
local useEC=io.read()
if useEC=="yes" then
  term.write("Encryption activated \n")
end
while true do
  str=io.read()
  if tostring(str)=="endme" then
    os.exit()
  end
  if useEC=="yes" then
    str=encrypt(str)
    str="encrypted" .. " " .. str
  end
-- send message
m.broadcast(tonumber(channel), str)
end