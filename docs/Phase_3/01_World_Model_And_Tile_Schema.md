# World Model and Tile Schema — The Drawdown Protocol (Phase 3)

## Reconciliation: what "the board" means for this concept

Plan.md calls Phase 3 "Isometric Board and Tile Model" — written for the old bioregion
concept. The updated concept plays on a **world of countries**, and the Phase 0 MVP scope
(`../Phase_0/03_MVP_Scope.md`) demoted the isometric map to nice-to-have, keeping
parameter-level procgen as the must-have. **Decision: Phase 3 is reframed as "World Model
and Board View", in two tiers.**

- **Tier A (MVP must-have):** a data-level **world model** — ~12 procedurally generated
  regions (countries) with typed fields — plus an abstract **dashboard board view** that
  renders them. This is what the loop actually needs: diplomacy targets, event flavor and
  scars, and per-seed world variety.
- **Tier B (nice-to-have, specified now so the pipeline is ready):** an **isometric tile
  visual layer** on top of the same model, delivering the grey-to-solarpunk arc
  (`03_Board_Rendering_Spec.md`).

Rationale: golden rules 1 and 3 — the smallest fun loop needs a world model, not tile art;
building the isometric layer before the loop is proven was Risk #6 in
`../Phase_0/06_Risk_Register.md`. **This does not amend the MVP scope table**; it
implements its must-have "procedurally generated starting world" row and specs its
nice-to-have map row. The load-bearing rule for both tiers:

> **Tiles and region panels render state; they never own state.** All simulation lives in
> the global model from `../Phase_1/01_Balance_Model.md`. Region data *decomposes* global
> values for display, targeting, and flavor — it never forks them.

## RegionData schema (Tier A — custom Resource)

```gdscript
class_name RegionData
extends Resource

@export var id: StringName            # stable, e.g. &"region_07"
@export var display_name: String      # procgen name, e.g. "Korvatna"
@export var archetype: StringName     # preset id, see 02_Procgen spec
# --- decomposition of global simulation values (fractions, generated once) ---
@export var ind_share: float          # fraction of global industry base (20 Gt)
@export var tra_share: float          # fraction of global transport base (15 Gt)
@export var agr_share: float          # fraction of global agro base (15 Gt)
@export var sink_share: float         # fraction of global absorption A
# --- vulnerability tags (drive event targeting weights) ---
@export var coastal: bool = false     # eligible for flood/tsunami
@export var arid: bool = false        # heat-wave weight x2, fire-eligible
@export var forested: bool = false    # fire-eligible, sink flavor
# --- diplomacy ---
@export var is_player_home: bool = false
@export var alliance_affinity: float = 1.0   # 0.8-1.2; MVP: flavor only, no cost effect
# --- runtime (not exported; owned by RunState, mirrored here for the view) ---
var ally_state: AllyState = AllyState.NEUTRAL   # NEUTRAL / ALLY / PLAYER_HOME
var scars: Array[StringName] = []               # e.g. [&"burned_2047", &"flooded_2051"]
```

`AllyState` is an enum in a shared `WorldEnums` script. `alliance_affinity` is a declared
tuning knob with **no effect in MVP** — DIP1 costs exactly 25 Influence per the balance
model; wiring affinity into cost would silently change Phase 1 numbers.

### Derived (never stored) region values

| Display value | Formula (from global state) |
|---|---|
| Region emissions | `Σ_s base_s × share_s(region) × (1 − 0.9 × prog_s / 100)` |
| Region absorption | `A × sink_share` |
| Region net | emissions − absorption |
| Transition stage shown | global `prog_s` (MVP mirrors global progress; per-region progress is out of scope) |

## Aggregation invariants (unit-tested, see 06)

- For each sector `s`: `Σ regions share_s = 1.0 ± 0.001`.
- `Σ regions sink_share = 1.0 ± 0.001`.
- `Σ regions derived emissions == global E` (same tolerance) every year.
- Exactly one region has `is_player_home = true`; it is never an event flavor target for
  ally-loss (you cannot lose yourself).
- At least 2 coastal and 2 forested-or-arid regions per world (event eligibility floor).

## TileData schema (Tier B — visual projection only)

```gdscript
class_name TileVisual              # deliberately not "TileData" (engine name clash)
extends RefCounted

var coord: Vector2i                # cell in the region diorama grid (12 x 12)
var terrain: Terrain               # URBAN, INDUSTRIAL, FIELD, FOREST, WATER, COAST
var sector: SectorTag              # IND, TRA, AGR, SINK, NONE (which progress drives it)
var stage: int                     # 0..3 visual state: smog-grey .. solarpunk
var scar: Scar                     # NONE, BURNED, FLOODED
var variant: int                   # per-tile jitter for stage thresholds and art variant
```

No simulation fields, no setters called by gameplay code: `stage` is recomputed from
`(global sector progress, variant)` on `year_advanced`, `scar` from region scars. Tiles
can be discarded and rebuilt from `(seed, region, global state)` at any time — that is
the determinism test in `06_Done_Criteria_And_Tests.md`.

## Link to the metric dictionary

| Region field | Decomposes / flavors (Phase_0/04 metric) |
|---|---|
| `ind/tra/agr_share` | Sector base emissions (E) |
| `sink_share` | Absorption (A) |
| `ally_state` | Allies count (diplomacy) |
| `coastal/arid/forested` | Event system targeting (no magnitude effect) |
| `scars` | Fires counter and event log, visualized |
| `stage` (tiles) | Sector progress %, visualized |

Money, Happiness, Influence, Warming, Resilience remain **global-only** metrics with no
per-region decomposition in MVP — putting them on regions would imply simulation depth
the model does not have (readable balance, pillar 1).
