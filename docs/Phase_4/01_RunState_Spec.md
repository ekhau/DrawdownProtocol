# RunState Spec — The Drawdown Protocol (Phase 4)

The single source of truth for one run. Plain, headless-capable, signal-emitting; the UI
never computes gameplay values (Plan.md engineering rules). Everything here implements
the yearly crisis-response pipeline of `../Phase_1/01_Balance_Model.md` 1:1, over the
world model of `../Phase_3/01_World_Model_And_Tile_Schema.md`.

## Ownership and shape

```
Sim (Node)                       # scene-facing owner; instantiated by Main or headless harness
└── run_state: RunState          # RefCounted; zero scene dependencies; unit-testable alone
```

`RunState` never touches nodes, autoloads, or `OS`; its only nondeterminism is its own
`rng_events` (stream 2 per `../Phase_3/02_Procedural_Generation_Spec.md`), consumed
**only by the year-start crisis draw**. Sim forwards RunState's emissions as the
scene-level signals of `../Phase_3/03_Board_Rendering_Spec.md`.

## Typed fields (each links to `../Phase_0/04_Simulation_Metric_Dictionary.md`)

```gdscript
class_name RunState
extends RefCounted

# --- identity / timeline ---
var run_seed: int
var year: int = 2030                      # metric: Year
var phase: Phase = Phase.AWAIT_ACTION     # turn state machine, below
# --- pillars and warming ---
var temp: float = 1.30                    # metric: Warming T (°C)
var money: float                          # metric: Money M (jittered start)
var happiness: float                      # metric: Happiness H
var influence: float = 10.0               # metric: Influence I
# --- carbon ledger ---
var sectors: Dictionary = {}              # StringName -> SectorState (ind, tra, agr)
var absorption: float                     # metric: Absorption A (jittered start)
var e_extra: float = 0.0                  # metric: feedback extras
var reforest_queue: Array[ReforestEntry] = []
# --- diplomacy / society ---
var allies: int = 0
var adapt: float = 0.0                    # clamp 0..60 (see 02, clarification C2)
var media: bool = false
var window: bool = false
var fire_discount: bool = false
var flood_rebuild: bool = false
# --- crises (drawn at year start; resolved at year end) ---
var pending_crises: Array[Dictionary] = []  # {id, kind, region_id, answered, answered_by}
# --- combos ---
var combo_chain: int = 0                  # +1 per combo, -1 on comboless years, min 0
var combos_fired_run: Dictionary = {}     # combo id -> fires this run (knowledge gating)
# --- long-term projects ---
var active_projects: Array[ProjectState] = []   # max PROJECT_MAX_ACTIVE
var project_history: Dictionary = {}      # id -> "completed" | "failed" | "abandoned"
var passives: Dictionary = {}             # aggregated completion powers
# --- run counters (deck growth + meta) ---
var crises_answered_total: int = 0
var combos_total: int = 0
var projects_completed: int = 0
var kp_earned: int = 0                    # in-run Knowledge (added to the KP award)
var unlocked_card_ids: Array[StringName] = []
# --- feedback loop one-shots ---
var fires: int = 0
var feedback_years: Dictionary = {}       # event id -> trigger year
# --- world (Phase 3) ---
var world: Array[RegionData] = []
var rng_events: RandomNumberGenerator     # ONLY rng inside RunState
var records: Array[TurnRecord] = []       # see 06_Turn_Log_And_Analytics.md
```

```gdscript
class SectorState:                        # inner class
    var base: float                       # jittered at init (ind ~20, tra ~15, agr ~15)
    var progress: float = 0.0             # 0..100
    var suff_played: bool = false         # lifts cap 70 -> 100

class ReforestEntry:
    var per_year: float
    var years_left: int

class ProjectState:
    var id: StringName
    var years_left: int                   # decremented per paid year; 0 => completed
```

Derived, never stored (recomputed on read): `emissions()`, `net()`, `band()`,
`resilience()`, `available_cards()` (starting pool + run unlocks) — formulas in
`03_Climate_Calc_Spec.md` and `04_Society_And_Resilience_Spec.md`.

## Initialization from procgen

`RunState.new_run(gen: WorldGenResult, base_catalog: Catalog, unlocked_ids: Array)`:

1. Copy jittered starts (sector bases, `absorption`, `money`, `happiness`) — produced by
   stream 1 in Phase 3 world generation; RunState does not re-roll them.
2. `rng_events.seed = SeedUtil.sub_seed(run_seed, STREAM_EVENTS)`.
3. Apply Knowledge modifiers (catalog patches and state grants — see
   `02_Policy_Effect_Resolver.md`).
4. `world` = generated regions; ally states all NEUTRAL except player home.
5. `_begin_year()` runs immediately: first income, first project pass (none), first
   crisis draw.

## Turn state machine — how the steps map to play

The Phase 1 pipeline order is preserved exactly; it is split across the interactive turn:

| Phase 1 step | When it runs | API |
|---|---|---|
| 1. Income + project upkeep | Automatically at year start | `_begin_year()` (internal) |
| 1b. Crisis draw (3 events) | Automatically at year start | `_draw_crises()` (internal; sole RNG consumer) |
| 2. Player actions | 0..MAX_CARDS_PER_TURN card plays + project launches/abandons | `play_card(id, target) -> Error`, `start_project(id) -> Error`, `abandon_project(id) -> Error` |
| 3–8. Ledger → warming → drift → crisis strikes → feedbacks → check | When the player presses Space | `resolve_year() -> TurnRecord` |

```gdscript
enum Phase { AWAIT_ACTION, RESOLVING, ENDED }
```

- `_begin_year()`: resets the turn accumulators (plays, tags, combos, project events,
  unlocks); applies income including completion passives and the H-based penalties;
  consumes `flood_rebuild`; charges every active project (pay → maybe complete; cannot
  pay → fail with penalty); draws the year's 3 crises; emits `year_started`.
- `play_card()`: validates (see resolver spec), pays, applies, grants rewards, answers
  the first matching open crisis, joins the tag multiset, fires any completed combos,
  and runs the deck-growth check. Multiple calls per year are the norm; the
  `MAX_CARDS_PER_TURN` cap is enforced in the model, not the UI (Plan.md quality gate).
- `resolve_year()`: runs steps 3–8 in strict order, appends the `TurnRecord`, then either
  ends the run (`phase = ENDED`) or increments `year` and calls `_begin_year()`.
  Calling it while `ENDED` is a no-op returning the terminal record.

Passing is implicit: `resolve_year()` with zero plays records an explicit pass line
(banking money is a real decision and is logged as one — golden rule 13).

## Signals

RunState emits; Sim relays. The original seven plus **four crisis-loop additions**
(amendment A6): `crisis_answered`, `combo_triggered`, `card_unlocked`,
`project_changed` — the juice layer (banners, tray rebuilds, chain label) needs each of
these the moment it happens, not at resolve.

```gdscript
signal year_started(year: int)
signal card_played(card_id: StringName, accepted: bool)
signal crisis_answered(crisis_id: StringName, card_id: StringName)        # A6
signal combo_triggered(combo_id: StringName, chain: int, mult: float)     # A6
signal card_unlocked(card_id: StringName)                                 # A6
signal project_changed(project_id: StringName, status: StringName)        # A6: launched|charged n/a|completed|failed|abandoned
signal year_advanced(report: TurnRecord)         # after step 8, non-terminal
signal event_struck(event_id: StringName, region_id: StringName, opportunity: StringName)
signal warming_band_changed(band: int)           # both directions
signal ally_changed(region_id: StringName, is_ally: bool)
signal run_ended(outcome: StringName, knowledge_points: int)   # terminal, exactly once
```

Emission points: `crisis_answered` / `combo_triggered` / `card_unlocked` during step 2
(inside `play_card`); `project_changed` from launches/abandons (step 2) and the upkeep
pass (step 1); `event_struck` during step 6 (one per unanswered crisis that strikes,
damage already applied) and step 7 (feedbacks); `warming_band_changed` at step 4;
`ally_changed` from ally ops (steps 1–2) and social-crisis loss (step 6); `run_ended`
from step 8 only.

## Determinism contract

- `rng_events` is consumed **only** by `_draw_crises()` at year start, in fixed order:
  (weighted pick, then flavor-target draw) × CRISES_PER_TURN. Steps 2–8 consume no
  randomness at all — combo matching, crisis answering, unlocks, and project resolution
  are pure functions of state and player input.
- All dictionary iteration uses fixed orders (`[&"ind", &"tra", &"agr"]`, catalog order
  for cards/combos/events, launch order for projects).
- Same `(run_seed, knowledge profile, decision list)` ⇒ byte-identical TurnRecord stream.
