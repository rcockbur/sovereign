# Sovereign — Coding Context
*Read this at the start of every session.*

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

### IDs
One global incrementing counter for all entity types (units, memories, buildings, jobs, furniture, mover rules, resource nodes). No collisions possible. A unit's `id` persists when they die and become a memory.

### Architecture Pattern
Units carry state. Config tables carry rules. Systems read both. Tier-based behavioral differences (need drain rates, mood thresholds, etc.) live in config tables keyed by tier — not on the unit. Skill caps live in job config tables — not on the unit.

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
HOURS_PER_YEAR   = HOURS_PER_SEASON * SEASONS_PER_YEAR   -- 672

-- Tick system
TICK_RATE        = 60     -- ticks per real second at x1
HASH_INTERVAL    = 60     -- ticks between hashed entity updates (1 real second at x1)
TICKS_PER_MINUTE = 25
TICKS_PER_HOUR   = 1500
TICKS_PER_DAY    = 36000
TICKS_PER_SEASON = 252000
TICKS_PER_YEAR   = 1008000

-- Conversion helpers for config readability
PER_MINUTE = 1 / TICKS_PER_MINUTE
PER_HOUR   = 1 / TICKS_PER_HOUR
PER_DAY    = 1 / TICKS_PER_DAY
PER_SEASON = 1 / TICKS_PER_SEASON

-- Speed
Speed = { NORMAL = 1, FAST = 2, VERY_FAST = 4, ULTRA = 8 }

-- Schedule
WAKE_HOUR  = 6   -- 6am
SLEEP_HOUR = 22  -- 10pm
DAY_START  = 6
DAY_END    = 18
CHURCH_DAY = 1   -- Sunday (day 1 of the week)

-- Aging
AGES_PER_YEAR = SEASONS_PER_YEAR
AGE_OF_ADULTHOOD = 16

-- Day/season names
DAY_NAMES    = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
SEASON_NAMES = { "Spring", "Summer", "Autumn", "Winter" }
```

---

## Module Ownership

| Module | Owns |
|---|---|
| **Time** | Clock state (tick, minute, hour, day, season, year). Accumulator and speed. Provides `hashOffset()` utility. Does not know about other systems. |
| **Simulation** | The `onTick` orchestrator. Calls module update functions in order. Owns no data. |
| **World** | Tile grid, buildings, resource nodes, forest depth map. Owns building and resource update loops (with hash offsets). Posts jobs to the queue when the world needs work done. |
| **Units** | Unit state: attributes, skills, needs, mood, health, relationships, tier, current activity. Owns the unit update loop (with hash offsets). Also owns creation, death (conversion to memory), promotion/demotion. |
| **Job Queue** | Standalone. Owns the prioritized list of available work tasks. World posts jobs; units query and claim them. |
| **Dynasty** | Succession logic, leader tracking, regency state. Reads from unit relationship graphs. |
| **Events** | Event system (Changeling, Fey encounters, random occurrences, funerals, weddings, Sunday service). Reads from world and units; can modify both. Stub for now. |
| **Registry** | `registry[id]` returns either a living unit or a memory. Single lookup pool — relationship traversal doesn't need to know if a target is alive or dead. |

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

`time:accumulate(dt)` adds real delta time to an internal accumulator and returns how many ticks should fire this frame based on the current speed setting. `time:advance()` increments the tick counter and updates the clock (minute, hour, day, season, year). The main loop is the orchestrator — `time` does not know about `simulation`.

At x1 speed, 1 tick fires per frame (60 ticks/sec at 60fps). At x8, 8 ticks fire per frame.

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

This is a direct call chain — no event bus, no registration. Adding a new system means adding a line here and consciously deciding its position in the order.

Calendar-driven logic (daily events, seasonal aging, Sunday service) uses modulo checks in `simulation:onTick`, not inside individual systems. For example:

```lua
if time.tick % TICKS_PER_SEASON == 0 then
    units:processSeasonalAging(time)
end
```

---

## Hash Offset System

All entity collections use hash offsets to distribute updates evenly across ticks. Each entity updates once per `HASH_INTERVAL` ticks (once per real second at x1). A prime multiply scatters sequential IDs to avoid clustering from the shared global ID counter:

```lua
function hashOffset(id)
    return (id * 7919) % HASH_INTERVAL
end
```

Each module owns its own update loop:

```lua
function units:update(time)
    for _, unit in ipairs(self.all) do
        if (time.tick + hashOffset(unit.id)) % HASH_INTERVAL == 0 then
            unit:update(time)
        end
    end
end
```

With `HASH_INTERVAL = 60`, approximate per-tick workload:

| Entity type | Typical count | Updates per tick |
|---|---|---|
| Units | ~200 | ~3.3 |
| Buildings | ~300 | ~5 |
| Resource nodes | ~1500 | ~25 |
| **Total** | ~2000 | **~33** |

### Per-Unit Update Order

When a unit's hash fires, it runs through all its systems in one burst:

1. Update needs (drain toward depletion)
2. Check for critical need interrupts (drop job, self-assign behavior)
3. If idle, poll job queue
4. Execute work progress (grow attribute; grow skill if T2/T3 job and below cap)
5. Recalculate mood (stateless, from scratch)
6. Recalculate health (stateless, from scratch)

---

## Key Architectural Decisions

**OO, not ECS.** At ~200 units, ECS adds complexity without meaningful performance benefit.

**Composition over inheritance for units.** Tier differences (Serf, Freeman, Gentry) are data differences, not behavioral ones. A single shallow `Unit` prototype with composed tier data. No subclasses — avoids awkward runtime class-swapping on promotion/demotion.

**Hash offset updates, not global sweeps.** Entities update via hash offsets (one real-second cadence at x1). All systems for a given entity run in one burst on its assigned tick. No tiered cadence scheduling — one universal interval for everything. Prime multiply on the global ID prevents clustering.

**Direct call chain for simulation.** `simulation:onTick` calls module update functions in explicit order. No event bus, no callback registration. Tick order is visible in one function.

**Frequency scheduling in the simulation loop.** Calendar-driven logic (daily events, seasonal aging, Sunday service) uses modulo checks in `simulation:onTick`, not inside individual systems. Per-entity update logic lives inside each module's hash-offset loop.

**Job queue: polling, not idle notification.** Idle units scan the queue during their hashed update. No event bus needed. Simple, correct, negligible cost at this scale.

**Needs bypass the job queue.** When a need becomes critical, the unit interrupts its current work job, returns it to the queue, and self-assigns need behavior directly. Needs are never posted as jobs.

**Mood and health are stateless.** Both recalculated from scratch on each unit's hashed update. Mood = sum of stored decaying modifiers + calculated modifiers derived from current state. Health = `100 + sum of all health modifier values`, clamped 0–100.

**Skill caps on the job, not the unit.** A unit's skill grows until it hits the current job's `max_skill`. Promotion to a higher-tier job sharing the same skill uncaps further growth. Serfs have no skills at all.

**Config values in per-tick terms.** All rates (drain, damage, recovery) are stored as per-tick values. Conversion constants (`PER_HOUR`, `PER_MINUTE`, etc.) make config tables human-readable. Game_minutes exist as a config unit but are not player-facing.

**Single-zone map.** No separate maps or regions. Settlement on the left half, forest on the right. Forest depth is fixed at map gen, never recalculated. `forest_depth` stored on tile; `forest_danger` derived on demand as `depth²`.

**Blueprint-based building.** No room detection. Blueprint claims tiles immediately. Units fetch materials and construct. Building interiors are spatial data (bed positions, etc.) defined in building config and created automatically on construction completion.

**Workers own their full job cycle.** A woodcutter chops and carries. A builder fetches and builds. No separate hauling job type. Carry capacity derived from Strength.

**Market delivery model.** Merchant walks a greedy nearest-neighbor route delivering consumer goods to homes. Homes that can't be served fall back to self-fetch from stockpiles.

**Spirituality is not a need.** Sunday church service is a scheduled weekly event that applies a decaying mood modifier. No self-interrupt behavior for spirituality.

---

## Data Structures (Reference)

### Unit
```lua
unit = {
    id = 0, name = "", tier = Tier.SERF,
    age = 0,                            -- in "life years" (not calendar years)
    birth_day = 0, birth_season = 0,    -- age increments on birth_day of each new season
    is_child = true,                    -- age < AGE_OF_ADULTHOOD
    attending_school = false,           -- child-only: if true, greys out job priorities

    is_leader = false, is_regent = false,

    father_id = nil, mother_id = nil,
    child_ids = {}, spouse_id = nil,
    friend_ids = {}, enemy_ids = {},    -- up to 3 each

    attributes = {
        strength = 0, dexterity = 0, intelligence = 0,
        wisdom = 0, charisma = 0,
    },
    skills = {
        -- Only tracked for Freeman and Gentry. All default 0.
        melee_combat = 0, smithing = 0, hunting = 0, tailoring = 0,
        baking = 0, brewing = 0, construction = 0, scholarship = 0,
        herbalism = 0, medicine = 0, priesthood = 0, barkeeping = 0,
        trading = 0, jewelry = 0, leadership = 0,
    },
    needs = {
        hunger = 100, sleep = 100, recreation = 100,
    },

    mood = 0,               -- recalculated each hashed update, unbounded
    mood_modifiers = {},    -- { source = "family_death", value = -20, ticks_remaining = 14 * TICKS_PER_DAY }

    health = 100,           -- recalculated each hashed update, clamped 0–100
    health_modifiers = {},  -- injury, illness, malnourished conditions

    current_job_id = nil,
    current_activity = nil, -- "working" | "eating" | "sleeping" | "socializing" | "attending_church" | etc.
    home_id = nil,          -- assigned building id
    bed_index = nil,        -- index into building interior bed positions
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
    type = "chop_tree",      -- keys into JobConfig
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
    forest_depth = 0.0,     -- precomputed at map gen, never recalculated
}
```

### Building
```lua
building = {
    id = 0, type = "cottage",
    x = 0, y = 0, width = 0, height = 0,
    is_built = false, build_progress = 0,
    interior = {},           -- spatial positions: { { type = "bed", x = 0, y = 0 }, ... }
    crop = nil,              -- farm plots only: "wheat" | "barley" | "flax"
    assigned_worker_id = nil, -- for staffed buildings
}
```

### Household
```lua
household = {
    building_id = 0,
    member_ids = {},
    food = {
        bread = 0, vegetables = 0, meat = 0, fish = 0,
    },
    clothing = 0,
}
```

### World
```lua
world = {
    width = 0, height = 0,
    tiles = {},              -- 2D array
    buildings = {},          -- keyed by building id
    resources = {},          -- keyed by resource id
    job_queue = {},
}
```

### Time
```lua
time = {
    speed = Speed.NORMAL,
    paused = false,
    accumulator = 0,          -- real seconds accumulated toward next tick

    tick = 0,                 -- total ticks since game start
    minute = 0,               -- 0–59
    hour = 6,                 -- 0–23 (game starts at 6am)
    day = 1,                  -- 1–7
    season = 1,               -- 1–4
    year = 1,
}
```

---

## Config Tables (Reference)

All rate values are per-tick. Use conversion constants for readability.

### Needs Config

```lua
NeedsConfig = {
    child = {
        hunger     = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
        sleep      = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
        recreation = { drain = 8 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
    },
    [Tier.SERF] = {
        hunger     = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
        sleep      = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
        recreation = { drain = 2 * PER_HOUR, mood_threshold = 30, mood_penalty = -10 },
    },
    [Tier.FREEMAN] = {
        hunger     = { drain = 3 * PER_HOUR, mood_threshold = 50, mood_penalty = -15 },
        sleep      = { drain = 3 * PER_HOUR, mood_threshold = 50, mood_penalty = -15 },
        recreation = { drain = 3 * PER_HOUR, mood_threshold = 50, mood_penalty = -15 },
    },
    [Tier.GENTRY] = {
        hunger     = { drain = 4 * PER_HOUR, mood_threshold = 60, mood_penalty = -20 },
        sleep      = { drain = 4 * PER_HOUR, mood_threshold = 60, mood_penalty = -20 },
        recreation = { drain = 4 * PER_HOUR, mood_threshold = 60, mood_penalty = -20 },
    },
}
```

### Job Config

```lua
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

-- Jobs children can perform (subset of T1)
ChildJobs = { "hauler", "farmer", "gatherer", "fisher" }
```

### Health Config

```lua
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
```

### Building Config

```lua
BuildingConfig = {
    -- Housing
    cottage = {
        width = 3, height = 3, housing_tier = Tier.SERF,
        build_cost = { logs = 40, stone = 20 },
        interior = {
            { type = "bed", x = 0, y = 0 },
            { type = "bed", x = 1, y = 0 },
            { type = "bed", x = 0, y = 2 },
            { type = "bed", x = 1, y = 2 },
        },
    },
    house = {
        width = 4, height = 3, housing_tier = Tier.FREEMAN,
        build_cost = { logs = 80, stone = 50 },
        interior = {
            { type = "bed", x = 0, y = 0 },
            { type = "bed", x = 1, y = 0 },
            { type = "bed", x = 0, y = 2 },
            { type = "bed", x = 1, y = 2 },
            { type = "bed", x = 2, y = 0 },
            { type = "bed", x = 2, y = 2 },
        },
    },
    manor = {
        width = 5, height = 4, housing_tier = Tier.GENTRY,
        build_cost = { logs = 150, stone = 120 },
        interior = {
            { type = "bed", x = 0, y = 0 },
            { type = "bed", x = 1, y = 0 },
            { type = "bed", x = 0, y = 3 },
            { type = "bed", x = 1, y = 3 },
            { type = "bed", x = 3, y = 0 },
            { type = "bed", x = 3, y = 3 },
            { type = "bed", x = 4, y = 0 },
            { type = "bed", x = 4, y = 3 },
        },
    },

    -- Farm (crop selected per plot: "wheat" | "barley" | "flax")
    farm_plot = { width = 4, height = 4, build_cost = { logs = 10 } },

    -- Resource extraction
    woodcutters_camp = { width = 2, height = 2, build_cost = { logs = 20 } },
    mine             = { width = 3, height = 3, build_cost = { logs = 40, stone = 30 } },
    quarry           = { width = 3, height = 3, build_cost = { logs = 30 } },
    gatherers_hut    = { width = 2, height = 2, build_cost = { logs = 15 } },
    hunting_cabin    = { width = 2, height = 2, build_cost = { logs = 25 } },
    fishing_dock     = { width = 2, height = 2, build_cost = { logs = 20 } },

    -- Processing
    mill              = { width = 3, height = 3, build_cost = { logs = 50, stone = 30 } },
    bakery            = { width = 3, height = 3, build_cost = { logs = 40, stone = 20 } },
    brewery           = { width = 3, height = 3, build_cost = { logs = 50, stone = 20 } },
    tailors_shop      = { width = 3, height = 3, build_cost = { logs = 40, stone = 15 } },
    smithy            = { width = 3, height = 3, build_cost = { logs = 30, stone = 40 } },
    foundry           = { width = 4, height = 4, build_cost = { logs = 60, stone = 80 } },
    jewelers_workshop = { width = 3, height = 3, build_cost = { logs = 40, stone = 30 } },

    -- Services
    market    = { width = 4, height = 3, build_cost = { logs = 60, stone = 30 } },
    church    = { width = 5, height = 4, build_cost = { logs = 80, stone = 60 } },
    infirmary = { width = 3, height = 3, build_cost = { logs = 50, stone = 30 } },
    tavern    = { width = 4, height = 3, build_cost = { logs = 60, stone = 30 } },
    school    = { width = 3, height = 3, build_cost = { logs = 50, stone = 20 } },

    -- Storage (stockpile is free, no entry needed)
    warehouse = { width = 4, height = 3, build_cost = { logs = 80, stone = 40 } },

    -- Military
    barracks   = { width = 4, height = 3, build_cost = { logs = 60, stone = 40 } },
    watchtower = { width = 2, height = 2, build_cost = { logs = 30, stone = 30 } },

    -- Governance / Late-game
    town_hall = { width = 5, height = 4, build_cost = { logs = 120, stone = 100 } },
    library   = { width = 4, height = 3, build_cost = { logs = 80, stone = 50 } },
}
```

### Resource Config

```lua
ResourceSpawnConfig = {
    timber     = { min_depth = 0.0  },
    wildlife   = { min_depth = 0.0  },
    herbs      = { min_depth = 0.01 },
    artifacts  = { min_depth = 0.8  },
}
```

### Production Chains (Reference)

```
-- Food
wheat_farm → wheat → mill → flour → bakery → bread
gatherers_hut → vegetables
hunting_cabin → meat
fishing_dock → fish

-- Alcohol
barley_farm → barley → brewery → beer

-- Textiles
flax_farm → flax → tailors_shop → clothing

-- Metal
mine → iron → smithy → tools, weapons, armor
mine → iron → foundry → steel → elite tools, weapons, armor

-- Jewelry
mine → gold/silver/gems (rare) → jewelers_workshop → jewelry

-- Construction materials
woodcutters_camp → logs
quarry → stone

-- Medicine
forest (herbalist) → herbs → infirmary (healer) → treatment
```
