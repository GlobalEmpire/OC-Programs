local Compatibility = "2.0"
local event = require("event")
local component = require("component")
local term = require("term")
local GERTi = require("GERTiClient")
local DC = component.data
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
local KeyList = {}
local IVCList = {}
local HashList = {}

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
		filename = math.random(1000000, 9999999)
		if HashList[Address] ~= nil then 
			Content = DC.decrypt(Content, HashList[Address], DC.md5(tostring(IVCList[Address]))) 
		end
		path[Address] = tostring(filename .. "." .. Content)
		fileReceive[Address] = io.open(tostring("/home/" .. path[Address]), "w")
		socket[Address]:write("StartConfirm")
	elseif Type == "SendNKey" then
		KeyList[Address] = {}
		IVCList[Address] = 0
		local a, b = DC.generateKeyPair()
		KeyList[Address]["PuKey"], KeyList[Address]["PrKey"] = a, b
		local DeKey = DC.deserializeKey(Content, "ec-public")
		HashList[Address] = DC.md5(DC.ecdh(KeyList[Address]["PrKey"], DeKey))
		socket[Address]:write(KeyList[Address]["PuKey"].serialize())
	elseif Type == "S.FileContinue" then
		if HashList[Address] ~= nil then 
			IVCList[Address] = IVCList[Address] + 1
			Content = DC.decrypt(Content, HashList[Address], DC.md5(tostring(IVCList[Address]))) 
		end
		fileReceive[Address]:write(Content)
		socket[Address]:write("WriteContinue")
	elseif Type == "S.FileFin" then
		fileReceive[Address]:close()
		if HashList[Address] ~= nil then 
			IVCList[Address] = IVCList[Address] + 1
			path[Address] = DC.encrypt(path[Address], HashList[Address], DC.md5(tostring(IVCList[Address]))) 
			KeyList[Address] = nil
			HashList[Address] = nil
			IVCList[Address] = nil
		end
		socket[Address]:write(path[Address]) --- encrypt
	elseif Type == "FTPErrorR" then
		fileReceive[Address]:close()
		KeyList[Address] = nil
		HashList[Address] = nil
		IVCList[Address] = nil
	elseif Type == "R.FileStart" then 
		if HashList[Address] ~= nil then
			Content = DC.decrypt(Content, HashList[Address], DC.md5(tostring(IVCList[Address])))
		end
		fileSend[Address] = io.open(tostring("/home/" .. Content))
		socket[Address]:write("R.Ready")
	elseif Type == "R.FileCont" then
		local EncryptedContent = nil
		P[Address] = fileSend[Address]:read(4096)
		if HashList[Address] ~= nil then
			IVCList[Address] = IVCList[Address] + 1
			EncryptedContent = DC.encrypt(P[Address], HashList[Address], DC.md5(tostring(IVCList[Address])))
		else
			EncryptedContent = P[Address]
		end
		socket[Address]:write("R.FTPCont")
		socket[Address]:write(EncryptedContent)
		os.sleep(1)
		while string.len(P[Address]) == 4096 do
			P[Address] = fileSend[Address]:read(4096)
			if HashList[Address] ~= nil then
				IVCList[Address] = IVCList[Address] + 1
				EncryptedContent = DC.encrypt(P[Address], HashList[Address], DC.md5(tostring(IVCList[Address])))
			else
				EncryptedContent = P[Address]
			end			
			socket[Address]:write("R.FTPCont")
			socket[Address]:write(EncryptedContent)
			os.sleep(1)
		end
		socket[Address]:write("R.Fin")
		socket[Address]:write(0)
		fileSend[Address]:close()
		IVCList[Address] = nil
		HashList[Address] = nil
	end
end

local function DataGroup(_, Address, CID, data)
	if CID == -1 then
		if data == "GetVersion" then
			GERTi.send(Address, Compatibility)
		end
	elseif CID == 98 then
		local buffer = socket[Address]:read()
		if messageBuffer1[Address] == nil then 
			messageBuffer1[Address] = buffer[1]
		elseif messageBuffer2[Address] == nil then 
			messageBuffer2[Address] = buffer[1]
		else messageBuffer3[Address] = buffer[1]
			Receive(Address, messageBuffer1[Address], messageBuffer2[Address], messageBuffer3[Address])
			messageBuffer1[Address], messageBuffer2[Address], messageBuffer3[Address] = nil, nil, nil
		end
	end
end
event.listen("GERTData", DataGroup)

print("The server is initialised. The server's address is the following:")
print(GERTi.getAddress())
os.exit()