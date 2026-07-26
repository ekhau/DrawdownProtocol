# Climate Calculation Spec — The Drawdown Protocol (Phase 4)

Steps 3, 4, and 7 of the yearly pipeline as pure, individually testable functions with
the exact constants of `../Phase_1/01_Balance_Model.md`. All functions live in a static
`ClimateCalc` class: inputs in, deltas out, no side effects — RunState applies them.

## Constants (from Phase 1; stored in `data/climate.json`)

```
K_WARM = 0.001      K_COOL = 0.00025     T_FLOOR = 1.20
T_WARN = 1.50       T_LOSS = 2.00
RESIDUAL = 0.10     A_FLOOR = 5.0
SINK_STRESS = [0.0, 0.10, 0.25]          # by warming band
PERMAFROST_T = 1.75   PERMAFROST_DE = 2.0
OCEAN_T      = 1.90   OCEAN_DA      = 2.0
AMAZON_FIRES = 3      AMAZON_DA     = 3.0
```

## Which temperature each step reads (order-critical)

The pipeline updates `temp` in step 4. Everything before reads last year's value;
everything after reads this year's. This matches the Phase 1 model exactly and must not
be "fixed":

| Step | Uses |
|---|---|
| 3. Sink stress band | `band(T_prev)` |
| 4. Warming delta | net carbon from step 3 |
| 5. Happiness stress band | `band(T_new)` |
| 6. Event probability band | `band(T_new)` |
| 7. Feedback thresholds | `T_new` |
| 8. Loss check | `T_new` |

## Step 3 — carbon ledger

```gdscript
static func band(t: float) -> int:
    if t >= 1.75: return 2
    if t >= 1.50: return 1
    return 0

static func mature_sinks(queue: Array[ReforestEntry]) -> float:
    # returns delta_A; caller decrements years_left and drops finished entries
    # delta_A = sum of per_year over entries (applied BEFORE stress, per Phase 1 order)

static func sink_stress(t_prev: float) -> float:
    return SINK_STRESS[band(t_prev)]
    # caller: absorption = max(A_FLOOR, absorption + matured - stress)

static func sector_emissions(s: SectorState) -> float:
    return s.base * (1.0 - (1.0 - RESIDUAL) * s.progress / 100.0)

static func gross_emissions(sectors, e_extra: float) -> float:
    # fixed order [ind, tra, agr]; + e_extra (feedback loops)

static func net(e: float, a: float) -> float:
    return e - a          # metric: Net carbon N; win requires N <= 0 at 2100
```

Order inside step 3 (Phase 1 contract): mature → stress → floor → compute E → compute N.
Region-level display values decompose these results via `RegionData` shares
(`../Phase_3/01`, invariant: region sums equal these globals — test T6).

## Step 4 — warming delta

```gdscript
static func warming_delta(n: float) -> float:
    return K_WARM * n if n > 0.0 else K_COOL * n

# caller: temp = max(T_FLOOR, temp + warming_delta(n))
#         if band(temp) != band(t_prev): emit warming_band_changed(band(temp))
```

`warming_band_changed` fires in **both directions** — Overshoot exit (winners cross back
below 1.5 mid-century) is the visual payoff of the whole run; the vignette must lift.

## Step 7 — one-time feedback loops (after the crisis strikes, using post-strike state)

```gdscript
# fires counter includes any UNANSWERED fire from THIS year's step 6 (Phase 1 contract)
if not permafrost and temp >= PERMAFROST_T:
    permafrost = true;  e_extra += PERMAFROST_DE          # log: "Permafrost methane release"
if not ocean_weak and temp >= OCEAN_T:
    ocean_weak = true;  absorption = max(A_FLOOR, absorption - OCEAN_DA)
if not amazon and fires >= AMAZON_FIRES:
    amazon = true;      absorption = max(A_FLOOR, absorption - AMAZON_DA)
```

Checked in this fixed order every year; each fires at most once per run. Note the
asymmetry, kept deliberately: permafrost worsens **emissions** (shows in E), ocean and
Amazon cut **absorption** (shows in A) — the two bars of the region mini-bars and HUD
ledger tell the player *which side* of the balance was hit.

Feedback A-cuts apply immediately in step 7; they do not re-trigger step 3's floor
logic beyond their own `max(A_FLOOR, ...)` clamp. E-effects (`e_extra`) are seen by the
ledger from the **next** year's step 3 onward — a feedback triggered this year cannot
retroactively change this year's N (already used for dT).

## Golden values (fixture anchors for unit tests)

| Input | Expected |
|---|---|
| All sectors 0%, `e_extra 0` | E = 50.0 (canonical bases 20/15/15) |
| All sectors 100% | E = 5.0 |
| ind 70, tra 70, agr 70 | E = 18.5 (the tech-cap plateau) |
| N = +30 | dT = +0.030 |
| N = −20 | dT = −0.005 |
| T 1.49 / 1.50 / 1.74 / 1.75 | band 0 / 1 / 1 / 2 |
| A 5.2, stress 0.25 | A → 5.0 (floor engaged) |

These are the numbers behind the seed-2030 fixture tables in
`../Phase_1/02_Sample_Runs.md`; if a golden value test fails, the balance model changed —
that is a design event, not a refactor (update Phase 1 docs first, code second).
