-- Manage filesystems according the the specifications defined at https://github.com/GlobalEmpire/OpenStandards/blob/master/Filesystems/OpenUPT.md and OpenFS.md
-- Currently Open Kernel only

local args = {...}

local openupt = require("openupt")

if #args < 1 or args[1] == "help" then
  error([[FSUtil (c) 2020 Ocawesome101. Licensed under the MIT license.
Usage: fsutil OPERATION ...
FSUtil will attempt to auto-detect unmanaged drives.
Available OPERATIONs are:
 format [mode=secure|fast]:           Format a disk with an OpenUPT partition table. If SECURE is specified, will zero the entire disk.
 mkpart START END LABEL:  Add a partition from sector START to sector END.
 delpart:                 Delete a partition.
 lspart:                  List the label, type, and GUID of all partitions on a drive.
]])
  return false
end

-- Default bootsector.
local boot_sector = [[local gpu, screen = component.list("gpu")(), component.list("screen")()
if gpu and screen then
  component.invoke(gpu, "bind", screen)
  component.invoke(gpu, "set", 1, 1, "Non-system disk or disk error. Press any key to reboot.")
  repeat
    local e = computer.pullSignal()
  until e == "key_down"
  computer.shutdown(true)
end
]]

print("Detecting unmanaged drives....")
local drives = {}
local drive = ""
for addr, ctype in component.list("drive") do
  if ctype == "drive" then
    table.insert(drives, addr)
  end
end

if #drives == 0 then
  return error("No unmanaged drives found")
end

if #drives == 1 then
  drive = component.proxy(drives[1])
end

if #drives > 1 then
  print("Choose a drive:")
  for i=1, #drives, 1 do
    print(tostring(i) .. ". " .. drives[i]:sub(1, 6))
  end
  local c
  repeat
    local e, _, id = event.pull()
    if e == "key_down" then c = tonumber(string.char(id)) end
  until c <= #drives
  drive = component.proxy(drives[c])
end

if args[1] == "format" then
  if args[2] and args[2] ~= "mode=secure" and args[2] ~= "mode=fast" then
    error("Unrecognized option " .. args[2])
    return false
  end
  print("WARNING: Formatting a disk will erase all currently stored data!")
  local inp = ""
  repeat
    write("Are you sure you want to continue? [y/N]: ")
    local e, id
    repeat
      e, _, id = event.pull()
    until e == "key_down"
    if e == "key_down" then
      inp = string.char(id)
      if inp:lower() == "n" then
        print("Operation canceled. Have a nice day.")
        return
      end
    end
    write("\n")
  until inp:lower() == "y"
  print("Formatting " .. drive.address:sub(1, 6))
  local zero = string.char(0):rep(512)
  if args[2] and args[2] == "mode=secure" then
    write("Zeroing drive. This might take a while...")
    for i=1, drive.getCapacity() / 512, 1 do
      if i % 8 == 0 then
        write(".")
      end
      drive.writeSector(i, zero)
    end
    print("done")
  end
  write("Writing boot sector...")
  drive.writeSector(1, boot_sector)
  print("done.")
elseif args[1] == "mkpart" then
  if not args[2] and args[3] then
    return error("Missing arguments. Run 'fsutil help' for help.")
  end
  print("Reading existing partition table")
  local ptable = drive.readSector(25)
  openupt.setPartitionTable(ptable)
  if openupt.partitionCount() == 8 then
    return error("The maximum supported number of partitions on volume " .. drive.address:sub(1,6) .. " has been reached.")
  end
  print("Creating partition")
  openupt.mkpart(args[2], args[3], args[4])
  drive.writeSector(25, openupt.rawPartitionTable())
  print("done.")
end
