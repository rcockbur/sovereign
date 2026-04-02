-- core/log.lua
-- Ring buffer logger. Severity filtering, category tags, last 200 messages for overlay.
-- Usage: log:info("UNIT", "Unit %d claimed job %d", unit.id, job.id)

local BUFFER_SIZE = 200

local LEVEL_NAMES = { "ERROR", "WARN", "INFO", "DEBUG" }

local log = {
    -- Severity level constants
    OFF   = 0,
    ERROR = 1,
    WARN  = 2,
    INFO  = 3,
    DEBUG = 4,

    -- Active filter level. Messages above this level are dropped.
    level = 3,   -- INFO by default

    _buffer = {},
    _head   = 0,   -- index of the most recently written slot (0 = empty)
    _count  = 0,   -- total messages written, capped at BUFFER_SIZE for reads
}

local function write(self, severity, category, fmt, ...)
    if severity > self.level then return end

    local entry = {
        severity  = severity,
        label     = LEVEL_NAMES[severity],
        category  = category,
        message   = string.format(fmt, ...),
        timestamp = os.date("%H:%M:%S"),
    }

    self._head = (self._head % BUFFER_SIZE) + 1
    self._buffer[self._head] = entry
    if self._count < BUFFER_SIZE then
        self._count = self._count + 1
    end

    print(string.format("[%s] %s %s: %s",
        entry.timestamp, LEVEL_NAMES[severity], category, entry.message))
end

function log:error(category, fmt, ...)
    write(self, self.ERROR, category, fmt, ...)
end

function log:warn(category, fmt, ...)
    write(self, self.WARN, category, fmt, ...)
end

function log:info(category, fmt, ...)
    write(self, self.INFO, category, fmt, ...)
end

function log:debug(category, fmt, ...)
    write(self, self.DEBUG, category, fmt, ...)
end

--- Return the last n entries in chronological order (oldest first, newest last).
--- Returns an empty table if the buffer is empty.
function log:tail(n)
    n = math.min(n or 10, self._count)
    if n == 0 then return {} end

    local result = {}
    for i = n, 1, -1 do
        local idx = ((self._head - i) % BUFFER_SIZE) + 1
        result[n - i + 1] = self._buffer[idx]
    end
    return result
end

return log
