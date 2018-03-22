local component = require("component")
local thread = require("thread")
local internet = component.internet
local data_card = component.data
local tape = component.tape_drive
local gpu = component.gpu
local params = table.pack(...)

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

print("Connecting...")
local socket = internet.connect(address, port)
while true do
    if internet.finishConnect() == true then
        break
    else

    end
end

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

local function datareaderstream(timeout)
    local returndata = ""
    while true do
        local data = read(timeout)
        if data == false then
            break
        else
            returndata = returndata .. data
        end
    end
    return returndata
end

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

local function framegettr()
    socket.write("PACK")
    while true do
        local framedat = datareaderstream(0.01)
        if framedat == "" then
            print("Server Went down. Get a more reliable host.")
            os.exit(1)
        else
            frames.insert(framedat)
        end
    end

end
-- render thread. run it seperately!
-- 1 frame:
--[['#664940|[0,43,1,44]/
     #999280|[15,42,16,43]|[21,42,23,43]|[26,41,27,43]|[28,42,29,43]|[47,54,48,55]/
     #ccdbc0|[22,45,23,46]|[27,43,28,44]|[29,43,30,44]|[48,56,49,57]/
     #666d80|[23,42,24,43]|[27,42,28,43]/
     #000000|[0,0,51,59]|[17,42,18,43]|[18,42,20,44]|[20,43,21,44]|[25,41,26,42]|[30,44,31,45]/
     #002400|[42,52,43,53]/
     #ffdbff|[22,44,23,45]|[27,41,28,42]|[33,48,34,49]/
     #ccb6c0|[1,43,2,44]/#334940|[16,42,17,43]|[26,40,27,41]/
     #99b6c0|[20,42,21,43]|[20,44,22,45]|[25,43,26,44]|[28,43,29,44]']]
local function render()
    local frame = frames[1]
    local framearray = frame.split("/")
    --Set GPU color.
    for colourwithfill in framearray do
        local command = colourwithfill.split("|")
        gpu.setBackground(string.gsub(command[1],"#","0x"))
        for i=2,#colourwithfill do
            gpu.fill()
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