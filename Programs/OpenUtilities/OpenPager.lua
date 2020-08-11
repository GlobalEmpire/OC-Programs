local component = require("component")
local shell = require("shell")
local computer = require("computer")
local fs = require("filesystem")
local GERTi = require("GERTiClient")
local term = require("term")
local args, opts = shell.parse(...)
local serialization = require("serialization")
local event = require("event")
local ConfigSettings = {}
ConfigSettings["CID"] = 128
local OpenConnections = {}
if OpenPagerListeners == nil then
    OpenPagerListeners = {}
end
::RestartProgram::
local function toboolean(var, strict)
    if var == "true" then 
        return true
    elseif var == "false" or strict ~= nil then
        return false
    else
        return var
    end
end
if component.filesystem.isReadOnly() then os.exit() end
if not(fs.exists("../OpenPager")) then 
    fs.makeDirectory("../OpenPager")
elseif not(fs.isDirectory("../OpenPager")) then
    fs.rename("../OpenPager", "../OpenPager.old")
    fs.makeDirectory("../OpenPager")
end
local function readSocket(originAddress)
    OpenConnections[originAddress]:read()
end
local function ReBeep(a)
    computer.beep(a)
end
local function receiveData(eventName, originAddress, connectionID, data)
    print(eventName, originAddress, connectionID, data)
    if ConfigSettings["CID"] == connectionID or connectionID == -1 then
        if data == nil then
            data = readSocket(originAddress)
        elseif data == "OpenPagerSendNames" then
            GERTi.send(originAddress, ConfigSettings["DeviceName"])
        elseif string.len(data) > 9 and string.sub(data,1,10) == "NewMessage" then
            local date = os.date()
            local NewFile = io.open("../OpenPager/" .. date, "w")
            NewFile:write(string.sub(data,11,-1))
            NewFile:close()
            local NewFile = io.open("../OpenPager/" .. date)
            local Name = NewFile:read("*l")
            local Subject = NewFile:read("*l")
            local Important = toboolean(NewFile:read("*l"))
            NewFile:close()
            if Important then Important = event.timer(1, ReBeep, math.huge)
            else
                computer.beep()
                os.sleep(1)
                computer.beep()
                os.sleep(1)
                computer.beep()
            end
            local UpdateFile = io.open("../OpenPager/.", "w")
            UpdateFile:seek("end")
            UpdateFile:write(Name .. "\n" .. Subject .. "\n" .. date .. "\n" .. tostring(Important) .. "\n")
            UpdateFile:close()
            computer.beep() -- make it three times
        end
    end
end
local function openSocket(eventName, originAddress, connectionID)
    if connectionID == ConfigSettings["CID"] then 
        OpenConnections[originAddress] = GERTi.openSocket(originAddress, connectionID) 
    end
end
local function closeSocket()

end
local function SendMessage(Subject,MessageContent,Important,Destination)
    local TotalMessage = tostring("NewMessage" .. ConfigSettings["DeviceName"]) .. "\n" .. tostring(Subject) .. "\n" .. tostring(Important) .. "\n" .. tostring(MessageContent)
    print(string.len(TotalMessage))
    if string.len(TotalMessage) < 6144 then
        GERTi.send(tonumber(Destination), TotalMessage)
        return true
    else
        return false
    end
end
if not(fs.exists("../OpenPager/.Config")) and string.lower(args[1]) ~= "config" then
    print("OpenPager has not been initialised on this device before or has just been updated. Please run <OpenPager Config> to enter configuration mode. OpenPager will be inactive until this is completed.")
    os.exit()
elseif args[1] ~= nil then
    if string.lower(args[1]) == "config" then
        if fs.exists("../OpenPager/.Config") then
            local ConfigFile = io.open("../OpenPager/.Config") 
            ConfigSettings = serialization.unserialize(ConfigFile:read())
            ConfigFile:close()
            io.stderr:write("====================\n")
            print("All Config Settings currently present in the file will now be listed. If you have recently upgraded the program, please delete the config file to regenerate by entering [deleteconfig] (The program will reinitialise next launch). Save and Exit by typing [exit]. Modify a value by entering the setting name, and afterwards the new value (Ensure you do not enter the two simultaneously). The new value can only be of the same variable type as the previous value.")        
            io.stderr:write("====================\n")
            for key, value in pairs(ConfigSettings) do
                print(tostring(key) .. " : " .. tostring(value))
            end
            io.stderr:write("====================\n")
            ::Config0::
            local userResponse = io.read()
            if string.lower(userResponse) == "exit" then
                print("Saving and Exiting")
                fs.remove("../OpenPager/.Config")
                local ConfigFile = io.open("../OpenPager/.Config", "w")
                ConfigFile:write(serialization.serialize(ConfigSettings))
                ConfigFile:close()
                os.exit()
            elseif string.lower(userResponse) == "deleteconfig" then
                fs.remove("../OpenPager/.Config")
                print("Deleted")
                os.exit()
            elseif ConfigSettings[userResponse] ~= nil then
                local userResponse2 = toboolean(io.read())
                if type(userResponse2) == type(ConfigSettings[userResponse]) then
                    ConfigSettings[userResponse] = userResponse2
                    print("Successfully Updated")
                    io.stderr:write("====================\n")
                else
                    print("Incorrect variable value type")
                end
            else
                io.stderr:write("Unknown command/option")
            end
            goto Config0
        else
            io.stderr:write("====================\n")
            print("This is the first time initialisation of OpenPager. Commencing setup:")
            print("Please give this device a name. If a duplicate device name appears on the network, both devices will be asked to resolve. If you have a better idea on what to do, please tell us.")
            ConfigSettings["DeviceName"] = tostring(io.read())
            ::A::
            io.stderr:write("====================\n")
            print("Do you wish to be notified about Broadcasted Messages? [boolean]")
            ConfigSettings["BroadNotif"] = tostring(io.read())
            if not(ConfigSettings["BroadNotif"] == "true" or ConfigSettings["BroadNotif"] == "false") then
                print("Invalid Entry")
                goto A
            else
                ConfigSettings["BroadNotif"] = toboolean(ConfigSettings["BroadNotif"])
            end
            ::B::
            io.stderr:write("====================\n")
            print("Do you wish to be notified about Direct Messages? [boolean]")
            ConfigSettings["DirectNotif"] = tostring(io.read())
            if not(ConfigSettings["DirectNotif"] == "true" or ConfigSettings["DirectNotif"] == "false") then
                print("Invalid Entry")
                goto B
            else
                ConfigSettings["DirectNotif"] = toboolean(ConfigSettings["DirectNotif"])
            end
            io.stderr:write("====================\n")
            print("Do you wish to allow 'Important' messages to notify you continuously until read? [boolean]")
            ConfigSettings["ImportantNotif"] = tostring(io.read())
            if not(ConfigSettings["ImportantNotif"] == "true" or ConfigSettings["ImportantNotif"] == "false") then
                print("Invalid Entry")
                goto B
            else
                ConfigSettings["ImportantNotif"] = toboolean(ConfigSettings["ImportantNotif"])
            end
            local ConfigFile = io.open("../OpenPager/.Config", "w")
            ConfigFile:write(serialization.serialize(ConfigSettings))
            ConfigFile:close()
            args[1] = "restart"
            goto RestartProgram
        end
    elseif string.lower(args[1]) == "start" then
        local ConfigFileLoad = io.open("../OpenPager/.Config", "r")
        ConfigSettings = serialization.unserialize(ConfigFileLoad:read())
        ConfigFileLoad:close()
        if #OpenPagerListeners == 0 then
            OpenPagerListeners[1] = event.listen("GERTData",receiveData)
            if opts.o then if OpenPagerListeners[1] then print("Direct Message OpenPagerListeners successfully activated.\n") else io.stderr:write("Direct Message OpenPagerListeners Already Active\n") end end
            OpenPagerListeners[2] = event.listen("GERTConnectionID",openSocket)
            if opts.o then if OpenPagerListeners[2] then print("Socket Opener successfully activated.\n") else io.stderr:write("Socket Opener Already Active\n") end end
            OpenPagerListeners[3] = event.listen("GERTConnectionClose",closeSocket)
            if opts.o then if OpenPagerListeners[3] then print("Socket Closer successfully activated.\n") else io.stderr:write("Socket Closer Already Active\n") end end
        else
            if opts.o then io.stderr:write("OpenPagerListeners Processes already active") end
        end
        os.exit()
    elseif string.lower(args[1]) == "stop" then
        if #OpenPagerListeners == 0 then 
            if opts.o then io.stderr:write("No OpenPagerListeners processes currently active") end
        else
            local DataReturn = event.cancel(OpenPagerListeners[1])
            if opts.o then if DataReturn then print("Direct Message OpenPagerListeners successfully deactivated.\n") else io.stderr:write("Direct Message OpenPagerListeners Not Found\n") end end
            local OSocketReturn = event.cancel(OpenPagerListeners[2])
            if opts.o then if OSocketReturn then print("Socket Opener successfully deactivated.\n") else io.stderr:write("Socket Opener Not Found\n") end end
            local CSocketReturn = event.cancel(OpenPagerListeners[3])
            if opts.o then if CSocketReturn then print("Socket Closer successfully deactivated.\n") else io.stderr:write("Socket Closer Not Found\n") end end
            OpenPagerListeners = {}
        end
        os.exit()
    elseif string.lower(args[1]) == "restart" then
        if #OpenPagerListeners == 0 then 
            if opts.o then io.stderr:write("No OpenPagerListeners processes currently active") end
        else
            local DataReturn = event.cancel(OpenPagerListeners[1])
            if opts.o then if DataReturn then print("Direct Message OpenPagerListeners successfully deactivated.\n") else io.stderr:write("Direct Message OpenPagerListeners Not Found\n") end end
            local OSocketReturn = event.cancel(OpenPagerListeners[2])
            if opts.o then if OSocketReturn then print("Socket Opener successfully deactivated.\n") else io.stderr:write("Socket Opener Not Found\n") end end
            local CSocketReturn = event.cancel(OpenPagerListeners[3])
            if opts.o then if CSocketReturn then print("Socket Closer successfully deactivated.\n") else io.stderr:write("Socket Closer Not Found\n") end end
            OpenPagerListeners = {}
        end
        local ConfigFileLoad = io.open("../OpenPager/.Config")
        ConfigSettings = serialization.unserialize(ConfigFileLoad:read())
        ConfigFileLoad:close()
        if #OpenPagerListeners == 0 then
            OpenPagerListeners[1] = event.listen("GERTData",receiveData)
            if opts.o then if OpenPagerListeners[1] then print("Direct Message OpenPagerListeners successfully activated.\n") else io.stderr:write("Direct Message OpenPagerListeners Already Active\n") end end
            OpenPagerListeners[2] = event.listen("GERTConnectionID",openSocket)
            if opts.o then if OpenPagerListeners[2] then print("Socket Opener successfully activated.\n") else io.stderr:write("Socket Opener Already Active\n") end end
            OpenPagerListeners[3] = event.listen("GERTConnectionClose",closeSocket)
            if opts.o then if OpenPagerListeners[3] then print("Socket Closer successfully activated.\n") else io.stderr:write("Socket Closer Already Active\n") end end
        else
            io.stderr:write("OpenPagerListeners Processes already active")
        end    
        os.exit()
    elseif string.lower(args[1]) == "compose" then
        local ConfigFileLoad = io.open("../OpenPager/.Config")
        ConfigSettings = serialization.unserialize(ConfigFileLoad:read())
        ConfigFileLoad:close()
        local Subject
        if args[2] ~= nil then
            Subject = args[2]
            if args[3] ~= nil then
                local MessageContent = args[3]
                if args[4] ~= nil then
                    local Important = toboolean(args[4],0)
                    SendMessage(Subject, MessageContent, Important, args[5])
                else
                    SendMessage(Subject, MessageContent, false, args[5])
                end
            end
        else
            while Subject == nil do
                io.stderr:write("====================\n")
                print("Please enter the message subject (Cannot be empty): ")
                Subject = io.read()
            end
            local MessageContent
            while MessageContent == nil do
                io.stderr:write("====================\n")
                print("Please enter the message subject (Cannot be empty): ")
                MessageContent = io.read()
            end
            local Important = 0
            while type(Important) ~= "boolean" do
                io.stderr:write("====================\n")
                print("Do you want to tag this as important? (true/false):")
                Important = toboolean(io.read())
            end
            local Destination
            while type(Destination) ~= "string" do
                io.stderr:write("====================\n")
                print("Enter the Destination GERTi address: ")
                Destination = io.read()
            end
            local response = SendMessage(Subject, MessageContent, Important, Destination)
            if response then 
                print("Message Sent!") 
            else
                io.stderr:write("Message Content too long, This is a pager, not email!")
            end
        end
    end
end -- make an else clause that activates a GUI if no args detected
--create update notifier using internet cards and event.timer
--assign to event listener for gertdata. create a separate function for sockets
