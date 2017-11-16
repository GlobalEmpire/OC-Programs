local shell = {}

local gpu = component.list("gpu", true)()
gpu = component.proxy(gpu)
local screen = component.list("screen", true)()
gpu.bind(screen)

local maxX, maxY = gpu.getResolution()
gpu.fill(1, 1, maxX, maxY, " ")
local curX, curY = 1, 1

function printf(msg)
    msg = tostring(msg)
    for i = 1, unicode.len(msg) do
        local char = ""
        char = unicode.sub(msg, i, i)
        if char == "\n" then
            curX, curY = 1, curY+1
        else
            gpu.set(curX, curY, char)
            curX = curX + 1
        end
        if curX > maxX then
            curY = curY + 1
            curX = 1
        end
        
        if curY == maxY and curX == maxX or curY > maxY then
            gpu.copy(1, 2, maxX, maxY - 1, 0, -1)
            gpu.fill(1, maxY, maxX, 1, " ")
            curY = maxY
            curX = 1
        elseif curX == maxX then
            curY = curY + 1
            curX = 1
        end
    end
end

function readline()
    local s = ""
    while true do
        local results = {computer.pullSignal()}
        if results[1] == "key_down" then
            local char = results[3]
            if results[3] == 13 then
                printf('\n')
                coroutine.yield()
                return s
            elseif results[3] == 8 then
                if s:len() > 0 then
                    gpu.set(curX - 1, curY, " ")
                    curX = curX - 1
                    s = s:sub(1, -2)
                end
            elseif char > 31 and char < 127 then
                printf(string.char(results[3]))
                s = s .. string.char(results[3])
            end
        end
    end
end

while true do
    printf('> ')
    local com = readline()
    if not com then break end
    printf(com .. "\n")
end
