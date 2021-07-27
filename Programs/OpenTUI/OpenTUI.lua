local term = require("term")
local component = require("component")
local keyboard = require("keyboard")
local event = require("event")

local gpu = component.gpu
-- The entry parameter is a string.
-- Takes a given string, and writes to the center of the screen at the same height as the cursor, surrounded in an ASCII box. 
-- It tries a different fancy thing if it only has one line to work with, and simply does nothing otherwise.
-- Returns nothing.


local function DrawBoxLeft(stringlen,CursorY,ScreenWidth) -- draws left selection cursor for BinaryChoice function
    local TextRows = {}
    TextRows[1]="╔"
    for LoopCount=1,stringlen,1 do
        TextRows[1] = TextRows[1] .. "═"
    end
    TextRows[1] = TextRows[1] .. "╗"
    TextRows[3]="╚"
    for LoopCount=1,stringlen,1 do
        TextRows[3] = TextRows[3] .. "═"
    end
    TextRows[3] = TextRows[3] .. "╝"
    for LoopCount=1,3,2 do 
        term.setCursor(ScreenWidth/2-stringlen-2,CursorY+LoopCount-3)
        term.write(TextRows[LoopCount])
    end
    term.setCursor(ScreenWidth/2-stringlen-2,CursorY-1)
    term.write("║")
    term.setCursor(ScreenWidth/2-1,CursorY-1)
    term.write("║")
    term.setCursor(1,CursorY)
    return
end

local function DrawBoxRight(stringlen,CursorY,ScreenWidth) -- draws right selection cursor for BinaryChoice function
    local TextRows = {}
    TextRows[1]="╔"
    for LoopCount=1,stringlen,1 do
        TextRows[1] = TextRows[1] .. "═"
    end
    TextRows[1] = TextRows[1] .. "╗"
    TextRows[3]="╚"
    for LoopCount=1,stringlen,1 do
        TextRows[3] = TextRows[3] .. "═"
    end
    TextRows[3] = TextRows[3] .. "╝"
    for LoopCount=1,3,2 do 
        term.setCursor(ScreenWidth/2,CursorY+LoopCount-3)
        term.write(TextRows[LoopCount])
    end
    term.setCursor(ScreenWidth/2,CursorY-1)
    term.write("║")
    term.setCursor(ScreenWidth/2+stringlen+1,CursorY-1)
    term.write("║")
    term.setCursor(1,CursorY)
    return
end

--I can and should merge DrawBoxRight and DrawBoxLeft, by getting the X positions of the cursor, calculating them at the start based on whether it's left or right, and then feeding it into the remaining code which is identical.

local function ClearBox(LeftLen,RightLen,CursorY,ScreenWidth)
    gpu.fill(1,CursorY-2,ScreenWidth,1," ")
    gpu.fill(1,CursorY,ScreenWidth,1," ")
    gpu.fill(ScreenWidth/2-LeftLen-2,CursorY-1,1,1," ")
    gpu.fill(ScreenWidth/2-1,CursorY-1,2,1," ")
    gpu.fill(ScreenWidth/2+1+RightLen,CursorY-1,1,1," ")
    return
end

local function ImposeTable(MainTable,ImposingTable)
    for k,v in pairs(ImposingTable) do
        MainTable[k] = v
    end
    return MainTable
end


local OpenTUI = {}
OpenTUI.Version = 1.0 

-- Writes the supplied string with the supplied colour. 
OpenTUI.ColourText = function (String,Colour)
    checkArg(1,String,"string")
    checkArg(2,Colour,"number")
    local OldColour, _ = gpu.setForeground(Colour)
    term.write(String,true)
    gpu.setForeground(OldColour)
    return
end


OpenTUI.PrintLogo = function (Text,ColourTable) -- Requires OpenTUI.ColourText()
    checkArg(1, Text, "string")
    local ScreenWidth, ScreenHeight = term.getViewport()
    local TextOffset = string.len(Text)/2+1
    local Middle = ScreenWidth/2
    local StartPoint = Middle-TextOffset
    if ScreenHeight < 3 or ScreenWidth < string.len(Text)+2 then
        if ScreenWidth < string.len(Text)+6 then
            return
        end
        term.clearLine()
        local _, CursorY = term.getCursor()
        term.setCursor(StartPoint-2,CursorY)
        term.write("╞╬╡" .. Text .. "╞╬╡")
        return
    end
    term.write("\n\n\n")
    local _, CursorY = term.getCursor()
    local TextRows = {}
    TextRows[1]="╔"
    for LoopCount=1,string.len(Text),1 do
        TextRows[1] = TextRows[1] .. "═"
    end
    TextRows[1] = TextRows[1] .. "╗"
    TextRows[2]=" " .. Text .. " " -- "║"
    TextRows[3]="╚"
    for LoopCount=1,string.len(Text),1 do
        TextRows[3] = TextRows[3] .. "═"
    end
    TextRows[3] = TextRows[3] .. "╝"
    local OriginColour = gpu.setForeground(ColourTable.MainAccent)
    for LoopCount=1,3,1 do 
        term.setCursor(StartPoint,CursorY+LoopCount-3)
        if LoopCount == 2 then
            OpenTUI.ColourText(TextRows[2],ColourTable.MainTextTheme)
        else
            term.write(TextRows[LoopCount])
        end
    end
    local CursorX, CursorY = term.getCursor()
    term.setCursor(CursorX-1,CursorY-1)
    term.write("║")
    term.setCursor(CursorX-string.len(Text)-3,CursorY-1)
    term.write("║")
    term.setCursor(CursorX,CursorY)
    term.write("\n")
    return
end



--[[
        Given two strings, it will display them on screen on the left and right, and display a selector box around the left option. 
        The third positional variable 'ColourTable' is a table containing the names of the elements that can be coloured as keys and their colours as values in hexcodes. The elements that can be coloured are: LeftTextColour, RightTextColour, SelectionColour, AcceptedColour. SelectionColour is white by default, and determines the colour of the selection box. AcceptedColour is green by default, and determines what colour the selection box becomes once the user has confirmed their choice.
        The user can use the arrow keys to select and enter to confirm their choice. 
        The program will return two parameters:
            The first parameter determines whether or not there was enough space on the viewport to fully display the menu.
            The second option returns either an error code or a selection:
                If selection: 1 for the left option and 2 for the right option.
                If Error: 1 for not enough space. More pending.
        If AllowAbbreviations is true, the user can press a letter key corresponding to the first letter in either option to select and confirm it instantly. The feature is forcefully set to false if both strings start with the same character 
        ]]
OpenTUI.BinaryChoice = function (LeftText,RightText,ColourTable,AllowAbbreviations)
    checkArg(1, LeftText,"string","number")
    checkArg(2, RightText,"string","number")
    ColourTable = ColourTable or []
    checkArg(3, ColourTable, "table")
    ColourTable.LeftTextColour = ColourTable.LeftTextColour or 0xffffff
    checkArg(3.1, ColourTable.LeftTextColour, "number")
    ColourTable.RightTextColour = ColourTable.RightTextColour or 0xffffff
    checkArg(3.2, ColourTable.RightTextColour, "number")
    ColourTable.SelectionColour = ColourTable.SelectionColour or 0xffffff
    checkArg(3.3, ColourTable.SelectionColour, "number")
    ColourTable.AcceptedColour = ColourTable.AcceptedColour or 0x00ff00
    checkArg(3.4, ColourTable.AcceptedColour, "number")
    AllowAbbreviations = not(not((AllowAbbreviations or false) and not(string.lower(string.sub(LeftText,1,1)) == string.lower(string.sub(RightText,1,1))) and string.match(string.lower(string.sub(LeftText,1,1)),"%a") and string.match(string.lower(string.sub(RightText,1,1)),"%a")))
    checkArg(4, AllowAbbreviations, "boolean")
    local ScreenWidth, ScreenHeight = term.getViewport()
    local LeftLen = string.len(LeftText)
    local RightLen = string.len(RightText)
    if ScreenHeight < 3 or ScreenWidth/2 < math.max(LeftLen, RightLen) + 2 then -- ensure enough space
        return false, 1
    end
    local Selected = 1
    term.write("\n\n\n")
    local CX,CY = term.getCursor()
    local OriginColour = gpu.setForeground(ColourTable.LeftTextColour) -- setup text and its colour
    term.setCursor(ScreenWidth/2-LeftLen-1,CY-1)
    term.write(LeftText)
    gpu.setForeground(ColourTable.RightTextColour)
    term.setCursor(ScreenWidth/2+1,CY-1)
    term.write(RightText)
    gpu.setForeground(ColourTable.SelectionColour)
    DrawBoxLeft(LeftLen,CY,ScreenWidth)
    local confirmation = true
    local AcceptedKeys = {} -- setup which key presses the program will care about
    AcceptedKeys[205] = true
    AcceptedKeys[203] = true
    AcceptedKeys[28] = true
    if AllowAbbreviations then -- if you can answer by using the first letter of the string, their codes are added automatically. I might provide an additional parameter which overrides this, to allow you to provide your own character per string instead of the first character of each string.
        AcceptedKeys[keyboard.keys[string.lower(string.sub(LeftText,1,1))]] = 1
        AcceptedKeys[keyboard.keys[string.lower(string.sub(RightText,1,1))]] = 2
    end
    while confirmation do
        local _, _, _, KeyCode = event.pull("key_down")
        if AcceptedKeys[KeyCode] then
            if KeyCode == 28 then
                confirmation = false
            elseif KeyCode == 205 then
                Selected = 2
                ClearBox(LeftLen,RightLen,CY,ScreenWidth)
                DrawBoxRight(RightLen,CY,ScreenWidth)
            elseif KeyCode == 203 then
                Selected = 1
                ClearBox(LeftLen,RightLen,CY,ScreenWidth)
                DrawBoxLeft(LeftLen,CY,ScreenWidth)
            else
                Selected = AcceptedKeys[KeyCode]
                confirmation = false
            end
        end
    end
    ClearBox(LeftLen,RightLen,CY,ScreenWidth)
    gpu.setForeground(ColourTable.AcceptedColour)
    if Selected == 1 then
        DrawBoxLeft(LeftLen,CY,ScreenWidth)
    else
        DrawBoxRight(RightLen,CY,ScreenWidth)
    end
    gpu.setForeground(OriginColour)
    return true, Selected
end

OpenTUI.ParamList = function (ParamTable,ColourTable,VarSet,ReadOnly) -- ColourTable used keys: 'KeyColour': determines colour of keys and unsaved modified values.
    local EditTable = {}
    ::helpEnd::
    term.clear()
    checkArg(1,ParamTable, "table")
    ColourTable = ColourTable or {}    
    checkArg(2,ColourTable, "table")
    ColourTable.KeyColour = ColourTable.KeyColour or 0xe6db74
    checkArg(2.1,ColourTable.KeyColour, "number")
    VarSet = VarSet or {}
    checkArg(3,VarSet,"table")
    ReadOnly = ReadOnly or false
    checkArg(4,ReadOnly, "boolean")
    local ScreenWidth, ScreenHeight = term.getViewport()
    local LineClearString = string.rep("═",ScreenWidth)
    local KeyHistoryTable = {}
    local LoopIndex = 1
    local LX,LY = term.getCursor()
    for key, value in pairs(ParamTable) do
        KeyHistoryTable[LoopIndex] = key
        LoopIndex = LoopIndex + 1
        term.clearLine()
        OpenTUI.ColourText(tostring(key) .. " : ",ColourTable.KeyColour)
        if EditTable[key] then
            OpenTUI.ColourText(tostring(EditTable[key] .. "\n"),ColourTable.KeyColour)
        else
            term.write(value .. "\n")
        end
    end
    term.write(LineClearString)
    local CX,CY = term.getCursor()
    CY = CY + 1
    if ReadOnly then
        return
    end
    local UserLoop = not(ReadOnly)
    local FunctionLoop = not(ReadOnly)
    local SetDefault = false
    while FunctionLoop do    
        local UserOutcome = "continue"
        while UserLoop do
            term.setCursor(1,CY)
            term.clearLine()
            term.write("Type 'help' and press control + enter for more information.")
            term.setCursor(1,CY+2)
            term.clearLine()
            term.setCursor(1,CY+1)
            term.clearLine()
            term.write("Input: ")
            local userResponse = string.sub(term.read(KeyHistoryTable,nil,KeyHistoryTable),1,-2)
            if keyboard.isControlDown() then
                if string.lower(userResponse) == "save" then
                    UserLoop = false
                    UserOutcome = "save"
                    term.setCursor(1,CY+3)
                    term.clearLine()
                    term.write("Saved")
                elseif string.lower(userResponse) == "exit" then
                    UserLoop = false
                    UserOutcome = "exit"
                elseif string.lower(userResponse) == "default" then
                    UserLoop = false
                    UserOutcome = "default"
                elseif string.lower(userResponse) == "reset" then
                    UserOutcome = "reset"
                    UserLoop = false
                    term.setCursor(1,CY+3)
                    term.clearLine()
                    term.write("Reset")
                elseif string.lower(userResponse) == "discard" then
                    UserOutcome = "discard"
                    UserLoop = false
                elseif string.lower(userResponse) == "help" then
                    term.clear()
                    term.write("Type the case-sensitive name of the parameter (on the left) that you want to modify and confirm with enter.\nYou will then be prompted to enter the new value of the parameter.\nModified values will not be saved to the original table until the 'save' command is passed.\nTo pass a command, type the command word and press control + enter.\nOther valid commands are: 'exit', which saves changes and exits the modification,\n'discard', which exits without saving,\n'reset', which discards changes without exiting,\nand 'default', which exits without saving, and if supported, instructs the main program to reset the parameters to default.\nPress anything to exit help.")
                    term.setCursorBlink(false)
                    term.read()
                    term.setCursorBlink(true)
                    term.clear()
                    goto helpEnd
                else
                    term.write("\n")
                    term.clearLine()
                    io.stderr:write("Invalid Command")
                end
            elseif ParamTable[userResponse] ~= nil then
                term.write("Modifying " .. tostring(userResponse) .. " : ")
                local AutoFillTable = {}
                for k,v in pairs(VarSet[userResponse]) do
                    AutoFillTable[k] = v
                end
                local userResponse2 = string.sub(term.read(AutoFillTable,nil,VarSet[userResponse]),1,-2)
                local inVarSet = false 
                local VarSetOnly = false
                if type(VarSet[userResponse]) == "table" then
                    VarSetOnly = true
                    for key,value in pairs(VarSet[userResponse]) do
                        if userResponse2 == value then
                            inVarSet = true
                            break
                        end
                    end
                end
                if (type(userResponse2) == type(ParamTable[userResponse]) and not(VarSetOnly)) or inVarSet then
                    EditTable[userResponse] = userResponse2
                    term.clearLine()
                    term.write("Confirmed")
                    UserLoop = false
                else
                    term.clearLine()
                    io.stderr:write("Invalid Value")
                end
            else
                term.write("\n")
                term.clearLine()
                io.stderr:write("Invalid Key")
            end
        end
        if UserOutcome == "save" then
            ImposeTable(ParamTable,EditTable)
            EditTable = {}
            UserLoop = true
        elseif UserOutcome == "exit" then
            ImposeTable(ParamTable,EditTable)
            EditTable = {}
            FunctionLoop = false
        elseif UserOutcome == "default" then
            FunctionLoop = false
            SetDefault = true
        elseif UserOutcome == "reset" then
            EditTable = {}
            UserLoop = true
        elseif UserOutcome == "discard" then
            EditTable = {}
            FunctionLoop = false
        else
            UserLoop = true
        end
        term.setCursor(LX,LY)
        local KeyHistoryTable = {}
        local LoopIndex = 1    
        for key, value in pairs(ParamTable) do
            KeyHistoryTable[LoopIndex] = key
            LoopIndex = LoopIndex + 1    
            term.clearLine()
            OpenTUI.ColourText(tostring(key) .. " : ",ColourTable.KeyColour)
            if EditTable[key] then
                OpenTUI.ColourText(tostring(EditTable[key] .. "\n"),ColourTable.KeyColour)
            else
                term.write(value .. "\n")
            end
        end
        term.write(LineClearString)    
    end
    term.setCursor(1,CY+3)
    term.clearLine()
    term.setCursor(1,CY+2)
    term.clearLine()
    return ParamTable,SetDefault
end

return OpenTUI