local Compatibility = "1.0"
local event = require("event")
local component = require("component")
local term = require("term")
local m = component.modem
local GERTi = require("GERTiClient")
m.open(98)
term.clear()
print("FTP SERVER STARTING")
local fileReceive = {}
local fileSend = {}
local messageBuffer1 = {}
local messageBuffer2 = {}
local messageBuffer3 = {}
local path = {}
local P = {}
local socket = {}

local function Register(_, Address, CID)
	if CID == 98 then 
		socket[Address] = GERTi.openSocket(Address, true, 98)
	end
end
event.listen("GERTConnectionID", Register)

local function CloseSocket(_, Address, _, CID)
	if CID == 98 then
		socket[Address]:close()
	end
end
event.listen("GERTConnectionClose", CloseSocket)



local function Receive(Address, Type, Content, Spare)
	if Type == "S.FileStart" then 
		local ReceiverAddress = Address
		filename = math.random(1000000, 9999999)
		path[ReceiverAddress] = tostring(filename .. "." .. Content)
		fileReceive[ReceiverAddress] = io.open(tostring("/home/" .. path[ReceiverAddress]), "w")
		socket[ReceiverAddress]:write("StartConfirm")
	elseif Type == "S.FileContinue" then
		local ReceiverAddress = Address
		fileReceive[ReceiverAddress]:write(Content)
		socket[ReceiverAddress]:write("WriteContinue")
	elseif Type == "S.FileFin" then
		local ReceiverAddress = Address
		fileReceive[ReceiverAddress]:close()
		socket[ReceiverAddress]:write(path[ReceiverAddress])
	elseif Type == "FTPErrorR" then
		fileReceive[Address]:close()
	elseif Type == "R.FileStart" then 
		local SenderAddress = Address
		fileSend[SenderAddress] = io.open(tostring("/home/" .. Content))
		socket[SenderAddress]:write("R.Ready")
	elseif Type == "R.FileCont" then
		local SenderAddress = Address
		P[SenderAddress] = fileSend[SenderAddress]:read(4096)
		socket[SenderAddress]:write("R.FTPCont")
		socket[SenderAddress]:write(P[SenderAddress])
		os.sleep(1)
		while string.len(P[SenderAddress]) == 4096 do
			P[SenderAddress] = fileSend[SenderAddress]:read(4096)
			socket[SenderAddress]:write("R.FTPCont")
			socket[SenderAddress]:write(P[SenderAddress])
			os.sleep(1)
		end
		socket[SenderAddress]:write("R.Fin")
		socket[SenderAddress]:write(0)
		fileSend[SenderAddress]:close()
	end
end

local function DataGroup(_, Address, CID, data)
	if CID == -1 then
		if data == "GetVersion" then
			GERTi.send(Address, Compatibility)
		end
	elseif CID == 98 then
		local buffer = socket[Address]:read()
		if messageBuffer1[Address] == nil then messageBuffer1[Address] = buffer[1]
		elseif messageBuffer2[Address] == nil then messageBuffer2[Address] = buffer[1]
		else messageBuffer3[Address] = buffer[1]
		Receive(Address, messageBuffer1[Address], messageBuffer2[Address], messageBuffer3[Address])
		messageBuffer1[Address], messageBuffer2[Address], messageBuffer3[Address] = nil, nil, nil
		end
	end
end
event.listen("GERTData", DataGroup)

print("Server Initialised")
while true do
local usrstate = io.read()
if usrstate == "hide" or "Hide" then os.exit() elseif usrstate == "ADDRESS" then print(GERTi.getAddress()) end

end