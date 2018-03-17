local component = require("component")
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

if params[3] == nil then
  params[3] = 0
end

if params.n < 2 then
  print("Usage: client [test address] [port] [skipaudio]")
  os.exit(1)
end

local address, port = params[1], tonumber(params[2], 10)
if port == nil then
  print("Error: '" .. params[2] .. "' is not a number")
  os.exit(1)
end

if not internet.isTcpEnabled() then
  print("TCP sockets are not enabled")
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
        if os.clock() - time > timeout then
            return false
        end
      os.sleep(0)
    end
  end
end

