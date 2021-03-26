local fs = require("filesystem")
local shell = require("shell")
local args, opts = shell.parse(...)
if #args ~= 3 then io.stderr:write("This program requires exactly 3 arguments, <File path> <Line To Insert On (not After)> <Data To Insert>") os.exit() end
-- Make more robust error handling. So far I have no clue what this will do if you pass a line after the end of the file
-- Implement -o to overwrite the original file (should be easy) 
local file = io.open(args[1], "r")
local newfile = io.open("injected-" .. args[1], "w")
for line = 0, args[2], 1 do
    newfile:write(file:read("*l") .. "\n")
end
newfile:write(args[3] .. "\n")
local data = file:read()
while data ~= nil do
    newfile:write(data  .. "\n")
    data = file:read("*l")
end
file:close()
newfile:close()
print("Injected")