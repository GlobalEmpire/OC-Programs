-- OpenFTP Server - Lite (Beta 3) | B3LITE

local fs = require("filesystem")
local GERTi = require("GERTiClient")
local event = require("event")

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

local function GERTDataHandler(_,originAddress,connectionID,data)
    if fileSockets[originAddress] and connectionID == customPort then
        local information = fileSockets[originAddress]:read("-k")
        if type(information) == "table" then
            if information[1] == "FTPREADYTORECEIVE" then
                local FileDetails = {
                    file = customPath .. fs.canonical(information[2]),
                    address = originAddress,
                    port = customPort
                }
                local result, lastState = FTPCore.UploadFile(FileDetails,true,fileSockets[originAddress]) -- I might do something with these outputs later
            end
        end
    end
end





local completeSocketListener = event.listen("GERTConnectionID",CompleteSocket)
local closeSocketListener = event.listen("GERTConnectionClose",CloseSocket)
local GERTDataHandlerListener = event.listen("GERTData",GERTDataHandler)

io.write("OpenFTP Beta 3 LITE has been successfully started.\nTo shut down the program, type EXIT.\nIf the io crashes, the program will continue running in the background.\nThe only way to stop the program after this is to either kill its processes, or reboot.\n")
local response = true
while response ~= "EXIT" do
    response = io.read()
end
event.cancel(completeSocketListener)
event.cancel(closeSocketListener)
event.cancel(GERTDataHandlerListener)
io.write("OpenFTP has shut down.")