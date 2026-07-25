# Balance Model — The Drawdown Protocol (Phase 1)

Per-year formulas for the paper prototype. These numbers were validated by simulating the
three sample runs in `02_Sample_Runs.md` with a throwaway script (kept out of the repo per
golden rule 4); the formulas below are exactly what that script executed, so they can be
implemented without guessing. All constants belong in data files (golden rule 9).

Metric definitions live in `../Phase_0/04_Simulation_Metric_Dictionary.md`.

## Constants

| Constant | Value | Meaning |
|---|---|---|
| `START_YEAR / END_YEAR` | 2030 / 2100 | 71 turns, one card per turn |
| `T_START` | 1.30 °C | Warming at run start |
| `T_WARN / T_LOSS` | 1.50 / 2.00 °C | Overshoot warning / hard loss |
| `K_WARM` | 0.001 °C per GtCO2e | Warming per unit of positive net emissions (see Assumptions #3) |
| `K_COOL` | 0.00025 °C per GtCO2e | Cooling per unit of negative net (4× slower) |
| `T_FLOOR` | 1.20 °C | Warming cannot drop below this in-run |
| `SECTOR_BASE` | ind 20 / tra 15 / agr 15 GtCO2e/yr | Sector emissions at 0% progress (50 total) |
| `RESIDUAL` | 10% | Sector emissions remaining at 100% progress |
| `A_START / A_FLOOR` | 20.0 / 5.0 GtCO2e/yr | Starting / minimum absorption |
| `M_START / H_START / I_START` | 100 / 60 / 10 | Starting money, happiness, influence |
| `TECH_CAP` | 70% | Sector progress cap until a sufficiency card is played in that sector |
| `MAX_ALLIES` | 6 | Alliance cap |

## Yearly Pipeline (strict order)

Each turn resolves in this order. Implement as one method on the run state.

### 1. Income

```
income    = 100 + 20 × allies
if H < 25: income ×= 0.5           # elif: only the strongest penalty applies
elif H < 40: income ×= 0.75
M += income
I += 2 + 1 × allies + (1 if media else 0)
if flood_rebuild: prog[tra] += 5 (capped); flood_rebuild = false
```

### 2. Player action — exactly one card (or pass)

Card list and effects: `04_Policy_Effect_Matrix.md`. Playability: cost affordable
(money AND influence), ally requirements met, sector not at its cap. Passing banks money.

Happiness penalty rule: a sufficiency card's negative happiness cost is **waived** if
`media` is active or a social-crisis `window` is open (window is then consumed).

### 3. Carbon ledger

```
for each maturing restoration program: A += per_year; years_left -= 1
sink_stress = 0.0 (T < 1.5) | 0.10 (1.5 ≤ T < 1.75) | 0.25 (T ≥ 1.75)
A = max(A_FLOOR, A − sink_stress)
E = Σ_sector base_s × (1 − 0.9 × prog_s / 100) + E_extra
N = E − A
```

### 4. Warming

```
dT = K_WARM × N   if N > 0
dT = K_COOL × N   if N ≤ 0
T = max(T_FLOOR, T + dT)
```

### 5. Happiness drift (co-benefits vs Overshoot stress)

```
co_benefit = 1.5 × (average sector progress) / 100        # max +1.5/yr at full transition
stress     = 0.0 | 0.5 | 1.0 by warming band
H = clamp(H + co_benefit − stress, 0, 100)
```

This produces the intended arc: dip mid-century, bloom after the transition.

### 6. Random events

Roll each event independently at the band probabilities in
`03_Event_Probability_Table.md`. All damage is scaled by the resilience multiplier:

```
R    = clamp(0.4 × H + adapt, 0, 100)
mult = 1 − R / 200                      # R = 100 halves damage
```

### 7. One-time feedback loops

```
if T ≥ 1.75 and not permafrost:  E_extra += 2.0
if T ≥ 1.90 and not ocean_weak:  A = max(A_FLOOR, A − 2.0)
if fires ≥ 3 and not amazon:     A = max(A_FLOOR, A − 3.0)
```

### 8. End-of-turn check

```
if T ≥ 2.00                → LOSS (limit breached)
if year = 2100 and N ≤ 0   → WIN  (carbon-neutral world)
if year = 2100 and N > 0   → SOFT LOSS (survived, not neutral)
else                       → year += 1
```

## Knowledge Points (meta, awarded at run end)

```
KP = (last_year − 2030) ÷ 10 (floor)          # decades survived: 0–7
   + count(sector progress ≥ 70%)             # 0–3
   + allies ÷ 2 (floor)                       # 0–3
   + 3 if WIN
```

Observed range: 9 (early tech-rush loss) to 16 (alliance win). A ~6-node Knowledge tree
priced at 4–12 KP per node gives one meaningful unlock per run (golden rule 10).

## Determinism

One `RandomNumberGenerator` seeded per run; the sample runs use seed **2030**. Same seed +
same decisions ⇒ same timeline, for tests and balance regression.

## Known model gaps (accepted for Phase 1)

- No late-game money sink: winners hoard 6 000+ funds after full transition (Risk #5).
- Influence is uncapped; consider a 100 cap in implementation.
- Baseline assumes zero Knowledge nodes (first-run experience); Knowledge modifiers are
  specified in `04_Policy_Effect_Matrix.md` but not simulated yet.
