-- src/ui/renderer.lua
-- Draws the tile map, units, and HUD.

local Config = require("src.config.config")
local Camera = require("src.ui.camera")
local World  = require("src.core.world")
local Time   = require("src.core.time")

local Renderer = {}

-- Color palette
local COLORS = {
    grass       = { 0.35, 0.65, 0.25 },
    forest_base = { 0.15, 0.45, 0.12 },
    forest_deep = { 0.05, 0.20, 0.05 },
    grid_line   = { 0, 0, 0, 0.08 },
    unit_body   = { 0.85, 0.75, 0.55 },
    unit_outline = { 0.3, 0.2, 0.1 },
    hud_bg      = { 0, 0, 0, 0.6 },
    hud_text    = { 1, 1, 1 },
}

--- Lerp between two colors based on t (0-1).
local function lerpColor(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
    }
end

--- Determine which tiles are visible in the current viewport.
--- @return number start_x, number start_y, number end_x, number end_y
local function getVisibleTileRange()
    local ts = Config.tile_size
    local screen_w = love.graphics.getWidth()  / Camera.zoom
    local screen_h = love.graphics.getHeight() / Camera.zoom

    local start_x = math.max(1, math.floor(Camera.x / ts))
    local start_y = math.max(1, math.floor(Camera.y / ts))
    local end_x   = math.min(World.width,  math.ceil((Camera.x + screen_w) / ts) + 1)
    local end_y   = math.min(World.height, math.ceil((Camera.y + screen_h) / ts) + 1)

    return start_x, start_y, end_x, end_y
end

function Renderer.drawMap()
    local ts = Config.tile_size
    local sx, sy, ex, ey = getVisibleTileRange()

    for x = sx, ex do
        for y = sy, ey do
            local tile = World.tiles[x] and World.tiles[x][y]
            if tile then
                local color
                if tile.forest_depth > 0 then
                    color = lerpColor(COLORS.forest_base, COLORS.forest_deep, tile.forest_depth)
                else
                    color = COLORS.grass
                end

                love.graphics.setColor(color)
                love.graphics.rectangle("fill",
                    (x - 1) * ts, (y - 1) * ts, ts, ts)
            end
        end
    end

    -- Grid lines (only at sufficient zoom)
    if Camera.zoom >= 0.75 then
        love.graphics.setColor(COLORS.grid_line)
        for x = sx, ex do
            love.graphics.line(
                (x - 1) * ts, (sy - 1) * ts,
                (x - 1) * ts, ey * ts)
        end
        for y = sy, ey do
            love.graphics.line(
                (sx - 1) * ts, (y - 1) * ts,
                ex * ts,       (y - 1) * ts)
        end
    end
end

function Renderer.drawUnits(units)
    local ts = Config.tile_size
    local radius = ts * 0.35

    for _, unit in ipairs(units) do
        local px = (unit.x - 0.5) * ts
        local py = (unit.y - 0.5) * ts

        -- Body
        love.graphics.setColor(COLORS.unit_body)
        love.graphics.circle("fill", px, py, radius)

        -- Outline
        love.graphics.setColor(COLORS.unit_outline)
        love.graphics.circle("line", px, py, radius)

        -- Name label (only at close zoom)
        if Camera.zoom >= 1.0 then
            love.graphics.setColor(1, 1, 1)
            local font = love.graphics.getFont()
            local text_w = font:getWidth(unit.name)
            love.graphics.print(unit.name, px - text_w / 2, py - radius - 14)
        end
    end
end

function Renderer.drawHUD()
    love.graphics.setColor(COLORS.hud_bg)
    love.graphics.rectangle("fill", 0, 0, 420, 30)

    love.graphics.setColor(COLORS.hud_text)
    love.graphics.print(Time.getTimeString(), 8, 7)

    -- Speed indicator
    local speed_text = Time.paused and "PAUSED" or (Time.speed_multiplier .. "x")
    love.graphics.print(speed_text, 370, 7)
end

return Renderer
