-- src/simulation/unit.lua
-- Owns unit state: virtues, skills, needs, mood, health, relationships, tier.
-- Also owns creation, death (conversion to memory), promotion/demotion.

local Config   = require("src.config.config")
local Registry = require("src.core.registry")
local World    = require("src.core.world")

local Unit = {}

local FIRST_NAMES = {
    "Aldric", "Bran", "Cedric", "Dunstan", "Edric",
    "Godwin", "Hild", "Isolde", "Leofric", "Mildred",
    "Oswin", "Rowena", "Sigebert", "Theda", "Wulfric",
    "Aelfreda", "Cynric", "Eadgyth", "Frithuric", "Gytha",
}

--- Create a new unit with default state.
--- @param x number  tile x
--- @param y number  tile y
--- @param tier number|nil  defaults to Tier.SERF
--- @return table unit
function Unit.create(x, y, tier)
    local unit = {
        id        = Registry.nextId(),
        name      = FIRST_NAMES[math.random(#FIRST_NAMES)],
        tier      = tier or Config.Tier.SERF,
        age       = math.random(16, 40),
        birth_day = 0,

        is_leader = false,
        is_regent = false,

        father_id  = nil,
        mother_id  = nil,
        child_ids  = {},
        spouse_id  = nil,
        friend_ids = {},
        enemy_ids  = {},

        virtues = {
            strength     = math.random(3, 8),
            intelligence = math.random(3, 8),
            dexterity    = math.random(3, 8),
            wisdom       = math.random(3, 8),
            constitution = math.random(3, 8),
            charisma     = math.random(3, 8),
        },

        skills = {
            woodcutting  = 0,
            farming      = 0,
            combat       = 0,
            construction = 0,
            medicine     = 0,
        },

        needs = {
            hunger       = 100,
            sleep        = 100,
            recreation   = 100,
            spirituality = 100,
        },

        mood            = 0,
        mood_modifiers  = {},
        health          = 100,
        health_modifiers = {},

        current_job_id  = nil,
        current_activity = "idle",

        -- Position (tile coordinates, but stored as floats for smooth movement)
        x = x,
        y = y,

        -- Wander state (temp for initial scaffolding)
        _wander_target_x = nil,
        _wander_target_y = nil,
        _wander_cooldown = 0,
    }

    Registry.register(unit)
    return unit
end

--- Convert a dead unit to a lightweight memory.
--- @param unit table
--- @param death_day number
--- @param death_cause string
--- @return table memory
function Unit.convertToMemory(unit, death_day, death_cause)
    local memory = {
        id          = unit.id,
        name        = unit.name,
        father_id   = unit.father_id,
        mother_id   = unit.mother_id,
        child_ids   = unit.child_ids,
        spouse_id   = unit.spouse_id,
        death_day   = death_day,
        death_cause = death_cause,
    }

    -- Replace the living unit with the memory in the registry
    Registry.register(memory)
    return memory
end

--- Wander behavior: pick a nearby tile and walk toward it.
--- This is temporary scaffolding to get visible unit movement.

local WANDER_SPEED = 2.0   -- tiles per second
local WANDER_RADIUS = 8    -- max tiles from current position
--- @param unit table
--- @param dt number  frame delta
function Unit.updateWander(unit, dt)
    -- Cooldown between wander decisions
    if unit._wander_cooldown > 0 then
        unit._wander_cooldown = unit._wander_cooldown - dt
    end

    -- Pick a new target if we don't have one or reached the current one
    if not unit._wander_target_x or unit._wander_cooldown <= 0 then
        local tx = unit.x + math.random(-WANDER_RADIUS, WANDER_RADIUS)
        local ty = unit.y + math.random(-WANDER_RADIUS, WANDER_RADIUS)

        -- Clamp to settlement half (don't wander into deep forest)
        local max_x = math.floor(World.width / 2)
        tx = math.max(1, math.min(max_x, tx))
        ty = math.max(1, math.min(World.height, ty))

        unit._wander_target_x = tx
        unit._wander_target_y = ty
        unit._wander_cooldown = math.random(2, 5)  -- seconds until next decision
    end

    -- Move toward target
    local dx = unit._wander_target_x - unit.x
    local dy = unit._wander_target_y - unit.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0.1 then
        local step = WANDER_SPEED * dt
        if step > dist then step = dist end
        unit.x = unit.x + (dx / dist) * step
        unit.y = unit.y + (dy / dist) * step
    else
        -- Arrived
        unit._wander_target_x = nil
        unit._wander_target_y = nil
    end
end

return Unit
