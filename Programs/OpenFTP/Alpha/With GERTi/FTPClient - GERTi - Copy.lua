local Compatibility = "1.0"
local component = require("component")
local event = require("event")
local term = require("term")
local m = component.modem
local GERTi = require("GERTiClient")
term.clear()
print("Please enter Server GERTi Address: ")
local FTPaddress = tonumber(io.read()) -- Get Address of FTP server
print("This computer's GERTi address is: " .. GERTi.getAddress())
GERTi.send(FTPaddress, "GetVersion")
local _, _, _, ServerVersion = event.pull("GERTData")
if ServerVersion ~= Compatibility then print("Selected Server does not meet the compatibility requirements of this client program version. Your client is at version ", Compatibility, " while the server is at version ", ServerVersion, ". Please Update either your program or the server. Report any bugs and/or errors that may have forced you to downgrade to lower versions.") os.exit() end

local function batchSocket3(var1, var2, var3, socket)
	socket:write(var1)
	os.sleep(0.1)
	socket:write(var2)
	os.sleep(0.1)
	socket:write(var3)
	os.sleep(0.1)
end

local function FTPCSend(Path, name) -- Send file function; (Absolute path of file, Name to save file under)
	assert(type(Path) == "string", "File Path must be the absolute path of the file to send given as a string")
	assert(type(name) == "string" or type(name) == "number", "The name that the file will be stored under partially must be either a string or a number")
	FTPsocket = GERTi.openSocket(FTPaddress, true, 98) -- Create communication socket with the FTP server
	os.sleep(1) -- Wait a bit
	FTPsocket:write("S.FileStart") -- Write state
	os.sleep(0.1)
	FTPsocket:write(name) -- write new file name
	os.sleep(0.1)
	FTPsocket:write(GERTi.getAddress()) -- write address (unused; vestigial code)
	::pull1::
	local _, _, Pid = event.pull("GERTData") -- Wait for response
	if Pid ~= 98 then goto pull1 end	
	local state = FTPsocket:read() -- state
	if state[1] == "StartConfirm" then -- Confirm server has correctly initialised the transfer
		print("Sending")
		local file = io.open(Path) -- Open File
		local P = file:read(4096) -- Read file
		FTPsocket:write("S.FileContinue") -- Write state
		FTPsocket:write(P) -- write data
		FTPsocket:write(GERTi.getAddress())	-- write address (unused vestigial code)
		::pull2::
		local _, _, Pid = event.pull("GERTData")
		if Pid ~= 98 then goto pull2 end
		local state = FTPsocket:read() -- state
		while string.len(P) == 4096 do -- send file until no file left to send
			print("Sending")
			P = file:read(4096)
			FTPsocket:write("S.FileContinue")
			os.sleep(0.1)
			FTPsocket:write(P)
			os.sleep(0.1)
			FTPsocket:write(GERTi.getAddress())
			::pull3::
			local _, _, Pid = event.pull("GERTData")
			if Pid ~= 98 then goto pull3 end
		end
		print("Finishing")
		FTPsocket:write("S.FileFin") -- Write state
		os.sleep(0.1)
		FTPsocket:write(0) -- legacy
		os.sleep(0.1)
		FTPsocket:write(GERTi.getAddress()) -- Write address (unused; kept for potential compatibility)
		file:close() -- stop reading file
		local _, _, _, _, _ = event.pull("GERTData")
		FTPsocket:close() -- close socket
		ID = FTPsocket:read()
		return true, ID[2] -- Return file identifier
	else
		FTPsocket:close()
		return false, "FTP Error - Incorrect State Response" -- if server has not initialised file transfer correctly
	end
end
	

local function FTPCReceive(FileIdName, ResultPath)
	assert(type(FileIdName)=="string", "The identifier for the file must be a string; usually in the format <name.number>.")
	if ResultPath == nil then file = io.open(tostring("/home/" .. FileIdName), "w")
	else file = io.open(tostring(ResultPath), "w") end
	local FTPsocket = GERTi.openSocket(FTPaddress, true, 98) -- Create communication socket with the FTP server
	os.sleep(1)
	batchSocket3("R.FileStart", FileIdName, GERTi.getAddress(), FTPsocket)
	::pull4::
	local _, _, Pid = event.pull("GERTData")
	if Pid ~= 98 then goto pull4 end
	local State = FTPsocket:read()
	if State[1] == "R.Ready" then
		print("Stream Opening")
		batchSocket3("R.FileCont", 0, GERTi.getAddress(), FTPsocket)
		::pull5::
		local _, _, Pid = event.pull("GERTData")
		if Pid ~= 98 then goto pull5 end
		os.sleep(0.8)
		local data = FTPsocket:read()
		local State = data[1]
		local FTP = data[2]
		print("Stream Starting")
		while State ~= "R.Fin" do
			file:write(FTP)
			print("Written")
			::pull6::
			local _, _, Pid = event.pull("GERTData")
			if Pid ~= 98 then goto pull6 end
			os.sleep(0.2)
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