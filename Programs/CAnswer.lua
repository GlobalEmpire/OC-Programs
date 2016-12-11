local component = require("component")
local term = require("term")

term.write("Greetings \n")

while true do
term.write("For more information about the server type 'info', server rules: 'rules', and to apply, type 'apply', to view my Patreon page, type 'patreon', all queries are case-sensitive, so please use all lower-case  \n", true)
local message = io.read()

if tostring(message)== "info" then
term.write("The server known as Yuon is a team oriented survival server where people are able to build and fight without too many restrictions. Amass huge piles of resources, and build the world's greatest automation? Yuon is the place for you! Enjoy building WMD's? Yuon is the place for you! (please consult the rules on griefing before rubble-izing people's places) Yuon is run by a group of benificent operators, and all are welcome to join (pursuant to following the rules) \n", true)
end

if tostring(message)== "rules" then
term.write("To view the rules, please feel free to go to https://goo.gl/V8XRYt \n")
end

if tostring(message)== "apply" then
term.write("To apply, please email Major General Relativity at majgenrelativity@gmail.com \n")
end

if tostring(message)== "patreon" then
term.write("Thank you for being interested in supporting me! My Patreon page is at www.patreon.com/MajGenR \n", true)
end