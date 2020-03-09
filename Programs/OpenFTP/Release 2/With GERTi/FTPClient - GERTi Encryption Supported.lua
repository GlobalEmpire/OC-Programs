local Compatibility = "2.0"
local component = require("component")
local event = require("event")
local term = require("term")
local m = component.modem
local GERTi = require("GERTiClient")
term.clear()
local DC = component.data
if DC.generateKeyPair == nil then print("This service requires a T3 data card to be installed. There is no T3 data card detected by this program. Please ensure that you have a ///T3/// card installed.") os.exit() end
print("Please enter Server GERTi Address: ")
local FTPaddress = tonumber(io.read())
print("This computer's GERTi address is: " .. GERTi.getAddress())
GERTi.send(FTPaddress, "GetVersion")
local _, _, _, ServerVersion = event.pull("GERTData")
if ServerVersion ~= Compatibility then 
	print("Selected Server does not meet the compatibility requirements of this client program version. Your client is at version ", Compatibility, " while the server is at version ", ServerVersion, ". Please Update either your program or the server. Report any bugs and/or errors that may have forced you to downgrade to lower versions.") 
	print("You can override the compatibility check, however it could cause problems. We do not bug-fix issues between incompatible clients, unless it also effects same-version clients. We will re-organise the compatibility scheme once we have implemented all the features we want in the base program. [Y/N]: ")
	local response = tostring(io.read())
	if response == "Y" then 
		print("Overriding")
	else
		print("Exiting")
		os.exit()
	end
end

local function WaitForResponse(PID)
	local tPID = 0
	while tPID ~= PID do
		_, _, tPID = event.pull("GERTData")
	end
	return
end

local function batchSocket3(var1, var2, var3, socket)
	socket:write(var1)
	os.sleep(0.1)
	socket:write(var2)
	os.sleep(0.1)
	socket:write(var3)
	os.sleep(0.1)
end

local function FTPCSend(Path, name)
	assert(type(Path) == "string", "File Path must be the absolute path of the file to send given as a string")
	assert(type(name) == "string" or type(name) == "number", "The name that the file will be stored under partially must be either a string or a number")
	local FTPsocket = GERTi.openSocket(FTPaddress, true, 98)
	local CID = 0
	while CID ~= 98 do
		_, _, CID = event.pull("GERTConnectionID")
	end
	local PuKey, PrKey = DC.generateKeyPair()
	batchSocket3("SendNKey", PuKey.serialize(), 0, FTPsocket)
	WaitForResponse(98)
	local SvrKey = FTPsocket:read()
	SvrKey = SvrKey[1]
	local SvrKey = DC.deserializeKey(SvrKey, "ec-public")
	local EncryptionKey = DC.ecdh(PrKey, SvrKey)
	local HashKey, IVC = DC.md5(EncryptionKey), 0
	batchSocket3("S.FileStart", DC.encrypt(tostring(name), HashKey, DC.md5(tostring(IVC))), GERTi.getAddress(), FTPsocket)
	WaitForResponse(98)	
	local state = FTPsocket:read()
	if state[1] == "StartConfirm" then
		print("Sending")
		local file = io.open(Path)
		IVC = IVC + 1
		local UnP = file:read(4096)
		local P = DC.encrypt(UnP, HashKey, DC.md5(tostring(IVC)))
		batchSocket3("S.FileContinue", P, GERTi.getAddress(), FTPsocket)
		WaitForResponse(98)
		local state = FTPsocket:read()
		while string.len(UnP) == 4096 do
			print("Sending")
			IVC = IVC + 1
			UnP = file:read(4096)
			P = DC.encrypt(UnP, HashKey, DC.md5(tostring(IVC)))
			batchSocket3("S.FileContinue", P, GERTi.getAddress(), FTPsocket)			
			WaitForResponse(98)
			FTPsocket:read()
		end
		print("Finishing")
		batchSocket3("S.FileFin", 0, GERTi.getAddress(), FTPsocket) 
		WaitForResponse(98)
		file:close()
		IVC = IVC + 1
		local ID = FTPsocket:read()
		ID = DC.decrypt(ID[1], HashKey, DC.md5(tostring(IVC)))
		FTPsocket:close()
		return true, ID
	else
		FTPsocket:close()
		return false, "FTP Error - Incorrect State Response"
	end
end

local function FTPCReceive(FileIdName, ResultPath)
	assert(type(FileIdName)=="string", "The identifier for the file must be a string; usually in the format <name.number>.")
	if ResultPath == nil then file = io.open(tostring("/home/" .. FileIdName), "w")
	else file = io.open(tostring(ResultPath), "w") end
	local FTPsocket = GERTi.openSocket(FTPaddress, true, 98)
	local CID = 0
	while CID ~= 98 do
		_, _, CID = event.pull("GERTConnectionID")
	end
	local PuKey, PrKey = DC.generateKeyPair()
	batchSocket3("SendNKey", PuKey.serialize(), 0, FTPsocket)
	WaitForResponse(98)
	local SvrKey = FTPsocket:read()
	SvrKey = SvrKey[1]
	local SvrKey = DC.deserializeKey(SvrKey, "ec-public")
	local EncryptionKey = DC.ecdh(PrKey, SvrKey)
	local HashKey, IVC = DC.md5(EncryptionKey), 0
	batchSocket3("R.FileStart", DC.encrypt(FileIdName, HashKey, DC.md5(tostring(IVC))), GERTi.getAddress(), FTPsocket)
	WaitForResponse(98)
	os.sleep(0.1)
	local State = FTPsocket:read()
	if State[1] == "R.Ready" then
		print("Stream Opening")
		batchSocket3("R.FileCont", 0, GERTi.getAddress(), FTPsocket)
		WaitForResponse(98)
		os.sleep(0.4)
		local data = FTPsocket:read()
		local State = data[1]
		local FTP = data[2]
		print("Stream Starting")
		while State ~= "R.Fin" do
			IVC = IVC + 1
			file:write(DC.decrypt(FTP, HashKey, DC.md5(tostring(IVC))))
			print("Written")
			WaitForResponse(98)
			os.sleep(0.4)
			data = FTPsocket:read()
			State = data[1]
			FTP = data[2]
		end
		file:close()
		FTPsocket:close()
		return true
	else FTPsocket:close() file:close() return false, "FTP Error - Incorrect State Response"  end
end
while true do
print("Server Found - Address is " .. FTPaddress)
print("Type 'Send' to send a file to the server or 'Request' to request a file from the Server")
print("Please enter Mode:")
local OPMode = io.read()

if OPMode == "Send" then
	print("Please specify the absolute path of the file starting with '/'")
	Path = tostring(io.read())
	print("Please enter the name which will be given to the file when transfered: ")
	local name = tostring(io.read())
	print("The file will now be sent to the Server. You will be sent an identifier for the program when the transfer is completed which you may use to request your file from the server from any connected computer.")
	local state, ID = FTPCSend(Path, name)
	if state == true then print("File successfully saved onto server. Request it with the ID " .. ID)
	else print("Something went wrong; error string: ", ID)
	end
elseif OPMode == "Request" then
	print("Enter the file's identification string that was given upon completion of the File Transfer to the server.")
	local FileIdCode = tostring(io.read())
	local err, code = FTPCReceive(FileIdCode)
	if err == false then print("Something went wrong; error string: ", code) else print("Your file has been successfully downloaded to /home/" .. FileIdCode)
	end 
	os.exit()
else 
	print("You have not entered a valid mode of operation. Please try again. To exit; press 'ctrl+alt+c'")
	os.sleep(5)
	term.clear()
end
end
