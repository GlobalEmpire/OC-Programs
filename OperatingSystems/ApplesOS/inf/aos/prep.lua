-- Handles initialisation of the system 
local loadfile = ... -- Sets the loadfile variable to the loadfile function passed here

_G._OSVERSION = "ApplesOS Alpha 1" -- Current OS version

-- Report boot progress
local gpu = component.list("gpu", true)()
local screen = component.list("screen", true)()

local x,y
if gpu and screen then
    gpu = component.proxy(gpu)
    gpu.bind(screen)
    x,y = gpu.maxResolution()
    gpu.setResolution(x,y)
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, x, y, " ")
end
local curY = 1

local function display(file)
    if gpu and screen then
        msg = os.date("%H:%M:%S") .. " > " .. file
        gpu.set(1, curY, msg)
        if curY == y then
            gpu.copy(1, 2, x, y - 1, 0, -1)
            gpu.fill(1, x, y, 1, " ")
        else
            curY = curY + 1
        end
    end
end

local function load(file)
    display(file)
    return loadfile(file)
end

display("Booting " .. _G._OSVERSION .. "...")

local function dofile(file)
    local app, reason = load(file)
    if app then
        local result = table.pack(pcall(app))
        if result[1] then
            return table.unpack(result, 2, result.n)
        else
            error(result[2])
        end
    else
        error(reason)
    end
end

-- Init sys
