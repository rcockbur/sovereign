local time = {}

local seconds_per_hour = 1
local elapsed
local hour
local day
local season
local year

local hour_names = { "12:00 AM", "1:00 AM", "2:00 AM", "3:00 AM", "4:00 AM", "5:00 AM", "6:00 AM", "7:00 AM", "8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM", "10:00 PM", "11:00 PM" }
local day_names = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local season_names = { "Spring", "Summer", "Autumn", "Winter" }
local hours_per_day = 24
local days_per_season = 7

function time.init()
    elapsed = 0
    hour = 1
    day = 1
    season = 1
    year = 1
end

function time.update(dt)
    elapsed = elapsed + dt
    if elapsed >= seconds_per_hour then
        elapsed = elapsed - seconds_per_hour
        hour = hour + 1
        if hour >= hours_per_day then
            hour = 0
            day = day + 1
            if day > days_per_season then
                day = 1
                season = season + 1
                if season > 4 then
                    season = 1
                    year = year + 1
                end
            end
        end
    end
end

function time.draw()
    local label = string.format("Year %d — %s — %s — %s", year, season_names[season], day_names[day], hour_names[hour])
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(label, 10, 10)
end

return time