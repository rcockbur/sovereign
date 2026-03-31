# Sovereign — CLAUDE.md
*Coding reference for Claude Code. See CONTEXT.md for full rationale.*

---

## Stack

- **Engine:** Love2D (Lua)
- **Editor:** VS Code
- **Platform:** PC (Windows primary)
- **Population cap:** ~200 units

---

## Folder Structure

```
main.lua
/core         -- time, registry, world
/simulation   -- unit.lua, jobs, needs, mood, health
/config       -- all config tables
/ui           -- rendering and input
/events       -- event system, Fey, Changeling
```

---

## Entry Point

```lua
-- main.lua
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end
```

---

## Conventions

### Naming
- `snake_case` for variables and table keys
- `camelCase` for functions
- String identifiers for equality-only checks (modifier sources, skill names, illness names, activity types, crop types, resource types)
- Integer constants for ordered/comparable values (tier, priority, job tier)

### Error Handling
- Prefer hard failures over silent ones — access config tables and variables directly, let Lua throw on nil
- Use `assert` only when a clearer error message is worth the extra line
- Never guard against missing data with `if x then` when missing data indicates a programming error
- Use `== false` instead of `not`

### IDs
- One global incrementing counter for all entity types (units, memories, buildings, jobs, furniture, mover rules, resource nodes)
- A unit's `id` persists when they die and become a memory

### Architecture
- Units carry state. Config tables carry rules. Systems read both.
- Tier-based behavioral differences live in config tables keyed by tier — not on the unit.
- Skill caps live in job config tables — not on the unit.

---

## Constants

```lua
Tier     = { SERF = 1, FREEMAN = 2, GENTRY = 3 }
JobTier  = { T1 = 1, T2 = 2, T3 = 3 }
Priority = { DISABLED = 0, LOW = 1, NORMAL = 2, HIGH = 3 }

-- Calendar
MINUTES_PER_HOUR = 60
HOURS_PER_DAY    = 24
DAYS_PER_SEASON  = 7
SEASONS_PER_YEAR = 4
DAYS_PER_YEAR    = DAYS_PER_SEASON * SEASONS_PER_YEAR   -- 28
HOURS_PER_SEASON = HOURS_PER_DAY * DAYS_PER_SEASON      -- 168
HOURS_PER_YEAR   = HOURS_PER_SEASON * SEASONS_PER_YEAR  -- 672

-- Tick system
TICK_RATE        = 60
HASH_INTERVAL    = 60
TICKS_PER_MINUTE = 25
TICKS_PER_HOUR   = 1500
TICKS_PER_DAY    = 36000
TICKS_PER_SEASON = 252000
TICKS_PER_YEAR   = 1008000

-- Conversion helpers
PER_MINUTE = 1 / TICKS_PER_MINUTE
PER_HOUR   = 1 / TICKS_PER_HOUR
PER_DAY    = 1 / TICKS_PER_DAY
PER_SEASON = 1 / TICKS_PER_SEASON

-- Speed
Speed = { NORMAL = 1, FAST = 2, VERY_FAST = 4, ULTRA = 8 }

-- Schedule
WAKE_HOUR  = 6
SLEEP_HOUR = 22
DAY_START  = 6
DAY_END    = 18
CHURCH_DAY = 1   -- Sunday

-- Aging
AGES_PER_YEAR    = SEASONS_PER_YEAR
AGE_OF_ADULTHOOD = 16

-- Day/season names
DAY_NAMES    = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
SEASON_NAMES = { "Spring", "Summer", "Autumn", "Winter" }
```

---

## Module Ownership

| Module | Owns |
|---|---|
| **Time** | Clock state (tick, minute, hour, day, season, year). Accumulator and speed. Provides `hashOffset()`. Does not know about other systems. |
| **Simulation** | The `onTick` orchestrator. Calls module update functions in order. Owns no data. |
| **World** | Tile grid, buildings, resource nodes, forest depth map. Posts jobs to the queue. |
| **Units** | Unit state: attributes, skills, needs, mood, health, relationships, tier, current activity. Owns creation, death, promotion/demotion. |
| **Job Queue** | Standalone. Owns the prioritized list of available work tasks. World posts; units query and claim. |
| **Dynasty** | Succession logic, leader tracking, regency state. Reads unit relationship graphs. |
| **Events** | Changeling, Fey encounters, random occurrences, funerals, weddings, Sunday service. Reads/modifies world and units. |
| **Registry** | `registry[id]` returns a living unit or a memory. Single lookup pool. |

---

## Main Loop

```lua
function love.update(dt)
    local ticks_this_frame = time:accumulate(dt)
    for i = 1, ticks_this_frame do
        time:advance()
        simulation:onTick(time)
    end
end
```

---

## Simulation Loop

```lua
function simulation:onTick(time)
    time:updateClock()
    units:update(time)
    world:updateBuildings(time)
    world:updateResources(time)
end
```

Calendar-driven logic uses modulo checks in `simulation:onTick`, not inside individual systems:

```lua
if time.tick % TICKS_PER_SEASON == 0 then
    units:processSeasonalAging(time)
end
```

---

## Hash Offset System

```lua
function hashOffset(id)
    return (id * 7919) % HASH_INTERVAL
end

function units:update(time)
    for _, unit in ipairs(self.all) do
        if (time.tick + hashOffset(unit.id)) % HASH_INTERVAL == 0 then
            unit:update(time)
        end
    end
end
```

### Per-Unit Update Order
1. Update needs (drain)
2. Check critical need interrupts (drop job, self-assign behavior)
3. If idle, poll job queue
4. Execute work progress (grow attribute; grow skill if T2/T3 and below cap)
5. Recalculate mood (stateless)
6. Recalculate health (stateless)

---

## Architectural Directives

- **OO, not ECS**
- **Single `unit.lua`** — no split unit files
- **Single global job queue** for all job types
- **Needs bypass the job queue** — self-assigned directly on critical threshold
- **Three needs only:** hunger, sleep, recreation. Spirituality is NOT a need (handled by Sunday service).
- **Mood and health are stateless** — recalculated from scratch each hashed update
- **Skill caps on the job, not the unit** — Serfs have no skills at all
- **Workers own their full job cycle** — no separate hauling job type
- **Blueprint-based buildings** — no room detection; interiors are spatial data from config
- **Single-zone map** — no separate regions; `forest_danger` derived on demand as `depth²`
- **All rate values stored as per-tick** — use conversion constants in config tables
- **Market delivery model** — merchant walks greedy nearest-neighbor route to homes

---

## Data Structures

### Unit
```lua
unit = {
    id = 0, name = "", tier = Tier.SERF,
    age = 0,
    birth_day = 0, birth_season = 0,
    is_child = true,
    attending_school = false,

    is_leader = false, is_regent = false,

    father_id = nil, mother_id = nil,
    child_ids = {}, spouse_id = nil,
    friend_ids = {}, enemy_ids = {},    -- up to 3 each

    attributes = {
        strength = 0, dexterity = 0, intelligence = 0,
        wisdom = 0, charisma = 0,
    },
    skills = {
        -- Freeman and Gentry only. All default 0.
        melee_combat = 0, smithing = 0, hunting = 0, tailoring = 0,
        baking = 0, brewing = 0, construction = 0, scholarship = 0,
        herbalism = 0, medicine = 0, priesthood = 0, barkeeping = 0,
        trading = 0, jewelry = 0, leadership = 0,
    },
    needs = {
        hunger = 100, sleep = 100, recreation = 100,
    },

    mood = 0,
    mood_modifiers = {},    -- { source, value, ticks_remaining }

    health = 100,
    health_modifiers = {},

    current_job_id = nil,
    current_activity = nil,
    home_id = nil,
    bed_index = nil,
    x = 0, y = 0,
}
```

### Memory (Dead Unit)
```lua
memory = {
    id = 0, name = "",
    father_id = nil, mother_id = nil,
    child_ids = {}, spouse_id = nil,
    death_day = 0, death_season = 0, death_year = 0,
    death_cause = "",
}
```

### Job
```lua
job = {
    id = 0,
    type = "chop_tree",
    priority = Priority.NORMAL,
    x = 0, y = 0,
    target_id = nil,
    claimed_by = nil,
    progress = 0,
}
```

### Tile
```lua
tile = {
    terrain = "grass",
    building_id = nil,
    resource = nil,
    forest_depth = 0.0,
}
```

### Building
```lua
building = {
    id = 0, type = "cottage",
    x = 0, y = 0, width = 0, height = 0,
    is_built = false, build_progress = 0,
    interior = {},
    crop = nil,
    assigned_worker_id = nil,
}
```

### Household
```lua
household = {
    building_id = 0,
    member_ids = {},
    food = { bread = 0, vegetables = 0, meat = 0, fish = 0 },
    clothing = 0,
}
```

### World
```lua
world = {
    width = 0, height = 0,
    tiles = {},
    buildings = {},
    resources = {},
    job_queue = {},
}
```

### Time
```lua
time = {
    speed = Speed.NORMAL,
    paused = false,
    accumulator = 0,
    tick = 0,
    minute = 0,
    hour = 6,
    day = 1,
    season = 1,
    year = 1,
}
```

---

## Config Tables

```lua
NeedsConfig = {
    child = {
        hunger     = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
        sleep      = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
        recreation = { drain = 8 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
    },
    [Tier.SERF]    = { hunger = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 }, ... },
    [Tier.FREEMAN] = { hunger = { drain = 3 * PER_HOUR, mood_threshold = 50, mood_penalty = -15 }, ... },
    [Tier.GENTRY]  = { hunger = { drain = 4 * PER_HOUR, mood_threshold = 60, mood_penalty = -20 }, ... },
}

JobConfig = {
    -- T1: Any unit, attribute only, no skill
    hauler       = { job_tier = JobTier.T1, attribute = "strength" },
    woodcutter   = { job_tier = JobTier.T1, attribute = "strength",     work_ticks = 8 * TICKS_PER_HOUR },
    miner        = { job_tier = JobTier.T1, attribute = "strength",     work_ticks = 8 * TICKS_PER_HOUR },
    stonecutter  = { job_tier = JobTier.T1, attribute = "strength",     work_ticks = 8 * TICKS_PER_HOUR },
    miller       = { job_tier = JobTier.T1, attribute = "strength" },
    farmer       = { job_tier = JobTier.T1, attribute = "wisdom",       work_ticks = 4 * TICKS_PER_HOUR },
    fisher       = { job_tier = JobTier.T1, attribute = "wisdom",       work_ticks = 4 * TICKS_PER_HOUR },
    gatherer     = { job_tier = JobTier.T1, attribute = "wisdom",       work_ticks = 4 * TICKS_PER_HOUR },

    -- T2: Freeman+, attribute + skill
    guard        = { job_tier = JobTier.T2, attribute = "strength",     skill = "melee_combat",  max_skill = 5 },
    smith        = { job_tier = JobTier.T2, attribute = "dexterity",    skill = "smithing",      max_skill = 5 },
    huntsman     = { job_tier = JobTier.T2, attribute = "dexterity",    skill = "hunting",       max_skill = 5 },
    tailor       = { job_tier = JobTier.T2, attribute = "dexterity",    skill = "tailoring",     max_skill = 5 },
    baker        = { job_tier = JobTier.T2, attribute = "intelligence", skill = "baking",        max_skill = 5 },
    brewer       = { job_tier = JobTier.T2, attribute = "intelligence", skill = "brewing",       max_skill = 5 },
    builder      = { job_tier = JobTier.T2, attribute = "intelligence", skill = "construction",  max_skill = 5 },
    teacher      = { job_tier = JobTier.T2, attribute = "intelligence", skill = "scholarship",   max_skill = 5 },
    herbalist    = { job_tier = JobTier.T2, attribute = "wisdom",       skill = "herbalism",     max_skill = 5 },
    healer       = { job_tier = JobTier.T2, attribute = "wisdom",       skill = "medicine",      max_skill = 5 },
    priest       = { job_tier = JobTier.T2, attribute = "wisdom",       skill = "priesthood",    max_skill = 5 },
    barkeep      = { job_tier = JobTier.T2, attribute = "charisma",     skill = "barkeeping",    max_skill = 5 },
    merchant     = { job_tier = JobTier.T2, attribute = "charisma",     skill = "trading",       max_skill = 5 },

    -- T3: Gentry only, attribute + skill
    knight       = { job_tier = JobTier.T3, attribute = "strength",     skill = "melee_combat",  max_skill = 10 },
    armorer      = { job_tier = JobTier.T3, attribute = "dexterity",    skill = "smithing",      max_skill = 10 },
    jeweler      = { job_tier = JobTier.T3, attribute = "dexterity",    skill = "jewelry",       max_skill = 10 },
    architect    = { job_tier = JobTier.T3, attribute = "intelligence", skill = "construction",  max_skill = 10 },
    scholar      = { job_tier = JobTier.T3, attribute = "intelligence", skill = "scholarship",   max_skill = 10 },
    physician    = { job_tier = JobTier.T3, attribute = "wisdom",       skill = "medicine",      max_skill = 10 },
    bishop       = { job_tier = JobTier.T3, attribute = "wisdom",       skill = "priesthood",    max_skill = 10 },
    steward      = { job_tier = JobTier.T3, attribute = "charisma",     skill = "trading",       max_skill = 10 },
    leader       = { job_tier = JobTier.T3, attribute = "charisma",     skill = "leadership",    max_skill = 10 },
}

ChildJobs = { "hauler", "farmer", "gatherer", "fisher" }

InjuryConfig = {
    bruised = { initial_damage = 10, recovery = 0.5 * PER_HOUR  },
    wounded = { initial_damage = 30, recovery = 0.2 * PER_HOUR  },
    maimed  = { initial_damage = 50, recovery = 0.05 * PER_HOUR },
}

IllnessConfig = {
    cold        = { damage = 0.1 * PER_HOUR, recovery_chance = 0.08,  recovery = 0.4 * PER_HOUR  },
    flu         = { damage = 0.2 * PER_HOUR, recovery_chance = 0.08,  recovery = 0.4 * PER_HOUR  },
    the_flux    = { damage = 0.4 * PER_HOUR, recovery_chance = 0.10,  recovery = 0.3 * PER_HOUR  },
    consumption = { damage = 0.1 * PER_HOUR, recovery_chance = 0.005, recovery = 0.2 * PER_HOUR  },
    pox         = { damage = 0.3 * PER_HOUR, recovery_chance = 0.02,  recovery = 0.2 * PER_HOUR  },
    pestilence  = { damage = 0.5 * PER_HOUR, recovery_chance = 0.01,  recovery = 0.15 * PER_HOUR },
}

MalnourishedConfig = { damage = 0.3 * PER_HOUR, recovery = 0.5 * PER_HOUR }

BuildingConfig = {
    cottage           = { width = 3, height = 3, housing_tier = Tier.SERF,    build_cost = { logs = 40,  stone = 20 } },
    house             = { width = 4, height = 3, housing_tier = Tier.FREEMAN, build_cost = { logs = 80,  stone = 50 } },
    manor             = { width = 5, height = 4, housing_tier = Tier.GENTRY,  build_cost = { logs = 150, stone = 120 } },
    farm_plot         = { width = 4, height = 4, build_cost = { logs = 10 } },
    woodcutters_camp  = { width = 2, height = 2, build_cost = { logs = 20 } },
    mine              = { width = 3, height = 3, build_cost = { logs = 40, stone = 30 } },
    quarry            = { width = 3, height = 3, build_cost = { logs = 30 } },
    gatherers_hut     = { width = 2, height = 2, build_cost = { logs = 15 } },
    hunting_cabin     = { width = 2, height = 2, build_cost = { logs = 25 } },
    fishing_dock      = { width = 2, height = 2, build_cost = { logs = 20 } },
    mill              = { width = 3, height = 3, build_cost = { logs = 50, stone = 30 } },
    bakery            = { width = 3, height = 3, build_cost = { logs = 40, stone = 20 } },
    brewery           = { width = 3, height = 3, build_cost = { logs = 50, stone = 20 } },
    tailors_shop      = { width = 3, height = 3, build_cost = { logs = 40, stone = 15 } },
    smithy            = { width = 3, height = 3, build_cost = { logs = 30, stone = 40 } },
    foundry           = { width = 4, height = 4, build_cost = { logs = 60, stone = 80 } },
    jewelers_workshop = { width = 3, height = 3, build_cost = { logs = 40, stone = 30 } },
    market            = { width = 4, height = 3, build_cost = { logs = 60, stone = 30 } },
    church            = { width = 5, height = 4, build_cost = { logs = 80, stone = 60 } },
    infirmary         = { width = 3, height = 3, build_cost = { logs = 50, stone = 30 } },
    tavern            = { width = 4, height = 3, build_cost = { logs = 60, stone = 30 } },
    school            = { width = 3, height = 3, build_cost = { logs = 50, stone = 20 } },
    warehouse         = { width = 4, height = 3, build_cost = { logs = 80, stone = 40 } },
    barracks          = { width = 4, height = 3, build_cost = { logs = 60, stone = 40 } },
    watchtower        = { width = 2, height = 2, build_cost = { logs = 30, stone = 30 } },
    town_hall         = { width = 5, height = 4, build_cost = { logs = 120, stone = 100 } },
    library           = { width = 4, height = 3, build_cost = { logs = 80, stone = 50 } },
}

ResourceSpawnConfig = {
    timber     = { min_depth = 0.0  },
    wildlife   = { min_depth = 0.0  },
    herbs      = { min_depth = 0.01 },
    artifacts  = { min_depth = 0.8  },
}
```
