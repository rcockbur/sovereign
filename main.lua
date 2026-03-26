require("lldebugger").start()

local time = require("src/time")
local world = require("src/world")

function love.load()
    world.init()
    time.init()
end

function love.update(dt)
    time.update(dt)
end

function love.draw()
    world.draw()
    time.draw()
end