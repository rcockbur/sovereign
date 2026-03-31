-- src/core/registry.lua
-- Global ID counter and entity lookup pool.
-- registry[id] returns a living unit or a memory. Relationship traversal
-- doesn't need to know if a target is alive or dead.

local Registry = {
    next_id  = 1,
    entities = {},   -- id -> unit or memory
}

--- Generate a new unique ID.
--- @return number
function Registry.nextId()
    local id = Registry.next_id
    Registry.next_id = Registry.next_id + 1
    return id
end

--- Register an entity (unit, memory, building, job, etc.) by its id.
--- @param entity table  must have an `id` field
function Registry.register(entity)
    assert(entity.id, "Registry.register: entity has no id")
    Registry.entities[entity.id] = entity
end

--- Remove an entity from the registry.
--- @param id number
function Registry.remove(id)
    Registry.entities[id] = nil
end

--- Look up an entity by id.
--- @param id number
--- @return table|nil
function Registry.get(id)
    return Registry.entities[id]
end

return Registry
