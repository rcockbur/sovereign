-- core/save.lua
-- Serialization. Collects state from modules via :serialize(), writes a Lua
-- table literal to love.filesystem. Loads via love.filesystem.load().
-- Module serialize/deserialize are stubs until Phase 11 content is final.

local log      = require("core.log")
local time     = require("core.time")
local world    = require("core.world")
local units    = require("simulation.unit")
local jobqueue = require("simulation.jobqueue")
local dynasty  = require("simulation.dynasty")

local save = {}

local SAVE_FILE = "sovereign_save.lua"
local VERSION   = 1

-- ---------------------------------------------------------------------------
-- Lua table literal serializer
-- ---------------------------------------------------------------------------

--- Recursively convert a Lua value to a Lua-literal string.
--- Handles nil, boolean, number, string, and tables (no cycles or functions).
local function toLua(val, depth)
    local t = type(val)
    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return tostring(val)
    elseif t == "number" then
        return string.format("%.17g", val)
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "table" then
        local indent = string.rep("    ", depth)
        local inner  = string.rep("    ", depth + 1)
        local parts  = {}
        local n = #val
        -- Array part first (preserves order, avoids double-emitting keys)
        for i = 1, n do
            parts[#parts + 1] = inner .. toLua(val[i], depth + 1)
        end
        -- Hash part
        for k, v in pairs(val) do
            local is_array_key = type(k) == "number"
                                 and k >= 1 and k <= n
                                 and math.floor(k) == k
            if is_array_key == false then
                local key
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    key = k
                else
                    key = "[" .. toLua(k, 0) .. "]"
                end
                parts[#parts + 1] = inner .. key .. " = " .. toLua(v, depth + 1)
            end
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
    else
        error("save: cannot serialize type '" .. t .. "'")
    end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Collect state from all modules and write a save file to love.filesystem.
function save:write(filename)
    filename = filename or SAVE_FILE
    local data = {
        version  = VERSION,
        time     = time:serialize(),
        world    = world:serialize(),
        units    = units:serialize(),
        jobqueue = jobqueue:serialize(),
        dynasty  = dynasty:serialize(),
    }
    local str    = "return " .. toLua(data, 0) .. "\n"
    local ok, err = love.filesystem.write(filename, str)
    if ok == false then
        log:error("SAVE", "write failed (%s): %s", filename, tostring(err))
    else
        log:info("SAVE", "saved to %s", filename)
    end
end

--- Load a save file and distribute state to all modules.
--- Returns true on success, false if the file does not exist or fails to parse.
function save:read(filename)
    filename = filename or SAVE_FILE
    if love.filesystem.getInfo(filename) == nil then
        log:warn("SAVE", "no save file found: %s", filename)
        return false
    end
    local chunk, err = love.filesystem.load(filename)
    if chunk == nil then
        log:error("SAVE", "parse error in %s: %s", filename, tostring(err))
        return false
    end
    local data = chunk()
    if data.version ~= VERSION then
        log:warn("SAVE", "version mismatch (file=%d, expected=%d)",
            data.version or 0, VERSION)
    end
    time:deserialize(data.time         or {})
    world:deserialize(data.world       or {})
    units:deserialize(data.units       or {})
    jobqueue:deserialize(data.jobqueue or {})
    dynasty:deserialize(data.dynasty   or {})
    log:info("SAVE", "loaded %s", filename)
    return true
end

return save
