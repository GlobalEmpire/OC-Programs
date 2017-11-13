local gpu = component.list("gpu", true)()
gpu = component.proxy(gpu)
local screen = component.list("screen", true)()
gpu.bind(screen)

gpu.setResolution(30, 2)

local maxX, maxY = gpu.getResolution()
gpu.fill(1, 1, maxX, maxY, " ")
local curX, curY = 1, 1

function printf(msg)
    msg = tostring(msg)
    local strLen = string.len(msg)
    if msg == "\n" then
        curY = curY+1
        curX = 1
    elseif strLen + curX > maxX then
        gpu.set(curX, curY, string.sub(msg, 1, maxX-curX))
        gpu.set(1, curY+1, string.sub(msg, (maxX-curX)+1, strLen))
        curY = curY + 1
        curX = strLen
    else
        gpu.set(curX, curY, msg)
        curX = curX + strLen
    end
    
    if curY == maxY and curX == maxX or curY > maxY then
        gpu.copy(1, 2, maxX, maxY - 1, 0, -1)
        gpu.fill(1, maxY, maxX, 1, " ")
        curY = maxY
        curX = 1
    elseif curX == maxX then
        curY = curY + 1
        curX = 0
    end
end

while true do
    local results = {computer.pullSignal()}
    if results[1] == "key_down" then
        if results[3] == 13 then
            printf('\n')
        else
            printf(string.char(results[3]))
        end
    end
end
