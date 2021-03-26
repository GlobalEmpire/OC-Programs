local component = require("component")
local shell = require("shell")
local args, ops = shell.parse(...)
local computer = require("computer")
local fs = require("filesystem")
if #args ~= 1 then print("This function only needs one argument: The name of the file you wish to transfer to the floppy.") os.exit() end
local fslist = component.list("filesystem")
local floppies = {}
for element in fslist do 
    if component.proxy(element).getLabel() == nil then
        floppies[#floppies+1] = element
    end
end
if #floppies == 0 then
    print("At least one unlabelled storage disk must be present")
    os.exit()
elseif #floppies >= 2 then
    ::pull::
    local num = 0
    for element in floppies do
        num = num+1
        print("(" .. num .. ")" .. " " .. element)
    end
    print("Please enter the number of the correct destination filesystem. Hover your cursor over the item to see its component ID.")
    local userNum = io.read()
    if userNum < 1 or userNum > #floppies then
        print("Invalid Number")
        goto pull
    end
    local destfs = component.proxy(floppies[userNum])
else
    destfs = component.proxy(floppies[1])
end
--Pass the option -d if you are copying a directory.
--pass -d as an option for a directory
if computer.freeMemory() - 1000 < fs.size(tostring(args[1])) then print("Your computer does not have enough free memory to copy this file. Install more memory, or find a better program.") os.exit() end
local file = io.open(args[1])
local filedest = destfs.open(args[1], "w")
destfs.write(filedest,file:read("*a"))
file:close()
print("Completed")