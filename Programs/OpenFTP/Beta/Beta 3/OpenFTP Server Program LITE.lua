-- OpenFTP Server - Lite (Beta 3) | B3LITE

local fs = require("filesystem")
local GERTi = require("GERTiClient")
local event = require("event")
local SRL = require("serialization")

local FTPCore = require("FTPCore")



local customPath = "/home/OpenFTP/"
local customPort = 98
local fileSockets = {}

local function CompleteSocket(_,originAddress,connectionID)
    if connectionID == customPort then
        os.sleep()
        fileSockets[originAddress] = GERTi.openSocket(originAddress,connectionID)
    end
    return true
end

local function CloseSocket(_, originAddress,destAddress)
    if fileSockets[originAddress] then
        fileSockets[originAddress]:close()
        fileSockets[originAddress] = nil
    elseif fileSockets[destAddress] then 
        fileSockets[destAddress]:close()
        fileSockets[destAddress] = nil
    end
    return true
end

local function updateListFile(directory)
    local listString = ""
    for v in fs.list(directory) do
        if v ~= "list" then
            listString = listString .. v .. "\n"
        end
    end
    local listFile = io.open(directory .. "list", "w")
    listFile:write(listString)
    listFile:close()
end

local function GERTDataHandler(_,originAddress,connectionID,data)
    if fileSockets[originAddress] ~= nil and connectionID == customPort then
        local information = fileSockets[originAddress]:read("-k")[1]
        if type(information) == "table" then
            if information[1] == "FTPREADYTORECEIVE" then
                fileSockets[originAddress]:read()
                local FileDetails = {
                    file = customPath .. fs.canonical(information[2]),
                    address = originAddress,
                    port = customPort
                }
                local result, lastState = FTPCore.UploadFile(FileDetails,true,fileSockets[originAddress]) -- I might do something with these outputs later
                local directory = fs.path(FileDetails.file)
                updateListFile(directory)
            elseif information[1] == "FTPSENDPROBE" then
                fileSockets[originAddress]:read()
                local FileDetails = SRL.unserialize(information[2])
                FileDetails.address = originAddress
                local FileData = SRL.unserialize(information[3])
                local result, lastState = FTPCore.DownloadFile(FileDetails,FileData,fileSockets[originAddress])
            elseif information[1] == "FTPDELETE" then
                local directory = customPath .. fs.canonical(information[2])
                fileSockets[originAddress]:read()
                local success, result = fs.remove(directory)
                fileSockets[originAddress]:write(success,result)
                updateListFile(fs.path(directory))
            elseif information[1] == "FTPNEWDIR" then
                fileSockets[originAddress]:read()
                local directory = customPath .. fs.canonical(information[2])
                local success, result = fs.makeDirectory(directory)
                fileSockets[originAddress]:write(success,result)
                updateListFile(fs.path(directory))
            end
        end
    end
end





local completeSocketListener = event.listen("GERTConnectionID",CompleteSocket)
local closeSocketListener = event.listen("GERTConnectionClose",CloseSocket)
local GERTDataHandlerListener = event.listen("GERTData",GERTDataHandler)


io.write("OpenFTP Beta 3 LITE has been successfully started.\nTo shut down the program, type EXIT, to run in background, type BACKGROUND.\nIf the io crashes, the program will continue running in the background.\nThe only way to stop the program after this is to either kill its processes, or reboot.\n")
local response = true
while response ~= "EXIT" and response ~= "BACKGROUND" do
    response = io.read()
end
if response == "BACKGROUND" then
    os.exit()
end
event.cancel(completeSocketListener)
event.cancel(closeSocketListener)
event.cancel(GERTDataHandlerListener)
io.write("OpenFTP has shut down.")