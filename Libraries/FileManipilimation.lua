-- whenever used, the program must include the word manipilimation
local manipilimation = {}

-- this function allows an arbitrary string to be inserted at any point in the document. A \n must be used before the input string if you do not desire the add-on string to be used on the same line as indicated.
function manipilimation.insert(path, line, insertString)
    local f = io.open(tostring(path), r)
    local junkTable = {}
    local readIndex=0

    repeat
        readIndex=readIndex+1

        if readIndex~=line then
            junkTable[readIndex]=f:read("*L")

        else

            junkTable[readIndex]=f:read("*l")

            junkTable[readIndex]=tostring(junkTable[readIndex]) .. insertString

        end

    until junkTable[readIndex] == nil

    f:close()
    local wF = io.open(tostring(path), 'w')
    readIndex=1
    while junkTable[readIndex] ~= nil do
        --print(junkTable[readIndex])
        wF:write(junkTable[readIndex])
        readIndex=readIndex+1
    end
    wF:close()
end
return manipilimation