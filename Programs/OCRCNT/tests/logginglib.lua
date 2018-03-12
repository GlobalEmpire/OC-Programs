---
--- Created by Ristelle.
--- DateTime: 12/3/2018 2:25 PM
---
local component = require("component")
function info(strings)
    local number, is_palette = component.gpu.getForeground()
    if is_palette == true then
        number = component.gpu.getPaletteColor(number)
    end
    component.gpu.setForeground(0x787878)

end