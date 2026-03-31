-- src/config/config.lua
-- All config tables. Game rules live here, not on entities.

local Tier     = { SERF = 1, FREEMAN = 2, GENTRY = 3 }
local Priority = { DISABLED = 0, LOW = 1, NORMAL = 2, HIGH = 3 }

local HOURS_PER_DAY    = 24
local DAYS_PER_SEASON  = 7
local SEASONS_PER_YEAR = 4
local HOURS_PER_SEASON = HOURS_PER_DAY * DAYS_PER_SEASON
local HOURS_PER_YEAR   = HOURS_PER_SEASON * SEASONS_PER_YEAR

local Config = {
    -- Enums / constants
    Tier     = Tier,
    Priority = Priority,

    HOURS_PER_DAY    = HOURS_PER_DAY,
    DAYS_PER_SEASON  = DAYS_PER_SEASON,
    SEASONS_PER_YEAR = SEASONS_PER_YEAR,
    HOURS_PER_SEASON = HOURS_PER_SEASON,
    HOURS_PER_YEAR   = HOURS_PER_YEAR,

    -- Time pacing
    seconds_per_hour = 2.0,

    -- Map
    map_width  = 200,
    map_height = 100,
    tile_size  = 32,

    -- Window
    window_width  = 1280,
    window_height = 720,

    -- Starting units
    starting_unit_count = 8,

    -- Needs: keyed by tier, then by need name
    needs = {
        [Tier.SERF] = {
            hunger       = { drain_per_hour = 2, mood_threshold = 30, mood_penalty = -10 },
            sleep        = { drain_per_hour = 2, mood_threshold = 30, mood_penalty = -10 },
            recreation   = { drain_per_hour = 1, mood_threshold = 20, mood_penalty = -5  },
            spirituality = { drain_per_hour = 1, mood_threshold = 20, mood_penalty = -5  },
        },
        [Tier.FREEMAN] = {
            hunger       = { drain_per_hour = 3, mood_threshold = 50, mood_penalty = -15 },
            sleep        = { drain_per_hour = 3, mood_threshold = 50, mood_penalty = -15 },
            recreation   = { drain_per_hour = 2, mood_threshold = 40, mood_penalty = -10 },
            spirituality = { drain_per_hour = 2, mood_threshold = 40, mood_penalty = -10 },
        },
        [Tier.GENTRY] = {
            hunger       = { drain_per_hour = 4, mood_threshold = 60, mood_penalty = -20 },
            sleep        = { drain_per_hour = 4, mood_threshold = 60, mood_penalty = -20 },
            recreation   = { drain_per_hour = 3, mood_threshold = 50, mood_penalty = -15 },
            spirituality = { drain_per_hour = 3, mood_threshold = 50, mood_penalty = -15 },
        },
    },

    -- Jobs
    jobs = {
        chop_tree = { skill = "woodcutting",  min_skill = 0, min_tier = Tier.SERF,    work_hours = 8   },
        build     = { skill = "construction", min_skill = 0, min_tier = Tier.SERF,    work_hours = nil  },
        harvest   = { skill = "farming",      min_skill = 0, min_tier = Tier.SERF,    work_hours = 4   },
        heal      = { skill = "medicine",     min_skill = 5, min_tier = Tier.FREEMAN, work_hours = 2   },
    },

    -- Injuries
    injuries = {
        bruised = { initial_damage = 10, recovery_per_hour = 0.5  },
        wounded = { initial_damage = 30, recovery_per_hour = 0.2  },
        maimed  = { initial_damage = 50, recovery_per_hour = 0.05 },
    },

    -- Illnesses
    illnesses = {
        cold        = { damage_per_hour = 0.1, recovery_chance = 0.08,  recovery_per_hour = 0.4  },
        flu         = { damage_per_hour = 0.2, recovery_chance = 0.08,  recovery_per_hour = 0.4  },
        the_flux    = { damage_per_hour = 0.4, recovery_chance = 0.10,  recovery_per_hour = 0.3  },
        consumption = { damage_per_hour = 0.1, recovery_chance = 0.005, recovery_per_hour = 0.2  },
        pox         = { damage_per_hour = 0.3, recovery_chance = 0.02,  recovery_per_hour = 0.2  },
        pestilence  = { damage_per_hour = 0.5, recovery_chance = 0.01,  recovery_per_hour = 0.15 },
    },

    -- Malnourished
    malnourished = { damage_per_hour = 0.3, recovery_per_hour = 0.5 },

    -- Buildings
    buildings = {
        cottage = { width = 3, height = 3, build_cost = 80,  bed_count = 4, housing_tier = Tier.SERF    },
        house   = { width = 4, height = 3, build_cost = 150, bed_count = 6, housing_tier = Tier.FREEMAN },
        manor   = { width = 5, height = 4, build_cost = 300, bed_count = 8, housing_tier = Tier.GENTRY  },
    },

    -- Resource spawning by forest depth
    resource_spawns = {
        timber     = { min_depth = 0.0  },
        wildlife   = { min_depth = 0.0  },
        rare_herbs = { min_depth = 0.01 },
        alchemical = { min_depth = 0.6  },
        artifacts  = { min_depth = 0.8  },
    },

    -- Mood thresholds
    mood_thresholds = {
        inspired   = 80,
        content    = 40,
        sad        = 20,
        distraught = 0,
        -- below 0 = defiant
    },
}

return Config
