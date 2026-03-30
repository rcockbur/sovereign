# Sovereign — Design & Architecture Document
*Working title. Version 0.3*

---

## Project Overview

**Stack:** Love2D · Lua · VS Code · PC (Windows primary)

**Concept:** A medieval village survival and management sim in the vein of Banished, RimWorld, and Dwarf Fortress. The player oversees a small settlement from its earliest days, guiding it through generations of growth, hardship, and discovery.

### Design Pillars

**Individual stories over aggregate statistics.**
At any point in the game, the player should be aware of a handful of specific individuals and following their development. Units are never anonymous — they have families, skills, histories, and fates the player comes to care about. Systems should actively surface interesting individuals rather than letting them be lost in the crowd.

**The dynasty is the through-line.**
The player's leader and their family are the main characters of every playthrough. The leader begins as a knight — a Gentry unit with a military background — and may rise to become a baron as the settlement grows. When the leader dies, succession rules determine who inherits. The leader's family, their heirs, and the crises that threaten the dynasty give each playthrough its narrative shape.

**Losing is fun.**
The goal is to build a large, stable village, and this is achievable — but random events, cascading failures, and chaotic emergent situations mean that losing is always possible. Failure should feel dramatic and earned rather than arbitrary.

**The forest is always there.**
The wilderness at the map's edge is a source of mystery, danger, and reward. Players can thrive without exploring it deeply, but the forest exerts a pull — some resources and late-game possibilities require venturing in. The deeper you go, the stranger it gets.

**Streamlined depth.**
DF depth without DF bloat. Systems should be rich enough to generate interesting situations but legible enough that the player always understands what is happening and why.

### Design Goals
- Readable, intuitive UI — a direct response to DF's weaknesses
- Mouse-driven PC controls
- Systems that remain engaging and legible at both small and large population sizes
- Population cap of approximately 200 units
- Multi-generational play within a single playthrough
- Late-game magic systems emerging naturally from existing unit progression

### What This Is Not
- Not trying to match DF's simulation depth or content breadth
- Not a roguelike
- Not multiplayer
- Not an RTS — combat exists but is not the focus

---

## Conventions

### Naming
- `snake_case` for variables and table keys
- `camelCase` for functions
- String identifiers for equality-only checks (modifier sources, skill names, illness names, activity types)
- Integer constants for ordered/comparable values (tier, priority)

### IDs
One global incrementing counter for all entity types (units, memories, buildings, jobs, furniture, mover rules). No collisions possible. A unit's id persists when they die and become a memory.

### Constants

```lua
Tier = { SERF = 1, FREEMAN = 2, GENTRY = 3 }
Priority = { DISABLED = 0, LOW = 1, NORMAL = 2, HIGH = 3 }
```

### Architecture Pattern
Units carry state. Config tables carry rules. Systems read both. Tier-based behavioral differences (need drain rates, mood thresholds, etc.) live in config tables keyed by tier, not on the unit.

---

## Time

- 1 year = 4 seasons
- 1 season = 1 week (7 days, Sunday–Saturday)
- 1 day = 24 hours
- `seconds_per_hour` is the single pacing knob
- Multiple generations expected within a single playthrough
- Weekly cadence supports recurring events (church on Sundays, market days, festivals, etc.)

All durations stored in hours internally. Helper constants for readability:

```lua
HOURS_PER_DAY = 24
DAYS_PER_SEASON = 7
SEASONS_PER_YEAR = 4
HOURS_PER_SEASON = HOURS_PER_DAY * DAYS_PER_SEASON
HOURS_PER_YEAR = HOURS_PER_SEASON * SEASONS_PER_YEAR
```

Surviving the first winter is an intended milestone. Subsequent winters become progressively less threatening as the settlement matures, with new pressure sources taking over as the primary drivers of drama.

---

## Module Ownership

- **World** — owns tile grid, buildings, resource nodes, forest depth map. Posts jobs to the queue when the world needs work done.
- **Units** — each unit is a table. Owns its own virtues, skills, needs, mood, health, relationships, tier, current activity. Also owns creation, death (conversion to memory), and promotion/demotion logic.
- **Job Queue** — standalone system. Owns the prioritized list of available work tasks. Exposes interface for world to post jobs and units to query/claim them.
- **Time** — owns the clock. Drives the tick. Other systems register with time or get called by it.
- **Dynasty** — owns succession logic, leader tracking, regency state. Reads from unit relationship graphs.
- **Events** — owns the event system (Changeling, Fey encounters, random occurrences). Reads from world and units, can modify both. Stub for now.

### Tick Order
1. Time advances
2. Units update needs; self-assign behavior if a need is critical
3. Idle units query the job queue
4. Units execute work
5. World processes results (resources gathered, buildings progressed, etc.)
6. Mood and health recalculated

---

## The Dynasty

The player's leader is always a specific, named Gentry unit — the most important individual in the settlement and the primary vehicle for player attachment.

### The Leader

The game begins with the leader as a knight (a Gentry unit with military skills) accompanied by a small founding group including a spouse and children. Starting with an established family ensures the player has individuals to care about from the first moments of play.

As the settlement grows, the leader may take on the title of baron. This is primarily thematic — it reflects the settlement's growth and the leader's status — and does not require modeling a detailed external political world.

### Succession

When the leader dies, succession proceeds as follows:

1. **Primogeniture.** The eldest child inherits. Gender does not affect succession.
2. **Regency.** If the heir is a child at the time of succession, an appointed Gentry unit serves as regent until the heir comes of age. Regency is a period of instability and vulnerability — a natural crisis structure if the leader dies unexpectedly.
3. **No family heir.** If no family heir exists, an existing Gentry unit inherits the leadership role. This is the fallback, not the primary system.

The possibility of a succession crisis — an unprepared heir, a power-hungry regent, a dynasty ended by misfortune — is an intended and desirable failure mode.

---

## The Forest

The wilderness surrounding the settlement is not simply a resource zone — it is a place with its own character, rules, and inhabitants. It is the primary source of late-game mystery and opt-in escalation.

### Structure

The forest exists on the same map as the settlement, not as a separate zone. The player starts on the left side of the map. The left half has a forest depth of 0.0. Starting at the midpoint, depth increases linearly to 1.0 at the far right edge. Danger scales quadratically (depth²), making the deep forest disproportionately more threatening.

### Resources

Forest resources are tiered by depth. Basic materials are available everywhere, rarer materials require venturing deeper. Some late-game systems, including magic, are gated behind deep resources.

```lua
ResourceSpawnConfig = {
    timber      = { min_depth = 0.0 },
    wildlife    = { min_depth = 0.0 },
    rare_herbs  = { min_depth = 0.01 },
    alchemical  = { min_depth = 0.6 },
    artifacts   = { min_depth = 0.8 },
}
```

### Inhabitants

The forest is home to animals, hostile human factions, ruins of unknown origin, and Fey.

**The Fey** are the forest's defining presence. They are not straightforwardly evil — they are ancient, strange, and operating by their own logic. Encounters with the Fey can be hostile, but they can also be negotiated. A unit with high Charisma sent as an envoy may achieve outcomes that warriors cannot.

The Fey want things. Two primary bargaining currencies:

- **Tribute** — resources offered on a recurring basis in exchange for safe passage or favor.
- **People** — in rare and significant moments, the Fey may demand a person. *(See: The Changeling Event.)*

*Fey faction structure, specific encounter types, and the full range of bargaining outcomes are undecided.*

### The Changeling Event

A rare, high-stakes event in which the Fey demand a child from the settlement. The player must decide whether to comply.

If the child is given, they disappear into the forest. After an in-game generation — long enough for the player to wonder — they return as a young adult, changed by their time among the Fey. The nature of that change is unpredictable: the returned changeling may come bearing gifts and goodwill, may return as a threat, or may be something harder to categorize.

The event is designed to carry maximum dramatic weight. The taken child should be someone the player knows — ideally connected to a family the player has followed. The worst version of this event: the Fey demand your heir.

*Specific mechanical outcomes for the returned changeling are undecided.*

---

## Magic

Magic is a late-game system that emerges from existing unit progression rather than being bolted on as a separate mechanic. It is rare, significant, and partially gated behind deep forest resources.

### Divine Magic

Priests who reach high levels of Wisdom and spiritual skill may begin to develop the ability to perform miracles. A veteran priest who has tended the village church for decades performing their first miracle is intended to be a story moment — something the player has earned through long investment in that individual.

### Arcane Magic

Scholars of sufficient Intelligence who pursue forbidden knowledge may learn to cast spells. Arcane magic is more explicitly tied to forest resources — alchemical ingredients, recovered artifacts, and stranger materials found deeper in the wilderness.

### Divine vs. Arcane Tension

The two magic types are not simply parallel tracks. A settlement with both a powerful priest and a practicing scholar may experience internal conflict — social, theological, or otherwise. This is a feature, not a problem to be solved.

*Specific spells, miracle types, and the mechanical scope of magic are undecided.*

---

## Registry

`registry[id]` returns either a living unit or a memory (dead unit). Single lookup pool. Code that follows relationship links does not need to know whether the target is alive or dead.

---

## Units

Every unit is simulated individually at all times. Players can configure units in work groups collectively or individually. In the late game, player attention naturally shifts toward Gentry and Freemen — Serfs can be managed in aggregate through group tooling, though individual control is always available.

### Unit Data

```lua
unit = {
    -- Identity
    id = 0,
    name = "",
    tier = Tier.SERF,
    age = 0,              -- cached, updated once per day tick
    birth_day = 0,         -- absolute world-day count
    is_leader = false,
    is_regent = false,

    -- Relationships (ids into registry)
    father_id = nil,
    mother_id = nil,
    child_ids = {},        -- unbounded
    spouse_id = nil,       -- current spouse, nullable
    friend_ids = {},       -- up to 3
    enemy_ids = {},        -- up to 3

    -- Virtues (sub-table)
    virtues = {
        strength = 0,
        intelligence = 0,
        dexterity = 0,
        wisdom = 0,
        constitution = 0,
        charisma = 0,
    },

    -- Skills (sub-table, every skill present, default 0)
    skills = {
        woodcutting = 0,
        farming = 0,
        combat = 0,
        construction = 0,
        medicine = 0,
        -- full list TBD
    },

    -- Needs (sub-table, 0–100, drain over time)
    needs = {
        hunger = 100,
        sleep = 100,
        recreation = 100,
        spirituality = 100,
    },

    -- Mood
    mood = 0,              -- recalculated each tick, unbounded both directions
    mood_modifiers = {},   -- stored decaying event modifiers only

    -- Health
    health = 100,          -- recalculated each tick: 100 + sum of modifiers. Clamped 0–100. Death at 0.
    health_modifiers = {}, -- injury, illness, malnourished conditions

    -- Activity
    current_job_id = nil,
    current_activity = nil, -- "working" | "eating" | "sleeping" | etc.

    -- Position
    x = 0,
    y = 0,
}
```

### Tiers

Three tiers: **Serf / Freeman / Gentry.** All tiers share the same underlying rules — no fundamentally different mechanics per tier. Differences are data-driven via config tables:

| Property | Effect |
|---|---|
| Needs profile | Higher tiers drain faster and have higher mood thresholds |
| Job eligibility | Higher tiers access more advanced jobs |
| Skill ceiling | Higher tiers can learn skills unavailable to lower tiers |

**Promotion** is a manual player action and is straightforward to perform.
**Demotion** is a manual player action and carries a one-time decaying mood modifier. Demoted units do not retain higher-tier needs.

Higher tier units are more costly and suffer mood debuffs when forced to perform menial work. Knights are Gentry units with a military skill focus — not a separate category.

### Virtues

Six core attributes that increase slowly through use. Cross-skill transfer applies — a virtue improved by one job carries over to other jobs that share the same virtue.

- **Strength** — physical labor, combat, carry capacity
- **Intelligence** — scholarship, crafting, arcane magic
- **Dexterity** — precision work, ranged combat
- **Wisdom** — spiritual development, divine magic, counsel
- **Constitution** — endurance, health recovery
- **Charisma** — negotiation, leadership, Fey diplomacy

### Skills

- Leveled by use (numeric proficiency, not discrete unlocks)
- Tied to one or more Virtues
- Gate job eligibility (minimum skill level required for some jobs)
- Determine job output quality (higher skill = faster work, less waste, more output)
- Some skills are only available to Freeman or Gentry tier
- Every skill key present on every unit, default 0

### Relationships

- **Stored:** `father_id`, `mother_id`, `child_ids`, `spouse_id`, `friend_ids` (up to 3), `enemy_ids` (up to 3)
- **Derived:** siblings (query parent's children), half-siblings (share one parent), step-siblings (parent's spouse's children)
- No ex-spouse tracking. When a spouse dies, `spouse_id` goes nil. Dead spouse remains linked as parent to shared children via memory.
- No divorce. Marriage is permanent until death.

*Relationship depth, formation mechanics, and broader systemic effects are undecided.*

---

## Memory (Dead Unit)

```lua
memory = {
    id = 0,              -- same id the unit had when alive
    name = "",
    father_id = nil,
    mother_id = nil,
    child_ids = {},
    spouse_id = nil,      -- who they were married to at death
    death_day = 0,
    death_cause = "",
}
```

No virtues, skills, needs, mood, health, position, or activity. Maintains the family graph and provides UI/flavor information.

---

## Needs System

Four needs, same keys for all tiers. Values range 0–100, draining over time. Refilled by self-assigned unit behavior (eating, sleeping, attending church, recreation). Needs do **not** go through the job queue — when a need is critical, the unit interrupts their current work job and returns it to the queue.

Drain rates, mood thresholds, and mood penalty values are tier-specific:

```lua
NeedsConfig = {
    [Tier.SERF] = {
        hunger = { drain_per_hour = 2, mood_threshold = 30, mood_penalty = -10 },
        sleep  = { drain_per_hour = 3, mood_threshold = 30, mood_penalty = -10 },
        -- ...
    },
    [Tier.FREEMAN] = {
        hunger = { drain_per_hour = 3, mood_threshold = 50, mood_penalty = -15 },
        -- ...
    },
    [Tier.GENTRY] = {
        hunger = { drain_per_hour = 4, mood_threshold = 60, mood_penalty = -20 },
        -- ...
    },
}
```

---

## Mood System

Mood is **stateless** — recalculated from scratch each tick. Unbounded in both directions.

### Inputs
1. **Stored modifiers** — event-driven, decay over time:
   ```lua
   { source = "family_death", value = -20, hours_remaining = 14 * HOURS_PER_DAY }
   ```
2. **Calculated modifiers** — derived fresh each tick from current state, not stored on the unit. Values come from config tables keyed by tier:
   - Need contributions (based on current need values and tier thresholds)
   - Housing quality (building `housing_tier` vs. unit tier)
   - Food variety (relative to tier expectations)
   - Luxury goods access (relative to tier expectations)
   - Job/tier mismatch (debuff while performing work below tier)
   - Health (penalty from low health)
   - Sleeping on floor (no bed assignment)

### Thresholds

| Threshold | Value | Effect |
|-----------|-------|--------|
| Inspired | 80+ | Productivity bonus |
| Content | 40–80 | No effect (baseline) |
| Sad | 20–40 | Slight productivity penalty |
| Distraught | 0–20 | Productivity penalty + chance for deviancy |
| Defiant | Below 0 | Won't work, high chance for deviancy |

---

## Health System

Health is **stateless** — recalculated each tick as `100 + sum of all health modifier values`. Clamped 0–100. Unit dies at 0. The UI can always show a clean breakdown of why a unit has low health.

Three condition types, stored in `health_modifiers`:

### Injury
```lua
{ type = "injury", name = "wounded", source = "mining accident",
  modifier = -30, is_treated = false }
```
- `modifier` starts at `-initial_damage`, recovers toward 0
- Recovery: modifier increments each hour by `recovery_per_hour` (doubled if treated)
- Removed when modifier reaches 0
- Multiple injuries allowed, including same type; distinguished by `source`

```lua
InjuryConfig = {
    bruised  = { initial_damage = 10, recovery_per_hour = 0.5 },
    wounded  = { initial_damage = 30, recovery_per_hour = 0.2 },
    maimed   = { initial_damage = 50, recovery_per_hour = 0.05 },
}
```

### Illness
```lua
{ type = "illness", name = "the_flux",
  modifier = 0, is_treated = false, is_recovering = false }
```
- `modifier` starts at 0, grows negative over time
- Each hour: roll for recovery; if passed, `is_recovering` flips to true
- While not recovering: modifier decreases by `damage_per_hour` (halved if treated)
- While recovering: modifier increases by `recovery_per_hour` (doubled if treated)
- Removed when modifier reaches 0 during recovery
- One per illness name maximum (can't have two colds, but can have cold + flux)
- Treatment is always a 2x multiplier on all three stats
- A single illness can kill on its own — even a cold, though unlikely

```lua
IllnessConfig = {
    cold        = { damage_per_hour = 0.1, recovery_chance = 0.08, recovery_per_hour = 0.4 },
    flu         = { damage_per_hour = 0.2, recovery_chance = 0.08, recovery_per_hour = 0.4 },
    the_flux    = { damage_per_hour = 0.4, recovery_chance = 0.10, recovery_per_hour = 0.3 },
    consumption = { damage_per_hour = 0.1, recovery_chance = 0.005, recovery_per_hour = 0.2 },
    pox         = { damage_per_hour = 0.3, recovery_chance = 0.02, recovery_per_hour = 0.2 },
    pestilence  = { damage_per_hour = 0.5, recovery_chance = 0.01, recovery_per_hour = 0.15 },
}
```

### Malnourished
```lua
{ type = "malnourished", modifier = 0, is_recovering = false }
```
- No severity, no treatment
- Grows while hunger is at 0; `is_recovering` flips when hunger is above 0
- Removed when modifier reaches 0 during recovery

```lua
MalnourishedConfig = { damage_per_hour = 0.3, recovery_per_hour = 0.5 }
```

### Stacking
All condition modifiers sum. A unit with a wounded injury (-30), a minor cold (-5 current), and malnourished (-8 current) has health = 100 + (-30) + (-5) + (-8) = 57.

---

## Map

Top-down 2D grid of tiles, procedurally generated. Single-zone — no separate maps or regions. Player starts on the left half. Forest occupies the right half.

*Map size, generation parameters, and biome details are undecided.*

### Tile
```lua
tile = {
    terrain = "grass",      -- "grass", "forest", "water", "stone", etc.
    building_id = nil,       -- claimed by a building blueprint, or nil
    resource = nil,          -- resource node on this tile, if any
    forest_depth = 0.0,      -- precomputed at map gen, never recalculated
}
```

### Forest Depth and Danger
```lua
function getForestDepth(x, world_width)
    local midpoint = world_width / 2
    if x <= midpoint then
        return 0.0
    else
        return (x - midpoint) / midpoint
    end
end

function getForestDanger(x, world_width)
    local depth = getForestDepth(x, world_width)
    return depth * depth
end
```

- **Depth** (linear, 0.0–1.0): resource spawning, anything that scales evenly
- **Danger** (quadratic, 0.0–1.0): encounter chance, Fey activity, hostile factions
- Both derived from x position. Only `forest_depth` stored on the tile.
- The forest does not retreat when the player builds into it — depth is fixed at map gen.

---

## Buildings

Blueprint-based placement. No room detection system (unlike RimWorld). Player places a blueprint which claims tiles immediately. Units carry construction materials to the site, then build.

### Building
```lua
building = {
    id = 0,
    type = "house",
    x = 0, y = 0,          -- top-left tile
    width = 0, height = 0,
    is_built = false,
    build_progress = 0,     -- 0 to build_cost from config
    interior = {},          -- list of furniture objects
}
```

### Furniture
```lua
{ type = "bed", x = 1, y = 0, assigned_unit_id = nil, occupied_unit_id = nil }
```

Furniture occupies full tiles. Interior positions are tile coordinates relative to the building origin. `assigned_unit_id` is persistent (whose bed), `occupied_unit_id` is transient (who's in it now).

The player can toggle roof visibility to inspect building interiors, see beds, and observe who is sleeping where.

### Housing

```lua
BuildingConfig = {
    cottage = { width = 3, height = 3, build_cost = 80,  bed_count = 4, housing_tier = Tier.SERF },
    house   = { width = 4, height = 3, build_cost = 150, bed_count = 6, housing_tier = Tier.FREEMAN },
    manor   = { width = 5, height = 4, build_cost = 300, bed_count = 8, housing_tier = Tier.GENTRY },
}
```

- Houses are assigned to families
- No hard cap on family size; overflow members sleep on the floor with a mood penalty
- Housing quality is per building type, not per instance
- Mood system checks building `housing_tier` against unit tier

---

## Job System

### Core Model

- **Single global job queue.** Tasks are posted by the world (chop this tree, haul this resource, construct this building, etc.).
- **Units pull from the queue** when idle, filtered by tier and skill eligibility.
- **Needs bypass the queue.** Units self-assign need behaviors when thresholds are critical.
- **Job output quality** scales with the unit's relevant Skill and Virtue levels.

### Job
```lua
job = {
    id = 0,
    type = "chop_tree",     -- string, keys into JobConfig
    priority = Priority.NORMAL,
    x = 0, y = 0,
    target_id = nil,         -- resource, building, or other entity
    claimed_by = nil,        -- unit id, or nil
    progress = 0,            -- 0 to completion threshold
}
```

### Job Config
```lua
JobConfig = {
    chop_tree = { skill = "woodcutting", min_skill = 0, min_tier = Tier.SERF, work_hours = 8 },
    build     = { skill = "construction", min_skill = 0, min_tier = Tier.SERF, work_hours = nil },
    harvest   = { skill = "farming", min_skill = 0, min_tier = Tier.SERF, work_hours = 4 },
    heal      = { skill = "medicine", min_skill = 5, min_tier = Tier.FREEMAN, work_hours = 2 },
}
```

### Priority System

Four priority levels. Priority is configurable globally, per group, or per unit.

| Level | Value | Description |
|---|---|---|
| High | 3 | Urgent work |
| Normal | 2 | Default for most work |
| Low | 1 | Background tasks |
| Disabled | 0 | Unit will not pull this job category |

### Idle Unit Flow
1. Check needs — if any critical, self-assign behavior, stop
2. Scan job queue: filter by tier >= `min_tier`, skill >= `min_skill`, priority not disabled
3. Among eligible jobs, pick highest priority
4. Tiebreak by combination of distance (closer first) and job age (older first)
5. Claim job; move to position; work each hour (progress scales with skill/virtues)
6. On completion: effects apply, job removed

### Job Abandonment
Progress persists when a unit leaves a job (need became critical, player reassigned). Another unit can pick it up.

### Hauling
Workers handle their own complete job cycle. A woodcutter chops the tree and carries logs to the nearest stockpile. A builder fetches materials and builds. No separate hauling step or hauling job type.

Carry capacity is derived from Strength. Each resource type has a Weight stat.

---

## Mover System

Movers are a dedicated job type for redistributing resources between stockpiles. By default there is nothing to move — the player configures rules.

### Mover Rule
```lua
mover_rule = {
    id = 0,
    source_building_id = 0,
    target_building_id = 0,
    resource = "timber",
    mode = "push",          -- "push" or "pull"
    threshold = 100,
}
```

- **Push:** when source has more than `threshold`, post jobs for the excess
- **Pull:** when target has less than `threshold`, post jobs to pull from source

### Mover Job
```lua
{
    id = 0,
    type = "move_resource",
    priority = Priority.NORMAL,
    source_building_id = 0,
    target_building_id = 0,
    resource = "timber",
    amount = 0,
    claimed_by = nil,
}
```

Mover jobs go through the global job queue. Carry capacity derived from Strength and resource weight.

---

## World

```lua
world = {
    width = 0,
    height = 0,
    tiles = {},          -- 2D array of tile objects
    buildings = {},      -- keyed by building id
    resources = {},      -- keyed by resource id
    job_queue = {},      -- the global job queue
}
```

---

## Sections Pending Design & Architecture

- **Economy and resources** — resource types, production chains, trade, stockpile data model
- **Full skill list and job categories**
- **Map and world generation** — parameters, biomes, starting conditions
- **UI/UX architecture** — interface design, information hierarchy, late-game management tools
- **Dynasty/succession implementation** — detailed succession traversal, regency mechanics
- **Event system** — Changeling, Fey encounters, random occurrences
- **Combat**
- **Fey encounter mechanics** — faction structure, bargaining outcomes
- **Magic system implementation** — spells, miracles, mechanical scope