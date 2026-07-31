# Climate Calculation Spec — The Drawdown Protocol (Phase 4)

Steps 3, 4, and 7 of the per-turn pipeline as pure, individually testable functions
with the exact constants of `../Phase_1/01_Balance_Model.md`. All functions live in a
static `ClimateCalc` class: inputs in, deltas out, no side effects — RunState applies
them. One turn = 5 years; **every rate below is per turn**, not per year.

## Constants (from Phase 1; stored in `data/climate.json`)

```
K_WARM = 0.0011     K_COOL = 0.00028     T_FLOOR = 1.20
T_WARN = 1.50       T_BAND2 = 1.75       T_LOSS = 2.00
CLOCK_T_ZERO = 1.00
RESIDUAL = 0.10     A_FLOOR = 5.0
SINK_STRESS = [0.0, 0.5, 1.2]            # by warming band, per turn
```

The three feedback loops are **data, not constants**: `data/events.json` entries of
`kind: feedback` carry their `trigger` (`temp_gte` / `fires_gte`) and `effect`
(`e_extra` / `absorption`) — permafrost at T ≥ 1.75 (+2.0 E), ocean sink at T ≥ 1.90
(−2.0 A), Amazon at 3 fires (−3.0 A). Step 7 below reads them from the catalog.

## The Climate Clock (the adversary gauge)

Warming rendered as percent of the run's race track: 0% at `CLOCK_T_ZERO` (+1.0 °C),
100% at `T_LOSS` (+2.0 °C = the tipping point = defeat).

```gdscript
static func clock_pct(t: float) -> float:
    return clampf((t - CLOCK_T_ZERO) / (T_LOSS - CLOCK_T_ZERO) * 100.0, 0.0, 100.0)

static func clock_delta_pct(dt: float) -> float:   # a dT in clock points (HUD forecast)
    return dt / (T_LOSS - CLOCK_T_ZERO) * 100.0
```

The run starts at 30% (+1.30 °C). The HUD's next-turn forecast
(`RunState.clock_forecast_pct()`) projects one do-nothing turn: current city emissions
+ ally-damped actor curves − stressed sinks, pushed through `warming_delta`.

## Which temperature each step reads (order-critical)

The pipeline updates `temp` in step 4. Everything before reads last turn's value;
everything after reads this turn's. This matches the Phase 1 model exactly and must not
be "fixed":

| Step | Uses |
|---|---|
| 3. Sink stress band | `band(T_prev)` |
| 4. Warming delta | net carbon from step 3 |
| 5. Happiness stress band | `band(T_new)` |
| 6. Event probability band | `band(T_new)` (next turn's draw) |
| 6b. Summit goal | this turn's N (or `clock_pct` of T_new) |
| 7. Feedback thresholds | `T_new` |
| 8. Loss/win check | `T_new`, N, happiness |

## Step 3 — carbon ledger (city + world)

```gdscript
static func band(t: float) -> int:
    if t >= 1.75: return 2
    if t >= 1.50: return 1
    return 0

static func sink_stress(t_prev: float) -> float:
    return SINK_STRESS[band(t_prev)]
    # caller: absorption = max(A_FLOOR, absorption + matured - stress)

static func sector_emissions(base: float, progress: float) -> float:
    return base * (1.0 - (1.0 - RESIDUAL) * progress / 100.0)

static func net(e: float, a: float) -> float:
    return e - a          # metric: Net carbon N; win the moment N <= 0, any turn
```

Order inside step 3 (Phase 1 contract, extended for the clock race):

1. **Answered on-draw spikes revert**: for each answered crisis with an `on_draw_e`
   spike, `e_extra -= spike` — answering this turn dissipates the baked-in emissions
   before the ledger is read; an ignored spike is permanent.
2. **Mature**: each `ReforestEntry` adds `per_turn` to absorption and decrements
   `turns_left`; finished entries drop out.
3. **Stress → floor**: `absorption = max(A_FLOOR, absorption − sink_stress(T_prev))`.
4. **Compute E**: `E = E_city + E_world` — the city sphere
   (`gross_emissions()` = sectors in fixed order + `e_extra`) plus the **world actors'**
   summed emission curves (`world_emissions()`; see `01_RunState_Spec.md` step 7b for
   how those curves move).
5. **Compute N** = E − A.

Region-level display values decompose the *city* results via `RegionData` shares
(`../Phase_3/01`, invariant: region sums equal the city globals — test T6); the world
actors render in their own blocs panel, never on the region map.

## Step 4 — warming delta

```gdscript
static func warming_delta(n: float) -> float:
    return K_WARM * n if n > 0.0 else K_COOL * n     # cooling ~4x slower

static func apply_warming(temp: float, n: float) -> float:
    return maxf(T_FLOOR, temp + warming_delta(n))
# caller: if band(temp) != band(t_prev): emit warming_band_changed(band(temp))
```

`warming_band_changed` fires in **both directions** — Overshoot exit (winners cross back
below 1.5 mid-century) is the visual payoff of the whole run; the vignette must lift.
The record also stores `clock_pct` — the HUD gauge and the log's "Climate clock: N%"
line are renderings of this one number.

## Step 7 — one-time feedback loops (after the crisis strikes, using post-strike state)

Data-driven: `catalog.feedback_events()` in ascending `order`, each at most once per
run (`feedback_years` holds the trigger year). Trigger keys: `temp_gte` (T_new),
`fires_gte` (the fires counter, which includes any UNANSWERED fire from THIS turn's
step 6 — Phase 1 contract). Effect keys: `e_extra` (added), `absorption` (added,
floored at A_FLOOR).

```
permafrost_methane   T >= 1.75   e_extra += 2.0      # log: "Permafrost methane release"
ocean_sink_weakening T >= 1.90   absorption -= 2.0
amazon_dieback       fires >= 3  absorption -= 3.0
```

Checked in this fixed order every turn. Note the asymmetry, kept deliberately:
permafrost worsens **emissions** (shows in E), ocean and Amazon cut **absorption**
(shows in A) — the two bars of the region mini-bars and HUD ledger tell the player
*which side* of the balance was hit.

Feedback A-cuts apply immediately in step 7; they do not re-trigger step 3's floor
logic beyond their own `max(A_FLOOR, ...)` clamp. E-effects (`e_extra`) are seen by the
ledger from the **next** turn's step 3 onward — a feedback triggered this turn cannot
retroactively change this turn's N (already used for dT).

## Golden values (fixture anchors for unit tests — `test_climate_calc.gd`)

| Input | Expected |
|---|---|
| All sectors 0%, `e_extra 0` | E_city = 50.0 (canonical bases 20/15/15) |
| All sectors 100% | E_city = 5.0 (10% residual) |
| ind 70, tra 70, agr 70 | E_city = 18.5 (the tech-cap plateau) |
| `e_extra 2.0` on the 0% baseline | E_city = 52.0 |
| N = +30 | dT = +0.033 / turn |
| N = −20 | dT = −0.0056 / turn (~4× slower cooling) |
| T 1.49 / 1.50 / 1.74 / 1.75 | band 0 / 1 / 1 / 2 |
| sink_stress at T 1.40 / 1.60 / 1.80 | 0.0 / 0.5 / 1.2 per turn |
| A 5.2, band-2 stress 1.2 | A → 5.0 (floor engaged) |
| clock_pct at T 1.30 / 2.00 / 0.90 / 2.30 | 30% / 100% / 0% / 100% (clamped) |
| clock_delta_pct(+0.05) | +5.0 clock points |

These are the numbers behind the seed-2030 fixture tables in
`../Phase_1/02_Sample_Runs.md`; if a golden value test fails, the balance model changed —
that is a design event, not a refactor (update Phase 1 docs first, code second).
