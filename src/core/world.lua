-- src/core/world.lua
-- Owns the tile grid, buildings, resource nodes, forest depth map.
-- Posts jobs to the queue when the world needs work done.

local Config   = require("src.config.config")
local Registry = require("src.core.registry")

local World = {
    width     = 0,
    height    = 0,
    tiles     = {},
    buildings = {},
    resources = {},
}

--- Generate the tile grid. Settlement on the left, forest on the right.
--- Forest depth is 0.0 on the left half, then increases linearly to 1.0
--- at the far right edge.
function World.generate()
    World.width  = Config.map_width
    World.height = Config.map_height
    World.tiles  = {}

    local midpoint = math.floor(World.width / 2)

    for x = 1, World.width do
        World.tiles[x] = {}
        for y = 1, World.height do
            local depth = 0.0
            if x > midpoint then
                depth = (x - midpoint) / (World.width - midpoint)
            end

            World.tiles[x][y] = {
                terrain      = depth > 0 and "forest" or "grass",
                building_id  = nil,
                resource     = nil,
                forest_depth = depth,
            }
        end
    end
end

--- Get forest danger at a tile (depth squared).
--- @param x number
--- @param y number
--- @return number
function World.getForestDanger(x, y)
    local tile = World.getTile(x, y)
    if not tile then return 0 end
    return tile.forest_depth * tile.forest_depth
end

--- Get a tile, or nil if out of bounds.
--- @param x number
--- @param y number
--- @return table|nil
function World.getTile(x, y)
    if x < 1 or x > World.width or y < 1 or y > World.height then
        return nil
    end
    return World.tiles[x][y]
end

--- Check if a tile position is walkable.
--- @param x number
--- @param y number
--- @return boolean
function World.isWalkable(x, y)
    local tile = World.getTile(x, y)
    if not tile then return false end
    -- For now, all tiles are walkable. Buildings will block later.
    return tile.building_id == nil
end

return World
