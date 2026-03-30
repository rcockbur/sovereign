# Sovereign — Design Document
*Working title. Version 0.4*

---

## Project Overview

**Stack:** Love2D · Lua · VS Code · PC (Windows primary)

**Concept:** A medieval village survival and management sim in the vein of Banished, RimWorld, and Dwarf Fortress. The player oversees a small settlement from its earliest days, guiding it through generations of growth, hardship, and discovery.

---

## Design Pillars

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

---

## Design Goals

- Readable, intuitive UI — a direct response to DF's weaknesses
- Mouse-driven PC controls
- Systems that remain engaging and legible at both small and large population sizes
- Population cap of approximately 200 units
- Multi-generational play within a single playthrough
- Late-game magic systems emerging naturally from existing unit progression

## What This Is Not

- Not trying to match DF's simulation depth or content breadth
- Not a roguelike
- Not multiplayer
- Not an RTS — combat exists but is not the focus

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

*Detailed succession traversal and regency mechanics are pending.*

---

## The Forest

The wilderness surrounding the settlement is not simply a resource zone — it is a place with its own character, rules, and inhabitants. It is the primary source of late-game mystery and opt-in escalation.

### Structure

The forest exists on the same map as the settlement, not as a separate zone. The player starts on the left side of the map. The left half has a forest depth of 0.0. Starting at the midpoint, depth increases linearly to 1.0 at the far right edge. Danger scales quadratically (depth²), making the deep forest disproportionately more threatening.

### Resources

Forest resources are tiered by depth. Basic materials are available everywhere, rarer materials require venturing deeper. Some late-game systems, including magic, are gated behind deep resources.

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

## Units

Every unit is simulated individually at all times. Players can configure units in work groups collectively or individually. In the late game, player attention naturally shifts toward Gentry and Freemen — Serfs can be managed in aggregate through group tooling, though individual control is always available.

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

*Full skill list is pending.*

### Relationships

- **Stored:** `father_id`, `mother_id`, `child_ids`, `spouse_id`, `friend_ids` (up to 3), `enemy_ids` (up to 3)
- **Derived:** siblings (query parent's children), half-siblings (share one parent), step-siblings (parent's spouse's children)
- No ex-spouse tracking. When a spouse dies, `spouse_id` goes nil. Dead spouse remains linked as parent to shared children via memory.
- No divorce. Marriage is permanent until death.

*Relationship depth, formation mechanics, and broader systemic effects are undecided.*

---

## Needs System

Four needs, same keys for all tiers. Values range 0–100, draining over time. Refilled by self-assigned unit behavior (eating, sleeping, attending church, recreation). Needs do **not** go through the job queue — when a need is critical, the unit interrupts their current work job and returns it to the queue.

Drain rates, mood thresholds, and mood penalty values are tier-specific (see CONTEXT.md for config tables).

---

## Mood System

Mood is **stateless** — recalculated from scratch each tick. Unbounded in both directions.

### Inputs

1. **Stored modifiers** — event-driven, decay over time (e.g. `{ source = "family_death", value = -20, hours_remaining = 14 * HOURS_PER_DAY }`)
2. **Calculated modifiers** — derived fresh each tick from current state, not stored on the unit:
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

Health is **stateless** — recalculated each tick as `100 + sum of all health modifier values`. Clamped 0–100. Unit dies at 0.

Three condition types stored in `health_modifiers`: **Injury**, **Illness**, **Malnourished**. All condition modifiers sum. The UI can always show a clean breakdown of why a unit has low health.

See CONTEXT.md for full config tables and modifier data structures.

---

## Job System

### Core Model

- **Single global job queue.** Tasks posted by the world (chop tree, construct building, haul resource, etc.).
- **Units poll the queue** when idle, filtered by tier and skill eligibility.
- **Needs bypass the queue.** Critical needs trigger self-assigned behavior directly.
- **Job output quality** scales with the unit's relevant Skill and Virtue levels.
- **Progress persists on abandonment.** Another unit can pick up where the last left off.

### Priority System

Four priority levels, configurable globally, per group, or per unit:

| Level | Value | Description |
|---|---|---|
| High | 3 | Urgent work |
| Normal | 2 | Default |
| Low | 1 | Background tasks |
| Disabled | 0 | Unit will not pull this job category |

### Idle Unit Flow
1. Check needs — if any critical, self-assign behavior, stop
2. Scan job queue: filter by tier >= `min_tier`, skill >= `min_skill`, priority not disabled
3. Among eligible jobs, pick highest priority
4. Tiebreak by distance (closer first) and job age (older first)
5. Claim job; move to position; work each hour (progress scales with skill/virtues)
6. On completion: effects apply, job removed

### Hauling

Workers own their full job cycle. No separate hauling job type. Carry capacity derived from Strength; each resource type has a Weight stat.

---

## Mover System

Movers are a dedicated job type for redistributing resources between stockpiles. By default nothing moves — the player configures rules.

- **Push:** when source has more than `threshold`, post jobs for the excess
- **Pull:** when target has less than `threshold`, post jobs to pull from source

Mover jobs go through the global job queue.

---

## Buildings

Blueprint-based placement. No room detection system. Player places a blueprint which claims tiles immediately. Units carry construction materials to the site, then build.

- Houses are assigned to families
- No hard cap on family size; overflow members sleep on the floor with a mood penalty
- Housing quality is per building type, not per instance
- Mood system checks building `housing_tier` against unit tier
- Player can toggle roof visibility to inspect interiors

---

## Map

Top-down 2D grid of tiles, procedurally generated. Single-zone. Player starts on the left half. Forest occupies the right half. Forest depth is fixed at map gen and never recalculated.

*Map size, generation parameters, and biome details are undecided.*

---

## Time

- 1 year = 4 seasons
- 1 season = 1 week (7 days, Sunday–Saturday)
- 1 day = 24 hours
- `seconds_per_hour` is the single pacing knob
- Weekly cadence supports recurring events (church on Sundays, market days, festivals)

Surviving the first winter is an intended milestone. Subsequent winters become progressively less threatening as the settlement matures, with new pressure sources taking over as the primary drivers of drama.

---

## Sections Pending Design

- **Economy and resources** — resource types, production chains, trade, stockpile data model
- **Full skill list and job categories**
- **Map and world generation** — parameters, biomes, starting conditions
- **UI/UX architecture** — interface design, information hierarchy, late-game management tools
- **Dynasty/succession implementation** — detailed succession traversal, regency mechanics
- **Event system** — Changeling, Fey encounters, random occurrences
- **Combat**
- **Fey encounter mechanics** — faction structure, bargaining outcomes
- **Magic system implementation** — spells, miracles, mechanical scope
