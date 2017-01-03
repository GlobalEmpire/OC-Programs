--Identical to the normal controller but with a lower screen resolution
dofile( "/usr/lib/table-save.lua" )

local comp = require("component")
local dials = comp.list("ep_dialling_device")
API = require("button_api")
local event = require("event")
local term = require("term")
local gpu = comp.gpu
local adresses = comp.list("screen")
local screen = {}

term.clear()
print("Select touchscreen:")
local loop_tracker = 1
for adress in adresses do
    screen[loop_tracker] = adress
    print("["..loop_tracker.."]: "..adress)
    loop_tracker = loop_tracker + 1
end
local primaryScreen = screen[tonumber(term.read())]
term.clear()
print("Select screen with keyboard:")
for k,v in pairs(screen) do
    print("["..k.."]: "..v)
end
local secondaryScreen = screen[tonumber(term.read())]
term.clear()
gpu.bind(primaryScreen)
gpu.setResolution(80, 25)

function save_dests(destinations)
    assert( table.save( destinations, "destinations.lua" ) == nil )
end

function load_dests()
    local dests, err = table.load( "destinations.lua" )
    if err == nil then
        return dests
    end
    return {}
end

local destinations = load_dests()
local dests_amount = 0
for _,_ in pairs(destinations) do
    dests_amount = dests_amount + 1
end

local dest_length = 0
local two_digits = false
local page = 0

function API.fillTable()
    API.clear()
    API.clearTable()
    if page == 0 then
        API.heading("Portal Control")
        API.setTable("Exit", cmd_exit, nil, 70,78,2,4)
        API.setTable("Add", cmd_add_dest, nil, 70,78,22,24)
        if next(destinations) ~= nil then
            for k,v in pairs(destinations) do
                API.setTable(v["name"], cmd_tp, v, 15,65,7 + (k-1)*2,7.5 + (k-1)*2)
                API.setTable("Del "..k, cmd_delete_dest, k, 67,70,7 + (k-1)*2,7.5 + (k-1)*2)
            end
            API.label(1, 25, "Available Dests: "..dests_amount)
        else
            API.label(30, 11, "No Destinations available")
        end
    elseif page == 1 then
        API.heading("Enter Destination UID")
        API.label(5, 20, "UID: ")
        for i = 0, 26 do
            API.setTable(tostring(i), cmd_entered_char, tostring(i), 5 + i*8 - math.floor(i/9) * 72, 11 + i*8  - math.floor(i/9) * 72, 3 + math.floor(i/9) * 4, 5 + math.floor(i/9) * 4)
        end

        API.setTable(" ", cmd_entered_char, " ", 41,51,20,22)
        API.setTable("Delete", cmd_delete, nil, 53,63,20,22)
        API.setTable("Done", cmd_done, nil, 65,76,20,22)
    end
    API.screen()
end

function getClick()
    local _, _, x, y = event.pull(1,touch)
    if x == nil or y == nil then
        local h, w = gpu.getResolution()
        gpu.set(h, w, ".")
        gpu.set(h, w, " ")
    else
        API.checkxy(x,y)
    end
end

function cmd_exit()
    API.clear()
    term.clear()
    gpu.bind(secondaryScreen)
    gpu.setResolution(80, 25)
    os.exit()
end

function cmd_delete_dest(dest_key)
    API.flash("Del "..dest_key, 0.2)
    if destinations[dest_key + 1] == nil then
        destinations[dest_key] = nil
    else
        destinations[dest_key] = destinations[dest_key + 1]
        destinations[dest_key + 1] = nil
    end
    save_dests(destinations)
    API.fillTable()
end

function cmd_tp(destination)
    API.toggleButton(destination["name"])
    for adress in dials do
        local proxy = comp.proxy(adress)
        proxy.dial(destination["uid"])
    end
    os.sleep(5)
    for adress in dials do
        local proxy = comp.proxy(adress)
        proxy.terminate()
    end
    API.toggleButton(destination["name"])
end

function cmd_add_dest()
    page = 1
    dests_amount = dests_amount + 1
    destinations[dests_amount] = {}
    destinations[dests_amount]["uid"] = ""
    destinations[dests_amount]["name"] = ""
    dest_length = 0
    two_digits = false
    API.fillTable()
end

function cmd_entered_char(char)
    API.flash(char, 0.2)
    if dest_length < 9 then
        if string.len(char) < 2 then
            two_digits = false
        else
            two_digits = true
        end
        if dest_length ~= 0 then
            destinations[dests_amount]["uid"] = destinations[dests_amount]["uid"].." "..char
        else
            destinations[dests_amount]["uid"] = tostring(char)
        end

        dest_length = dest_length + 1
    else
        API.label(5, 21, "UID always contains 9 glyphs!")
    end
    API.label(5, 20, "UID: "..destinations[dests_amount]["uid"])
end

function cmd_done()
    API.flash("Done", 0.2)
    if dest_length == 9 then
        API.clearTable()
        API.label(20, 10, "!Enter name for new destination on screen with keyboard!")
        gpu.bind(secondaryScreen)
        gpu.setResolution(80, 25)
        API.clearTable()
        API.heading("Enter Name for: "..destinations[dests_amount]["uid"])
        while true do
            local _, char, code, _ = event.pull("key_down")
            if code == 8 or char == 0 then
                destinations[dests_amount]["name"] = string.sub(destinations[dests_amount]["name"], 1, #destinations[dests_amount]["name"]-1)
            elseif code == 13 then
                term.clear()
                gpu.bind(primaryScreen)
                gpu.setResolution(80, 25)
                save_dests(destinations)
                page = 0
                API.fillTable()
                break
            elseif #destinations[dests_amount ]["name"] <=30 then
                destinations[dests_amount]["name"] = destinations[dests_amount]["name"] .. string.char(code)
            end
            API.label(25, 10, destinations[dests_amount]["name"])
            API.label(25, 20, "Press enter when finished")
        end
    else
        API.label(5, 21, "UID always contains 9 glyphs!")
    end
end

function cmd_delete()
    API.flash("Delete", 0.2)
    if dest_length ~= 0 and not two_digits then
        destinations[dests_amount ]["uid"] = destinations[dests_amount]["uid"]:sub(2, -2)
        dest_length = dest_length - 1
    elseif dest_length ~= 0 and two_digits then
        destinations[dests_amount]["uid"] = destinations[dests_amount]["uid"]:sub(3, -2)
        dest_length = dest_length - 1
    end
    API.label(5, 20, "UID: "..destinations[dests_amount]["uid"])
end


term.setCursorBlink(false)
API.clear()
API.fillTable()

while true do
    getClick()
end