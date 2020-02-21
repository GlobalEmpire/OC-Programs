-- OpenUPT (https://github.com/GlobalEmpire/OpenStandards/blob/master/Filesystems/OpenUPT.md) parsing and generally make-life-easier library. --

local openupt = {}

if _VERSION == "Lua 5.2" then
  error("Lua 5.2 is unsupported. Please use Lua 5.3 instead.")
  return false
end

local ptable = setmetatable({}, { __index = table })

local zero = string.char(0)

local function r(n, n2)
  return tostring(string.char(math.random(n,n2)))
end

local function randomGUID()
  local g = table.concat({
    r(0,255), r(0,255), r(0,255), r(0,255),
    r(0,255), r(0,255), r(0,255), r(0,255)
  }, "")
  return g
end

function openupt.setPartitionTable(tableData)
  while #ptable > 0 do
    ptable:remove(1)
  end
  local p = setmetatable({}, { __index = table })
  for i=1, 512, 64 do
    local pstart, pend, fstype, pflags, guid, reserved, label = string.unpack("<IIc8Ic8Ic32", tableData:sub(i, i + 64))
    if guid and guid ~= "" and guid:sub(1, 1) ~= " " and string.byte(guid:sub(1, 1)) ~= 0 then
      ptable:insert({pstart, pend, fstype, pflags, guid, reserved, label})
    end
  end
end

function openupt.partitions() -- Return some info about partitions
  local rtn = {}
  for i=1, #ptable, 1 do
    table.insert(rtn, {guid = ptable[i][5], fstype = ptable[i][3], size = (ptable[i][1] + ptable[i][2]) * 512, label = ptable[i][7]})
  end
  return rtn
end

function openupt.partitionCount()
  return #openupt.partitions()
end

function openupt.mkpart(pstart, pend, ptype, flags, label)
  checkArg(1, pstart, "number")
  checkArg(2, pend, "number")
  checkArg(3, ptype, "string", "nil")
  checkArg(4, flags, "number", "nil")
  checkArg(5, label, "string", "nil")
  local ptype, label = ptype or zero:rep(8), label or zero:rep(32)
  local ptype = ptype:sub(1, 8)
  local flags = flags or 0x00000001
  local ptype = ptype or zero:rep(1, 8)
  while #ptype < 8 do
    ptype = ptype .. zero
  end
  while #label < 32 do
    label = label .. zero
  end
  if #ptable == 8 then
    return error("Too many partitions")
  end
  if pstart < 33 then
    pstart = 33
  end
  -- TODO: Flag parsing to get them in the right format (maybe?)
  -- also, it's currently up to the wrapper utility to verify that sectors are available. It would probably be better to have all partition management done in openUPT itself.
  ptable:insert({pstart, pend, ptype, flags, randomGUID(), 0x00000000, label})
end

function openupt.delpart(guid) -- Delete a partition based on its GUID
  checkArg(1, guid, "string")
  for i=1, #ptable, 1 do
    if ptable[i][5] == guid then
      table.remove(ptable, i)
      return true
    end
  end
  return false
end

function openupt.rawPartitionTable()
  local r = ""
  for i=1, #ptable, 1 do
    r = r .. string.pack("<IIc8Ic8Ic32", table.unpack(ptable[i]))
  end
  local z = string.char(0)
  while #r < 512 do
    r = r .. z
  end
  return r
end 

return openupt
