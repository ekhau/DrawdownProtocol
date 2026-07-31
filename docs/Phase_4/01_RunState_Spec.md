# RunState Spec — The Drawdown Protocol (Phase 4)

The single source of truth for one run. Plain, headless-capable, signal-emitting; the UI
never computes gameplay values (Plan.md engineering rules). Everything here implements
the per-turn crisis-response pipeline of `../Phase_1/01_Balance_Model.md` 1:1, over the
world model of `../Phase_3/01_World_Model_And_Tile_Schema.md`.

**One turn = 5 years (`YEARS_PER_TURN`).** A run is 15 decision turns, 2030–2100
(turn 1 = 2030, turn 15 = 2100). Victory is carbon neutrality (net ≤ 0) reached at
**any** turn before the tipping point; defeat is +2.0 °C (the climate clock at 100%),
happiness 0 (revolt), or reaching 2100 still net-positive.

## Ownership and shape

```
Sim (Node)                       # scene-facing owner; instantiated by Main or headless harness
└── run_state: RunState          # RefCounted; zero scene dependencies; unit-testable alone
```

`RunState` never touches nodes, autoloads, or `OS`; its nondeterminism lives in exactly
three seeded streams (`../Phase_3/02_Procedural_Generation_Spec.md`): `rng_events`
(stream 2, the turn-start crisis draw), `rng_market` (stream 5, the turn-start market
deal), and `rng_risk` (stream 6, consumed only when a push-your-luck card is played).
Sim forwards RunState's emissions as the scene-level signals of
`../Phase_3/03_Board_Rendering_Spec.md`.

## Typed fields (each links to `../Phase_0/04_Simulation_Metric_Dictionary.md`)

```gdscript
class_name RunState
extends RefCounted

# --- identity / timeline ---
var run_seed: int
var year: int = 2030                      # metric: Year (advances by 5 per turn)
var phase: Phase = Phase.AWAIT_ACTION     # turn state machine, below
# --- pillars and warming ---
var temp: float = 1.30                    # metric: Warming T (°C); clock_pct() derives the gauge
var money: float                          # metric: Money M (jittered start)
var happiness: float                      # metric: Happiness H (0 = LOSS_REVOLT)
var influence: float = 15.0               # metric: Influence I
# --- carbon ledger ---
var sectors: Dictionary = {}              # StringName -> SectorState (ind, tra, agr)
var absorption: float                     # metric: Absorption A (jittered start)
var e_extra: float = 0.0                  # metric: feedback extras + unanswered on-draw spikes
var reforest_queue: Array[ReforestEntry] = []
# --- diplomacy / society ---
var allies: int = 0
var adapt: float = 0.0                    # clamp 0..60 (see 02, clarification C2)
var media: bool = false
var window: bool = false
var fire_discount: bool = false
var flood_rebuild: bool = false
# --- crises (drawn at turn start; resolved at turn end) ---
var pending_crises: Array[Dictionary] = []  # {id, kind, region_id, answered, answered_by, on_draw_e}
# --- the project market (dealt at turn start) ---
var market: Array[StringName] = []        # current offers; playing consumes the offer
var market_bonus: Array[StringName] = []  # subset injected by events this turn
var market_enforced: bool = true          # op-level test suites may disable
# --- world actors (the rest of the world's emission curves) ---
var world_actors: Array[Dictionary] = []  # [{id, name, emissions, trend, floor}]
# --- city archetype (selected at run start; {} = baseline coalition) ---
var archetype: Dictionary = {}
# --- meta-lesson cards (unlocked by past defeats, available from turn 1) ---
var meta_cards: Array = []                # Array[String] of card ids
# --- summits (COPs) ---
var summit_results: Dictionary = {}       # summit id -> "met" | "missed"
var curve_bent_year: int = 0              # first year net <= 0 (0 = never)
# --- combos ---
var combo_chain: int = 0                  # +1 per combo, -1 on comboless turns, min 0
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
var rng_events: RandomNumberGenerator     # stream 2: crisis draw only
var rng_market: RandomNumberGenerator     # stream 5: market deal only
var rng_risk: RandomNumberGenerator       # stream 6: risk-card rolls only
var records: Array[TurnRecord] = []       # see 06_Turn_Log_And_Analytics.md
```

```gdscript
class SectorState:                        # inner class
    var base: float                       # jittered at init (ind ~20, tra ~15, agr ~15)
    var progress: float = 0.0             # 0..100
    var suff_played: bool = false         # lifts cap 70 -> 100

class ReforestEntry:
    var per_turn: float
    var turns_left: int

class ProjectState:
    var id: StringName
    var turns_left: int                   # decremented per paid turn; 0 => completed
```

Derived, never stored (recomputed on read): `gross_emissions()` (city sphere),
`world_emissions()` / `world_trend()` (actor curves), `total_emissions()`,
`net_emissions()`, `warming_band()`, `clock_pct()` / `clock_forecast_pct()` (the Climate
Clock gauge and its do-nothing projection), `turn_index()`, `resilience()`,
`available_cards()` (starting pool + run unlocks + meta lessons; bonus-only cards exist
only while an event holds them in the market) — formulas in `03_Climate_Calc_Spec.md`
and `04_Society_And_Resilience_Spec.md`.

## Initialization from procgen

`RunState.new_run(gen: WorldGenResult, base_catalog: Catalog, unlocked_ids: Array,
archetype_id: StringName = &"", meta_card_ids: Array = []) -> RunState`:

1. Copy jittered starts (sector bases, `absorption`, `money`, `happiness`) — produced by
   stream 1 in Phase 3 world generation; RunState does not re-roll them.
2. Seed the three streams: `rng_events` (STREAM_EVENTS 2), `rng_market`
   (STREAM_MARKET 5), `rng_risk` (STREAM_RISK 6) via `SeedUtil.sub_seed`.
3. Apply Knowledge modifiers (catalog patches and state grants — see
   `02_Policy_Effect_Resolver.md`); copy `meta_cards` (defeat-earned lessons).
4. Deep-copy the catalog's world-actor definitions into live per-run `world_actors`
   state (`{id, name, emissions, trend, floor}`).
5. Apply the selected **city archetype** as modifiers over the generated baseline
   (`money_mult`, `influence_bonus`, `happiness_delta`, `sector_mult` per sector,
   `start_allies` flipping the first neutral regions) so procgen jitter and archetype
   identity compose; the archetype dict is stored on `rs.archetype`. No archetype
   (`&""`) is the baseline coalition — the headless default.
6. `world` = generated regions; ally states all NEUTRAL except player home (plus
   archetype `start_allies`).
7. `_begin_year()` runs immediately: first income, first project pass (none), first
   crisis draw, first market deal.

## Turn state machine — how the steps map to play

The Phase 1 pipeline order is preserved exactly; it is split across the interactive turn:

| Pipeline step | When it runs | API |
|---|---|---|
| 1. Income + passives | Automatically at turn start | `_begin_year()` (internal) |
| 1b. Project upkeep (pay / fail / complete) | Turn start | `_charge_projects()` (internal) |
| 1c. Crisis draw (3 events) + on-draw spikes | Turn start | `_draw_crises()` + `_apply_on_draw_effects()` (sole `rng_events` consumer) |
| 1d. Market deal + guarantee rule + bonus injections | Turn start | `_deal_market()` (sole `rng_market` consumer) → `_ensure_answer_offer()` → `_inject_bonus_cards()` (both RNG-free) |
| 2. Player actions | 0..MAX_CARDS_PER_TURN plays from the market + project launches/abandons | `play_card(id, target) -> Error` (risk cards consume `rng_risk` here), `start_project(id) -> Error`, `abandon_project(id) -> Error` |
| 3–8. Ledger → warming → drift → strikes → summit → feedbacks → actor advance → check | When the player presses Space | `resolve_year() -> TurnRecord` |

```gdscript
enum Phase { AWAIT_ACTION, RESOLVING, ENDED }
```

- `_begin_year()`: resets the turn accumulators (plays, tags, combos, project events,
  unlocks, market snapshot); applies income including completion passives, archetype
  multipliers and the H-based penalties; consumes `flood_rebuild`; charges every active
  project (pay → maybe complete; cannot pay → fail with penalty); draws the turn's 3
  events and applies their **on-draw emission spikes** (tracked per crisis on
  `on_draw_e`); deals the **project market** (MARKET_SIZE 4 offers, weighted by card
  `market_weight` × the archetype's tag lean, without replacement), then applies the
  RNG-free **guarantee rule** (if no offer answers an open event, the last slot is
  swapped for the cheapest answering card) and **event bonus injections** (an event's
  `bonus_card` joins the market when its resource gate holds at draw time — e.g.
  `heat_wave` → HWP1 while happiness ≥ 40); emits `year_started`.
- `play_card()`: validates (see resolver spec — a card must be **in the market** while
  `market_enforced`), pays, applies, rolls the card's `risk` block if present (exactly
  one `rng_risk.randf()`), grants rewards, answers the first matching open crisis,
  joins the tag multiset, fires any completed combos, **consumes the market offer**,
  and runs the deck-growth check. Multiple calls per turn are the norm; the
  `MAX_CARDS_PER_TURN` cap is enforced in the model, not the UI (Plan.md quality gate).
- `resolve_year()`: runs steps 3–8 in strict order — including 6b (summit evaluation)
  and 7b (world-actor advance, skipped once the run is over) — appends the
  `TurnRecord`, then either ends the run (`phase = ENDED`) or advances `year` by
  `YEARS_PER_TURN` and calls `_begin_year()`. Calling it while `ENDED` is a no-op
  returning the terminal record.

Passing is implicit: `resolve_year()` with zero plays records an explicit pass line
(banking money is a real decision and is logged as one — golden rule 13).

## Signals

RunState emits; Sim relays. The original seven plus the four crisis-loop additions
(amendment A6: `crisis_answered`, `combo_triggered`, `card_unlocked`,
`project_changed`) plus **three clock-race additions**: `summit_resolved`,
`risk_resolved`, `curve_bent` — the juice layer (summit verdict banner, breakthrough
beat, clock plunge) needs each of these the moment it happens, not at resolve.

```gdscript
signal year_started(year: int)
signal card_played(card_id: StringName, accepted: bool)
signal crisis_answered(crisis_id: StringName, card_id: StringName)        # A6
signal combo_triggered(combo_id: StringName, chain: int, mult: float)     # A6
signal card_unlocked(card_id: StringName)                                 # A6
signal project_changed(project_id: StringName, status: StringName)        # A6: launched|charged|completed|failed|abandoned
signal year_advanced(report: TurnRecord)         # after step 8, non-terminal
signal event_struck(event_id: StringName, region_id: StringName, opportunity: StringName)
signal warming_band_changed(band: int)           # both directions
signal ally_changed(region_id: StringName, is_ally: bool)
signal summit_resolved(summit_id: StringName, met: bool)                  # step 6b
signal risk_resolved(card_id: StringName, success: bool)                  # step 2, on the roll
signal curve_bent(year: int)                     # first turn net <= 0 (the drawdown moment)
signal run_ended(outcome: StringName, knowledge_points: int)   # terminal, exactly once
```

Emission points: `crisis_answered` / `combo_triggered` / `card_unlocked` /
`risk_resolved` during step 2 (inside `play_card`); `project_changed` from
launches/abandons (step 2) and the upkeep pass (step 1b); `event_struck` during step 6
(one per unanswered crisis that strikes, damage already applied) and step 7 (feedbacks);
`warming_band_changed` at step 4; `ally_changed` from ally ops (steps 1–2) and
social-crisis loss (step 6); `summit_resolved` at step 6b; `curve_bent` at step 8, the
first time net ≤ 0 (which is also the winning turn); `run_ended` from step 8 only.

## Determinism contract

- `rng_events` is consumed **only** by `_draw_crises()` at turn start, in fixed order:
  (weighted pick, then flavor-target draw) × CRISES_PER_TURN.
- `rng_market` is consumed **only** by `_deal_market()` at turn start: exactly
  MARKET_SIZE (4) `randf` draws, weighted without replacement over the available pool
  in fixed pool order. The guarantee rule and bonus injections that follow are pure
  functions of state — no randomness.
- `rng_risk` is consumed **only** inside `play_card()` when the played card carries a
  `risk` block — exactly one `randf` per risk card played, so identical decision lists
  reproduce identical rolls.
- Steps 3–8 consume no randomness at all — combo matching, crisis answering, unlocks,
  summit evaluation, project resolution and the actor advance are pure functions of
  state and player input (the advance processes actors steepest-trend-first with
  index-order tie-breaks).
- All dictionary iteration uses fixed orders (`[&"ind", &"tra", &"agr"]`, catalog order
  for cards/combos/events/summits, launch order for projects, definition order for
  actors).
- Same `(run_seed, knowledge profile, archetype, decision list)` ⇒ byte-identical
  TurnRecord stream.
