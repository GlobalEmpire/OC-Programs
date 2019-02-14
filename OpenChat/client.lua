local component = require("component")
local event = require("event")
local GERTi = require('GERTiClient')
local serial = require('serialization')
local GUI = require('GUI')

local application = GUI.application()
local socket = {}

local lastY = 5

local connected = false
local nickname = ""

function connectToServer(ipAddress)
	socket = GERTi.openSocket(tonumber(ipAddress), true, 1)
	connected = true

	application:addChild(GUI.text(3, 4, 0xFFFFFF, "You are connected to: " .. ipAddress))
	-- Need to sleep so that the client can be added to the clients table on the server side otherwise the data below isn't parsed
	os.sleep(0.1)
	socket:write(serial.serialize({nickname, "", "newUser"}))
end

function parseMessage()
	local sData = socket:read()
	local data = serial.unserialize(sData[1])

	application:addChild(GUI.text(3, lastY+1, 0xFFFFFF, data[1] .. ": " .. data[2]))
	lastY = lastY + 1
	application:draw(true)
end


function initiateGUI()

	--Background Panel
	application:addChild(GUI.panel(1, 1, application.width, application.height, 0x262626))

	-- Exit Button
	local actionButtons = application:addChild(GUI.actionButtons(3, 2, true))

	actionButtons.close.onTouch = function()
		if(connected) then
			socket:write(serial.serialize({nickname, "", "disconnect"}))
			os.sleep(0.1)
			socket:close()
			event.ignore("GERTData", parseMessage)
		end
		os.execute("clear")
		os.exit()
	end
	--Nickname Input
	local nickInput = application:addChild(GUI.input((application.width - 20)/2, 5, 20, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", "Nickname..."))
	nickInput.onInputFinished = function()
		if(string.len(string.gsub(nickInput.text, "%s+", "")) > 3) then
			nickInput.hidden = true
			-- Set user nickname in a variable for easy access
			nickname = nickInput.text
			--IP Input
			local ipInput = application:addChild(GUI.input((application.width - 20)/2, 5, 20, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", "Server Address..."))
			ipInput.onInputFinished = function()
				if(string.len(string.gsub(ipInput.text, "%s+", "")) > 0) then
					connectToServer(ipInput.text)
					ipInput.hidden = true

					--Message Panel
					local messageInput = application:addChild(GUI.input((application.width - (application.width-4))/2, application.height, application.width - 2, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", "Message..."))

					messageInput.onInputFinished = function()
						if(string.len(string.gsub(messageInput.text, "%s+", "")) > 0) then
							-- Send the server our message
							socket:write(serial.serialize({nickname, messageInput.text, "newMessage"}))
							messageInput.text = ""
						end
					end
				end
			end
		else
			GUI.alert("Username needs to be 3 or more characters.")
		end
	end

	-- Draw GUI and Start it.
	application:draw(true)
	application:start()
end

event.listen("GERTData", parseMessage)
initiateGUI()