-- core/gamestate.lua
-- Stack-based game state machine. Love2D callbacks delegate to the current state.
-- Each state is a table with optional hooks: enter, exit, update(dt), draw,
-- keypressed(key), mousepressed(x, y, button), wheelmoved(x, y), resize(w, h).

local log = require("core.log")

local gamestate = {
    _current = nil,
    _stack   = {},
}

-- State tables (hooks populated by later phases)
gamestate.loading   = { name = "loading"   }
gamestate.main_menu = { name = "main_menu" }
gamestate.playing   = { name = "playing"   }

--- Flat transition: exit the current state, enter the new one.
function gamestate:switch(state)
    local from = self._current and self._current.name or "nil"
    local to   = state and state.name or "nil"
    log:info("STATE", "switch: %s -> %s", from, to)

    if self._current and self._current.exit then
        self._current:exit()
    end
    self._current = state
    if self._current and self._current.enter then
        self._current:enter()
    end
end

--- Push a modal state on top of the current one (reserved for future overlays).
function gamestate:push(state)
    if self._current then
        table.insert(self._stack, self._current)
    end
    self._current = state
    if self._current and self._current.enter then
        self._current:enter()
    end
end

--- Pop the top state and resume the one below.
function gamestate:pop()
    if self._current and self._current.exit then
        self._current:exit()
    end
    self._current = table.remove(self._stack)
end

-- Love2D callback delegation

function gamestate:update(dt)
    if self._current and self._current.update then
        self._current:update(dt)
    end
end

function gamestate:draw()
    if self._current and self._current.draw then
        self._current:draw()
    end
end

function gamestate:keypressed(key)
    if self._current and self._current.keypressed then
        self._current:keypressed(key)
    end
end

function gamestate:mousepressed(x, y, button)
    if self._current and self._current.mousepressed then
        self._current:mousepressed(x, y, button)
    end
end

function gamestate:wheelmoved(x, y)
    if self._current and self._current.wheelmoved then
        self._current:wheelmoved(x, y)
    end
end

function gamestate:resize(w, h)
    if self._current and self._current.resize then
        self._current:resize(w, h)
    end
end

return gamestate
