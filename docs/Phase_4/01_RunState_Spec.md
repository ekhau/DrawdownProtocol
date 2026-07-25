# RunState Spec — The Drawdown Protocol (Phase 4)

The single source of truth for one run. Plain, headless-capable, signal-emitting; the UI
never computes gameplay values (Plan.md engineering rules). Everything here implements
the 8-step yearly pipeline of `../Phase_1/01_Balance_Model.md` 1:1, over the world model
of `../Phase_3/01_World_Model_And_Tile_Schema.md`.

## Ownership and shape

```
Sim (Node)                       # scene-facing owner; instantiated by Main or headless harness
└── run_state: RunState          # RefCounted; zero scene dependencies; unit-testable alone
```

`RunState` never touches nodes, autoloads, or `OS`; its only nondeterminism is its own
`rng_events` (stream 2 per `../Phase_3/02_Procedural_Generation_Spec.md`). Sim forwards
RunState's emissions as the scene-level signals of `../Phase_3/03_Board_Rendering_Spec.md`.

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
# --- feedback loop one-shots ---
var fires: int = 0
var permafrost: bool = false
var ocean_weak: bool = false
var amazon: bool = false
# --- world (Phase 3) ---
var world: Array[RegionData] = []
var action_taken: bool = false            # one-card-per-year lock
var rng_events: RandomNumberGenerator     # ONLY rng inside RunState
var log: TurnLogBuffer                    # see 06_Turn_Log_And_Analytics.md
```

```gdscript
class SectorState:                        # inner class or small Resource
    var base: float                       # jittered at init (ind ~20, tra ~15, agr ~15)
    var progress: float = 0.0             # 0..100
    var suff_played: bool = false         # lifts cap 70 -> 100

class ReforestEntry:
    var per_year: float
    var years_left: int
```

Derived, never stored (recomputed on read): `emissions()`, `net()`, `band()`,
`resilience()` — formulas in `03_Climate_Calc_Spec.md` and `04_Society_And_Resilience_Spec.md`.

## Initialization from procgen

`RunState.new_from_worldgen(gen: WorldGenResult, knowledge: KnowledgeProfile)`:

1. Copy jittered starts (sector bases, `absorption`, `money`, `happiness`) — produced by
   stream 1 in Phase 3 world generation; RunState does not re-roll them.
2. `rng_events.seed = SeedUtil.sub_seed(run_seed, STREAM_EVENTS)`.
3. Apply Knowledge modifiers (catalog patches and state grants — see
   `02_Policy_Effect_Resolver.md`; e.g. Informed Public ⇒ `media = true`,
   Crisis-Ready Design ⇒ `adapt = 10.0`).
4. `world` = generated regions; ally states all NEUTRAL except player home.

## Turn state machine — how the 8 steps map to play

The Phase 1 pipeline order is preserved exactly; it is split across the interactive turn:

| Phase 1 step | When it runs | API |
|---|---|---|
| 1. Income | Automatically at year start | `_begin_year()` (internal) |
| 2. Player action | When the player picks a card (or never — pass) | `play_card(id, target_region) -> Error` |
| 3–8. Ledger → warming → happiness → events → feedbacks → check | When the player presses Space | `resolve_year() -> TurnRecord` |

```gdscript
enum Phase { AWAIT_ACTION, RESOLVING, ENDED }
```

- `_begin_year()`: applies income and influence gain, consumes `flood_rebuild`
  (step 1 exactly as specified in Phase 1, including the H-based income penalties from
  `04_Society_And_Resilience_Spec.md`); resets `action_taken`; emits `year_started`.
- `play_card()`: validates (see resolver spec), applies immediately, sets
  `action_taken = true`. A second call this year returns `ERR_UNAVAILABLE` — the
  one-policy-per-year lock is enforced in the model, not the UI (Plan.md quality gate).
- `resolve_year()`: runs steps 3–8 in strict order, appends the `TurnRecord`, then either
  ends the run (`phase = ENDED`) or increments `year` and calls `_begin_year()`.
  Calling it while `ENDED` is a no-op returning the terminal record.

Passing is implicit: `resolve_year()` with `action_taken == false` records action `"pass"`
(banking money is a real decision and is logged as one — golden rule 13).

## Signals

RunState emits; Sim relays. The five Phase 3 signals plus **two additions** (amendment
A1, flagged): `year_started` and `card_played` — the board needs both to animate the
turn without polling.

```gdscript
signal year_started(year: int)                                   # A1: new
signal card_played(card_id: StringName, accepted: bool)          # A1: new
signal year_advanced(report: YearReport)                         # after step 8, non-terminal
signal event_struck(event_id: StringName, region_id: StringName, opportunity: StringName)
signal warming_band_changed(band: int)                           # both directions (Overshoot exit is real: Run A, 2091)
signal ally_changed(region_id: StringName, is_ally: bool)
signal run_ended(outcome: StringName, knowledge_points: int)     # terminal, exactly once
```

Emission points per step: `event_struck` during step 6 (one per event, damage already
applied); `warming_band_changed` at step 4 if band changed; `ally_changed` from DIP1
(step 2) and social-crisis ally loss (step 6); `run_ended` from step 8 only.

## Determinism contract

- `rng_events` is consumed **only** in step 6, in fixed order: heat trigger → (target if
  hit) → fire trigger → (target) → flood trigger → (target) → social trigger → (target).
  No other code may touch it — enforced by test T7-P4 in `07_Done_Criteria_And_Tests.md`.
- All dictionary iteration uses the fixed order `[&"ind", &"tra", &"agr"]`.
- Same `(run_seed, knowledge profile, decision list)` ⇒ byte-identical TurnRecord stream.
