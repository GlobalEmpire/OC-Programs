local event = require("event")
local component = require("component")
local term = require("term")
local m = component.modem
m.open(98)
m.open(99)
term.clear()
print("FTP SERVER STARTING")
fileReceive = {}
fileSend = {}

local function Receive(_, A, AS, P, _, Type, Content, Spare)
	if P == 98 then
		m.send(Content, 98, m.address)
		--print(Content .. " Requested FTP address; Responding")
	elseif P == 99 then
		if Type == "S.FileStart" then 
			ReceiverAddress = Spare
			filename = math.random(1000000, 9999999)
			path = tostring(filename .. "." .. Content)
		--	print("Creating file from " .. ReceiverAddress .. " With Address " .. path) 
			fileReceive[ReceiverAddress] = io.open(tostring("/home/" .. path), "w")
			m.send(ReceiverAddress, 99, "StartConfirm")
		elseif Type == "S.FileContinue" then
			ReceiverAddress = Spare
			fileReceive[ReceiverAddress]:write(Content)
		--	print("Written")
			m.send(ReceiverAddress, 99, "WriteContinue")
		elseif Type == "S.FileFin" then
			ReceiverAddress = Spare
			fileReceive[ReceiverAddress]:close()
		--	print("Complete")
			m.send(ReceiverAddress, 99, path)
		elseif Type == "FTPErrorR" then
			fileReceive[Spare]:close()
		elseif Type == "R.FileStart" then 
		--	print("Start Stream")
			SenderAddress = Spare
			fileSend[SenderAddress] = io.open(tostring("/home/" .. Content))
			m.send(SenderAddress, 99, "R.Ready")
		elseif Type == "R.FileCont" then
			SenderAddress = Spare
		--	print("Continue Stream")
			P = fileSend[SenderAddress]:read(4096)
			m.send(SenderAddress, 99, "R.FTPCont", P)
			os.sleep(1.5)
			while string.len(P) == 4096 do
				P = fileSend[SenderAddress]:read(4096)
				m.send(SenderAddress, 99, "R.FTPCont", P)
		--		print("Continue Stream")
				os.sleep(1.5)
			end
			m.send(SenderAddress, 99, "R.Fin", 0)
			fileSend[SenderAddress]:close()
		--	print("Stream Finished")
		end
	end
end
event.listen("modem_message", Receive)
print("Server Initialised")
while true do
local usrstate = io.read()
if usrstate == "hide" or "Hide" then os.exit() end
end