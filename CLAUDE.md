# Sovereign — Claude Context

Medieval village survival/management sim. Love2D (Lua), VS Code, Windows. ~200 unit population cap.

Full design doc: `docs/DESIGN.md`
Full coding context (data structures, config tables): `docs/CONTEXT.md`

---

## Folder Structure

```
main.lua
/src          -- (current: time.lua, world.lua)
/core         -- time, registry, world
/simulation   -- unit.lua, jobs, needs, mood, health
/config       -- all config tables
/ui           -- rendering and input
/events       -- event system, Fey, Changeling
```

---

## Conventions

- `snake_case` for variables and table keys
- `camelCase` for functions
- String identifiers for equality-only values (modifier sources, skill names, illness names, activity types)
- Integer constants for ordered/comparable values (tier, priority)
- One global incrementing ID counter across all entity types — no per-type counters

---

## Core Architecture Rules

**Units carry state. Config tables carry rules. Systems read both.**
Tier-based differences (drain rates, mood thresholds, job eligibility) live in config tables keyed by tier — never on the unit itself.

- **OO, not ECS.** ~200 units; ECS adds complexity without benefit.
- **No unit subclasses.** Tier differences are data, not behavior. Single `Unit` prototype with composed tier data. No subclasses — avoids runtime class-swapping on promotion/demotion.
- **Job queue: polling only.** Idle units scan the queue each tick. No event bus for idle notification.
- **Needs bypass the job queue.** Critical needs cause the unit to interrupt current work, return the job to the queue, and self-assign need behavior directly. Never post needs as jobs.
- **Mood and health are stateless.** Both recalculated from scratch each tick. Neither is stored between ticks.
- **Single-zone map.** `forest_depth` stored on tile at map gen, never recalculated. `forest_danger` derived on demand as `depth²`.
- **Workers own their full job cycle.** No separate hauling job type.

---

## Tick Order

1. Time advances
2. Units update needs; self-assign behavior if critical
3. Idle units poll the job queue
4. Units execute work
5. World processes results
6. Mood and health recalculated

---

## Module Ownership

| Module | Owns |
|---|---|
| **World** | Tile grid, buildings, resource nodes, forest depth map. Posts jobs to queue. |
| **Units** | All unit state. Creation, death (→ memory), promotion/demotion. |
| **Job Queue** | Standalone. Prioritized work task list. World posts; units claim. |
| **Time** | The clock. Drives the tick. |
| **Dynasty** | Succession logic, leader tracking, regency state. |
| **Events** | Changeling, Fey encounters, random occurrences. Stub for now. |
| **Registry** | `registry[id]` returns living unit or memory — single lookup pool. |

---

## Pending — Do Not Implement Without Discussion

These systems are intentionally undesigned. Implement only the minimum needed for current work; flag before going further:

- Economy, resources, production chains, trade
- Full skill list and job categories
- Map generation parameters
- UI/UX architecture
- Dynasty/succession traversal and regency mechanics
- Event system (Changeling outcomes, Fey encounters)
- Combat
- Fey faction structure and bargaining
- Magic system (spells, miracles, mechanical scope)
