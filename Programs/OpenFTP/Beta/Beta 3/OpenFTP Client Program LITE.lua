-- OpenFTP Client - Lite (Beta 3) | B3LITE

local fs = require("filesystem")
local GERTi = require("GERTiClient")
local event = require("event")

local FTPCore = require("FTPCore")

local SocketWithTimeout = function (Details,Timeout) -- Timeout defaults to 5 seconds. Details must be a keyed array with the address under "address" and the port/CID under "port"
    local socket = GERTi.openSocket(Details.address,Details.port)
    local serverPresence = false
    if socket then serverPresence = event.pullFiltered(Timeout or 5,function (eventName,oAdd,CID) return eventName=="GERTConnectionID" and oAdd==Details.address and CID==Details.port end) end
    if not serverPresence then
        socket:close()
        return false, -1
    end
    return true, socket
end

local function sendFile(fileName,destination,address,port,socket)
    
    local result, code = FTPCore.UploadFile(FileDetails,true,socket)
end








io.write("OpenFTP LITE started. Enter the server's address or EXIT: ")
local address
while type(address) ~= "number" and address ~= "EXIT" do
    address = io.read()
end
if address == "EXIT" then
    os.exit()
end
local FileDetails = {
    address = address,
    port = 98
}
local success, result = SocketWithTimeout(FileDetails)
if not success then
    io.stderr:write("Server Unreachable.")
    os.exit()
end
io.write("Successfully Established Socket.\nSelect your mode:\nSEND RECEIVE DELETE EXIT")
local loop = true
while loop do
    local response = io.read()
    if response == "SEND" then
        io.write("Enter destination of file on server: /home/OpenFTP/")
        FileDetails.destination = io.read()
        io.write("Enter local file path (Where it is): ")
        FileDetails.file = io.read()
        local FileData = fs.size(FileDetails.file)
        local success, result = FTPCore.DownloadFile(FileDetails,FileData,result)
        if success then
            io.write("File Successfully Sent, return code ".. tostring(result))
        else
            io.stderr:write("Error in download, Error Code " .. tostring(result))
        end

    elseif response == "RECEIVE" then
        io.write("Enter path of file on server: /home/OpenFTP/")
        FileDetails.file = io.read()
        io.write("Enter local file destination (Where it will be downloaded to): ")
        FileDetails.destination = io.read()

    elseif response == "DELETE" then

    elseif response == "EXIT" then
        loop = false
    else
        io.stderr:write("INVALID COMMAND")
    end
end