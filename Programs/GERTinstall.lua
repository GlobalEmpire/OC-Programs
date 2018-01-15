--[[
GERTInstaller is an automated installer for the GERTi system. It can automatically install GERTi clients and GERTi servers.
Combined with the simple foxlib UI the system install is quick and painless. 
1) download and execute the raw program using wget. 
2) Press the button associated with the install you want, follow any prompts that appear.
3) Reboot the machine
See, simple as 1,2,3

Global Empire, TheBoxFox
]]--

local component = require "component"
local term = require "term"
local event = require "event"
local computer = require "computer"
local os = require "os"
local fs = require "filesystem"

local modem = component.modem
local w,h = term.getViewport()

--DON'T CHANGE
local foxlibURL = "https://raw.githubusercontent.com/TheBoxFox/OpenComputers/master/foxlib.lua"
local GERTiClient = "https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/GERTiClient.lua"
local GERTiServer = "https://raw.githubusercontent.com/GlobalEmpire/GERT/master/GERTi/GERTiMNC.lua"

--Let's make sure everything is here
if not(term or component or os or event or computer or modem) then
  error("Missing required system libraries.")
end

if not(fs.exists('/lib/foxlib.lua')) then
  flib = os.execute('wget '..foxlibURL..' /lib/foxlib.lua')
else 
  flib=true
end

if flib then 
  local foxlib = require "foxlib"
else
  error("Please install https://github.com/TheBoxFox/OpenComputers/blob/master/foxlib.lua")
end


local function drawControl()
term.setCursor(1,2)
  print("Thank you for using the GERT Installer. Please follow the prompts below to ensure you retrieve the proper installation of GERT. Press q to quit.")
  print("1) Client Installation (Surface) This option installs to a directory, you will have to require 'GERTi' to use it. ")
  print("2) Client Installation (Integrated) This option installs to the operating system. GERTi will become a system-wide library.")
  print("3) GERTi Router Installation. You should probably only do this if you know what you're doing.")
  print("4) Uninstall GERTi. Why you do this?")
end

local function Inst(num)
print(" ")
 if num == 1 then
   local g = os.execute('wget '..GERTiClient..' /home/GERTi.lua')
    if g then
      os.sleep(1)
      print("GERTi Installed to /home directory.")
      computer.shutdown(true)
    else
    error("Couldn't retrieve GERTi.lua from github.")
    end  
  
  elseif num == 2 then
   local g = os.execute('wget '..GERTiClient..' /lib/GERTi.lua')
    if g then
      os.sleep(1)
      print("GERTi Installed to /lib directory.")
     local f =  io.open('/boot/50_GERTi.lua','w')
      f:write("computer = require 'computer'\ncomputer.beep(700,.1)\n require 'GERTi' ")
      f:close()
      computer.shutdown(true)
    else
    error("Couldn't retrieve GERTi.lua from github.")
    end  
  elseif num == 3 then
   local g = os.execute('wget '..GERTiServer..' /boot/50_GERTiMNC.lua')
     if g then 
      computer.shutdown(true)
     else
      error("Couldn't download GERTiMNC from github.")
     end
  end
end

local function rmFile()
print("searching for GERTi install")
   if fs.exists("/lib/GERTi.lua") then
     print("Files located...")
     os.execute("rm /lib/GERTi.lua")
     os.execute("rm /boot/50_GERTi.lua")
     print("Files removed, rebooting")
     os.sleep(1)
     computer.shutdown(true)
   elseif fs.exists("/home/GERTi.lua") then 
      print("File located...")
      os.execute("rm /home/GERTi.lua")
      print("File removed. System reboot")
      os.sleep(1)
      computer.shutdown(true)
   elseif fs.exists("/boot/50_GERTiMNC.lua") or fs.exists("50_GERTi.lua") then
       print("Files located")
       os.execute("rm /boot/50_*")
       print("Files removed. System reboot")
       os.sleep(1)
       computer.shutdown(true)
   else
       print("No GERTi files found.")
   end
end

local function UIUpdate()

  while true do   
    local _,_,char,code = event.pull("key_up")
    if char == 113 and code == 16 then
      term.clear()
      break
    elseif char == 49 and code == 2 then
      Inst(1)
      break
    elseif char == 50 and code == 3 then
      Inst(2)
      break
    elseif char == 51 and code == 4 then 
      Inst(3)
      break  
    elseif char == 52 and code == 5 then
      rmFile()
      break
    end
  end
end

local function start()
  term.clear()
  foxlib.ui.setTitle("GERT Installer 0.6")
  drawControl()
  UIUpdate()
end


start()
