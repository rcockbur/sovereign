require("lldebugger").start()

local Config   = require("src.config.config")
local Time     = require("src.core.time")
local Registry = require("src.core.registry")
local World    = require("src.core.world")
local Unit     = require("src.simulation.unit")
local Camera   = require("src.ui.camera")
local Renderer = require("src.ui.renderer")

-- Living units list (separate from registry for iteration)
local units = {}

function love.load()
    love.window.setTitle("Sovereign")
    love.window.setMode(Config.window_width, Config.window_height, { resizable = true })

    -- Generate the world
    World.generate()

    -- Spawn starting units in the settlement half
    local max_x = math.floor(World.width / 2)
    for i = 1, Config.starting_unit_count do
        local x = math.random(5, max_x - 5)
        local y = math.random(5, World.height - 5)
        local tier = (i == 1) and Config.Tier.GENTRY or Config.Tier.SERF
        local unit = Unit.create(x, y, tier)

        if i == 1 then
            unit.is_leader = true
            unit.name = "Lord " .. unit.name
            unit.virtues.charisma = math.random(6, 10)
            unit.skills.combat = math.random(3, 6)
        end

        table.insert(units, unit)
    end

    -- Center camera on settlement
    Camera.x = 0
    Camera.y = (World.height * Config.tile_size / 2) - (Config.window_height / 2)
    Camera.clamp()
end

function love.update(dt)
    -- Time
    local hours_ticked = Time.update(dt)

    -- Camera
    Camera.update(dt)

    -- Unit wandering (temporary scaffolding)
    for _, unit in ipairs(units) do
        Unit.updateWander(unit, dt)
    end
end

function love.draw()
    -- World and units (camera space)
    Camera.applyTransform()
    Renderer.drawMap()
    Renderer.drawUnits(units)
    Camera.resetTransform()

    -- HUD (screen space)
    Renderer.drawHUD()
end

function love.wheelmoved(x, y)
    Camera.onMouseWheel(x, y)
end

function love.keypressed(key)
    if key == "space" then
        Time.paused = not Time.paused
    elseif key == "1" then
        Time.speed_multiplier = 1
    elseif key == "2" then
        Time.speed_multiplier = 2
    elseif key == "3" then
        Time.speed_multiplier = 5
    elseif key == "4" then
        Time.speed_multiplier = 10
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.resize(w, h)
    Camera.clamp()
end