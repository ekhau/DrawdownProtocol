# Target Balance Bands by Decade — The Drawdown Protocol (Phase 1)

Expected corridors for competent play, derived from the two winning sample runs (A and C
in `02_Sample_Runs.md`) with margins; the tech-rush loss (Run B) is shown as the
out-of-band reference. Use these bands to judge future tuning: if playtest runs sit
outside the corridor while players report playing well, retune values (not formulas)
until they fit — data-driven balance, golden rule 9.

## Warming (°C above pre-industrial)

| Decade end | Competent corridor | Danger signal | Run B (loss) |
|---|---|---|---|
| 2040 | 1.55 – 1.60 | > 1.62 | 1.50 * |
| 2050 | 1.62 – 1.72 | > 1.78 | 1.54 * |
| 2060 | 1.62 – 1.75 | > 1.85 | 1.58 * |
| 2070 | 1.58 – 1.72 | > 1.90 | 1.64 |
| 2080 | 1.52 – 1.68 | > 1.95 | 1.73 |
| 2090 | 1.46 – 1.63 | ≥ 2.00 = loss | 1.86 |
| 2100 | 1.42 – 1.58 | — | 2.00 (lost 2099) |

\* Run B is *below* band early — the trap of the tech rush: the fastest start of the three
runs, then the 70% cap freeze. Early warming is not the whole story; the corridor must be
read together with net emissions.

Every strategy crosses +1.5 °C around 2038–2040: **Overshoot is the designed mid-game**,
peaking at ≤ +1.75 °C for winners and re-exiting (T < 1.5) between ~2090 and 2100.

## Net Carbon (GtCO2e/yr; win requires ≤ 0 at 2100)

| Decade end | Competent corridor | Danger signal |
|---|---|---|
| 2040 | +14 to +19 | > +22 |
| 2050 | +2 to +10 | > +14 |
| 2060 | −12 to −2 | still positive after 2065 |
| 2070 | −24 to −13 | > −5 |
| 2080–2100 | −24 to −18 (structural) | trending toward 0 (sink loss outpacing restoration) |

Pivot target: **net zero crossed between 2055 and 2065.** Run B never crossed it (frozen
at ≈ +4 by the caps, then rising with feedback loops).

## Money (funds)

| Decade end | Competent corridor | Danger signal |
|---|---|---|
| 2040 | 250 – 550 | < 100 (no crisis buffer) |
| 2050 | 600 – 1 050 | < 200 |
| 2060 | 1 300 – 1 600 | < 400 |
| 2070 | 1 900 – 2 200 | — |
| 2080+ | 2 900+ (hoarding begins) | — (known gap, Risk #5) |

Reserves below ~100 mean one flood (−40 × mult) can lock the player out of a card year —
acceptable tension early, a death knell mid-game.

## Happiness (0–100)

| Decade end | Competent corridor | Danger signal | Run B (loss) |
|---|---|---|---|
| 2040 | 55 – 68 | < 50 | 61 |
| 2050 | 45 – 68 | < 42 | 57 |
| 2060 | 45 – 65 | < 40 (income penalty + crisis zone) | 55 |
| 2070 | 55 – 68 | < 45 | 51 |
| 2080 | 70 – 82 | < 55 | 55 |
| 2090 | 70 – 82 | < 55 | 35 |
| 2100 | 72 – 90 | < 60 | 24 |

Intended arc: **dip mid-century (bottom 45–50 around 2050–2060), bloom after the
transition** as co-benefits outweigh Overshoot stress. A happiness line still falling
after 2070 predicts the social death spiral roughly two decades before it kills the run
(Run B: falling from 2070, nine social crises in the 2080s–90s).

## How to Use These Bands

1. In playtests and automated runs (Plan.md Phase 8), sample the four metrics at each
   decade and count band exits per run.
2. Winners should sit inside all four corridors ≥ 5 of 7 decades; losses should be
   attributable to a visible, early band exit (teachability test).
3. If a strategy wins from far outside a corridor, it is a dominant-strategy suspect —
   check the watch list in `04_Policy_Effect_Matrix.md`.
