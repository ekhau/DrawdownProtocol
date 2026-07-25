# Turn Log and Analytics Spec — The Drawdown Protocol (Phase 4)

One record per resolved year, one schema, three consumers: the in-game log, the F3 debug
overlay, and the headless CSV/JSONL harness (`../Phase_3/05_Debug_View_Spec.md`).
Golden rule 13 — track what players actually do — is designed in here, not bolted on.

## TurnRecord schema

```gdscript
class_name TurnRecord
extends RefCounted            # built once per resolve_year(); immutable afterwards

var year: int
# step 1 — income
var income_money: float; var income_influence: float
var income_penalty: StringName        # &"none" | &"h_below_40" | &"h_below_25"
var rebuild_bonus_applied: bool       # flood_rebuild consumed this year
# step 2 — action
var action: StringName                # card id or &"pass"
var action_target: StringName         # region id for DIP1, else &""
var costs_paid: Vector2               # (money, influence); reflects fire_discount
var effects_applied: Array[Dictionary]  # [{op, param, requested, applied}] — applied may be cap-clamped
var waiver_used: StringName           # &"none" | &"media" | &"window"
# steps 3–4 — climate
var emissions: float; var absorption: float; var net: float
var sink_matured: float; var sink_stress: float
var warming_delta: float; var temp: float; var band: int
# step 5 — society drift
var co_benefit: float; var overshoot_stress: float; var happiness: float
# step 6 — events
var events: Array[Dictionary]
#   [{id, region_id, mult, damages: {money, happiness, absorption, influence, ally_lost},
#     opportunity: StringName}]
# step 7 — feedbacks
var feedbacks: Array[StringName]      # e.g. [&"permafrost"] — triggered THIS year only
# step 8 — end
var end_status: StringName            # RunStatus string
# snapshot (post-step-8, the row the balance bands read)
var money: float; var influence: float; var allies: int; var resilience: float
```

`requested` vs `applied` in `effects_applied` is deliberate: "industry +6 → +2 (at cap)"
is both the honest log line and the analytics signal that a player is wasting joint
projects on capped sectors — a UX finding waiting in the data.

## Consumer 1 — in-game log (and HUD)

Every player-visible line is a **template over record fields** (`data/log_templates.json`),
e.g. `"Heat wave strikes {region}: happiness {damages.happiness}, funds {damages.money}"`.
Rule from the debug spec, now enforced structurally: if a line cannot be produced from
the record, the record is missing a field — extend the schema, never compute in the view.
Pillar 1 parity between what the player reads and what analytics sees is therefore free.

## Consumer 2 — headless harness (CSV)

The Phase 3 batch harness flattens records to the established CSV: one row per run —
`seed, outcome, loss_year, kp` + decade samples of `T/N/M/H` (exactly the
`../Phase_1/05_Balance_Bands.md` metrics, taken from the year-2030/40/... records'
snapshot section). Determinism contract: byte-identical CSV for identical inputs
(Phase 3 done criterion 1, re-tested here as T12-P4).

## Consumer 3 — full analytics (JSONL, debug/headless builds only)

`TurnRecord.to_dict()` → one JSON line per year per run (`user://runs/<seed>_<n>.jsonl`).
71 records × ~40 fields is trivially small; no sampling needed. The golden-rule-13
questions this answers without new instrumentation:

| Question (Plan.md Phase 8 needs it) | Query over JSONL |
|---|---|
| Win rate, failure causes | last record's `end_status` per run |
| Average failure year | `year` of terminal records by status |
| Most/least picked cards | histogram of `action` |
| Dead choices | cards with high availability (needs debug flag) but near-zero picks |
| Dominant-strategy watch (Risk #3) | DIP2 share of non-pass actions in winning runs |
| Overshoot depth/duration | per-run max `temp`, count of records with `band >= 1` |
| Death-spiral onset | first year `income_penalty != "none"` vs terminal status |
| Opportunity riders actually used | `waiver_used == "window"` count; `fire_discount` cost deltas in `costs_paid` |

## Implementation notes

- Records live in a plain `Array[TurnRecord]` on RunState (max 71 — no ring buffer
  needed; the whole run history is one screen of memory).
- Built inline during `resolve_year()` — one allocation per year, nothing per frame.
- `YearReport` (the signal payload from `01_RunState_Spec.md`) **is** the TurnRecord —
  one type, two names collapsed. *(Amendment A2: Phase_3/03 described YearReport as a
  separate snapshot class; merging them removes a copy and a drift risk. The signal
  signature `year_advanced(report)` is unchanged.)*
- JSONL writing is behind `OS.is_debug_build() or headless` — release builds keep the
  in-memory records for the end screen and discard on run end.
