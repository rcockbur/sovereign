# Sovereign — Design Document
*Working title. Version 0.6*

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

## Time

### Calendar

- 1 game_year = 4 seasons (Spring, Summer, Autumn, Winter)
- 1 season = 7 days (Sunday through Saturday)
- 1 day = 24 game_hours
- 1 game_hour = 60 game_minutes

Game_minutes are an internal config unit, not shown to the player. The smallest player-facing time unit is the game_hour.

### Player Display

The player sees datetime in the format: **Year 4 - Spring - Tuesday - 3:00 PM**

The weekly cadence supports recurring events: church on Sundays, market days, festivals.

### Day/Night Cycle

Daytime runs from 6am to 6pm. Nighttime from 6pm to 6am. Units are awake from 6am to 10pm (16 waking hours) and sleep from 10pm to 6am (8 sleeping hours). The day/night cycle is functional — it structures the unit's daily routine, not just a visual effect.

### Pacing

One game_day = 10 real minutes at Normal speed (25 real seconds per game_hour).

| Speed | Multiplier | Real minutes per game_day | Real minutes per game_year |
|---|---|---|---|
| Normal | x1 | 10 | 280 (~4.7 hrs) |
| Fast | x2 | 5 | 140 (~2.3 hrs) |
| Very Fast | x4 | 2.5 | 70 (~1.2 hrs) |
| Ultra | x8 | 1.25 | 35 min |

### Starting Conditions

The game begins at **6:00 AM, Sunday, Spring, Year 1**.

### Event Speed Controls

The player can configure auto-pause or auto-slowdown for specific event types (e.g., unit death, succession, Fey encounter, illness outbreak).

*Event type list and configuration UI are pending.*

### Simulation Tick

The simulation runs at 60 ticks per real second at Normal speed, scaling with the speed multiplier. Entity updates are distributed across ticks using hash offsets — each entity updates once per real second at Normal speed. See CONTEXT.md for tick system details.

### Seasonal Milestones

Surviving the first winter is an intended milestone. Subsequent winters become progressively less threatening as the settlement matures, with new pressure sources taking over as the primary drivers of drama.

---

## Aging

Units age 1 life-year per season (4 life-years per calendar year). A unit born on Day 3 of Spring ages up when Day 3 of Summer arrives, then again on Day 3 of Autumn, and so on — each unit ages on their own birth-season anniversary, not all at once.

Adulthood is reached at age 16 (4 calendar years / 16 seasons from birth). Average lifespan is approximately 60 life-years (~15 calendar years).

A generation — the time between a leader taking power and their heir succeeding them — is roughly 8–10 calendar years. At Fast speed (x2), this translates to roughly 9–12 real hours of play, spread across multiple sessions.

---

## The Dynasty

The player's leader is always a specific, named Gentry unit — the most important individual in the settlement and the primary vehicle for player attachment.

### The Leader

The game begins with the leader as a knight (a Gentry unit with military skills) accompanied by a small founding group including a spouse and children. Starting with an established family ensures the player has individuals to care about from the first moments of play.

As the settlement grows, the leader may take on the title of baron. This is primarily thematic — it reflects the settlement's growth and the leader's status.

### Succession

When the leader dies, succession proceeds as follows:

1. **Primogeniture.** The eldest child inherits. Gender does not affect succession.
2. **Regency.** If the heir is a child (under 16), an appointed Gentry unit serves as regent until the heir comes of age.
3. **No family heir.** If no family heir exists, an existing Gentry unit inherits the leadership role.

*Detailed succession traversal and regency mechanics are pending.*

---

## The Forest

The wilderness surrounding the settlement is not simply a resource zone — it is a place with its own character, rules, and inhabitants. It is the primary source of late-game mystery and opt-in escalation.

### Structure

The forest exists on the same map as the settlement, not as a separate zone. The player starts on the left side of the map. The left half has a forest depth of 0.0. Starting at the midpoint, depth increases linearly to 1.0 at the far right edge. Danger scales quadratically (depth²).

### Resources

Forest resources are tiered by depth. Basic materials are available everywhere, rarer materials require venturing deeper. Some late-game systems, including magic, are gated behind deep resources.

### Inhabitants

The forest is home to animals, hostile human factions, ruins of unknown origin, and Fey.

**The Fey** are the forest's defining presence. They are not straightforwardly evil — they are ancient, strange, and operating by their own logic. A unit with high Charisma sent as an envoy may achieve outcomes that warriors cannot.

*Fey faction structure, specific encounter types, and the full range of bargaining outcomes are undecided.*

### The Changeling Event

A rare, high-stakes event in which the Fey demand a child from the settlement. The player must decide whether to comply. If given, the child returns after a generation, changed unpredictably.

*Specific mechanical outcomes for the returned changeling are undecided.*

---

## Magic

Magic is a late-game system that emerges from existing unit progression rather than being bolted on as a separate mechanic. It is rare, significant, and partially gated behind deep forest resources.

### Divine Magic

Priests/Bishops who reach high levels of Wisdom and priesthood skill may begin to develop the ability to perform miracles.

### Arcane Magic

Scholars of sufficient Intelligence who pursue forbidden knowledge may learn to cast spells. Arcane magic is more explicitly tied to forest resources.

### Divine vs. Arcane Tension

The two magic types are not simply parallel tracks. A settlement with both a powerful priest and a practicing scholar may experience internal conflict. This is a feature, not a problem to be solved.

*Specific spells, miracle types, and the mechanical scope of magic are undecided.*

---

## Units

Every unit is simulated individually at all times. In the late game, player attention naturally shifts toward Gentry and Freemen — Serfs can be managed in aggregate through group tooling, though individual control is always available.

### Tiers

Three tiers: **Serf / Freeman / Gentry.** All tiers share the same underlying rules — differences are data-driven via config tables:

| Property | Effect |
|---|---|
| Needs profile | Higher tiers drain faster and have higher mood thresholds |
| Skills | Serfs cannot learn skills. Freeman and Gentry can. |
| Job eligibility | T1 for any unit. T2 requires Freeman+. T3 requires Gentry. |
| Mood penalties | Higher tiers are unhappy performing work below their tier |

**Promotion** is a manual player action and is straightforward to perform.
**Demotion** is a manual player action and carries a one-time decaying mood modifier.

### Attributes

Five core attributes that increase slowly through use:

- **Strength** — physical labor, hauling, melee combat
- **Dexterity** — precision crafting, smithing, hunting, tailoring
- **Intelligence** — knowledge work, construction, brewing, baking, scholarship
- **Wisdom** — farming, fishing, gathering, medicine, herbalism, priesthood
- **Charisma** — trading, leadership, barkeeping

All units grow attributes through work, including Serfs and children.

### Skills

- Leveled by use (numeric proficiency, default 0)
- Skill caps are per-job, not per-unit
- Serfs cannot learn skills (effective cap of 0)
- Freeman and Gentry grow skills through T2/T3 work
- Every skill key present on every unit, default 0

**15 skills:** melee_combat, smithing, hunting, tailoring, baking, brewing, construction, scholarship, herbalism, medicine, priesthood, barkeeping, trading, jewelry, leadership

### Job Tiers

- **T1 (Unskilled):** Any unit. Attribute only. Intended for Serfs. Higher tiers get mood penalties.
- **T2 (Skilled):** Freeman+ only. Attribute + skill. Gentry get mood penalties.
- **T3 (Skilled, Elite):** Gentry only. Attribute + skill. Highest specialization.

T2/T3 career ladders sharing the same skill: Guard→Knight (melee_combat), Smith→Armorer (smithing), Builder→Architect (construction), Teacher→Scholar (scholarship), Healer→Physician (medicine), Priest→Bishop (priesthood), Merchant→Steward (trading).

### Full Job Table

**T1 — Unskilled (any unit, attribute only):**

| Job | Attribute |
|---|---|
| Hauler | Strength |
| Woodcutter | Strength |
| Miner | Strength |
| Stonecutter | Strength |
| Miller | Strength |
| Farmer | Wisdom |
| Fisher | Wisdom |
| Gatherer | Wisdom |

**T2 — Skilled (Freeman+, attribute + skill):**

| Job | Attribute | Skill | Max Skill |
|---|---|---|---|
| Guard | Strength | melee_combat | 5 |
| Smith | Dexterity | smithing | 5 |
| Huntsman | Dexterity | hunting | 5 |
| Tailor | Dexterity | tailoring | 5 |
| Baker | Intelligence | baking | 5 |
| Brewer | Intelligence | brewing | 5 |
| Builder | Intelligence | construction | 5 |
| Teacher | Intelligence | scholarship | 5 |
| Herbalist | Wisdom | herbalism | 5 |
| Healer | Wisdom | medicine | 5 |
| Priest | Wisdom | priesthood | 5 |
| Barkeep | Charisma | barkeeping | 5 |
| Merchant | Charisma | trading | 5 |

**T3 — Elite (Gentry only, attribute + skill):**

| Job | Attribute | Skill | Max Skill |
|---|---|---|---|
| Knight | Strength | melee_combat | 10 |
| Armorer | Dexterity | smithing | 10 |
| Jeweler | Dexterity | jewelry | 10 |
| Architect | Intelligence | construction | 10 |
| Scholar | Intelligence | scholarship | 10 |
| Physician | Wisdom | medicine | 10 |
| Bishop | Wisdom | priesthood | 10 |
| Steward | Charisma | trading | 10 |
| Leader | Charisma | leadership | 10 |

### Children

Children (under 16) can be assigned to **school** or to limited safe T1 jobs: Hauler, Farmer, Gatherer, Fisher.

Children have a fast-draining recreation need, causing frequent play interrupts that naturally limit productive hours without requiring a special schedule system.

- **School child** — grows Intelligence, Wisdom, Charisma. Enters adulthood with strong mental attributes.
- **Working child** — grows Strength or Wisdom through labor. Provides immediate economic value.
- **Idle child** — grows nothing meaningfully.

School vs. work is a binary assignment on the unit's job priority UI. Choosing school greys out all job options.

### Relationships

- **Stored:** `father_id`, `mother_id`, `child_ids`, `spouse_id`, `friend_ids` (up to 3), `enemy_ids` (up to 3)
- **Derived:** siblings (query parent's children), half-siblings, step-siblings
- No divorce. Marriage is permanent until death.

*Relationship formation mechanics are undecided.*

---

## Needs System

Three needs: **hunger, sleep, recreation.** Values range 0–100, draining over time. Refilled by self-assigned behavior (eating at home, sleeping at home, visiting the tavern). Needs bypass the job queue — when critical, the unit interrupts work.

Spirituality is not a need — it is handled by the scheduled Sunday church service.

Drain rates, mood thresholds, and mood penalty values are tier-specific. Children have a faster recreation drain rate.

---

## Mood System

Mood is **stateless** — recalculated from scratch on each unit's hashed update. Unbounded in both directions.

### Inputs

1. **Stored modifiers** — event-driven, decay over time (e.g. `{ source = "family_death", value = -20, ticks_remaining = 14 * TICKS_PER_DAY }`)
2. **Calculated modifiers** — derived fresh from current state:
   - Need contributions (based on current need values and tier thresholds)
   - Housing quality (building `housing_tier` vs. unit tier)
   - Food variety (distinct food types stocked in household)
   - Clothing (tier-appropriate clothing in household)
   - Luxury goods (jewelry for Gentry)
   - Job/tier mismatch (debuff for work below tier)
   - Health (penalty from low health)
   - Sleeping on floor (no bed assignment)
   - Sunday service attendance (weekly decaying modifier)
   - Funeral/wedding attendance (event-driven modifier)

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

Health is **stateless** — recalculated on each unit's hashed update as `100 + sum of all health modifier values`. Clamped 0–100. Unit dies at 0.

Three condition types: **Injury**, **Illness**, **Malnourished**. See CONTEXT.md for config tables.

---

## Job System

### Core Model

- **Single global job queue.** Tasks posted by the world.
- **Units poll the queue** when idle, filtered by tier and skill eligibility.
- **Needs bypass the queue.** Critical needs trigger self-assigned behavior.
- **Job output quality** scales with attribute (T1) or attribute + skill (T2/T3).
- **Progress persists on abandonment.**

### Priority System

| Level | Value | Description |
|---|---|---|
| High | 3 | Urgent work |
| Normal | 2 | Default |
| Low | 1 | Background tasks |
| Disabled | 0 | Unit will not pull this job category |

### Hauling

Workers own their full job cycle. No separate hauling job type. Carry capacity derived from Strength.

---

## Consumption Model

### Eat at Home

Units consume food, clothing, and luxury goods at their assigned home. Households track stocked goods. Mood modifiers are calculated per-household based on availability vs. tier expectations.

### Market Distribution

The Market is a staffed building. The Merchant pulls consumer goods from stockpiles and delivers them directly to homes via delivery routes. Uses greedy nearest-neighbor routing per trip, limited by carry capacity. Trading skill determines throughput.

Without a market, units self-fetch from the nearest stockpile — functional but inefficient. The market replaces many individual fetch trips with one merchant doing delivery loops.

### Communal Fallback

Units without a home assignment eat from a communal stockpile directly. Mood penalty ("no home") pressures the player to build housing.

### Consumer Goods

- **Food** — bread, vegetables, meat, fish. Variety (distinct types in household) drives mood.
- **Clothing** — tier-appropriate. Missing or wrong-tier = mood penalty.
- **Beer** — consumed at the Tavern, not at home.
- **Jewelry** — Gentry luxury good. Absence = Gentry mood penalty.

---

## Mover System

Movers redistribute resources between stockpiles via player-configured rules:

- **Push:** when source exceeds threshold, post jobs for excess
- **Pull:** when target is below threshold, post jobs to pull from source

Mover jobs go through the global job queue.

---

## Production Chains

### Food

| Chain | Steps |
|---|---|
| Bread | Wheat Farm (Farmer, T1) → wheat → Mill (Miller, T1) → flour → Bakery (Baker, T2) → bread |
| Vegetables | Gatherer's Hut (Gatherer, T1) → vegetables |
| Meat | Hunting Cabin (Huntsman, T2) → meat |
| Fish | Fishing Dock (Fisher, T1) → fish |

Bread is most efficient at scale but requires three buildings and a Freeman baker. Vegetables and fish are simple but bottlenecked by natural supply. Meat requires a Freeman huntsman. Food variety drives household mood.

### Alcohol

| Chain | Steps |
|---|---|
| Beer | Barley Farm (Farmer, T1) → barley → Brewery (Brewer, T2) → beer |

Beer is consumed at the Tavern. Barley competes with wheat and flax for farm plots.

### Textiles

| Chain | Steps |
|---|---|
| Clothing | Flax Farm (Farmer, T1) → flax → Tailor's Shop (Tailor, T2) → clothing |

### Metal

| Chain | Steps |
|---|---|
| Iron goods | Mine (Miner, T1) → iron → Smithy (Smith, T2) → tools, weapons, armor |
| Steel goods | Mine (Miner, T1) → iron → Foundry (Armorer, T3) → steel → elite tools, weapons, armor |
| Jewelry | Mine (Miner, T1) → rare gold/silver/gems → Jeweler's Workshop (Jeweler, T3) → jewelry |

Iron is the baseline metal. Steel is a late-game upgrade: the Foundry refines iron into steel and produces finished elite goods. Precious metals and gems are rare erratic outputs from the mine.

### Construction Materials

| Source | Output |
|---|---|
| Woodcutter's Camp (Woodcutter, T1) | Logs |
| Quarry (Stonecutter, T1) | Stone |

No processing step — raw materials go directly to construction sites.

### Medicine

| Chain | Steps |
|---|---|
| Treatment | Forest (Herbalist, T2) → herbs → Infirmary (Healer/Physician, T2/T3) → treatment |

### Farm Allocation

Farms are a single building type with per-plot crop selection: wheat, barley, or flax. Three crops compete for farm space: wheat → bread (food), barley → beer (recreation), flax → clothing (mood).

---

## Buildings

### Housing

| Building | Housing Tier |
|---|---|
| Cottage | Serf |
| House | Freeman |
| Manor | Gentry |

Interior positions (beds) defined in building config, created on construction completion. Units are always visible — never hidden inside buildings. Player can toggle roof visibility to inspect interiors.

### Agriculture

| Building | Notes |
|---|---|
| Farm Plot | Single type, per-plot crop selection (wheat, barley, flax) |

### Resource Extraction

| Building | Job | Output |
|---|---|---|
| Woodcutter's Camp | Woodcutter (T1) | Logs |
| Mine | Miner (T1) | Iron, rare gold/silver/gems |
| Quarry | Stonecutter (T1) | Stone |
| Gatherer's Hut | Gatherer (T1) | Vegetables (limited by natural supply) |
| Hunting Cabin | Huntsman (T2) | Meat (limited by deer population) |
| Fishing Dock | Fisher (T1) | Fish (limited by water access) |

### Processing

| Building | Job | Input → Output |
|---|---|---|
| Mill | Miller (T1) | Wheat → flour |
| Bakery | Baker (T2) | Flour → bread |
| Brewery | Brewer (T2) | Barley → beer |
| Tailor's Shop | Tailor (T2) | Flax → clothing |
| Smithy | Smith (T2) | Iron → tools, weapons, armor |
| Foundry | Armorer (T3) | Iron → steel → elite tools, weapons, armor |
| Jeweler's Workshop | Jeweler (T3) | Gold/silver/gems → jewelry |

### Services

| Building | Job | Function |
|---|---|---|
| Market | Merchant (T2) | Delivers consumer goods to homes |
| Church | Priest (T2) / Bishop (T3) | Sunday service, weekday prayer, funerals, weddings |
| Infirmary | Healer (T2) / Physician (T3) | Treats sick/injured, consumes herbs |
| Tavern | Barkeep (T2) | Recreation hub. Unstaffed: socializing only. Staffed: beer served, skill reduces consumption |
| School | Teacher (T2) | Children grow Int/Wis/Cha. Teacher's scholarship skill sets growth rate |
| Library | Scholar (T3) | Late-game scholarship and arcane research |

#### Church Details

- **Monday–Saturday:** Priest prays (priesthood skill and Wisdom grow)
- **Sunday:** All units attend service. Decaying mood modifier applied, quality scales with priesthood skill.
- **Events:** Funerals (comfort modifier for bereaved) and weddings (mood boost for attendees) as they occur.

#### Market Details

Merchant delivers consumer goods from stockpiles to homes via greedy nearest-neighbor routes. Carry capacity limits deliveries per trip. Trading skill determines throughput. Without a market, households self-fetch.

#### Tavern Details

Units visit the Tavern to fulfill recreation need. Without a barkeep, units socialize only (partial recreation). With a staffed barkeep, beer is served — full recreation bonus. Higher barkeeping skill reduces beer consumed per visit, stretching barley supply further.

### Storage

| Building | Notes |
|---|---|
| Stockpile | Free, outdoor, limited capacity |
| Warehouse | Built, indoor, higher capacity |

### Military

| Building | Notes |
|---|---|
| Barracks | Military housing and training |
| Watchtower | Early warning |
| Walls/Palisade | Defensive perimeter |

### Governance

| Building | Notes |
|---|---|
| Town Hall | Unlocks when leader becomes baron |

---

## Map

Top-down 2D grid of tiles, procedurally generated. Single-zone. Player starts on the left half. Forest occupies the right half. Forest depth fixed at map gen.

*Map size, generation parameters, and biome details are undecided.*

---

## Sections Pending Design

- **Economy details** — stockpile data model, tool requirements, resource weights
- **Map and world generation** — parameters, biomes, starting conditions
- **UI/UX architecture** — interface design, information hierarchy, management tools
- **Dynasty/succession implementation** — traversal, regency mechanics
- **Event system** — Changeling, Fey encounters, random occurrences
- **Event speed controls** — configurable auto-pause/slowdown per event type
- **Combat** — mechanics, military behavior, threat types
- **Fey encounter mechanics** — faction structure, bargaining outcomes
- **Magic system implementation** — spells, miracles, mechanical scope
- **Animal husbandry** — livestock, pastures (deferred)
- **External trade** — caravans, external economy (scope TBD)
