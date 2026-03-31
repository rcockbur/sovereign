-- src/core/time.lua
-- Owns the clock. Drives the tick. seconds_per_hour is the single pacing knob.

local Config = require("src.config.config")

local Time = {
    hour    = 6,   -- start at 6 AM
    day     = 1,
    season  = 1,   -- 1=Spring, 2=Summer, 3=Autumn, 4=Winter
    year    = 1,

    accumulator    = 0,
    total_hours    = 0,
    paused         = false,
    speed_multiplier = 1,
}

local SEASON_NAMES = { "Spring", "Summer", "Autumn", "Winter" }
local DAY_NAMES    = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }

function Time.getSeasonName()
    return SEASON_NAMES[Time.season]
end

function Time.getDayName()
    return DAY_NAMES[((Time.day - 1) % 7) + 1]
end

function Time.getTimeString()
    return string.format(
        "Year %d, %s, %s Day %d, %02d:00",
        Time.year, Time.getSeasonName(), Time.getDayName(), Time.day, Time.hour
    )
end

--- Advance the clock. Returns the number of hours that ticked this frame.
--- @param dt number  love.update delta time
--- @return number hours_ticked
function Time.update(dt)
    if Time.paused then return 0 end

    local seconds_per_hour = Config.seconds_per_hour / Time.speed_multiplier
    Time.accumulator = Time.accumulator + dt

    local hours_ticked = 0
    while Time.accumulator >= seconds_per_hour do
        Time.accumulator = Time.accumulator - seconds_per_hour
        hours_ticked = hours_ticked + 1
        Time.total_hours = Time.total_hours + 1

        Time.hour = Time.hour + 1
        if Time.hour >= Config.HOURS_PER_DAY then
            Time.hour = 0
            Time.day = Time.day + 1
            if Time.day > Config.DAYS_PER_SEASON then
                Time.day = 1
                Time.season = Time.season + 1
                if Time.season > Config.SEASONS_PER_YEAR then
                    Time.season = 1
                    Time.year = Time.year + 1
                end
            end
        end
    end

    return hours_ticked
end

return Time
