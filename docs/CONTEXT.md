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

## Conventions

### Naming
- `snake_case` for variables and table keys
- `camelCase` for functions
- String identifiers for equality-only checks (modifier sources, skill names, illness names, activity types)
- Integer constants for ordered/comparable values (tier, priority)

### IDs
One global incrementing counter for all entity types (units, memories, buildings, jobs, furniture, mover rules). No collisions possible. A unit's `id` persists when they die and become a memory.

### Architecture Pattern
Units carry state. Config tables carry rules. Systems read both. Tier-based behavioral differences (need drain rates, mood thresholds, etc.) live in config tables keyed by tier — not on the unit.

---

## Constants

```lua
Tier     = { SERF = 1, FREEMAN = 2, GENTRY = 3 }
Priority = { DISABLED = 0, LOW = 1, NORMAL = 2, HIGH = 3 }

HOURS_PER_DAY    = 24
DAYS_PER_SEASON  = 7
SEASONS_PER_YEAR = 4
HOURS_PER_SEASON = HOURS_PER_DAY * DAYS_PER_SEASON
HOURS_PER_YEAR   = HOURS_PER_SEASON * SEASONS_PER_YEAR
```

---

## Module Ownership

| Module | Owns |
|---|---|
| **World** | Tile grid, buildings, resource nodes, forest depth map. Posts jobs to the queue when the world needs work done. |
| **Units** | Unit state: virtues, skills, needs, mood, health, relationships, tier, current activity. Also owns creation, death (conversion to memory), promotion/demotion. |
| **Job Queue** | Standalone. Owns the prioritized list of available work tasks. World posts jobs; units query and claim them. |
| **Time** | Owns the clock. Drives the tick. Other systems register with time or are called by it. |
| **Dynasty** | Succession logic, leader tracking, regency state. Reads from unit relationship graphs. |
| **Events** | Event system (Changeling, Fey encounters, random occurrences). Reads from world and units; can modify both. Stub for now. |
| **Registry** | `registry[id]` returns either a living unit or a memory. Single lookup pool — relationship traversal doesn't need to know if a target is alive or dead. |

---

## Tick Order

1. Time advances
2. Units update needs; self-assign behavior if a need is critical
3. Idle units poll the job queue
4. Units execute work
5. World processes results (resources gathered, buildings progressed, etc.)
6. Mood and health recalculated

---

## Key Architectural Decisions

**OO, not ECS.** At ~200 units, ECS adds complexity without meaningful performance benefit.

**Composition over inheritance for units.** Tier differences (Serf, Freeman, Gentry) are data differences, not behavioral ones. A single shallow `Unit` prototype with composed tier data. No subclasses — avoids awkward runtime class-swapping on promotion/demotion.

**Job queue: polling, not idle notification.** Idle units scan the queue each tick (step 3). No event bus needed. Simple, correct, negligible cost at this scale.

**Needs bypass the job queue.** When a need becomes critical, the unit interrupts its current work job, returns it to the queue, and self-assigns need behavior directly. Needs are never posted as jobs.

**Mood and health are stateless.** Both recalculated from scratch each tick. Mood = sum of stored decaying modifiers + calculated modifiers derived from current state. Health = `100 + sum of all health modifier values`, clamped 0–100. Neither value is stored between ticks.

**Single-zone map.** No separate maps or regions. Settlement on the left half, forest on the right. Forest depth is fixed at map gen, never recalculated. `forest_depth` stored on tile; `forest_danger` derived on demand as `depth²`.

**Blueprint-based building.** No room detection. Blueprint claims tiles immediately. Units fetch materials and construct.

**Workers own their full job cycle.** A woodcutter chops and carries. A builder fetches and builds. No separate hauling job type. Carry capacity derived from Strength.

---

## Data Structures (Reference)

### Unit
```lua
unit = {
    id = 0, name = "", tier = Tier.SERF,
    age = 0, birth_day = 0,             -- age cached, updated once per day
    is_leader = false, is_regent = false,

    father_id = nil, mother_id = nil,
    child_ids = {}, spouse_id = nil,
    friend_ids = {}, enemy_ids = {},    -- up to 3 each

    virtues = {
        strength = 0, intelligence = 0, dexterity = 0,
        wisdom = 0, constitution = 0, charisma = 0,
    },
    skills = {
        woodcutting = 0, farming = 0, combat = 0,
        construction = 0, medicine = 0,   -- full list TBD
    },
    needs = {
        hunger = 100, sleep = 100, recreation = 100, spirituality = 100,
    },

    mood = 0,               -- recalculated each tick, unbounded
    mood_modifiers = {},    -- decaying event modifiers only

    health = 100,           -- recalculated each tick, clamped 0–100
    health_modifiers = {},  -- injury, illness, malnourished conditions

    current_job_id = nil,
    current_activity = nil, -- "working" | "eating" | "sleeping" | etc.
    x = 0, y = 0,
}
```

### Memory (Dead Unit)
```lua
memory = {
    id = 0, name = "",
    father_id = nil, mother_id = nil,
    child_ids = {}, spouse_id = nil,
    death_day = 0, death_cause = "",
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
    id = 0, type = "house",
    x = 0, y = 0, width = 0, height = 0,
    is_built = false, build_progress = 0,
    interior = {},           -- list of furniture objects
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

---

## Config Tables (Reference)

```lua
NeedsConfig = {
    [Tier.SERF]    = { hunger = { drain_per_hour = 2, mood_threshold = 30, mood_penalty = -10 }, ... },
    [Tier.FREEMAN] = { hunger = { drain_per_hour = 3, mood_threshold = 50, mood_penalty = -15 }, ... },
    [Tier.GENTRY]  = { hunger = { drain_per_hour = 4, mood_threshold = 60, mood_penalty = -20 }, ... },
}

JobConfig = {
    chop_tree = { skill = "woodcutting",   min_skill = 0, min_tier = Tier.SERF,    work_hours = 8   },
    build     = { skill = "construction",  min_skill = 0, min_tier = Tier.SERF,    work_hours = nil },
    harvest   = { skill = "farming",       min_skill = 0, min_tier = Tier.SERF,    work_hours = 4   },
    heal      = { skill = "medicine",      min_skill = 5, min_tier = Tier.FREEMAN, work_hours = 2   },
}

InjuryConfig = {
    bruised = { initial_damage = 10, recovery_per_hour = 0.5  },
    wounded = { initial_damage = 30, recovery_per_hour = 0.2  },
    maimed  = { initial_damage = 50, recovery_per_hour = 0.05 },
}

IllnessConfig = {
    cold        = { damage_per_hour = 0.1, recovery_chance = 0.08,  recovery_per_hour = 0.4  },
    flu         = { damage_per_hour = 0.2, recovery_chance = 0.08,  recovery_per_hour = 0.4  },
    the_flux    = { damage_per_hour = 0.4, recovery_chance = 0.10,  recovery_per_hour = 0.3  },
    consumption = { damage_per_hour = 0.1, recovery_chance = 0.005, recovery_per_hour = 0.2  },
    pox         = { damage_per_hour = 0.3, recovery_chance = 0.02,  recovery_per_hour = 0.2  },
    pestilence  = { damage_per_hour = 0.5, recovery_chance = 0.01,  recovery_per_hour = 0.15 },
}

MalnourishedConfig = { damage_per_hour = 0.3, recovery_per_hour = 0.5 }

BuildingConfig = {
    cottage = { width = 3, height = 3, build_cost = 80,  bed_count = 4, housing_tier = Tier.SERF    },
    house   = { width = 4, height = 3, build_cost = 150, bed_count = 6, housing_tier = Tier.FREEMAN },
    manor   = { width = 5, height = 4, build_cost = 300, bed_count = 8, housing_tier = Tier.GENTRY  },
}

ResourceSpawnConfig = {
    timber    = { min_depth = 0.0  },
    wildlife  = { min_depth = 0.0  },
    rare_herbs = { min_depth = 0.01 },
    alchemical = { min_depth = 0.6  },
    artifacts  = { min_depth = 0.8  },
}
```
