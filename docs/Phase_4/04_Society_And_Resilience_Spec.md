# Society and Derived-Resilience Spec — The Drawdown Protocol (Phase 4)

Steps 1, 1c, 5, and 6 of the per-turn pipeline: income, the crisis draw, happiness
drift, crisis strikes, and the derived resilience stat. Implements Plan.md Phase 4's
"resilience update logic" under the reconciliation of
`../Phase_0/04_Simulation_Metric_Dictionary.md`: **resilience is derived, never stored,
never a damage-side loss condition** — but happiness itself now is one: at H ≤ 0 the
run ends in `LOSS_REVOLT` (`05_End_State_Evaluator.md`). Social collapse acts through
systems, and finally through the streets. Constants live in `data/society.json`; one
turn = 5 years, all rates per turn.

## Step 1 — income (runs in `_begin_year()`)

```gdscript
static func income(h: float, allies: int) -> Dictionary:
    var base := 250.0 + 40.0 * allies          # INCOME_BASE + INCOME_PER_ALLY
    # strongest penalty only (INCOME_PENALTIES, sorted ascending, first match wins):
    if h < 25.0:   return base * 0.50          # "h_below_25"
    elif h < 40.0: return base * 0.75          # "h_below_40"
    return base

static func influence_income(allies: int, media: bool) -> float:
    return 6.0 + 2.0 * allies + (2.0 if media else 0.0)
    # INFLUENCE_BASE + INFLUENCE_PER_ALLY + INFLUENCE_MEDIA_BONUS
```

The caller (RunState) then layers on: the archetype's `income_mult` (Industrial City
×1.2, Political Capital ×0.75) and `influence_income_bonus` (Port City +2, Political
Capital +3), plus completion passives (`income_money`, `income_influence`). Also in
step 1: `happiness_per_turn` / `absorption_per_turn` passives, `flood_rebuild`
consumption (+5 transport progress, cap-clamped, logged as `"rebuild_better_tra"`), and
the project upkeep pass (step 1b — `02_Policy_Effect_Resolver.md`). The income
penalties are the social death spiral's teeth — and its exits are cards (SOC2, the
response family, the revolt-earned SOC4), the crisis window, and Knowledge, per Risk #4.

## Step 1c — the crisis draw (sole consumer of `rng_events`)

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
three times, at turn start, and nothing else from this stream all turn. `band` reads
the CURRENT temperature (last turn's resolution).

Immediately after the draw, **on-draw spikes** apply (`_apply_on_draw_effects`): a
drawn crisis with an `on_draw.e_extra` (the record heat wave, +1.0) bakes its spike
into `e_extra` at draw time and remembers it on the crisis entry (`on_draw_e`).
Answering that crisis this turn reverts the spike before the ledger is read
(`03_Climate_Calc_Spec.md` step 3); ignoring it makes the spike permanent. The market
deal (step 1d) follows — that is the market's spec territory, `01_RunState_Spec.md`.

## Step 5 — happiness drift (after warming update, reads `band(T_new)`)

```gdscript
static func happiness_drift(avg_progress: float, band: int) -> Dictionary:
    var co_benefit := 4.0 * avg_progress / 100.0        # CO_BENEFIT_MAX: transition makes life better
    var stress: float = [0.0, 2.0, 4.0][band]           # OVERSHOOT_STRESS: Overshoot makes it worse
    return {"co_benefit": co_benefit, "stress": stress}
# caller: happiness = clampf(happiness + co_benefit - stress, 0.0, 100.0)
```

`avg_progress` = mean of the three sector progresses. Its two constants (4.0 max
co-benefit per turn, 2.0/4.0 stress per turn) are top-tier tuning levers and live in
`data/society.json`. At 5-year turns these bite hard: two Overshoot-II turns undo a
fully-transitioned economy's co-benefits — the drift is a genuine race against the
revolt clock.

## Derived resilience and the damage multiplier

```gdscript
static func resilience(h: float, adapt: float) -> float:
    return clampf(0.4 * h + adapt, 0.0, 100.0)

static func damage_mult(h: float, adapt: float) -> float:
    return 1.0 - resilience(h, adapt) / 200.0            # R 100 halves damage
```

**Computed once at step 6 entry** (after the drift), then used for all of this turn's
strikes — mid-step damage does not re-lower the multiplier (prevents intra-turn spirals
the player cannot read).

## Step 6 — unanswered crises strike (no RNG here)

The turn's `pending_crises` resolve in draw order. Answered entries are contained —
no damage, no counters, no scar, no rider (and their on-draw spike already dissipated).
Missed opportunities pass by with a log line. Each unanswered **crisis** applies its
catalog damages:

```
scaled_by_resilience true  : each damage × mult
scaled_by_resilience false : flat (markets and politics ignore seawalls)
money/happiness/influence floors clamp at 0; absorption at A_FLOOR
ally_lost: the targeted ally if any, else highest-affinity ally; no-op at 0 allies
counters (fires), scar, and the opportunity rider apply ONLY on a real strike:
    mega_fire  -> fire_discount ; flood_tsunami -> flood_rebuild ; social_crisis -> window
```

Ally loss flips the region's `ally_state` back to NEUTRAL and emits `ally_changed` —
income, influence and drift-damping drop from next turn's step 1; already-applied
progress is never rolled back (alliances leave the world better even when they end).

Also in step 6: the combo chain decays by 1 (min 0) if no combo fired this turn.
Step 6b (the summit verdict) and step 7b (the world actors' advance) follow — specced
in `01_RunState_Spec.md`; their society-side effects appear in the audit table below.

Every strike writes a TurnRecord crisis entry carrying: event id, kind, region id,
answered state, `mult` used, final applied damages, on-draw spike, ally lost, and the
rider it set — the log line and the analytics row are the same data
(`06_Turn_Log_And_Analytics.md`).

## Where each society value can change (audit table)

| Value | Step 1 (+upkeep) | Step 2 (plays/risk/combos/projects) | Step 5 | Step 6 | Step 6b (summit) | Elsewhere |
|---|---|---|---|---|---|---|
| Money | +income, −upkeep | −costs, +rewards (card/risk/response/combo) | — | −damages | +reward / −penalty | never |
| Happiness | +passive, −fail/abandon penalty | ±card dH (waiver rule in 02), −cost_happiness, +rewards, −risk failure | ±drift | −damages | +reward / −penalty | never |
| Influence | +gain, −upkeep, −fail/abandon penalty | −costs, +rewards | — | −12 social | +reward / −penalty | never |
| Allies | +project completion | +1 DIP1 | — | −1 social | — | archetype `start_allies` at init |
| Adapt | — | +ADP1/SNK2/RSP*/HWP1 / combo effects (clamp 60) | — | — | — | Knowledge grant at init |
| kp_earned | — | +knowledge rewards (cards, risk successes, first-fire combos, seized opportunities) | — | — | +knowledge reward (if any) | never |
| e_extra | +on-draw spikes (step 1c) | — | — | — | — | −answered spikes (step 3), +feedbacks (step 7) |

If any implementation writes these fields outside their columns, it is a bug by
definition — this table is the review checklist for the society code path.
