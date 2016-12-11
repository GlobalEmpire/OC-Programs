local robot = require("robot")
local component = require("component")
local sides = require("sides")
local nav = component.navigation
local term = require("term")
local modem = component.modem
local event = require("event")

-- actual protocol table
local protocol = { ["forward"] = robot.forward,
["back"] = robot.back,
["left"] = robot.turnLeft,
["right"] = robot.turnRight,
["turnAround"] = robot.turnAround,
["goUp"] = robot.up,
["goDown"] = robot.down,
["swing"] = robot.swing,
["swingUp"] = robot.swingUp,
["swingDown"] = robot.swingDown,

}