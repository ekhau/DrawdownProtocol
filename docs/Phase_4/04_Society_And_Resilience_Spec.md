# Society and Derived-Resilience Spec — The Drawdown Protocol (Phase 4)

Steps 1, 1b, 5, and 6 of the yearly pipeline: income, the crisis draw, happiness drift,
crisis strikes, and the derived resilience stat. Implements Plan.md Phase 4's
"resilience update logic" under the reconciliation of
`../Phase_0/04_Simulation_Metric_Dictionary.md`: **resilience is derived, never stored,
never a loss condition** — social collapse acts through systems.

## Step 1 — income (runs in `_begin_year()`)

```gdscript
static func income(h: float, allies: int) -> Dictionary:
    var base := 100.0 + 20.0 * allies          # + passive_income_money, added by caller
    if h < 25.0:   return base * 0.50          # strongest penalty only, elif-chain
    elif h < 40.0: return base * 0.75
    return base

static func influence_income(allies: int, media: bool) -> float:
    return 2.0 + 1.0 * allies + (1.0 if media else 0.0)   # + passive_income_influence
```

Also in step 1: completion passives (`happiness_per_year` clamped, `absorption_per_year`),
`flood_rebuild` consumption (+5 transport progress, cap-clamped, logged as
`"rebuild_better_tra"`), and the project upkeep pass (`02_Policy_Effect_Resolver.md`).
The income penalties are the social death spiral's teeth — and its exits are cards
(SOC2, the response family), the crisis window, and Knowledge, per Risk #4.

## Step 1b — the crisis draw (sole consumer of `rng_events`)

Three events, weighted draw without replacement over the drawable deck
(`kind: crisis | opportunity`), per `../Phase_1/03_Event_Probability_Table.md`:

```gdscript
static func crisis_weight(entry: Dictionary, band: int, h: float, media: bool) -> float:
    var w := float(entry["weights"][band])
    var mods: Dictionary = entry.get("weight_mods", {})
    if mods.is_empty(): return w
    if h < float(mods.get("happiness_threshold", 0.0)): w *= float(mods.get("low_happiness_mult", 1.0))
    if media: w *= float(mods.get("media_mult", 1.0))
    return w
```

Consumption order is part of the determinism contract (`01_RunState_Spec.md`): per drawn
event, one pick roll then one flavor-target roll (`../Phase_3/02` targeting rules),
three times, at year start, and nothing else all year. `band` reads the CURRENT
temperature (last year's resolution).

## Step 5 — happiness drift (after warming update, reads `band(T_new)`)

```gdscript
static func happiness_drift(avg_progress: float, band: int) -> float:
    var co_benefit := 1.5 * avg_progress / 100.0        # transition makes life better
    var stress: float = [0.0, 0.5, 1.0][band]           # Overshoot makes it worse
    return co_benefit - stress
# caller: happiness = clampf(happiness + drift, 0.0, 100.0)
```

`avg_progress` = mean of the three sector progresses. Its two constants (1.5 max
co-benefit, 0.5/1.0 stress) are top-tier tuning levers and live in `data/society.json`.

## Derived resilience and the damage multiplier

```gdscript
static func resilience(h: float, adapt: float) -> float:
    return clampf(0.4 * h + adapt, 0.0, 100.0)

static func damage_mult(h: float, adapt: float) -> float:
    return 1.0 - resilience(h, adapt) / 200.0            # R 100 halves damage
```

**Computed once at step 6 entry** (after the drift), then used for all of this year's
strikes — mid-step damage does not re-lower the multiplier (prevents intra-turn spirals
the player cannot read).

## Step 6 — unanswered crises strike (no RNG here)

The year's `pending_crises` resolve in draw order. Answered entries are contained —
no damage, no counters, no scar, no rider. Missed opportunities pass by with a log line.
Each unanswered **crisis** applies its catalog damages:

```
scaled_by_resilience true  : each damage × mult
scaled_by_resilience false : flat (markets and politics ignore seawalls)
money/happiness/influence floors clamp at 0; absorption at A_FLOOR
ally_lost: the targeted ally if any, else highest-affinity ally; no-op at 0 allies
counters (fires), scar, and the opportunity rider apply ONLY on a real strike:
    mega_fire  -> fire_discount ; flood_tsunami -> flood_rebuild ; social_crisis -> window
```

Ally loss flips the region's `ally_state` back to NEUTRAL and emits `ally_changed` —
income and influence drop from next year's step 1; already-applied progress is never
rolled back (alliances leave the world better even when they end).

Also in step 6: the combo chain decays by 1 (min 0) if no combo fired this year.

Every strike writes a TurnRecord crisis entry carrying: event id, kind, region id,
answered state, `mult` used, final applied damages, ally lost, and the rider it set —
the log line and the analytics row are the same data (`06_Turn_Log_And_Analytics.md`).

## Where each society value can change (audit table)

| Value | Step 1 (+upkeep) | Step 2 (plays/combos/projects) | Step 5 | Step 6 | Elsewhere |
|---|---|---|---|---|---|
| Money | +income, −upkeep | −costs, +rewards | — | −damages | never |
| Happiness | +passive, −fail/abandon penalty | ±card dH (waiver rule in 02), −cost_happiness, +rewards | ±drift | −damages | never |
| Influence | +gain, −upkeep, −fail/abandon penalty | −costs, +rewards | — | −8 social | never |
| Allies | +project completion | +1 DIP1 | — | −1 social | never |
| Adapt | — | +ADP1/SNK2/RSP* / combo effects (clamp 60) | — | — | Knowledge grant at init |
| kp_earned | — | +knowledge rewards (cards, first-fire combos, seized opportunities) | — | — | never |

If any implementation writes these fields outside their columns, it is a bug by
definition — this table is the review checklist for the society code path.
