# Turn Log and Analytics Spec — The Drawdown Protocol (Phase 4)

One record per resolved year, one schema, three consumers: the in-game log, the F3 debug
overlay, and the headless CSV/JSONL harness (`../Phase_3/05_Debug_View_Spec.md`).
Golden rule 13 — track what players actually do — is designed in here, not bolted on.

## TurnRecord schema

```gdscript
class_name TurnRecord
extends RefCounted            # built once per resolve_year(); immutable afterwards

var year: int
# step 1 — income and projects
var income_money: float; var income_influence: float
var income_penalty: StringName        # &"none" | &"h_below_40" | &"h_below_25"
var rebuild_bonus_applied: bool       # flood_rebuild consumed this year
var project_events: Array[Dictionary] # [{id, event: launched|charged|completed|failed|
                                      #   abandoned, cost_money, cost_influence, ...}]
# step 1b — crisis draw (outcome fields filled during step 6)
var crises: Array[Dictionary]
#   [{id, kind, region_id, answered, answered_by, mult,
#     damages: {money, happiness, absorption, influence}, ally_lost, opportunity}]
# step 2 — player actions (0..MAX_CARDS_PER_TURN plays, in play order)
var actions: Array[Dictionary]
#   [{card, target, cost_money, cost_influence, cost_happiness, rewards,
#     effects_applied: [{op, ..., requested, applied}],   # applied may be cap-clamped
#     waiver: none|media|window, crisis_answered, combos: [combo ids]}]
var combos_fired: Array[Dictionary]   # [{id, chain, mult, rewards, effects_applied}]
var combo_chain: int                  # chain value after this year (post-decay)
var cards_unlocked: Array[StringName] # deck growth this year
# steps 3–4 — climate
var emissions: float; var absorption: float; var net: float
var sink_matured: float; var sink_stress: float
var warming_delta: float; var temp: float; var band: int
# step 5 — society drift
var co_benefit: float; var overshoot_stress: float; var happiness: float
# step 7 — feedbacks
var feedbacks: Array[StringName]      # triggered THIS year only
# step 8 — end
var end_status: StringName            # RunStatus string
var kp_awarded: int                   # terminal records only (formula + kp_earned)
# snapshot (post-step-8, the row the balance bands read)
var money: float; var influence: float; var allies: int; var resilience: float
var kp_earned: float                  # cumulative in-run Knowledge so far
```

`requested` vs `applied` in `effects_applied` is deliberate: "industry +5 → +2 (at cap)"
is both the honest log line and the analytics signal that a player is wasting joint
projects on capped sectors — a UX finding waiting in the data.

## Consumer 1 — in-game log (and HUD)

Every player-visible line is a **template over record fields** (`data/log_templates.json`).
The year renders in step order: income → project events → the crisis-draw line ("Crises
this year: …") → per-play blocks (enact line, effect lines, returns line, crisis-answer
line, combo lines) → ledger → warming → drift → unanswered strikes (damage first, rider
second — always) and missed opportunities → unlocks → feedbacks → terminal lines.
Rule from the debug spec, enforced structurally: if a line cannot be produced from the
record, the record is missing a field — extend the schema, never compute in the view.

## Consumer 2 — headless harness (CSV)

The batch harness flattens records to the established CSV: one row per run —
`seed, strategy, outcome, end_year, kp` + decade samples of `T/N/M/H` (exactly the
`../Phase_1/05_Balance_Bands.md` metrics, taken from the snapshot section).
Determinism contract: byte-identical CSV for identical inputs (re-tested as T12-P4).

## Consumer 3 — full analytics (JSONL, debug/headless builds only)

`TurnRecord.to_dict()` → one JSON line per year per run. The golden-rule-13 questions
this answers without new instrumentation:

| Question (Plan.md Phase 8 needs it) | Query over JSONL |
|---|---|
| Win rate, failure causes | last record's `end_status` per run |
| Average failure year | `year` of terminal records by status |
| Most/least picked cards | histogram over `actions[].card` |
| Answer rate / bleed rate | `crises[].answered` share per year; damages histogram |
| Combo literacy | `combos_fired` per decade; `combo_chain` trajectory; dead combos (never fired) |
| Dominant-strategy watch (Risk #12) | Grand Bargain share of combo fires; combo income vs base income |
| Project economics | `project_events` lifecycles: completion rate, failure year, abandon rate |
| Deck growth reach | `cards_unlocked` count and year per run |
| Overshoot depth/duration | per-run max `temp`, count of records with `band >= 1` |
| Death-spiral onset | first year `income_penalty != "none"` vs terminal status |
| Rider usage | `waiver == "window"` count; fire-discount deltas in `actions[].cost_money` |

## Implementation notes

- Records live in a plain `Array[TurnRecord]` on RunState (max 71 — no ring buffer
  needed; the whole run history is one screen of memory).
- Built inline during `resolve_year()`; the crisis entries are the same dictionaries the
  draw created, enriched with their outcome — one allocation, no copies.
- `YearReport` (the signal payload from `01_RunState_Spec.md`) **is** the TurnRecord —
  one type, two names collapsed (amendment A2, unchanged).
- JSONL writing is behind `OS.is_debug_build() or headless` — release builds keep the
  in-memory records for the end screen and discard on run end.
