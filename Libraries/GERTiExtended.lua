--[[
GERTiExtended is a library built to expand the functionality of the GERT system, enabling multicasts and broadcasts to be sent
across multiple networks if a connection is able to be made. Current functions of this library are 
GERTiExtended.setNet() which takes a table of addresses and creates sockets for each.
GERTiExtended.Netcast() which takes data, and a selective list of addresses to broadcast to, if left empty this will default to all
GERTiExtended.getStreams() This command gets a list of all currently connected broadcast streams.
GERTiExtended.flush() will destroy all streams in the table, closing the connection on both sides.

Global Empire, TheBoxFox
]]--

local GERTi = require("GERTi") --Require our mother library 

--ONLY CHANGE THESE SETTINGS IF YOU KNOW WHAT YOU ARE DOING

local DEBUG = false
local logfile = "/GERTi/logs/GERTiExtended.log"

--Setup system tables.
local GERTiExtended = {}
local streams = {}
local connections = GERTi.getConnections()
local neighbors = GERTi.getNeighbors()




local function Log(str,flag)
 if DEBUG then
  local a = io.open(logfile,'a')
    a:write(os.clock().."["..flag.."]"..str..'\n')
   a:close()
 end
end

function GERTiExtended.setNet(tbl)

local connStat = {}
 if type(tbl) == "table" then
  for k,v in pairs(tbl)do
    if type(v) == "number" then
     local skt, err = GERTi.openSocket(v)

      if not(err) then 
        connStat[#connStat+1] = {v,skt}
      else
        connStat[#connStat+1]= {v,err}
        Log("Failed to establish connection with"..v,"CRITICAL")
      end 

    else
     
      connStat[#connStat+1] = {v,err}
      io.stderr:write("GERTi.setNet() requires one or more addresses.")
      Log("Invalid address"..v,"WARN")

    end 

  end 

  for k,v in pairs(connStat) do 
    streams[#streams+1] = connStat[k]
  
  end
 else
  io.stderr:write("GERTiExtended.setNet() expected table, got "..type(tbl))
  Log("GERTiExtended.setNet() Argument #1, expected table, got "..type(tbl))
 return connStat
end

function GERTiExtended.Netcast(data,peers)
  if type(peers) == ("table" or "nil") then  

    for k,v in pairs(peers or streams)do
      v[2]:write(data)
    end
  else
    Log("GERTiExtended.Netcast Argument #2, expected table got"..type(peers),"CRITICAL")
    io.stderr:write("GERTiExtended.Netcast Argument #2, expected table got "..type(peers))
  end
end

function GERTiExtended.getStreams()
  return streams
end

function GERTiExtended.flush()
  for k,v in pairs(streams) do
    v[2]:close() 
   table.remove(streams,k)
  Log("Flush triggered. Stream["..k.."] was dumped.","DEBUG")
  end
Log("Flush completed, remaining objects in table:"..#streams,"DEBUG")
end


Log("GERTiExtended has loaded.","DEBUG")

return GERTiExtended
