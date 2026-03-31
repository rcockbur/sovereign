-- src/ui/camera.lua
-- Panning, zoom, screen-to-world coordinate conversion.

local Config = require("src.config.config")

local Camera = {
    x    = 0,     -- world pixel offset (top-left corner of viewport)
    y    = 0,
    zoom = 1.0,

    min_zoom = 0.25,
    max_zoom = 3.0,
    pan_speed = 500,  -- pixels per second (before zoom scaling)
}

function Camera.update(dt)
    local speed = Camera.pan_speed / Camera.zoom * dt

    if love.keyboard.isDown("w", "up")    then Camera.y = Camera.y - speed end
    if love.keyboard.isDown("s", "down")  then Camera.y = Camera.y + speed end
    if love.keyboard.isDown("a", "left")  then Camera.x = Camera.x - speed end
    if love.keyboard.isDown("d", "right") then Camera.x = Camera.x + speed end

    Camera.clamp()
end

function Camera.clamp()
    local world_px_w = Config.map_width  * Config.tile_size
    local world_px_h = Config.map_height * Config.tile_size
    local screen_w   = love.graphics.getWidth()  / Camera.zoom
    local screen_h   = love.graphics.getHeight() / Camera.zoom

    Camera.x = math.max(0, math.min(Camera.x, world_px_w - screen_w))
    Camera.y = math.max(0, math.min(Camera.y, world_px_h - screen_h))
end

function Camera.applyTransform()
    love.graphics.push()
    love.graphics.scale(Camera.zoom, Camera.zoom)
    love.graphics.translate(-Camera.x, -Camera.y)
end

function Camera.resetTransform()
    love.graphics.pop()
end

--- Convert screen pixel coordinates to world tile coordinates.
--- @param screen_x number
--- @param screen_y number
--- @return number tile_x, number tile_y
function Camera.screenToTile(screen_x, screen_y)
    local world_x = screen_x / Camera.zoom + Camera.x
    local world_y = screen_y / Camera.zoom + Camera.y
    local tile_x = math.floor(world_x / Config.tile_size) + 1
    local tile_y = math.floor(world_y / Config.tile_size) + 1
    return tile_x, tile_y
end

function Camera.onMouseWheel(wx, wy)
    local old_zoom = Camera.zoom
    Camera.zoom = Camera.zoom * (1 + wy * 0.1)
    Camera.zoom = math.max(Camera.min_zoom, math.min(Camera.max_zoom, Camera.zoom))

    -- Zoom toward mouse position
    local mx, my = love.mouse.getPosition()
    Camera.x = Camera.x + mx / old_zoom - mx / Camera.zoom
    Camera.y = Camera.y + my / old_zoom - my / Camera.zoom

    Camera.clamp()
end

return Camera
