local Compatibility = "1.0"
local component = require("component")
local event = require("event")
local term = require("term")
local m = component.modem
local GERTi = require("GERTiClient")

local exportFunctions = {}

local function batchSocket3(var1, var2, var3, socket)
	socket:write(var1)
	os.sleep(0.1)
	socket:write(var2)
	os.sleep(0.1)
	socket:write(var3)
	os.sleep(0.1)
end

local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
 end


exportFunctions.FTPCSend = function (Path, name,FTPaddress) -- Send file function; (Absolute path of file, Name to save file under)
	assert(type(Path) == "string", "File Path must be the absolute path of the file to send given as a string")
	assert(type(name) == "string" or type(name) == "number", "The name that the file will be stored under partially must be either a string or a number")
	assert(type(FTPaddress)== "number")
	FTPsocket = GERTi.openSocket(FTPaddress, true, 98) -- Create communication socket with the FTP server
	batchSocket3("S.FileStart",name,GERTi.getAddress(),FTPsocket) -- write address (unused; vestigial code)
	::pull1::
	local _, _, Pid = event.pull("GERTData") -- Wait for response
	if tonumber(Pid) ~= 98 then goto pull1 end	
	local state = FTPsocket:read() -- state
	if state[1] == "StartConfirm" then -- Confirm server has correctly initialised the transfer
		local file = io.open(Path) -- Open File
		local P = file:read(4096) -- Read file
		batchSocket3("S.FileContinue",P,GERTi.getAddress(),FTPsocket)	-- write address (unused vestigial code)
		::pull2::
		local _, _, Pid = event.pull("GERTData")
		if tonumber(Pid) ~= 98 then goto pull2 end
		local state = FTPsocket:read() -- state
		while string.len(P) == 4096 do -- send file until no file left to send
			P = file:read(4096)
			batchSocket3("S.FileContinue",P,GERTi.getAddress(),FTPsocket)
			::pull3::
			local _, _, Pid = event.pull("GERTData")
			if tonumber(Pid) ~= 98 then goto pull3 end
		end
		batchSocket3("S.FileFin",0,GERTi.getAddress(),FTPsocket) -- Write address (unused; kept for potential compatibility)
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
	

exportFunctions.FTPCReceive = function (FileIdName, ResultPath,FTPaddress)
	if FileIdName == nil then
		FileIdName = ""
	end
	assert(type(FileIdName)=="string", "The identifier for the file must be a string; usually in the format <name.number>.")
	assert(type(FTPaddress)== "number" or type(FTPaddress) == "string")
	if ResultPath == nil then 
		file = io.open(tostring("/home/" .. FileIdName), "w")
	else 
		file = io.open(tostring(ResultPath), "w") 
	end
	local FTPsocket = GERTi.openSocket(FTPaddress, true, 98) -- Create communication socket with the FTP server
	os.sleep(1)
	batchSocket3("R.FileStart", FileIdName, GERTi.getAddress(), FTPsocket)
	::pull4::
	local _, _, Pid = event.pull("GERTData")
	if tonumber(Pid) ~= 98 then goto pull4 end
	local State = FTPsocket:read()
	if State[1] == "R.Ready" then
		batchSocket3("R.FileCont", 0, GERTi.getAddress(), FTPsocket)
		::pull5::
		local _, _, Pid = event.pull("GERTData")
		if tonumber(Pid) ~= 98 then goto pull5 end
		os.sleep(0.8)
		local data = FTPsocket:read()
		local State = data[1]
		local FTP = data[2]
		while State ~= "R.Fin" do
			file:write(FTP)
			::pull6::
			local _, _, Pid = event.pull("GERTData")
			if tonumber(Pid) ~= 98 then goto pull6 end
			os.sleep(0.2)
			data = FTPsocket:read()
			State = data[1]
			FTP = data[2]
		end
		file:close()
		FTPsocket:close()
		return true
	else if FTPsocket then FTPsocket:close() end if file then file:close() end return false, "FTP Error - Incorrect State Response", State[1]  end
end

return exportFunctions