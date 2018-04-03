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
-- getter thread. run it seperately!
local function framegettr()
    socket.write("PACK")
    while true do
        if framebuffer.len <=params[3] then
        local framedat = datareaderstream(0.05)
        if framedat == "" then
            print("Server Went down. Get a more reliable host.")
            os.exit(1)
        else
            framebuffer.insert(data_card.deflate(framedat))
        end
    end

    end

end

-- 1 frame:
--[[
    #000000|[0,0,48,30]|[0,23,2,3]|[2,23,4,3]|[38,13,10,18]|[39,25,3,3]|[40,25,3,4]/
    #33dbc0|[35,30,13,11]/
    #66b6c0|[41,39,2,2]|[46,40,2,2]/
#66dbc0|[43,23,2,2]|[44,15,1,7]/
#66dbff|[43,38,2,1]|[45,30,2,1]|[45,35,2,1]/
#99b6c0|[2,52,3,1]|[6,51,3,2]|[8,37,4,1]|[9,26,2,1]|[10,29,2,1]|[10,33,2,1]|[11,42,2,1]|[11,65,1,2]/
#99dbc0|[23,28,2,2]/
#336d80|[33,31,2,2]|[43,41,3,1]/
#666d40|[22,29,8,4]|[29,32,2,1]|[36,38,3,3]|[40,41,2,3]/
#666d80|[15,66,3,2]|[17,50,2,2]|[18,64,3,2]|[19,53,1,2]|[19,61,2,2]|[21,50,2,2]|[25,29,1,2]|[25,34,3,2]|[28,31,3,1]|[33,32,2,2]|[43,10,1,2]/
#996d40|[28,33,2,2]/
#996d80|[0,24,20,39]/
#002400|[12,21,4,1]|[13,69,3,1]|[17,22,2,2]|[19,66,2,1]|[24,26,2,2]|[41,45,2,1]|[42,21,1,2]|[43,5,5,8]/
#002440|[7,66,2,3]|[15,23,3,1]|[21,25,3,2]|[31,30,2,1]|[37,28,2,1]|[39,39,2,2]|[45,11,3,3]/
#9992c0|[3,63,2,2]/
#332440|[13,23,2,1]|[15,39,5,6]|[19,42,2,2]|[20,55,10,6]|[34,34,2,2]|[36,37,4,4]|[43,12,1,9]|[43,44,3,1]/
#334940|[6,23,1,2]|[9,23,10,5]|[10,66,4,4]|[12,22,1,2]|[18,65,2,1]|[21,27,1,2]|[22,64,2,2]|[26,30,2,2]|[26,61,2,2]|[37,37,2,2]|[40,39,2,2]/
#334980|[20,53,2,4]/
#669280|[13,41,5,6]|[14,44,1,2]|[14,64,2,2]|[14,64,4,4]|[15,24,9,6]|[15,48,7,6]|[17,37,20,15]|[20,31,7,6]|[20,60,5,3]|[21,62,2,3]|[24,59,2,2]|[24,62,2,2]/
#999280|[5,53,2,2]|[6,40,2,1]|[6,44,3,1]|[7,25,2,1]|[13,58,2,2]|[16,32,2,1]|[19,39,2,1]|[20,48,3,3]|[23,36,2,1]|[27,36,2,1]/
#ccb6c0|[5,58,3,3]/
#ccdbc0|[7,27,2,2]|[9,61,1,2]|[11,51,2,1]|[13,45,1,3]|[26,33,2,1]/
#ccffff|[3,61,5,4]|[12,64,1,2]|[14,60,2,4]|[21,61,2,1]|[23,35,3,6]|[36,31,12,7]|[44,42,4,2]/
#ffdbc0|[31,53,3,3]|[35,41,2,2]/
#ffdbff|[6,62,3,3]|[12,40,3,1]|[20,38,3,1]|[24,56,1,2]|[26,36,2,2]|[27,34,2,2]/
#ffffc0|[0,40,2,2]/
#ffffff|[8,39,6,4]|[11,53,9,14]|[13,38,3,2]|[13,52,2,2]|[19,37,2,1]|[23,48,12,8]|[27,48,7,4]|[29,51,6,6]|[43,43,2,1]

]]
local function render()
    local frame = frames[1]
    local framearray = frame.split("/")
    --Set GPU color.
    for colourwithfill in framearray do
        local command = colourwithfill.split("|")
        gpu.setBackground(string.gsub(command[1],"#","0x"))
        for i=2,#colourwithfill do
            local location = string.gsub(i,'[','').gsub(i,']','')
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