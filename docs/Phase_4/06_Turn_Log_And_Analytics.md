# Turn Log and Analytics Spec — The Drawdown Protocol (Phase 4)

One record per resolved turn, one schema, three consumers: the in-game log, the F3 debug
overlay, and the headless CSV/JSONL harness (`../Phase_3/05_Debug_View_Spec.md`) — plus
the run-end **post-mortem**, which is a fourth reader of the same records, never a
second simulation. Golden rule 13 — track what players actually do — is designed in
here, not bolted on.

## TurnRecord schema

```gdscript
class_name TurnRecord
extends RefCounted            # built once per resolve_year(); immutable afterwards

var year: int
var turn: int                         # 1-based decision-turn index (1..15)
# step 1 — income and projects
var income_money: float; var income_influence: float
var income_penalty: StringName        # &"none" | &"h_below_40" | &"h_below_25"
var rebuild_bonus_applied: bool       # flood_rebuild consumed this turn
var rebuild_bonus_amount: float
var project_events: Array[Dictionary] # [{id, event: launched|charged|completed|failed|
                                      #   abandoned, cost_money, cost_influence, turns_left, ...}]
# step 1c — crisis draw (outcome fields filled during step 6)
var crises: Array[Dictionary]
#   [{id, kind, region_id, answered, answered_by, mult, on_draw_e,
#     damages: {money, happiness, absorption, influence}, ally_lost, opportunity}]
# step 1d — the project market offered this turn
var market_offered: Array[StringName] # deal order; bonus injections last
var market_bonus: Array[StringName]   # subset injected by events
# step 2 — player actions (0..MAX_CARDS_PER_TURN plays, in play order)
var actions: Array[Dictionary]
#   [{card, target, cost_money, cost_influence, cost_happiness, rewards,
#     effects_applied: [{op, ..., requested, applied}],   # applied may be cap-clamped
#     waiver: none|media|window,
#     risk: {chance, success, effects_applied, rewards},  # {} for riskless cards
#     crisis_answered, combos: [combo ids]}]
var combos_fired: Array[Dictionary]   # [{id, chain, mult, rewards, effects_applied}]
var combo_chain: int                  # chain value after this turn (post-decay)
var cards_unlocked: Array[StringName] # deck growth this turn
# steps 3–4 — climate (emissions = city + world actors)
var emissions: float                  # total E
var emissions_city: float; var emissions_world: float
var absorption: float; var net: float
var sink_matured: float; var sink_stress: float
var warming_delta: float; var temp: float; var band: int; var band_prev: int
var clock_pct: float                  # warming as % of the tipping track
# step 5 — society drift
var co_benefit: float; var overshoot_stress: float; var happiness: float
# step 6b — the summit scheduled this turn ({} when none)
var summit: Dictionary                # {id, name, met, value, target, gains|penalty}
# step 7 — feedbacks
var feedbacks: Array[StringName]      # triggered THIS turn only
# step 7b — world actors AFTER their between-turn advance
var actors: Array[Dictionary]         # [{id, emissions, trend}]
# step 8 — end
var end_status: StringName            # RunStatus string
var kp_awarded: int                   # terminal records only (formula + kp_earned)
# snapshot (post-step-8, the row the balance bands read)
var money: float; var influence: float; var allies: int; var resilience: float
var kp_earned: float                  # cumulative in-run Knowledge so far
var log_lines: PackedStringArray      # rendered template output; views display, never compute
```

`requested` vs `applied` in `effects_applied` is deliberate: "industry +5 → +2 (at cap)"
is both the honest log line and the analytics signal that a player is wasting joint
projects on capped sectors — a UX finding waiting in the data.

## Consumer 1 — in-game log (and HUD)

Every player-visible line is a **template over record fields** (`data/log_templates.json`).
The turn renders in step order: income (with penalty note) → rebuild bonus → project
events → the draw line ("Events this turn: …") → **on-draw spike lines**
(`on_draw_hit` when ignored / `on_draw_cleared` when answered) → **bonus-card windows**
("Crisis window: {name} joins this turn's market") → per-play blocks (enact line,
effect lines, **risk verdict** — `risk_success` "BREAKTHROUGH …" or `risk_failure` —
returns line, crisis-answer line, combo lines) → sink maturation → **the global
ledger** ("Ledger: city {ec} + world {ew} − A {a} = net {n} Gt") → **the climate
clock** ("Climate clock: {clock}% ({t} C, {dt} this turn)") → `curve_bent` on a
net-negative turn → band changes → drift → unanswered strikes (damage first, rider
second — always) and missed opportunities → the **summit verdict**
(`summit_met`/`summit_missed`) → unlocks → feedbacks → the **world-drift line** ("The
world's blocs emit {we} Gt and drift +{trend}/turn", non-terminal turns) → terminal
lines (`endings.*` + KP). Rule from the debug spec, enforced structurally: if a line
cannot be produced from the record, the record is missing a field — extend the schema,
never compute in the view.

## Consumer 2 — headless harness (CSV)

The batch harness flattens records to the established CSV: one row per run —
`seed, strategy, outcome, end_year, kp` + decade samples of `T/N/M/H` (exactly the
`../Phase_1/05_Balance_Bands.md` metrics, taken from the snapshot section).
Determinism contract: byte-identical CSV for identical inputs (re-tested by the
fixture suite).

## Consumer 3 — full analytics (JSONL, debug/headless builds only)

`TurnRecord.to_dict()` → one JSON line per turn per run. The golden-rule-13 questions
this answers without new instrumentation:

| Question (Plan.md Phase 8 needs it) | Query over JSONL |
|---|---|
| Win rate, failure causes | last record's `end_status` per run |
| Average failure year | `year` of terminal records by status |
| Most/least picked cards | histogram over `actions[].card` |
| Offered-but-ignored cards (market health) | `market_offered` minus `actions[].card` per turn |
| Answer rate / bleed rate | `crises[].answered` share per turn; damages histogram |
| Spike discipline | `crises[].on_draw_e` on unanswered entries (permanent E bleed) |
| Risk appetite and payoff | `actions[].risk` outcomes vs `end_status` |
| Combo literacy | `combos_fired` per decade; `combo_chain` trajectory; dead combos (never fired) |
| Dominant-strategy watch (Risk #12) | Grand Bargain share of combo fires; combo income vs base income |
| Diplomacy reach | `actors` trajectories; `emissions_world` at run end; treaty/fund play counts |
| Summit performance | `summit.met` per scheduled turn; penalty incidence vs outcome |
| Project economics | `project_events` lifecycles: completion rate, failure turn, abandon rate |
| Deck growth reach | `cards_unlocked` count and turn per run |
| Overshoot depth/duration | per-run max `temp` / `clock_pct`, count of records with `band >= 1` |
| Death-spiral onset | first turn `income_penalty != "none"` vs terminal status |
| Rider usage | `waiver == "window"` count; fire-discount deltas in `actions[].cost_money` |

## Consumer 4 — the defeat post-mortem (`src/scripts/core/post_mortem.gd`)

`PostMortem.analyze(records, catalog) -> {pivot_year, pivot_turn, headline, lines}` —
a **pure static heuristic over the TurnRecords** that names the pivotal turn which
sealed the run's fate, so the player understands the mistake and wants to retry
immediately. Rendered on the run-end screen; never a second simulation. Per outcome
family:

- **Overheat** (`LOSS_LIMIT_BREACHED` and default): the pivot is the turn with the most
  *avoidable damage* — unanswered crisis damages normalized to money (happiness ×5,
  absorption ×25, influence ×1, plus unanswered on-draw spikes ×25), +40 for a missed
  summit, +25 for passing with ≥ 150 money banked. Strict comparison: **the earliest
  turn wins ties.** Closing line compares `emissions_world` vs `emissions_city` — when
  the world's blocs out-emitted the player's sphere, the diplomacy lever is named.
- **Revolt** (`LOSS_REVOLT`): the pivot is the biggest one-turn happiness drop, with
  its causes named from the record — happiness-cost policies, unanswered crisis
  damage, overshoot stress, a failed summit — and the counterweights (wellbeing
  policies, answered crises, sufficiency co-benefits, the Public Support Fund) offered.
- **Timeout** (`LOSS_NOT_NEUTRAL`): names the biggest remaining ledger block (world
  blocs still emitting vs the unfinished home transition), counts pass turns (≥ 3 is
  called out), and points at the costliest single turn.
- **Win** (`WIN_NEUTRAL`): celebrates the drawdown moment (turn, years before the
  deadline) and the peak combo chain (≥ 3) that paid for the endgame.

Weights (`HAPPINESS_WEIGHT` 5, `ABSORPTION_WEIGHT` 25, `SUMMIT_MISS_WEIGHT` 40,
`BANKED_PASS_WEIGHT` 25, `BANKED_MONEY_MIN` 150) are class constants — heuristic
tuning, not balance data; changing them changes copy, never outcomes.

## Implementation notes

- Records live in a plain `Array[TurnRecord]` on RunState (max 15 — one per turn; the
  whole run history is one screen of memory).
- Built inline during `resolve_year()`; the crisis entries are the same dictionaries the
  draw created, enriched with their outcome — one allocation, no copies.
- `log_lines` are rendered once at record time (`_build_log_lines`) from the same
  templates the banners use — a banner line **is** a log line.
- `YearReport` (the signal payload from `01_RunState_Spec.md`) **is** the TurnRecord —
  one type, two names collapsed (amendment A2, unchanged).
- JSONL writing is behind `OS.is_debug_build() or headless` — release builds keep the
  in-memory records for the end screen and post-mortem, and discard on run end.
