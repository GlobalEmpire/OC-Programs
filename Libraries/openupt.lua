-- OpenUPT (https://github.com/GlobalEmpire/OpenStandards/blob/master/Filesystems/OpenUPT.md) parsing and generally make-life-easier library. --

local struct = require("struct")

local openupt = {}

local ptable = setmetatable({}, { __index = table })

local zero = string.char(0)

function openupt.setPartitionTable(tableData)
  while #ptable > 0 do
    ptable:remove(1)
  end
  local p = setmetatable({}, { __index = table })
  for i=1, 512, 64 do
    local pstart, pend, fstype, pflags, guid, reserved, label = struct.unpack("<IIc8Ic8Ic32", tableData:sub(i, i + 64))
    if guid and guid ~= "" then
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
  return #ptable
end

function openupt.mkpart(start, end, type, flags, label)
  checkArg(1, start, "number")
  checkArg(2, end, "number")
  checkArg(3, type, "string", "nil")
  checkArg(4, flags, "number", "nil")
  checkArg(5, label, "string", "nil")
  local type = type:sub(1, 8) or ""
  local flags = flags or 
  while #type < 8 do
    type = type .. zero
  end
  if #ptable == 8 then
    return error("Too many partitions")
  end
  -- TODO: Flag parsing to get them in the right format (maybe?)
  -- also, it's currently up to the wrapper utility to verify that sectors are available. It would probably be better to have all partition management done in openUPT itself.
  ptable:insert({start, end, type, flags, label})
end

function openupt.delpart(guid) -- Delete a partition based on its GUID
  checkArg(1, guid, "string")
  for i=1, #ptable, 1 do
    if ptable[i][5] == guid then
      ptable:remove(i)
      return true
    end
  end
  return false
end

function openupt.rawPartitionTable()
  local r = ""
  for i=1, #ptable, 1 do
    r = r .. struct.pack("<IIc8Ic8Ic32", table.unpack(ptable[i]))
  end
  return r
end 
