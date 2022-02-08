-- OpenFTP Client - Lite (Beta 3) | B3LITE

local fs = require("filesystem")
local GERTi = require("GERTiClient")
local event = require("event")
local SRL = require("serialization")

local FTPCore = require("FTPCore") -- Dependency

--Error Codes
local INVALIDARGUMENT = 0
local NOSOCKET = -1
local TIMEOUT = -2
local NOSPACE = -3
local INTERRUPTED = -4
local NOLOCALFILE = -5
local UNKNOWN = -6
local SERVERRESPONSEFALSE = -7
local NOREMOTEFILE = -8
local CANNOTCHANGE = -9
local UPTODATE = -10
local NOREMOTERESPONSE = -11
local STUCK = -12

--Op Codes
local ALLGOOD = 0
local DOWNLOADED = 1
local ALREADYINSTALLED = 10


local PERMANENTADDRESS = nil -- Set this if you want to skip the dialogue


-- Functions start here
local SocketWithTimeout = function (Details,Timeout) -- Timeout defaults to 5 seconds. Details must be a keyed array with the address under "address" and the port/CID under "port"
    local socket = GERTi.openSocket(Details.address,Details.port)
    local serverPresence = false
    if socket then serverPresence = event.pullFiltered(Timeout or 5,function (eventName,oAdd,CID) return eventName=="GERTConnectionID" and oAdd==Details.address and CID==Details.port end) end
    if not serverPresence then
        socket:close()
        return false, NOSOCKET
    end
    return true, socket
end

local ProbeForSend = function (FileDetails, StepComplete, socket)
    if not StepComplete then
        return false, socket
    end
    local fileData = {}
    table.insert(fileData,FileDetails.file)
    table.insert(fileData,fs.size(FileDetails.file))
    socket:write("FTPSENDPROBE",SRL.serialize(FileDetails),SRL.serialize(fileData))
    local success = event.pullFiltered(5, function (eventName, iAdd, dAdd, CID) if (iAdd == FileDetails.address or dAdd == FileDetails.address) and (dAdd == FileDetails.port or CID == FileDetails.port) then if eventName == "GERTConnectionClose" or eventName == "GERTData" then return true end end return false end)
    if success == "GERTConnectionClose" then
        return false, INTERRUPTED
    elseif not success then
        return false, TIMEOUT
    end
    while #socket:read("-k") == 0 do
        os.sleep() -- \\\\This might need a lengthening to 0.1, if OC is weird.\\\\
    end
    local returnData = socket:read()
    if type(returnData[1]) == "table" and returnData[1][1] == "FTPREADYTORECEIVE" then
        return true, returnData
    else
        return false, returnData
    end
end




-- IO starts here
io.write("OpenFTP LITE started.") 
local address = PERMANENTADDRESS
if address == nil then
    io.write(" Enter the server's address or EXIT: ")
    while type(tonumber(address)) ~= "number" and address ~= "EXIT" do
        address = io.read()
    end
    if address == "EXIT" then
        os.exit()
    end
    address = tonumber(address)
else
    io.write("\n")
end
local FileDetails = {
    address = address,
    port = 98
}
local success, socket = SocketWithTimeout(FileDetails)
if not success then
    io.stderr:write("Server Unreachable.")
    os.exit()
end
io.write("Successfully Established Socket.\nSelect your mode:\nSEND RECEIVE DELETE MKDIR EXIT\n")
local loop = true
while loop do
    local response = io.read()
    if response == "SEND" then
        io.write("Enter destination of file on server: /home/OpenFTP/")
        FileDetails.destination = io.read()
        io.write("Enter local file path (Where it is): ")
        FileDetails.file = io.read()
        local success, result = ProbeForSend(FileDetails,true,socket)
        if not success then
            io.stderr:write("The server did not respond correctly, error code: " .. SRL.serialize(result,true) .. "\n")
        else
            local success, result = FTPCore.UploadFile(FileDetails,true,socket)
            if success then
                io.write("File Successfully Sent, return code ".. tostring(result) .. "\n")
            else
                io.stderr:write("Error in upload, Error Code " .. tostring(result) .. "\n")
            end
        end
    elseif response == "RECEIVE" then
        io.write("Enter path of file on server: /home/OpenFTP/")
        FileDetails.file = io.read()
        if fs.name(FileDetails.file) == "list" then
            FileDetails.destination = "/tmp/list"
            local FileData = 1
            local success, result = FTPCore.DownloadFile(FileDetails,FileData,socket)
            if success or result == 0 then
                os.execute("edit /tmp/list")
            else
                io.stderr:write("Could not retrieve list file\n")
            end
        else
            io.write("Enter local file destination (Where it will be downloaded to): ")
            FileDetails.destination = io.read()
            local FileData = 1
            local success, result = FTPCore.DownloadFile(FileDetails,FileData,socket)
            if success or result == 0 then
                io.write("File successfully downloaded, return code ".. tostring(result) .. "\n")
            else
                io.stderr:write("Error in download, error code " .. tostring(result) .. "\n")
            end
        end
    elseif response == "DELETE" then
        io.write("Please enter the file or directory you wish to delete:\n/home/OpenFTP/")
        local path = io.read()
        io.write("Are you sure? This is permanent. Type CONFIRM to confirm.\n")
        local answer = io.read()
        if answer == "CONFIRM" then
            io.write("CONFIRMED\n")
            socket:write("FTPDELETE",path)
            local success = event.pullFiltered(5, function (eventName, iAdd, dAdd, CID) if (iAdd == FileDetails.address or dAdd == FileDetails.address) and (dAdd == FileDetails.port or CID == FileDetails.port) then if eventName == "GERTConnectionClose" or eventName == "GERTData" then return true end end return false end)
            if success == "GERTConnectionClose" then
                return false, INTERRUPTED
            elseif not success then
                return false, TIMEOUT
            end
            while #socket:read("-k") == 0 do
                os.sleep() -- \\\\This might need a lengthening to 0.1, if OC is weird.\\\\
            end
            local information = socket:read()[1]
            if type(information) == "table" then
                if information[1] == nil then
                    io.stderr:write("Unable to delete entry at path, error code: " .. tostring(information[2]) .. "\n")
                else
                    io.write("Successfully Deleted.\n")
                end
            else
                if information == true then
                    io.write("File/Folder successfully deleted.\n")
                else
                    io.stderr:write("Error during operation, no details provided.\n")
                end
            end
        else
            io.write("Aborted.\n")
        end
    elseif response == "MKDIR" then
        io.write("Enter path of new directory: /home/OpenFTP/")
        local path = io.read()
        socket:write("FTPNEWDIR",path)
        local success = event.pullFiltered(5, function (eventName, iAdd, dAdd, CID) if (iAdd == FileDetails.address or dAdd == FileDetails.address) and (dAdd == FileDetails.port or CID == FileDetails.port) then if eventName == "GERTConnectionClose" or eventName == "GERTData" then return true end end return false end)
        if success == "GERTConnectionClose" then
            return false, INTERRUPTED
        elseif not success then
            return false, TIMEOUT
        end
        while #socket:read("-k") == 0 do
            os.sleep() -- \\\\This might need a lengthening to 0.1, if OC is weird.\\\\
        end
        local information = socket:read()[1]
        if information == true then
            io.write("Successfully created directory\n")
        else
            io.stderr:write("Unable to create directory at path, error code: " .. tostring(information[2]) .. "\n")
        end
    elseif response == "EXIT" then
        loop = false
        socket:close()
    else
        io.stderr:write("INVALID COMMAND\n")
    end
end