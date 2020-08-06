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
local function toboolean(var)
    if var == "true" then
        return true
    elseif var == "false" then
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
if not(fs.exists("../OpenPager/.Config")) and args[1] ~= "Config" then
    print("OpenPager has not been initialised on this device before or has just been updated. Please run <OpenPager Config> to enter configuration mode. OpenPager will be inactive until this is completed.")
    os.exit()
elseif args[1] == "Config" then
    if fs.exists("../OpenPager/.Config") then
        local ConfigFile = io.open("../OpenPager/.Config") 
        ConfigSettings = serialization.unserialize(ConfigFile:read())
        ConfigFile:close()
        print("All Config Settings currently present in the file will now be listed. If you have recently upgraded the program, please delete the config file to regenerate by entering DELETECONFIG (The program will reinitialise next launch). Save and Exit by typing EXIT. Modify a value by entering the setting name, and afterwards the new value (Ensure you do not enter the two simultaneously). The new value can only be of the same variable type as the previous value.")        
            for element in ConfigSettings do
            print(element .. " : " .. ConfigSettings[element])
        end
        ::Config0::
        local userResponse = io.read()
        if userResponse == "EXIT" then
            print("Saving and Exiting")
            fs.remove("../OpenPager/.Config")
            local ConfigFile = io.open("../OpenPager/.Config", "w")
            ConfigFile:write(serialization.serialize(ConfigSettings))
            ConfigFile:close()
            os.exit()
        elseif userResponse == "DELETECONFIG" then
            fs.remove("../OpenPager/.Config")
            print("Deleted")
            os.exit()
        elseif ConfigSettings[userResponse] ~= nil then
            local userResponse2 = toboolean(io.read())
            if type(userResponse2) == type(ConfigSettings[userResponse]) then
                ConfigSettings[userResponse] = userResponse2
                print("Successfully Updated")
            end
        end
        goto Config0
    else
        print("This is the first time initialisation of OpenPager. Commencing setup:")
        print("Please give this device a name. If a duplicate device name appears on the network, both devices will be asked to resolve.")
        ConfigSettings["DeviceName"] = tostring(io.read())
        ::A::
        print("Do you wish to be notified about Broadcasted Messages? [boolean]")
        ConfigSettings["BroadNotif"] = tostring(io.read())
        if not(ConfigSettings["BroadNotif"] == "true" or ConfigSettings["BroadNotif"] == "false") then
            print("Invalid Entry")
            goto A
        else
            ConfigSettings["BroadNotif"] = toboolean(ConfigSettings["BroadNotif"])
        end
        ::B::
        print("Do you wish to be notified about Direct Messages? [boolean]")
        ConfigSettings["DirectNotif"] = tostring(io.read())
        if not(ConfigSettings["DirectNotif"] == "true" or ConfigSettings["DirectNotif"] == "false") then
            print("Invalid Entry")
            goto B
        else
            ConfigSettings["DirectNotif"] = toboolean(ConfigSettings["DirectNotif"])
        end
        local ConfigFile = io.open("../OpenPager/.Config", "w")
        ConfigFile:write(serialization.serialize(ConfigSettings))
        ConfigFile:close()
    end
end
local function ReceiveMessage()

--assign to event listener for gertdata. create a separate function for sockets
