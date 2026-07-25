# Society and Derived-Resilience Spec — The Drawdown Protocol (Phase 4)

Steps 1, 5, and 6 of the yearly pipeline: income, happiness drift, events, and the
derived resilience stat. Implements Plan.md Phase 4's "resilience update logic" under the
reconciliation of `../Phase_0/04_Simulation_Metric_Dictionary.md`: **resilience is
derived, never stored, never a loss condition** — social collapse acts through systems.

## Step 1 — income (runs in `_begin_year()`)

```gdscript
static func income(h: float, allies: int) -> float:
    var base := 100.0 + 20.0 * allies
    if h < 25.0:   return base * 0.50      # strongest penalty only, elif-chain
    elif h < 40.0: return base * 0.75
    return base

static func influence_income(allies: int, media: bool) -> float:
    return 2.0 + 1.0 * allies + (1.0 if media else 0.0)
```

Also in step 1: consume `flood_rebuild` (+5 transport progress, cap-clamped, logged as
`"rebuild_better_tra"`). The income penalties are the social death spiral's teeth — and
its exits are cards (SOC2), the crisis window, and Knowledge, per Risk #4.

## Step 5 — happiness drift (after warming update, reads `band(T_new)`)

```gdscript
static func happiness_drift(avg_progress: float, band: int) -> float:
    var co_benefit := 1.5 * avg_progress / 100.0        # transition makes life better
    var stress: float = [0.0, 0.5, 1.0][band]           # Overshoot makes it worse
    return co_benefit - stress
# caller: happiness = clampf(happiness + drift, 0.0, 100.0)
```

`avg_progress` = mean of the three sector progresses. This single function owns the
dip-then-bloom arc of the balance bands; its two constants (1.5 max co-benefit,
0.5/1.0 stress) are top-tier tuning levers and live in `data/society.json`.

## Derived resilience and the damage multiplier

```gdscript
static func resilience(h: float, adapt: float) -> float:
    return clampf(0.4 * h + adapt, 0.0, 100.0)

static func damage_mult(h: float, adapt: float) -> float:
    return 1.0 - resilience(h, adapt) / 200.0            # R 100 halves damage
```

**Computed once at step 6 entry** (after the drift), then used for all of this year's
events — mid-step damage does not re-lower the multiplier (Phase 1 contract; prevents
intra-turn spirals the player cannot read).

## Step 6 — events (single consumer of `rng_events`, fixed order)

Probabilities by `band(T_new)` from `../Phase_1/03_Event_Probability_Table.md`.
Consumption order is part of the determinism contract (`01_RunState_Spec.md`):
**heat → fire → flood → social**, each trigger roll immediately followed by its region
target draw when it hits (`../Phase_3/02` targeting rules).

```
heat  : H -= 3*mult ; M -= 20*mult
fire  : A = max(A_FLOOR, A - 1.0*mult) ; M -= 10*mult ; H -= 1*mult
        fires += 1 ; fire_discount = true          # opportunity: rebuild better
flood : M -= 40*mult ; H -= 3*mult ; flood_rebuild = true
social: I = max(0, I - 10) ; M = max(0, M - 20)
        lose 1 ally (targeted ally, else highest-affinity ally; none if allies == 0)
        window = true                              # opportunity: policy window
```

All money/happiness floors clamp at 0. Social crisis probability — evaluated **after**
this year's heat/fire/flood damage (sequential reads of current H, Phase 1 contract):

```gdscript
static func social_crisis_p(h: float, band: int, media: bool) -> float:
    var base := 0.25 if h < 40.0 else 0.05
    var p: float = base * [1.0, 1.25, 1.5][band]
    return p * 0.5 if media else p
```

Ally loss flips the region's `ally_state` back to NEUTRAL and emits `ally_changed` —
income and influence drop from next year's step 1; already-applied progress is never
rolled back (alliances leave the world better even when they end).

Every event writes a TurnRecord entry carrying: event id, region id, `mult` used, final
applied damages, and the opportunity flag it set — the log line and the analytics row
are the same data (`06_Turn_Log_And_Analytics.md`).

## Where each society value can change (audit table)

| Value | Step 1 | Step 2 (cards) | Step 5 | Step 6 | Elsewhere |
|---|---|---|---|---|---|
| Money | +income | −costs | — | −damages | never |
| Happiness | — | ±card dH (waiver rule in 02) | ±drift | −damages | never |
| Influence | +gain | −costs | — | −10 social | never |
| Allies | — | +1 DIP1 | — | −1 social | never |
| Adapt | — | +ADP1/SNK2 (clamp 60) | — | — | Knowledge grant at init |

If any implementation writes these fields outside their columns, it is a bug by
definition — this table is the review checklist for the society code path.
