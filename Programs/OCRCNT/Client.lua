local component = require("component")
local computer = require("computer")
local thread = require("thread")
local term = require("term")
local internet = component.internet
local function testimport()
    return require("struct")
end

structtest,errormsg = pcall(testimport)
if structtest == false then
    print("failed to find struct dependancy!")
    os.exit(1)
-- Yes, like that.
-- >
end
local function ctape()
    return require("component.tape_drive")
end
tape,errormsg = pcall(ctape)
if tape == false then
    local tape = false
else
    local tape = component.tape_drive
end
local gpu = component.gpu
local params = table.pack(...)

-- Utility Functions
-- split by chunk
local function splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = tonumber(text:sub(i,i+chunkSize - 1))
    end
    return s
end
-- Pythonic split
local function extendstring(string,times)
    while times > 0 do
        string = string .. string
        times = times - 1
    end
    return string
end

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

local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- TODO: IDEA: do not convert strings to hex. just use 0 padded ints
local function tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
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
if params[3] == nil then
    params[3] = false
else
    params[3] = true
end
-- End checks.
print("Connecting...")
local socket = internet.connect(address, port)
while true do
    if socket.finishConnect() == true then
        break
    else

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
    if data == "OCRCNT/1.0.0" then
        socket.write("READY")
    end
    if params[3] == false or tape ~= false then
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
    if tape.getSize() < tonumber(filesize) then
        print("Not enough space! Waiting for disk with appropriate size.")
        while true do
            os.sleep(1)
            if tape.getSize() >= tonumber(filesize) then
                break
            end
        end
    end
    print("Tape File Size: " .. tape.getSize())
    socket.write("SEND")
    local x, _  =term.getCursor()
    local datasent = 0
    term.write("Recieved data:" .. datasent .."/" .. filesize)
    tape.seek(-1000000000000)
    while true do
        local data = read(5)
        if data == false then
            break
        else
            tape.write(data)
            term.clearLine()
            datasent = datasent + string.len(data)
            term.write("Recieved data:" .. datasent .."/" .. filesize)
        end
    end
    socket.write("OK")
    print("Finished.")
    state.mode = "play"
    return true
end
-- Frames Area [Getting frames etc...]
framebuffer = {}
-- Secondary buffer for rendering.
secondframebuff = {}
local waiting = false
framegetterbuffer = ""

local function render(frame)
    local commands = split(frame, "0x")
    local commands2 = {}
      for _,v in pairs(commands) do
          if v == "" then
          else
            commands2[ #commands2+1 ] = v
          end
      end
    for _, command in pairs(commands2) do
        if command ~= nil then
            local instructions = struct.unpack('<c6'..extendstring('c13',(string.len(command)-6)/12),command)
            --Set GPU color.
            gpu.setBackground(tonumber(string.format("0x%s",instructions[1])))

            newinstructions = {}
            for k,v in pairs(instructions) do
                if v ~= "" then
                    table.insert(newinstructions,v)
                end
            end
            for i=2,#newinstructions do
                local cm = splitByChunk(newinstructions[i],3)
                local c = cm[5]
                table.remove(cm,5)
                local cm2 = {}
                for k,v in pairs(cm) do
                    table.insert(cm2,tonumber(v))
                end
                table.insert(cm2," ")
                if c == 0 then
                    gpu.fill(table.unpack(cm2))
                else
                    gpu.set(table.unpack(cm2))
                end
            end
        end
    end
end

function handler.play()
    while true do
        local data, err=socket.read(4096)
        if data == "" and waiting == false then
            socket.write("PACK")
            waiting = true
            os.sleep(0.01)
        else
            if data == "" and framegetterbuffer ~= "" then
                waiting=false
                render(framegetterbuffer)
                framegetterbuffer = ""
            else
                framegetterbuffer = framegetterbuffer .. data
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