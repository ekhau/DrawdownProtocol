# Crisis Deck Table — The Drawdown Protocol (Phase 1)

The crisis deck: every year **exactly 3 events** are drawn from it (no duplicates within
a year), weighted by warming band and social state. Crises answered by a matching card
tag are contained (no damage, response reward paid); unanswered crises strike with the
damages below, scaled by the resilience multiplier `mult = 1 − R/200` where marked
(see `01_Balance_Model.md`). Every event must remain both a threat and a door
(design pillar 2): answering pays, and even an unanswered strike opens its rider.

## Warming Bands

| Band | Range | State |
|---|---|---|
| 0 | T < +1.5 °C | Stable |
| 1 | +1.5 ≤ T < +1.75 °C | **Overshoot I** (warning threshold crossed) |
| 2 | T ≥ +1.75 °C | **Overshoot II** (escalation) |

## Crises (draw weights by band; non-decreasing — Overshoot escalates)

| Crisis | W(b0) | W(b1) | W(b2) | Damage if unanswered (× mult) | Answer tags | Answer reward | Rider on a strike |
|---|---|---|---|---|---|---|---|
| **Drought** | 0.8 | 1.3 | 1.8 | Money −15, Happiness −2, Absorption −0.3; scar | water, food | +8 M, +2 I | — |
| **Heat wave** | 0.8 | 1.4 | 2.0 | Happiness −3, Money −20 | health, relief | +3 I, +1 H | — |
| **Mega fire** | 0.6 | 1.2 | 1.8 | Absorption −0.8, Money −10, Happiness −1; +1 fire counter; scar | forest, relief | +8 M | **Rebuild better:** next restoration card at 50% |
| **Flood / tsunami** | 0.6 | 1.0 | 1.5 | Money −30, Happiness −2; scar | coast, relief | +3 I | **Rebuild better:** +5% transport free next year |
| **Crop failure** | 0.5 | 1.0 | 1.5 | Money −20, Happiness −2 | food, water | +8 M, +1 H | — |
| **Energy crunch** | 0.8 | 1.0 | 1.2 | Money −25, Happiness −2 (flat — markets ignore seawalls) | energy, civic | +12 M | — |
| **Social crisis** | 0.5 | 0.8 | 1.2 | Influence −8, Money −15, lose 1 ally (flat) | civic, relief | +5 I | **Policy window:** next sufficiency card costs no happiness |

## Opportunities (pure upside; weights may fall as the world heats)

| Opportunity | W(b0) | W(b1) | W(b2) | If seized (answer tags) | If missed |
|---|---|---|---|---|---|
| **Climate summit** | 1.2 | 1.0 | 0.8 | treaty → +8 I, +15 M | passes by |
| **Green investment wave** | 1.0 | 0.9 | 0.7 | energy → +30 M | passes by |
| **Youth movement** | 1.0 | 1.0 | 1.0 | civic, health → +3 H, +3 I | passes by |

## Social-Crisis Weight Modifiers

Social unrest is driven by unhappiness first and climate stress second:

```
w_soc = weights[band]
if H < 40:  w_soc ×= 3.0       # low_happiness_mult
if media:   w_soc ×= 0.5       # Independent Media Fund
```

Design intent: a player who keeps happiness above 40 and funds media rarely sees one in
the draw; a player who treats people as an afterthought faces them constantly in late
Overshoot (the Risky archetype draws them nearly every year after 2050).

## Expected Draw Composition

Total deck weight at band 0 ≈ 7.8 (crises 4.6, opportunities 3.2): a typical stable-world
year deals ~1.8 crises and ~1.2 opportunities. At band 2 ≈ 13.5 (crises 11.0,
opportunities 2.5): ~2.4 crises, ~0.6 opportunities — Overshoot years are heavier AND
stingier, without ever changing the count of three.

## Feedback Loops (one-time, permanent — unchanged)

| Feedback loop | Trigger | Effect | Signal to player |
|---|---|---|---|
| **Permafrost methane release** | T reaches +1.75 °C | Gross emissions +2.0 permanently | Overshoot II announcement; the ledger worsens on its own |
| **Ocean sink weakening** | T reaches +1.90 °C | Absorption −2.0 immediately | Last-warning klaxon before +2.0 °C |
| **Amazon dieback** | 3rd unanswered mega fire of the run | Absorption −3.0 immediately | Fires are not local news; the counter is visible from fire #1 |

## Tuning Notes

- Draw weights are relative, not probabilities: adding a deck entry dilutes every other
  entry — the balance lever for "how often does X land" is its weight row.
- Balance levers, in order of preference: draw weights → damages → response rewards →
  rider strength. Trigger thresholds (1.75 / 1.90 / 3 fires) move only as a last resort —
  they are taught as facts of the world.
- Response tags are a contract with `04_Policy_Effect_Matrix.md`: every crisis must be
  answerable by at least one card in the STARTING pool (validator rule E10).
- Damages are deliberately smaller than the old always-roll model's, because presence is
  now guaranteed: three events land every single year.
