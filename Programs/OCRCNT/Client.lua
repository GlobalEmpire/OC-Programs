local component = require("component")
local thread = require("thread")
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
-- End Utility functions

-- Some checks
if not internet.isTcpEnabled() then
  print("TCP sockets are not enabled")
  os.exit(1)
end

if params.n < 2 then
  print("Usage: client (server address) (port) [buffered packets] [Packet Size]")
  os.exit(1)
end

if params[3] == nil then
    print("Using default number of buffered packets: 12")
    params[3] = 12
end

if params[4] == nil then
    print("Using default PacketSize: 4096")
    params[4] = 4096
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
    if internet.finishConnect() == true then
        break
    else

    end
end
-- Reader functions
local function read(timeout, ...)
    local time = os.clock()
  while true do
    local data, err=socket.read(...)
    if data == nil then
      error(err)
    elseif data ~= "" then
      return data
    else
        if os.clock() - time > timeout and timeout ~= nil then
            return false
        end
      os.sleep(0)
    end
  end
end

-- handler area

local state = {mode="handshake"}
local handler = {}
local framebuffer = {}
function handler.handshake()
    local data = read(nil)
    if data == "OCRCNT/1.0.0" then
        socket.write("READY")
    end
    local bsize = read(nil)
    if bsize == "BSIZE?" then
        socket.write(params[3])
    end
    socket.write(hasdatacard)
end

function handler.getaudio()
    print("Request Requesting Audio")
    socket.write("AUDIO")
    local filesize = read()
    print("Tape File Size: " + filesize)
    socket.write(params[4])
    print("Writing to drive")
    tape.seek(-1000000000000)
    while true do
        local data = read(20)
        if data == false then
            break
        else
            tape.write(data)
        end
    end
    socket.write("OK")
    print("Finished.")
end
--[[TODO:
    Well I need help:
    Specificallay the area below.
    This string of data will be sent:
    b'0x000000035082001004...|'
    All in 1 line.
    at the end there is a pipe to determine the end of a frame.
    I need help to make sure that:
    framebuffer only gets 1 frame data per value.
    you can implement it anyway you like. and if you want me to make any changes to my side, please let me know.
    1 "Fill" command: "0x000000 035 082 001 004 100 122 031 014... 035 082 001 004"
    --]]
-- Frames Area [Getting frames etc...]
local function datareaderstream(timeout)

    while true do
        local data = read(timeout)
        if data == false then
            break
        else
            framegetterbuffer = framegetterbuffer .. data
            local split = framegetterbuffer.split("|")
            for k,v in pairs(split) do
                if next(split,k) == nil then
                    framegetterbuffer = v
                else

                    print()
                end
                end
            end
    end
    return framegetterbuffer
end

local function framegettr()
    socket.write("PACK")
    while true do
        if framebuffer.len <=params[3] then
            local framedat = datareaderstream(0.05)
            if framedat == "" then
                print("Server Went down. Get a more reliable host.")
                os.exit(1)
            else
                framebuffer.insert()
            end
        end
    end
end


-- Render Thread now uses structs!
local function render()
    local frame = frames[1]
    local commands = frame.split("0x")
    for command in commands do
        local instructions = struct.unpack('<c6'+'c12'*((command.len-6)/12),command)
        --Set GPU color.
        gpu.setBackground(string.format("0x%s",instructions[1]))
        for i=2,#instructions do
            gpu.fill(unpack(splitByChunk(i,3))," ")
        end
    end
end

while true do
  print(state.mode)
  if not handler[state.mode]() then
    break
  end
end

--Reset States [Stolen fron ICE2]
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)