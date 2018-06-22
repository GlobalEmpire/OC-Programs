-- cli.lua
-- Original by Ristellise
-- Edited by 20KDC
-- Originally licensed by WTFPL. Relicensed to CC0

local component = require("component")
local computer = require("computer")
local thread = require("thread")
local term = require("term")
local internet = component.internet

-- Apparently, only 0-15 are even considered valid palette indexes.
-- So this table contains the compression decoding table,
--  which has the added benefit of being a failsafe in case of an
--  unusual custom palette.
local palRGB = {
    -- While table.insert will never add [0], it will
    -- use 1 as the next index and follow the natural sequence,
    -- and since 0 to 15 are fixed here, starting at 16 is fine.
    [0] = 0x0F0F0F,
    0x1E1E1E,
    0x2D2D2D,
    0x3C3C3C,
    0x4B4B4B,
    0x5A5A5A,
    0x696969,
    0x787878,
    0x878787,
    0x969696,
    0xA5A5A5,
    0xB4B4B4,
    0xC3C3C3,
    0xD2D2D2,
    0xE1E1E1,
    0xF0F0F0
}
local rTab = {0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF}
local gTab = {0x00, 0x24, 0x49, 0x6D, 0x92, 0xB6, 0xDB, 0xFF}
local bTab = {0x00, 0x40, 0x80, 0xC0, 0xFF}
for r = 1, #rTab do
    for g = 1, #gTab do
        for b = 1, #bTab do
            table.insert(palRGB, bTab[b] + (gTab[g] * 0x100) + (rTab[r] * 0x10000))
        end
    end
end

local function ctape()
    return require("component").tape_drive
end
tape,errormsg = pcall(ctape)
if tape == false then
    tape = false
else
    tape = component.tape_drive
end

-- NOTE: Use one of:
-- 1. if tape and downloadAudio then
-- 2. if tape then
local downloadAudio = true

local gpu = component.gpu
gpu.setResolution(160, 50)
gpu.setDepth(8)
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
local dlaModes = {
    noDL = function ()
        downloadAudio = false
    end,
    noTape = function ()
        tape = false
    end
}
if params[3] ~= nil then
    if not dlaModes[params[3]] then
        print("Available skip types: noDL, noTape")
        os.exit(1)
    end
    dlaModes[params[3]]()
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

local theBuffer = ""
local function read(timeout, ...)
  while true do
    local data, err=socket.read(...)
    if data == nil then
      error(err)
    elseif data ~= "" then
      theBuffer = theBuffer .. data
      return
    else
      os.sleep(0)
    end
  end
end

local function getString()
    local n
    repeat
        n = theBuffer:find("\x00", 1, true)
        if not n then read() end
    until n
    local str = theBuffer:sub(1, n - 1)
    theBuffer = theBuffer:sub(n + 1)
    return str
end
local function getU8()
    if theBuffer == "" then read() end
    local b = assert(theBuffer:byte())
    theBuffer = theBuffer:sub(2)
    return b
end
local function getU16()
    local h = getU8()
    return (h * 256) + getU8()
end
local function getU32()
    local h = getU16()
    return (h * 0x10000) + getU16()
end

-- handler area
local state = {mode="handshake"}
local handler = {}
function handler.handshake()
    socket.write("STOP/3\x00")
    local data = getString()
    print("I am 'STOP/3', I got '" .. data .. "'")
    if tape and downloadAudio then
        state.mode = "getaudio"
    else
        state.mode = "play"
    end
    return true
end

function handler.getaudio()
    print("Request Requesting Audio")
    socket.write("AUDIO\x00")
    local filesize = getU32()
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
    socket.write("SEND\x00")
    local x, _ = term.getCursor()
    local datasent = 0
    term.write("Recieved data:" .. datasent .."/" .. filesize)
    tape.stop()
    tape.seek(-math.huge)
    while datasent < filesize do
        if theBuffer == "" then
            read()
        end
        -- Take from the buffer up to the amount remaining, no more.
        local data = theBuffer:sub(1, filesize - datasent)
        theBuffer = theBuffer:sub(#data + 1)
        tape.write(data)
        term.clearLine()
        datasent = datasent + #data
        term.write("Recieved data:" .. datasent .."/" .. filesize)
    end
    tape.seek(-math.huge)
    print("Finished.")
    state.mode = "play"
    return true
end

-- Frames Area [Getting frames etc...]

local function render(pfx)
    -- tapeTime (start) and terminate (end) are omitted.
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0)
    gpu.fill(1, 50, 160, 1, " ")
    gpu.set(1, 50, pfx .. getString())
    for i = 1, getU16() do
        local bkg = getU8()
        gpu.setBackground(palRGB[bkg])
        for j = 1, getU16() do
            local x, y, w, h, s
            x = getU8()
            y = getU8()
            w = getU8()
            h = getU8()
            s = getU8()
            -- Clip
            h = math.min(h, 49 - y) -- Would be 50 - y, but bottom line is subtitle.
            if h > 0 then
                if s == 0 then
                    gpu.fill(x + 1, y + 1, w, h, " ")
                else
                    gpu.set(x + 1, y + 1, (" "):rep(w))
                end
            end
        end
    end
end

function handler.play()
    local didTapePlayYet = false
    local uptimeSyncTime
    --print("PASSWORD ACCEPTED")
    --print("PLEASE INDICATE MEMORY SIZE")
    --print("unlimited")
    --print("YOU WANT EVERYTHING?")
    --print("yes")
    socket.write("PACK\x00")
    while true do
        -- Tape time
        local tapeTime = getU32()
        render(tapeTime .. ";")
        -- "Terminate" U8
        if getU8() ~= 0 then return end
        if not didTapePlayYet then
            if tape then
                tape.seek(-math.huge)
                tape.play()
            end
            uptimeSyncTime = computer.uptime()
            didTapePlayYet = true
        end
        if tape then
            while tape.getPosition() < tapeTime do
                os.sleep(0.01)
            end
        else
            local endTime = uptimeSyncTime + (tapeTime / 6000)
            local timeDiff = endTime - computer.uptime()
            if timeDiff > 0.05 then
                os.sleep(timeDiff)
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