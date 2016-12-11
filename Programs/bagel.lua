local bagel = {}

local serialize = require("serialization")
function bagel.toast(input)
    local stringPos = 1
    local newPos = 1
    local charArray = {}
    local tempArray = {}
    -- turn each letter into a number, and shift the mapping by 1 each time to enhance security
    while stringPos <= string.len(input) do
        charArray[stringPos]=string.byte(string.sub(input, stringPos, stringPos))
        charArray[stringPos]=charArray[stringPos]+stringPos
        stringPos = stringPos + 1
    end
    
    stringPos = stringPos - 1
        --flip each pair of letters around
    while newPos <= stringPos do
        tempArray[newPos]=charArray[(newPos+1)]
        tempArray[(newPos+1)]=charArray[newPos]
        newPos = newPos + 2
    end
    
    newPos = 1
    --flip each block of four (2 pairs flipped around each other) flipped letters around (pretty sure I didn't know what I was doing when I thought this was a good idea)
    while newPos < stringPos do
        charArray[newPos]=tempArray[(newPos+2)]
        charArray[(newPos+1)]=tempArray[(newPos+3)]
        charArray[(newPos+2)]=tempArray[(newPos)]
        charArray[(newPos+3)]=tempArray[(newPos+1)]
        newPos = newPos+4
    end
    -- now jank the janky jank janks
    -- gamax92, this manipilimation usage is for you. I know you love the word manipilimation
    local mT = {5, -1, 0.5, 2, 0.1} -- manipilimation table
    -- apply the transformations
    newPos = 1
    local tabDex = 1
    while newPos < stringPos do
        if charArray[newPos] ~= nil then
            charArray[newPos] = charArray[newPos]*mT[tabDex]
            tabDex = tabDex + 1
            if tabDex > 5 then
                tabDex = 1
            end
        end
        newPos = newPos + 1
    end
    return charArray
end
-- lol
    function bagel.untoast(inputArray)
    local newPos = 1
    local tempArray = {}
    local newString = ""
    local stringPos = #inputArray - 1
    local mT = {5, -1, 0.5, 2, 0.1} -- manipilimation table
    -- apply the transformations
    newPos = 1
    local tabDex = 1
    while newPos < stringPos do
        if inputArray[newPos] ~= nil then
            inputArray[newPos] = inputArray[newPos]/mT[tabDex]
            tabDex = tabDex + 1
            if tabDex > 5 then
                tabDex = 1
            end
        end
        newPos = newPos + 1
    end
    newPos = 1
        --flip each block of four (2 pairs flipped around each other) flipped letters around
    --first reversal step to unscrambulation
    while newPos < stringPos do
        tempArray[newPos]=inputArray[(newPos+2)]
        tempArray[(newPos+1)]=inputArray[(newPos+3)]
        tempArray[(newPos+2)]=inputArray[(newPos)]
        tempArray[(newPos+3)]=inputArray[(newPos+1)]
        newPos = newPos+4
    end
    
    newPos = 1
    -- this stringPos + 1 thing is critical to functioning. Idk why
    stringPos = stringPos + 1
    -- redo the flipping performed the first time in bagel.toast This will now produce a string of numbers that just needs to be turned back into letters
    while newPos < stringPos do
        inputArray[newPos]=tempArray[(newPos+1)]
        inputArray[(newPos+1)]=tempArray[newPos]
        newPos = newPos + 2
    end
    
    newPos = 1
    stringPos = 1
    -- re-assemble the string
    serialize.serialize(inputArray)
    while stringPos <= #inputArray do
        newString = newString..string.char(inputArray[stringPos]-stringPos)
        stringPos = stringPos + 1
    end
    print(newString)
    return(newString)
end

-- performs a simple verification check of a file
function bagel.glutenous(correctNum, path)
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
return bagel