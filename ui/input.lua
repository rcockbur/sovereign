-- ui/input.lua
-- Input abstraction. Game code references actions, not physical keys.
-- Supports future remapping without touching game logic.

local input = {}

-- Action → key bindings
local bindings = {
    -- Camera
    pan_left      = { "a", "left"  },
    pan_right     = { "d", "right" },
    pan_up        = { "w", "up"    },
    pan_down      = { "s", "down"  },

    -- Simulation speed
    speed_1       = { "1" },
    speed_2       = { "2" },
    speed_3       = { "3" },
    speed_4       = { "4" },

    -- Pause
    pause         = { "space" },

    -- Dev overlay
    dev_overlay   = { "f3" },

    -- Unit commands (stubs — wired in Phase 11)
    draft_toggle  = { "g" },
}

--- Returns true if any key bound to the action is currently held.
function input:isAction(action)
    local keys = bindings[action]
    if keys == nil then return false end
    for i = 1, #keys do
        if love.keyboard.isDown(keys[i]) then
            return true
        end
    end
    return false
end

--- Returns true if the action was just pressed (use in keypressed callback).
function input:isActionPressed(action, key)
    local keys = bindings[action]
    if keys == nil then return false end
    for i = 1, #keys do
        if keys[i] == key then
            return true
        end
    end
    return false
end

--- Returns true if the mouse button matches the named action.
--- button: 1 = left, 2 = right
function input:isMouseAction(action, button)
    if action == "select"         then return button == 1 end
    if action == "context_action" then return button == 2 end
    return false
end

return input
