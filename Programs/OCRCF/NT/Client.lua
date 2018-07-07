local component = require("component")
local computer = require("computer")
local thread = require("thread")
local term = require("term")
local internet = component.internet
--Versiongstring--
local version = "OCRCNT/1.0.0"
------------------
local function ctape()
    return require("component").tape_drive
end
tape,errormsg = pcall(ctape)
if tape == false then
    tape = false
else
    tape = component.tape_drive
end

-- NOTE: Tape is set to false if audio downloading is disabled.
-- So no need for the or thing - use "if tape then" from now on.

local gpu = component.gpu
gpu.setResolution(160, 50)
local params = table.pack(...)

-- Utility Functions
-- split by chunk and convert to number
local function splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = assert(tonumber(text:sub(i,i+chunkSize - 1)), "Invalid packet '" .. text .. "'")
    end
    return s
end
-- Pythonic split

function split( string, inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( string, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( string, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( string, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( string, theStart ) )
  return outResults
end



local function cliunpack(clistring)
    local returntable = {}
    local hexstring = ""
    table.insert(returntable,string.sub(clistring,1,3))
    hexstring = ""
    local count = (#clistring - 3 )/ 13
    for i = 0,count do
        local curindex = i*13
        local sub = string.sub(clistring,curindex+4,curindex+13+4)
        if sub ~= "" then
            table.insert(returntable,sub)
        end
    end
    return returntable
end

local r = {"00","33","66","99","cc","ff"}
local g = {"00","24","49","6d","92","b6","db","ff"}
local b = {"00","40","80","c0","ff"}

local function hexunpack(hstring)
    local t = {}
    string.gsub(hstring,".", function (c) table.insert(t,c) end)
    return r[tonumber(t[1])+1]..g[tonumber(t[2])+1]..b[tonumber(t[3])+1]
end

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

-- End Utility functions

-- Some checks
if not internet.isTcpEnabled() then
  print("TCP sockets are not enabled")
  os.exit(1)
end

if params.n < 2 then
  print("Usage: client (server address) (port) [skip audio]")
  os.exit(1)
end

local address, port = params[1], tonumber(params[2], 10)
if port == nil then
  print("Error: '" .. params[2] .. "' is not a number")
  os.exit(1)
end
if params[3] ~= nil then
    tape = false
end
-- End checks.
print("Connecting...")
local socket = internet.connect(address, port)
while true do
    if socket.finishConnect() == true then
        break
    else
        -- ?
    end
end

function read(timeout, ...)
    local time = computer.uptime()
  while true do
    local data, err=socket.read(...)
    if data == nil then
      error(err)
    elseif data ~= "" then
      return data
    else
        if timeout ~= nil and computer.uptime() - time > timeout then
            return false
        end
      os.sleep(0)
    end
  end
end

-- handler area
local state = {mode="handshake"}
local handler = {}
function handler.handshake()
    local data = read(nil)
    if data == version then
        socket.write("READY")
    end
    if tape then
        state.mode = "getaudio"
    else
        state.mode = "play"
    end
    return true
end

function handler.getaudio()
    print("Request Requesting Audio")
    socket.write("AUDIO")
    local filesize = read()
    print(filesize)
    filesize = tonumber(filesize)
    if not filesize then error("File size not number") end
    if tape.getSize() < filesize then
        print("Not enough space! Waiting for disk with appropriate size.")
        while true do
            os.sleep(1)
            if tape.getSize() >= filesize then
                break
            end
        end
    end
    print("File Size/Tape Size: " .. filesize .. "/" .. tape.getSize())
    socket.write("SEND")
    local x, _  =term.getCursor()
    local datasent = 0
    term.write("Recieved data:" .. datasent .."/" .. filesize)
    tape.stop()
    tape.seek(-math.huge)
    while datasent < filesize do
        local data = read(10)
        if data == false then
            error("Audio stream end")
        else
            tape.write(data)
            term.clearLine()
            datasent = datasent + #data
            term.write("Recieved data:" .. datasent .."/" .. filesize)
        end
    end
    tape.seek(-math.huge)
    socket.write("OK")
    print("Finished.")
    state.mode = "play"
    return true
end
-- Frames Area [Getting frames etc...]
framegetterbuffer = ""

local function render(frame)
    local commands = split(frame, "|")
    -- This covers remaining data that may not be complete yet.
    local lastCmd = table.remove(commands, #commands)
    for _, command in pairs(commands) do
        if command ~= nil then
            local instructions = cliunpack(command)
            -- Result starts with the 3-byte gpucol (semi-compressed GPU colour)
            --Set GPU color.
            local gpuCol = table.remove(instructions, 1)
            gpu.setBackground(tonumber(string.format("0x%s",hexunpack(gpuCol))))
            -- The rest of what follows is 13-byte instruction data,
            --  until '|' is hit which separates the instructions.
            -- This instruction data is split into 3s.
            -- 3 6 9 12 13
            -- 1 2 3 4  5
            -- Format:
            -- 1/2/3/4 : X Y W H
            -- 5 : 'S/F' Bit - "0" if false, "1" if true.
            -- The arrangement results as follows:
            -- fill X Y W H " "
            -- set X Y " "
            for _, instr in ipairs(instructions) do
                -- NOTE: tonumbers all the things
                local cm = splitByChunk(instr,3)
                assert(#cm == 5, "Packet format incorrect")
                local c = table.remove(cm,5)
                table.insert(cm, " ")
                if c == 0 then
                    gpu.fill(table.unpack(cm))
                else
                    -- 'Use Set' bit.
                    -- Seems to be to reduce GPU call cost -
                    --  unsure of actual effect
                    table.remove(cm,3)
                    table.remove(cm,3)
                    gpu.set(table.unpack(cm))
                end
            end
        end
    end
    return lastCmd
end

function handler.play()
    local didTapePlayYet = false
    socket.write("PACK")
    while true do
        local data, err=socket.read(4096)
        assert(data, "The socket naturally closed.")
        if data == "" then
            os.sleep(0.01)
        else
            framegetterbuffer = framegetterbuffer .. data
            if framegetterbuffer:find("|", 1, true) then
                framegetterbuffer = render(framegetterbuffer)
                if (not didTapePlayYet) and tape then
                    tape.play()
                    didTapePlayYet = true
                end
            end
        end
    end
end

while true do
  print(state.mode)
  if not handler[state.mode]() then
    break
  end
end
thread.waitForAll({drt,renderer})
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)