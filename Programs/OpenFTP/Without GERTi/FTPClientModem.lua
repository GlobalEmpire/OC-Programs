local component = require("component")
local event = require("event")
local term = require("term")
local m = component.modem
local thread = require("thread")
term.clear()
print("Scanning for server")
m.open(98)
m.broadcast(98, "Request FTP ADDRESS", m.address)
local _, _, _, _, _, FTPaddress = event.pull("modem_message")
m.close(98)
m.open(99)
while true do
print("Server Found - Address is " .. FTPaddress)
print("Enter Mode:")
print("Type 'Send' to send a file to the server or 'Request' to request a file from the Server")
local OPMode = io.read()

if OPMode == "Send" then
	print("Please specify the relative or absolute path of the file; starting with '/'")
	Path = tostring(io.read())
	local file = io.open(Path)
	print("Please enter the name which will be given to the file when transfered: ")
	local name = tostring(io.read())
	print("The file will now be sent to the Server. You will be sent an identifier for the program when the transfer is completed which you may use to request your file from the server from any connected computer.")
	m.send(FTPaddress, 99, "S.FileStart", name, m.address)
	local _, _, _, _, _, state = event.pull("modem_message")
	if state == "StartConfirm" then
		print("Sending")
		local P = file:read(4096)
		m.send(FTPaddress, 99, "S.FileContinue", P, m.address)
		local _, _, _, _, _, state = event.pull("modem_message")
		while string.len(P) == 4096 do
			print("Sending")
			local P = file:read(4096)
			m.send(FTPaddress, 99, "S.FileContinue", P, m.address)
			local _, _, _, _, _, state = event.pull("modem_message")
			if state ~= "WriteContinue" then print("Something has gone wrong. Restarting") m.send(FTPaddress, 99, "FTPErrorR", 0, m.address) computer.shutdown(true) end
		end
		m.send(FTPaddress, 99, "S.FileFin", 0, m.address)
		file:close()
		local _, _, _, _, _, Identifier = event.pull("modem_message")
		print(Identifier)
	else
		print("Something has gone wrong. Restarting") m.send(FTPaddress, 99, "FTPErrorR", 0, m.address) computer.shutdown(true)
	end
elseif OPMode == "Request" then
	print("Enter the file's identification string that was given upon completion of the File Transfer to the server.")
	local FileIdCode = tostring(io.read())
	file = io.open(tostring("/home/" .. FileIdCode), "w")
	m.send(FTPaddress, 99, "R.FileStart", FileIdCode, m.address)
	local _, _, _, _, _, State = event.pull("modem_message")
	if State == "R.Ready" then
		print("Stream Starting")
		m.send(FTPaddress, 99, "R.FileCont", 0, m.address)
		local _, _, _, _, _, State, FTP = event.pull("modem_message")
		print("Stream Continuing")
		print(State)
		while State ~= "R.Fin" do
			file:write(FTP)
			print("Written")
			_, _, _, _, _, State, FTP = event.pull("modem_message")
			print(State)
		end
		file:close()
		print("Your file has been successfully downloaded to /home/" .. FileIdCode)
		os.exit()
	else  print("Something didnt work") file:close() end
else 
	print("You have not entered a valid mode of operation. Please try again.")
	os.sleep(5)
	term.clear()
end
end