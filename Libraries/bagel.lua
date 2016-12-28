local bagel = {}

local serialize = require("serialization")
function bagel.toast(inputString)
    local charArray = {}
    local tableDex = 2
    local index = 1
    local keyGen = true
    -- generate key and length of time to use it
    local key = math.random(9)
    local keyLength = math.random(2, 9)
    local keyInput = tonumber(tostring(key)..tostring(keyLength))
    local tempChar = ""
    local keyDex = 1
    charArray[1] = keyInput
    while string.sub(inputString, index, index) ~= "" do
        while keyDex <= keyLength do
            tempChar=string.byte(string.sub(inputString, index, index))
            if tempChar == nil then
                keyGen = false
                break
            end
            tempChar = tempChar*key
            charArray[tableDex]=tempChar
            index = index + 1
            tableDex = tableDex + 1
            keyDex = keyDex + 1
        end
        -- change key
        if keyGen == true then
            key = math.random(9)
            keyLengh = math.random(2, 9)
            keyInput = tonumber(tostring(key)..tostring(keyLength))
            charArray[tableDex]=keyInput
            keyDex = 1
            tableDex = tableDex + 1
        end
    end
    return charArray
end
-- lol
    function bagel.unToast(inputArray)
    local newString = ""
    local key = 1
    local keyLength = 1
    local keyInput = ""
    local tempChar = ""
    local keyDex = 1
    local index = 2
    if inputArray[1] ~= nil then
        keyInput = inputArray[1]
        keyLength = tonumber(string.sub(tostring(keyInput), 2, 2))
        key = tonumber(string.sub(tostring(keyInput), 1, 1))
    end
    while inputArray[index] ~= nil do
        while keyDex <= keyLength do
            tempChar = inputArray[index]
            if tempChar == nil then
                break
            end
            tempChar = tempChar/key
            newString = newString..string.char(tempChar)
            keyDex = keyDex + 1
            index = index + 1
        end
        keyInput = inputArray[index]
        keyLength = tonumber(string.sub(tostring(keyInput), 2, 2))
        key = tonumber(string.sub(tostring(keyInput), 1, 1))
        keyDex = 1
        index = index + 1
    end
    --print(newString)
    return newString
end

-- performs a simple verification check of a file
function bagel.glutenous(path, correctNum)
    local fs = require("filesystem")
    local f = io.open(path, "r")
    local line = f:read(1)
    local veriNum = 0
    while line ~=nil do
        veriNum = veriNum + string.byte(line)
        line = f:read(1)
    end
    return (veriNum == correctNum), veriNum
end

--toasts a file
function bagel.toastFile(path)
    local f = io.open(path, "r")
    local newString = ""
    local toasted = {}
    local toastDex = 1
    local line=f:read()
    while line ~= nil do
        for key,value in pairs(bagel.toast(line)) do
            toasted[toastDex] = tostring(value).."\n"
            toastDex = toastDex + 1
        end
        toasted[toastDex]="999".."\n"
        toastDex = toastDex + 1
        line = f:read()
    end
    f:close()
    toastDex = 1
    local wF = io.open(path, "w")
    while toasted[toastDex] ~= nil do
        wF:write(toasted[toastDex])
        toastDex = toastDex+1
    end
    wF:close()
end

--untoasts a file
function bagel.unToastFile(path)
    local f = io.open(path, "r")
    local newString = ""
    local unToasted = {}
    local toastDex = 1
    local tempArray = {}
    local writeTable = {}
    local writeDex = 1
    local unDex = 1
    local line = f:read()
    while line ~= nil do
        if tostring(line) ~= "999" then
            tempArray[toastDex]=line
            toastDex=toastDex+1
            line = f:read()
        else
            unToasted[unDex] = bagel.unToast(tempArray)
            tempArray = {}
            toastDex = 1
            unDex = unDex + 1
            line = f:read()
        end
    end
    f:close()
    unDex = 1
    local wF = io.open(path, "w")
    while unToasted[unDex] ~= nil do
        wF:write(unToasted[unDex].."\n")
        unDex = unDex+1
    end
    wF:close()
end
return bagel