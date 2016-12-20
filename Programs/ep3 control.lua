local component = require("component")
local dial = component.ep_dialling_device
dial.dial("3 3 3 3 3 3 3 3 3")
os.sleep(15)
dial.terminate()