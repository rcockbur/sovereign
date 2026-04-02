-- core/registry.lua
-- Global entity lookup. registry[id] returns any entity (unit, memory, building, job).
-- Single incrementing ID counter shared across all entity types.

local registry = {
    _next_id = 1,
}

--- Allocate and return a new unique ID.
function registry:nextId()
    local id = self._next_id
    self._next_id = self._next_id + 1
    return id
end

--- Insert an entity. Entity must have an `id` field.
function registry:insert(entity)
    self[entity.id] = entity
end

--- Remove an entity from the registry.
function registry:remove(id)
    self[id] = nil
end

--- Clear all entity entries and reset the ID counter. Called on new game / quit-to-menu.
function registry:reset()
    for k in pairs(self) do
        if type(k) == "number" then
            self[k] = nil
        end
    end
    self._next_id = 1
end

return registry
