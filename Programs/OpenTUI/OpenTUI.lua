local term = require("term")
local component = require("component")
local gpu = component.gpu
-- The entry parameter is a string.
-- Takes a given string, and writes to the center of the screen at the same height as the cursor, surrounded in an ASCII box. 
-- It tries a different fancy thing if it only has one line to work with, and simply does nothing otherwise.
-- Returns nothing.

local OpenTUI = {}

OpenTUI.PrintLogo =  function (Text,ScreenWidth,ScreenHeight)
    checkArg(1, Text, "string")
    ScreenWidth, ScreenHeight = term.getViewport()
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
    TextRows[2]="║" .. Text .. "║"
    TextRows[3]="╚"
    for LoopCount=1,string.len(Text),1 do
        TextRows[3] = TextRows[3] .. "═"
    end
    TextRows[3] = TextRows[3] .. "╝"
    for LoopCount=1,3,1 do 
        term.setCursor(StartPoint,CursorY+LoopCount-3)
        term.write(TextRows[LoopCount])
    end
    term.write("\n")
    return
end


-- Prints the supplied string with the supplied colour and then reverts it.
OpenTUI.ColourText = function (String,colour)
    local OldColour, _ = gpu.setForeground(EmphasisColour)
    term.write(String,true)
    gpu.setForeground(OldColour)
end


--[[
        Given two strings, it will display them on screen on the left and right, and display a selector box around the left option. 
        The user can use the arrow keys to select and enter to confirm their choice. 
        The program will return 1 for the left option and 2 for the right option.
        If AllowAbbreviations is true, the user can press a letter key corresponding to the first letter in either option to select and confirm it instantly. The feature is forcefully set to false if both strings start with the same character 
        ]]
OpenTUI.BinaryChoice = function (LeftText,RightText,LeftTextColour,RightTextColour,SelectionColour,AllowAbbreviations) 
    checkArg(1, LeftText,"string","number")
    checkArg(2, RightText,"string","number")
    LeftTextColour = LeftTextColour or 0xffffff
    checkArg(3, LeftTextColour, "number")
    RightTextColour = RightTextColour or 0xffffff
    checkArg(4, RightTextColour, "number")
    SelectionColour = SelectionColour or 0xffffff
    checkArg(5, SelectionColour, "number")
    AllowAbbreviations = AllowAbbreviations or false
    checkArg(6, AllowAbbreviations, "boolean")
    if string.lower(string.sub(LeftText,1,1)) == string.lower(string.sub(RightText,1,1)) then
        AllowAbbreviations = false
    end
    
end


return OpenTUI