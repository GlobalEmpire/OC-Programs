
local component = require("component")
local event = require("event")
local GERTi = require('GERTiClient')
local serial = require('serialization')

local clients = {}
local socket = {}

local ip = GERTi.getAddress()

local function newClient(eventName, originAddress, connectionID)
 -- 	print("Received an incoming connection from computer: "..originAddress.." with connectionID: "..connectionID)
  	local socket = GERTi.openSocket(originAddress, true, connectionID)
  	clients[originAddress] = socket
  	--print(dump(clients[originAddress]))
end

local function onMessage(eventName, originAddress, connectionID)
	--For debug
  	--print("Received and incoming data packet from computer: "..originAddress.." for connectionID: "..connectionID)
  	local sData = clients[originAddress]:read()
  	local data = serial.unserialize(sData[1])

  	local nickname = data[1]
  	local message = data[2]
  	local information = data[3]


	if information == "newMessage" then
		print(os.date("[%H:%M:%S] ") .. nickname .. ": " .. message)

	  --Go through all clients and send the message there way!
	  	for x,v in pairs(clients) do
			clients[x]:write(serial.serialize({nickname, message}))
	  	end
	elseif information == "disconnect" then
		for x,v in pairs(clients) do
			if(x == originAddress) then
			  	table.remove(clients, x)
			end
			clients[x]:write(serial.serialize({"[+] " .. nickname, "Has left the server."}))
		end
		print(os.date("[%H:%M:%S] ") .. nickname .. " Left the server (Disconnected)")
	elseif information == "newUser" then
		print(os.date("[%H:%M:%S] ") .. nickname .. " has joined the server (" .. originAddress .. ")")

	  	for x,v in pairs(clients) do
			clients[x]:write(serial.serialize({"[+] " .. nickname, "Has joined the server."}))
	  	end
	else
		print(os.date("[%H:%M:%S] ") .. " An error occurred, information was nil")
	end
end

--Useful for debugging tables
-- function dump(o)
--    if type(o) == 'table' then
--       local s = '{ '
--       for k,v in pairs(o) do
--          if type(k) ~= 'number' then k = '"'..k..'"' end
--          s = s .. '['..k..'] = ' .. dump(v) .. ','
--       end
--       return s .. '} '
--    else
--       return tostring(o)
--    end
-- end

event.listen("GERTConnectionID", newClient)
event.listen("GERTData", onMessage)
print("Listening on IP: " .. GERTi.getAddress())



while true do
  local id, _, x, y = event.pullMultiple("touch", "interrupted")
  if id == "interrupted" then
    print("soft interrupt, closing")
    event.ignore("GERTConnectionID", newClient)
    event.ignore("GERTData", onMessage)
    break
  end
end
