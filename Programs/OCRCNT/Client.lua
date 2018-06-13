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
else
    local struct = require("struct")
end
local tape = component.tape_drive
local gpu = component.gpu
local params = table.pack(...)
local framegetterbuffer = ""
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
function string:split(sSeparator, nMax, bRegexp)
   assert(sSeparator ~= '')
   assert(nMax == nil or nMax >= 1)

   local aRecord = {}

   if self:len() > 0 then
      local bPlain = not bRegexp
      nMax = nMax or -1

      local nField, nStart = 1, 1
      local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
      while nFirst and nMax ~= 0 do
         aRecord[nField] = self:sub(nStart, nFirst-1)
         nField = nField+1
         nStart = nLast+1
         nFirst,nLast = self:find(sSeparator, nStart, bPlain)
         nMax = nMax-1
      end
      aRecord[nField] = self:sub(nStart)
   end

   return aRecord
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
    state.mode = "getaudio"
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
local framebuffer = {}
-- Secondary buffer for rendering.
local secondframebuff = {}
local waiting = false
local function datareaderstream()
    while true do
        local data, err=socket.read(4096)
        if data == nil or data == "" and waiting == false then
            socket.write("PACK")
            os.sleep(0.1)
            waiting = true
        else
            framegetterbuffer = framegetterbuffer .. data
            local split = framegetterbuffer.split("|")
            for k,v in pairs(split) do
                if next(split,k) == nil then
                    framegetterbuffer = v
                    break
                else

                    table.insert(framebuffer,v)
                end
            end
            waiting = false
        end
    end
end

local eof = false
-- Render Thread now uses structs!
local function render()
    local frame = secondframebuff[1]
    local commands = frame.split("0x")
    for command in commands do
        local instructions = struct.unpack('<c6'+'c13'*((command.len-6)/12),command)
        --Set GPU color.
        gpu.setBackground(string.format("0x%s",instructions[1]))
        for i=2,#instructions do
            local cm = splitByChunk(i,4)
            local c = cm[4]
            cm = table.remove(cm,4)
            if c == 1 then
                gpu.fill(table.unpack(cm)," ")
            else
                gpu.set(table.unpack(cm)," ")
            end
        end
    end
end

-- Timer function to time updates

local function timer()
    local continue = true
    while continue do
        local ftick = 1
        local dt = computer.uptime()
        while true do
            if tablelength(framebuffer) >= 15 then
                -- We have enough frames. Move them to secondary framebuffer
                secondframebuff = table.move(framebuffer,1,15,1,secondframebuff)
                break
            else
                if eof then
                    continue = false
                end
                -- not enough frames for a full second.. soo we wait.
                os.sleep(0.05)
            end
        end
        while true do
            -- We are out of time for this second.
            if computer.uptime() - dt <= 0 then
                -- Empty 15 frame/sec buffer
                secondframebuff = {}
                break
            end
            if ftick == 16 then
                -- We are early.. which is nice...
                break
            else
                -- render frame. and delete it from 15frame/sec buffer
                render()
                ftick = ftick + 1
            end
            -- so that it doesnt look like we all at one shot just rendered it.
            -- But it's the hard truth
            os.sleep(0.005)
        end
    end
    return true
end

function handler.play()
    print("Start DRT")
    drt = thread.create(datareaderstream)
    print("Start Renderer")
    renderer = thread.create(timer)
    return false
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