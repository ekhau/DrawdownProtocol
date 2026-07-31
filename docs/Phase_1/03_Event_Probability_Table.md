# Crisis Deck Table — The Drawdown Protocol (Phase 1)

The crisis deck: every turn **exactly 3 events** are drawn from it (no duplicates within
a turn), weighted by warming band and social state. Crises answered by a matching card
tag are contained (no damage, response reward paid); unanswered crises strike with the
damages below, scaled by the resilience multiplier `mult = 1 − R/200` where marked
(see `01_Balance_Model.md`). Damages are tuned to the **five-year turn scale** — roughly
double the old yearly model — because each drawn event stands for the period's defining
disaster. Every event must remain both a threat and a door (design pillar 2): answering
pays, and even an unanswered strike opens its rider.

## Warming Bands

| Band | Range | State |
|---|---|---|
| 0 | T < +1.5 °C | Stable |
| 1 | +1.5 ≤ T < +1.75 °C | **Overshoot I** (warning threshold crossed) |
| 2 | T ≥ +1.75 °C | **Overshoot II** (escalation) |

## Crises (draw weights by band; non-decreasing — Overshoot escalates)

| Crisis | W(b0) | W(b1) | W(b2) | Damage if unanswered (× mult) | Answer tags | Answer reward | Rider / extra |
|---|---|---|---|---|---|---|---|
| **Drought** | 0.8 | 1.3 | 1.8 | Money −30, Happiness −4, Absorption −0.6; scar | water, food | +15 M, +3 I | — |
| **Record Heat Wave** | 0.8 | 1.4 | 2.0 | Happiness −6, Money −40 | health, relief | +4 I, +2 H | **On draw:** +1.0 `E_extra` immediately — dissipates if answered this turn, **permanent if ignored**. **Bonus card:** injects HWP1 Heatwave Response Plan into the market if H ≥ 40 |
| **Mega Fire** | 0.6 | 1.2 | 1.8 | Absorption −1.6, Money −20, Happiness −2; +1 fire counter; scar | forest, relief | +15 M | **Rebuild better:** next restoration card at 50% |
| **Flood & Tsunami** | 0.6 | 1.0 | 1.5 | Money −60, Happiness −4; scar | coast, relief | +4 I | **Rebuild better:** +5% transport free next turn |
| **Crop Failure** | 0.5 | 1.0 | 1.5 | Money −40, Happiness −4 | food, water | +15 M, +2 H | — |
| **Energy Crunch** | 0.8 | 1.0 | 1.2 | Money −50, Happiness −4 (flat — markets ignore seawalls) | energy, civic | +20 M | — |
| **Social Crisis** | 0.5 | 0.8 | 1.2 | Influence −12, Money −30, Happiness −3, lose 1 ally (flat) | civic, relief | +8 I | **Policy window:** next sufficiency card costs no happiness |

## Opportunities (pure upside; weights may fall as the world heats)

| Opportunity | W(b0) | W(b1) | W(b2) | If seized (answer tags) | If missed |
|---|---|---|---|---|---|
| **Treaty Conference** (id `climate_summit`) | 1.2 | 1.0 | 0.8 | treaty → +10 I, +30 M | passes by |
| **Green Investment Wave** | 1.0 | 0.9 | 0.7 | energy → +50 M | passes by |
| **Youth Movement** | 1.0 | 1.0 | 1.0 | civic, health → +4 H, +4 I | passes by |

> The event keeps its historical id `climate_summit` but displays as **Treaty
> Conference**, to avoid clashing with the scheduled COP summits (`data/summits.json`) —
> those are fixed-turn objectives, not draws.

## Social-Crisis Weight Modifiers

Social unrest is driven by unhappiness first and climate stress second:

```
w_soc = weights[band]
if H < 40:  w_soc ×= 3.0       # low_happiness_mult
if media:   w_soc ×= 0.5       # Independent Media Fund
```

Design intent: a player who keeps happiness above 40 and funds media rarely sees one in
the draw; a player who treats people as an afterthought faces them constantly in late
Overshoot (the Moonshot Rush archetype draws them nearly every turn after mid-century —
and at 0 happiness the run ends in revolt).

## Expected Draw Composition

Total deck weight at band 0 ≈ 7.8 (crises 4.6, opportunities 3.2): a typical stable-world
turn deals ~1.8 crises and ~1.2 opportunities. At band 2 ≈ 13.5 (crises 11.0,
opportunities 2.5): ~2.4 crises, ~0.6 opportunities — Overshoot turns are heavier AND
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
  rider strength → spike size. Trigger thresholds (1.75 / 1.90 / 3 fires) move only as a
  last resort — they are taught as facts of the world.
- Response tags are a contract with `04_Policy_Effect_Matrix.md`: every crisis must be
  answerable by at least one card in the STARTING pool (validator rule E10) — and the
  market's guarantee rule ensures at least one answering offer is dealt.
- On-draw effects are crisis-only (validator E7); bonus-card links must reference a real
  card and use known gate keys (validator E8). HWP1 exists **only** through its event
  injection (`bonus_only`).
- Response rewards are roughly ×2 the old yearly values, matching the doubled damages —
  the answer-vs-tempo ratio is preserved, only the scale changed.
