# Balance Model — The Drawdown Protocol (Phase 1)

Per-year formulas for the crisis-response loop. The numbers below are validated by the
scripted strategy runs in `02_Sample_Runs.md` (regenerable via `src/tools/gen_fixtures.gd`
and the 20-seed batch harness), so they can be implemented without guessing. All constants
belong in data files (golden rule 9).

Metric definitions live in `../Phase_0/04_Simulation_Metric_Dictionary.md`.

## Constants

| Constant | Value | Meaning |
|---|---|---|
| `START_YEAR / END_YEAR` | 2030 / 2100 | 71 turns |
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
| `CRISES_PER_TURN` | 3 | Events drawn every year (crises + opportunities) |
| `MAX_CARDS_PER_TURN` | 5 | Card plays per year (the only per-turn action limit) |
| `COMBO_CHAIN_STEP / CAP` | 0.1 / 10 | Combo reward multiplier `1 + 0.1 × min(chain, 10)` — ×1.0 to ×2.0 |
| `PROJECT_MAX_ACTIVE` | 2 | Long-term projects running at once |

## Yearly Pipeline (strict order)

Each turn resolves in this order. Implement as one method on the run state.

### 1. Income and project upkeep

```
income    = 100 + 20 × allies + passive_income_money
if H < 25: income ×= 0.5           # elif: only the strongest penalty applies
elif H < 40: income ×= 0.75
M += income
I += 2 + 1 × allies + (1 if media else 0) + passive_income_influence
H += passive_happiness_per_year (clamped);  A += passive_absorption_per_year
if flood_rebuild: prog[tra] += 5 (capped); flood_rebuild = false
for each active project (launch order):
    if upkeep affordable: pay; years_left -= 1
        if years_left == 0: COMPLETE - apply completion effects, add passives
    else: FAIL - apply abandon penalty (happiness, influence); project is gone for the run
```

### 1b. Crisis draw — the turn's pressure

Three events are drawn from the crisis deck (no duplicates within a year), weighted per
entry by warming band and social state:

```
weight(entry) = weights[band(T)]
if entry has weight_mods:                      # social_crisis in the shipped deck
    if H < happiness_threshold: weight ×= low_happiness_mult
    if media: weight ×= media_mult
```

Weights table: `03_Event_Probability_Table.md`. Each drawn event also draws its flavor
target region. Crises show their damages and **response tags**; opportunities show their
seize reward. This is the ONLY consumer of run randomness (2 draws per event, fixed order).

### 2. Player actions — up to 5 cards, resource-bound

Card list and effects: `04_Policy_Effect_Matrix.md`. Playability: cost affordable
(money AND influence AND happiness), ally requirements met, sector not at its cap, card
unlocked, per-turn cap not reached. Per play, in order:

```
pay costs (M / I / H); apply effects in catalog order; grant printed rewards
answer: first open drawn event whose response tags intersect the card's tags
        -> contained: flagged answered, response rewards granted immediately
tags of this play join the year's tag multiset
combo check: every not-yet-fired-this-year combo whose tag multiset is covered FIRES:
        mult = 1 + 0.1 × min(chain, 10)      # chain BEFORE this combo
        chain += 1; apply combo effects; grant rewards × mult
        (knowledge rewards only on the combo's FIRST fire of the run)
deck growth check: unlock conditions (crises answered, combos, allies,
        sector progress, projects completed)
```

Projects may be launched (pays the first year's upkeep immediately) or abandoned
(applies the penalty) at any point during the action phase. Passing (zero cards) is
legal and banks the money.

Happiness penalty rule: a sufficiency card's negative happiness cost is **waived** if
`media` is active or a social-crisis `window` is open (window is then consumed; media
does not consume the window).

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

### 6. Unanswered crises strike

Answered events are contained — no damage, no rider. Each unanswered **crisis** applies
its damages (`03_Event_Probability_Table.md`), scaled where the catalog says so:

```
R    = clamp(0.4 × H + adapt, 0, 100)
mult = 1 − R / 200                      # R = 100 halves damage
```

Only a crisis that actually strikes opens its opportunity rider (fire discount, flood
rebuild, policy window), appends its scar, and counts its fire. Unanswered
**opportunities** simply pass by — nothing lost but the chance. A comboless year decays
the combo chain by 1 (min 0).

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
   + kp_earned                                # in-run insight: first-fire combo
                                              # rewards + seized opportunities (~0–4)
```

Observed range: 2–5 (crisis-bled tech-rush loss) to 17–18 (competent win). A ~6-node
Knowledge tree priced at 5–12 KP per node gives one meaningful unlock per run
(golden rule 10).

## The tactical economy (why the numbers hold)

- **Answering pays, but costs tempo.** A response card (25–40 M) plus its response reward
  (~8–15 in resources) roughly cancels the avoided damage (15–30 M plus pillar hits) — the
  real cost of answering is the money NOT spent on transformation that year.
- **Combos are the profit margin.** A deliberate two-card pair yields +10 to +25 base,
  ×chain; the chain (≈ +1/yr for a combo-literate player, −1 on quiet years) is what
  funds answering three Overshoot-strength crises at once late-century.
- **Projects convert surplus into permanence.** 150–225 M over five years buys income,
  sinks, wellbeing or allies for the remaining decades — the main mid-run money sink.
- **Ignoring crises compounds.** Unanswered fires and droughts eat absorption directly
  (−0.8 / −0.3 per hit): the tech-rush archetype now dies mid-2060s at the sink floor
  rather than limping to 2099.

## Determinism

One `RandomNumberGenerator` seeded per run, consumed ONLY by the year-start crisis draw
(pick + target per event, fixed order). Same seed + same decisions ⇒ same timeline, for
tests and balance regression. The canonical fixture seed is **2030**.

## Known model gaps (accepted for Phase 1)

- Winners still hoard money after the transition completes (~5 000–6 500 by 2100 for the
  Safe archetype; the Mixed archetype spends down to ~100–200). Projects absorb some of
  it; Risk #5 remains open.
- Winners' happiness saturates at 100 from mid-century (answered crises + co-benefits);
  the old dip-then-bloom arc has become surge-then-hold. Acceptable while crisis pressure
  is the designed tension; revisit in the Phase 8 tuning pass (Risk #13).
- Influence is uncapped; consider a 100 cap in implementation.
- Baseline assumes zero Knowledge nodes (first-run experience).
