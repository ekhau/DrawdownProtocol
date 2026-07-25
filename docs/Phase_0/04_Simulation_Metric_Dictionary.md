# Simulation Metric Dictionary — The Drawdown Protocol

Every simulation variable, its definition, unit, starting value, and expected range.
Formulas that connect them live in `../Phase_1/01_Balance_Model.md`. All tunable values
belong in data files, never hard-coded (golden rule 9).

## Core Timeline

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Year | `year` | Current turn; one turn = one year | year | 2030 | 2030–2100 |
| Warming | `T` | Global temperature anomaly above pre-industrial | °C | 1.30 | 1.20–2.00 (loss at ≥ 2.00; Overshoot at ≥ 1.50) |

## Pillar 1 — Money

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Money | `M` | Spendable funds (abstract billions) | funds | 100 | 0–~6 500; healthy play stays > 0 with reserves 100–500 mid-run |
| Yearly income | — | `100 + 20 × allies`, reduced ×0.75 if H < 40, ×0.5 if H < 25 | funds/yr | 100 | 50–220 |

## Pillar 2 — Carbon Balance

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Gross emissions | `E` | Sum of sector emissions + feedback extras | GtCO2e/yr | 50.0 | 5.0–52.0 |
| Absorption | `A` | Global sink capacity (forests, soils, oceans, restoration) | GtCO2e/yr | 20.0 | 5.0 (floor)–~29 |
| Net emissions | `N` | `E − A`; neutrality means N ≤ 0 | GtCO2e/yr | +30.0 | −24 to +30 |
| Sector progress | `prog[s]` | Transition % for industry / transport / agro-economy | % | 0 / 0 / 0 | 0–100 (capped at 70 without a sufficiency card) |
| Sector base emissions | — | Industry 20, Transport 15, Agro-economy 15; residual 10% at full transition | GtCO2e/yr | 50 total | 5 total at full transition |
| Sufficiency flags | `suff[s]` | Whether a sufficiency card was played in sector s (lifts cap 70→100) | bool | false | — |
| Feedback extras | `E_extra` | Permanent emissions added by triggered feedback loops | GtCO2e/yr | 0 | 0–2 |

## Pillar 3 — Happiness

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Happiness | `H` | Population wellbeing and social acceptance | 0–100 | 60 | Winners: dip to ~45–55 mid-run, recover to 70–90; danger below 40 (income penalty, social crises) |

## Diplomacy

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Influence | `I` | Diplomatic capital; earned yearly, spent on alliances and joint projects | points | 10 | 0–~230 (uncapped in paper model; consider cap in implementation) |
| Influence income | — | `2 + 1 × allies (+1 if media funded)` | points/yr | 2 | 2–9 |
| Allies | `allies` | Countries in the coalition | count | 0 | 0–6 |

## Resilience (derived) and Adaptation

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Adaptation points | `adapt` | Accumulated adaptation infrastructure | points | 0 | 0–60 |
| Resilience | `R` | **Derived:** `clamp(0.4 × H + adapt, 0, 100)`; event damage is multiplied by `1 − R/200` | 0–100 | 24 | 0–100 (R = 100 halves event damage) |

> **Reconciliation with Plan.md.** Plan.md predates the concept update and lists
> "resilience ≤ 0" as a loss condition. **Decision: resilience is kept, but demoted to a
> derived stat** — an event-damage modifier computed from happiness and adaptation — and it
> is **no longer a loss condition**. Rationale: the updated concept has exactly one hard
> loss (warming ≥ +2.0 °C) so defeat stays readable (pillar: Readable Balance); the social
> collapse that "resilience 0" used to represent now expresses itself through systems —
> low happiness cuts income and triggers social crises that cost money, Influence, and
> allies. Plan.md Phase 4's "resilience update logic" maps onto the `R` formula and the
> happiness pipeline below.

## Simulation State Flags

| Variable | Definition |
|---|---|
| `band` | Warming band: 0 stable (< 1.5), 1 Overshoot I (≥ 1.5), 2 Overshoot II (≥ 1.75) |
| `media` | Independent Media Fund active (suff. cards lose happiness penalty; +1 Influence/yr; social crisis probability halved) |
| `window` | Social-crisis policy window open (next sufficiency card has no happiness cost) |
| `fire_discount` | Rebuild-better: next restoration card at 50% cost |
| `flood_rebuild` | Rebuild-better: +5% transport progress free next year |
| `fires` | Cumulative mega fires (3 ⇒ Amazon dieback feedback) |
| `permafrost`, `ocean_weak`, `amazon` | One-time feedback loops already triggered |
| `reforest[]` | Maturing restoration programs: list of (Gt/yr, years remaining) |

## Meta-Progression (persists across runs)

| Variable | Definition | Unit | Range |
|---|---|---|---|
| Knowledge Points | `KP = decades survived + sectors ≥ 70% + allies ÷ 2 + 3 if win` | points/run | ~4–16 per run |
| Knowledge nodes | Unlocked entries of the Knowledge tree (e.g. Affordable EVs, Healthy Sobriety, Informed Public) | — | ~6 nodes in MVP |
