<<<<<<< HEAD
function bootcode()
  -- Low level dofile implementation to read the rest of the OS.
  local bootfs = {}
  function bootfs.invoke(method, ...)
    return component.invoke(computer.getBootAddress(), method, ...)
  end
  function bootfs.open(file) return bootfs.invoke("open", file) end
  function bootfs.read(handle) return bootfs.invoke("read", handle, math.huge) end
  function bootfs.close(handle) return bootfs.invoke("close", handle) end
  function bootfs.inits(file) return ipairs(bootfs.invoke("list", "boot")) end
  function bootfs.isDirectory(path) return bootfs.invoke("isDirectory", path) end
  -- Custom low-level loadfile/dofile implementation reading from our bootfs.
  local function loadfile(file, mode, env)
    local handle, reason = bootfs.open(file)
    if not handle then
      error(reason)
    end
    local buffer = ""
    repeat
      local data, reason = bootfs.read(handle)
      if not data and reason then
        error(reason)
      end
      buffer = buffer .. (data or "")
    until not data
    bootfs.close(handle)
	if mode == nil then mode = "bt" end
    if env == nil then env = _G end
    return load(buffer, "=" .. file)
  end
  _G.loadfile = loadfile
end
bootcode()
local function dofile(file)
  local program, reason = loadfile(file)
  if program then
   bootcode = nil
   loadfile = nil
   dofile = nil
    local result = table.pack(pcall(program))
    if result[1] then
      return table.unpack(result, 2, result.n)
    else
      error(result[2], 3)
    end
  else
    error(reason, 3)
  end
end
dofile("boot")
=======
-- Temporarily using a modified version of OC bios.lua
computer.beep(1000, 0.2)
local component_invoke = component.invoke
function boot_invoke(address, method, ...)
  local result = table.pack(pcall(component_invoke, address, method, ...))
  if not result[1] then
    return nil, result[2]
  else
    return table.unpack(result, 2, result.n)
  end
end

-- backwards compatibility, may remove later
local eeprom = component.list("eeprom")()
computer.getBootAddress = function()
  return boot_invoke(eeprom, "getData")
end
computer.setBootAddress = function(address)
  return boot_invoke(eeprom, "setData", address)
end

do
  local screen = component.list("screen")()
  local gpu = component.list("gpu")()
  if gpu and screen then
    boot_invoke(gpu, "bind", screen)
  end
end
local function tryLoadFrom(address)
  local handle, reason = boot_invoke(address, "open", "/boot")
  if not handle then
    return nil, reason
  end
  local buffer = ""
  repeat
    local data, reason = boot_invoke(address, "read", handle, math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  boot_invoke(address, "close", handle)
  return load(buffer, "=init")
end
local init, reason
if computer.getBootAddress() then
  init, reason = tryLoadFrom(computer.getBootAddress())
end
if not init then
  computer.setBootAddress()
  for address in component.list("filesystem") do
    init, reason = tryLoadFrom(address)
    if init then
      computer.setBootAddress(address)
      break
    end
  end
end
if not init then
  error("no bootable medium found" .. (reason and (": " .. tostring(reason)) or ""), 0)
end
computer.beep(1000, 0.2)
init()
>>>>>>> a8826373409bdaa9a1601d29dcceb3f2026c79e1
