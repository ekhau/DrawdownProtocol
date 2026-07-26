# Target Balance Bands by Decade — The Drawdown Protocol (Phase 1)

Expected corridors for competent play, derived from the 20-seed × 2 winning-strategy
batch (Safe and Mixed archetypes, `src/tools/batch_runs.gd`) with margins; the tech-rush
loss (Risky) is shown as the out-of-band reference. Use these bands to judge future
tuning: if playtest runs sit outside the corridor while players report playing well,
retune values (not formulas) until they fit — data-driven balance, golden rule 9.

## Warming (°C above pre-industrial)

| Decade end | Competent corridor | Danger signal | Risky (loss) |
|---|---|---|---|
| 2040 | 1.48 – 1.61 | > 1.65 | 1.52 – 1.61 |
| 2050 | 1.44 – 1.64 | > 1.75 | 1.66 – 1.88 |
| 2060 | 1.36 – 1.59 | > 1.85 | 1.83 – 2.02 (dying) |
| 2070 | 1.26 – 1.50 | > 1.90 | lost 2055–2068 |
| 2080 | 1.20 – 1.40 | > 1.80 | — |
| 2090 | 1.20 – 1.28 | ≥ 2.00 = loss | — |
| 2100 | 1.20 | — | — |

Winners brush Overshoot I in the 2040s and re-exit by the 2050s–60s; deep Overshoot is
no longer the winner's guaranteed mid-game — the crisis draw weights carry the pressure
instead. Any run still above +1.75 °C after 2055 is on the Risky trajectory.

## Net Carbon (GtCO2e/yr; win requires ≤ 0 at 2100)

| Decade end | Competent corridor | Danger signal |
|---|---|---|
| 2040 | −2 to +18 | > +22 |
| 2050 | −30 to −7 | still positive after 2050 |
| 2060 | −44 to −18 | > −10 |
| 2070+ | −55 to −27 (structural) | trending toward 0 (sink loss outpacing restoration) |

Pivot target: **net zero crossed between 2042 and 2050.** Risky never crosses it (frozen
near +16 by drained money, then rising with the feedback loops).

## Money (funds)

| Decade end | Competent corridor | Danger signal |
|---|---|---|
| 2040 | 50 – 165 | < 40 (cannot answer next year's draw) |
| 2050 | 60 – 175 | < 50 |
| 2060 | 55 – 800 | < 50 |
| 2070+ | 55 – 4 000+ (styles diverge) | — (hoarding is Risk #5; lean is fine) |

The mid-game economy is deliberately tight: answering ~2 crises plus one transformation
card plus project upkeep consumes a full year's income. The corridor splits late by
archetype — Safe banks its surplus, Mixed reinvests everything (staying near 100 all
century is healthy Alliance-Web play). Reserves below ~40 mean one unanswered flood
locks the player out of answering the next draw.

## Happiness (0–100)

| Decade end | Competent corridor | Danger signal | Risky (loss) |
|---|---|---|---|
| 2040 | 80 – 100 | < 60 | 28 – 52 |
| 2050+ | 95 – 100 | < 70; any decade still falling | 0 – 20 |

Intended arc: **surge-then-hold** — answered crises stop the bleeding early and
co-benefits saturate happiness by mid-century; the danger signal is a line that is ever
*falling*, which now predicts the social death spiral about two decades before it kills
a run (Risky: below 40 by the mid-2040s, income halved, social crises weighted ×3 in
every draw thereafter). The saturation itself is a known gap (Risk #13 / model gaps in
`01_Balance_Model.md`).

## Crisis and Combo Health Metrics (new)

| Metric | Competent corridor | Danger signal |
|---|---|---|
| Crises answered per year | 2 – 3 | < 1.5 (bleeding), 3.0 with heavy surplus (answering too cheap — Risk #13) |
| Combos per decade | 6 – 10 | < 3 (deck read as 26 singletons) |
| Combo chain at 2100 | 25 – 50 | 0 chain past 2050 for a player trying |
| Projects completed per run | 1 – 2 | 0 (upkeep unaffordable — economy too tight) |
| Cards unlocked per run | 4 – 6 | < 2 (growth conditions out of reach) |

## How to Use These Bands

1. In playtests and automated runs (Plan.md Phase 8), sample the metrics at each decade
   and count band exits per run.
2. Winners should sit inside the corridors ≥ 5 of 7 decades; losses should be
   attributable to a visible, early band exit (teachability test).
3. If a strategy wins from far outside a corridor, it is a dominant-strategy suspect —
   check the watch list in `04_Policy_Effect_Matrix.md`.
