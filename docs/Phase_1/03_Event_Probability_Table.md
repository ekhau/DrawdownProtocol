# Event Probability Table — The Drawdown Protocol (Phase 1)

Baseline annual probabilities by warming band, with effects and opportunity riders.
Every event must remain both a threat and a door (design pillar 2). All events roll
independently each year; all damage is scaled by the resilience multiplier
`mult = 1 − R/200` (see `01_Balance_Model.md`).

## Warming Bands

| Band | Range | State |
|---|---|---|
| 0 | T < +1.5 °C | Stable |
| 1 | +1.5 ≤ T < +1.75 °C | **Overshoot I** (warning threshold crossed) |
| 2 | T ≥ +1.75 °C | **Overshoot II** (escalation) |

## Extreme Events

| Event | P(band 0) | P(band 1) | P(band 2) | Damage (× mult) | Opportunity rider |
|---|---|---|---|---|---|
| **Heat wave** | 10% | 25% | 40% | Happiness −3, Money −20 | — (pure pressure; the drumbeat of Overshoot) |
| **Mega fire** | 5% | 15% | 25% | Absorption −1.0 (permanent), Money −10, Happiness −1; +1 to fire counter | **Rebuild better:** next restoration card (Reforestation / Peatland & Ocean) costs 50% |
| **Flood / tsunami** | 5% | 10% | 15% | Money −40, Happiness −3 | **Rebuild better:** +5% transport progress free next year (rebuilt infrastructure is transformed infrastructure) |
| **Social crisis** | see formula | | | Influence −10, Money −20, lose 1 ally | **Policy window:** next sufficiency card has no happiness cost ("the crisis legitimizes the change") |

## Social Crisis Probability

Social unrest is driven by unhappiness first and climate stress second:

```
base   = 25% if H < 40, else 5%
p_soc  = base × band_scale        # band_scale: 1.0 / 1.25 / 1.5
if media active: p_soc ×= 0.5     # Independent Media Fund
```

Design intent: a player who keeps happiness above 40 and funds media almost never sees
one (≈ 2.5–3.75%/yr); a player who treats people as an afterthought sees one every ~3–4
years in late Overshoot (Run B: nine social crises in its last two decades).

## Feedback Loops (one-time, permanent)

| Feedback loop | Trigger | Effect | Signal to player |
|---|---|---|---|
| **Permafrost methane release** | T reaches +1.75 °C | Gross emissions +2.0 permanently | Overshoot II announcement; the ledger worsens on its own |
| **Ocean sink weakening** | T reaches +1.90 °C | Absorption −2.0 immediately | Last-warning klaxon before +2.0 °C |
| **Amazon dieback** | 3rd mega fire of the run | Absorption −3.0 immediately | Fires are not local news; the counter is visible from fire #1 |

## Tuning Notes

- Probabilities are per-year and independent; expected events per decade in band 1 ≈ 5
  (heat 2.5, fire 1.5, flood 1.0) — enough pressure that a decade rarely passes quietly,
  matching the mid-game tension target in `02_Sample_Runs.md`.
- The three feedback loops are the escalation ladder past +1.5 °C required by the concept;
  they are deliberately few, loud, and permanent (readable balance over simulation depth).
- Balance levers, in order of preference: band probabilities → damage values →
  opportunity rider strength. Trigger thresholds (1.75 / 1.90 / 3 fires) move only as a
  last resort — they are taught as facts of the world.
