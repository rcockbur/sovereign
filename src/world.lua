local world = {}

local tile_size = 32
local map_width = 20
local map_height = 20

local tile_colors = {
    [0] = {0.2, 0.5, 0.2}, -- grass
    [1] = {0.6, 0.5, 0.3}, -- dirt
}

local map = {}

function world.init()
    for y = 1, map_height do
        map[y] = {}
        for x = 1, map_width do
            map[y][x] = 0 -- all grass for now
        end
    end
    -- dirt patch for testing
    map[5][5] = 1
    map[5][6] = 1
    map[6][5] = 1
end

function world.draw()
    for y = 1, map_height do
        for x = 1, map_width do
            local tile = map[y][x]
            local color = tile_colors[tile]
            love.graphics.setColor(color)
            love.graphics.rectangle(
                "fill",
                (x - 1) * tile_size,
                (y - 1) * tile_size,
                tile_size - 1,
                tile_size - 1
            )
        end
    end
end

return world