local component = require("component")
local dial = component.ep_dialling_device
local input = ""
while true do
    print("Enter number to dial. Must be at 1-9 digit number, with each digit separated by a space. (e.g. 1 2 3 4)")
    input = io.read
    dial.dial(tostring(input))
    os.sleep(15)
    dial.terminate()
    os.sleep(1)
end