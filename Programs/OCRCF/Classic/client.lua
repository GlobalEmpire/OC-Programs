local component = require("component")
local serialization = require("serialization")
local internet = component.internet
local data_card = component.data
local tape = component.tape_drive
local gpu = component.gpu

local params = table.pack(...)
if params[3] == nil then
  params[3] = 0
end
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

local function mysplit(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[#t+1] = str
  end
  return t
end

local socket = internet.connect(address, port)

local function read(...)
  while true do
    local data, err=socket.read(...)
    if data == nil then
      error(err)
    elseif data ~= "" then
      return data
    else
      os.sleep(0)
    end
  end
end

local state={
mode="handshake"
}

local handler={}
function handler.handshake()
  local data = read()
  if data == "OCRS" then
    socket.write("READY")
    state.mode = "length"
    state.nextmode = "palette"
    state.doaudio = params[3]
    return true
  end
end

function handler.length()
  local data = read()
  state.length = tonumber(data, 10)
  state.data = {n = 0}
  state.mode = "collect"
  return state.length ~= nil
end

function handler.collect()
  local data = read(state.length - state.data.n)
  state.data[#state.data+1] = data
  state.data.n = state.data.n + #data
  if state.data.n >= state.length then
    state.data = table.concat(state.data)
    state.mode = state.nextmode
  end
  return true
end

function handler.palette()
  local data, err = data_card.inflate(state.data)
  if data then
    local palette, err = serialization.unserialize("{" .. data .. "}")
    if palette then
      state.palette=palette
      state.mode="info"
      return true
    else
      print(err)
    end
  else
    print(err)
  end
end

function handler.info()
  local data = read()
  local info, err = serialization.unserialize("{" .. data .. "}")
  if info then
    if #info == 3 then
      state.width, state.height, state.rate = table.unpack(info, 1, 3)
      if state.doaudio == "1" then
        state.mode = "stream"
      else 
        state.mode="audio"
      end
      return true
    else
      print("Wrong number of elements")
    end
  else
    print(err)
  end
end

function handler.audio()
  -- Send AUDIO
  socket.write("AUDIO")
  local data = read()
  if tonumber(data) > tape.getSize() then
    print("Tape Size Too Small! Use A Larger Tape!")
    socket.write("STOP")
    return false
  else
    if data == "404" then
      print("No .DFPWM Provided.")
    else
      print("Writing to Tape... please be patient.")
      socket.write("DO")
      fragment = 0
      while true do
        local data = read(2048)
        print("Frag No: "  .. fragment .. "| Size: " .. string.len(data))
        fragment = fragment + 1
          if string.find(data ,"AOK") then
            print("Breaking")
            break
      else
        tape.write(data)
        end
      end
    end
  end
  state.mode="stream"
  return true
end
function handler.stream()
  gpu.setResolution(state.width,state.height)
  print("Set tape at 0")
  tape.seek(-1000000000)
  tape.play()
  while true do
    socket.write("NXT")
    local data = read()
    if data == "FIN" then
        return true
    else
      -- Read Size packet
      local expectsize = data
      print(expectsize)
      local temptable = {}
      while true do
        state.data = read()
        local data, err = data_card.inflate(state.data)
        if data then
          table.insert(temptable,data)
        else
          print(err)
          break
        end
        if tonumber(string.len(table.concat(temptable))) >= tonumber(expectsize) then
          break
        end
      end
      temptable = string.split(tablestring,'|')
      heightcounter = 1
      widthcount = 1
      width = state.width + 1
      for x in ipairs(togpu) do
        print(state.palette[tonumber(x)])
        gpu.setForeground(state.palette[tonumber(x)])
        if x % width == 0 and x ~= 1 then
          heightcounter = heightcounter + 1
          widthcount = 1
          gpu.fill(1,1,widthcount,heightcounter," ")
        else
          gpu.fill(1,1,widthcount,heightcounter," ")
          widthcount = widthcount + 1
          
        end
      end
    end
    os.sleep(1/state.rate)
  end
end
while true do
  print(state.mode)
  if not handler[state.mode]() then
    break
  end
end