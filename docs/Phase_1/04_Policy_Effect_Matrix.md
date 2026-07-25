# Policy Effect Matrix — The Drawdown Protocol (Phase 1)

First-pass card catalog: 15 cards across the three sectors, sinks, society, and
diplomacy. One card is played per year. Costs are paid in Money (M) and Influence (I).
The catalog is data (JSON/resource files), never code (golden rule 9).

**Sufficiency rule:** each sector's transition is capped at **70%** until at least one
card tagged *sufficiency* is played in that sector (cap rises to 100%). This encodes the
IPCC demand-side finding — technology alone cannot finish the job.

**Happiness penalty rule:** negative happiness costs on sufficiency cards are waived while
the Independent Media Fund is active or during a social-crisis policy window.

## Sector Cards

| ID | Card | Sector | Cost M | Cost I | Immediate effect | Long-term effect | Pillar impact (M / C / H) | Sufficiency |
|---|---|---|---|---|---|---|---|---|
| IND1 | Industrial Efficiency | Industry | 80 | 0 | +8% industry progress | −1.44 Gt/yr emissions at full effect | − / ++ / · | — |
| IND2 | Clean Energy Grid | Industry | 150 | 0 | +15% industry progress | −2.7 Gt/yr | −− / +++ / · | — |
| IND3 | Circular Economy | Industry | 120 | 0 | +10% industry progress, +1 happiness | Lifts industry cap to 100% | −− / ++ / + | **Yes** |
| TRA1 | Rail & Bike Networks | Transport | 80 | 0 | +10% transport progress, +2 happiness | Lifts transport cap; feeds co-benefit drift | − / ++ / ++ | **Yes** |
| TRA2 | Affordable EVs | Transport | 140 | 0 | +15% transport progress | −2.03 Gt/yr | −− / +++ / · | — |
| TRA3 | Walkable Cities | Transport | 60 | 0 | +8% transport progress, −3 happiness (waivable) | Lifts transport cap; cheap cap-lifter | − / + / −→+ | **Yes** |
| AGR1 | Plant-Rich Diet Campaign | Agro-economy | 60 | 0 | +10% agro progress, −3 happiness (waivable) | Lifts agro cap; frees land narrative for sinks | − / ++ / −→+ | **Yes** |
| AGR2 | Agroecology Transition | Agro-economy | 100 | 0 | +12% agro progress, +0.2 absorption | Dual-purpose: cuts emissions AND grows the sink | − / ++ / · | — |

## Sink, Adaptation, and Society Cards

| ID | Card | Cost M | Cost I | Immediate effect | Long-term effect | Pillar impact (M / C / H) |
|---|---|---|---|---|---|---|
| SNK1 | Reforestation Program | 70 | 0 | Starts maturation | +0.3 absorption/yr for 5 years (+1.5 total) | − / ++ / · |
| SNK2 | Peatland & Ocean Restoration | 90 | 0 | +5 adaptation; starts maturation | +0.2 absorption/yr for 5 years (+1.0 total) | − / ++ / · (+resilience) |
| ADP1 | Adaptation Infrastructure | 90 | 0 | +15 adaptation points | All event damage reduced via R multiplier | − / · / + (protective) |
| SOC1 | Independent Media Fund | 50 | 0 | Media active for rest of run | Sufficiency penalties waived; +1 Influence/yr; social crisis probability halved | − / · / ++ |
| SOC2 | Global Wellbeing Fund | 100 | 0 | +3 happiness | Late-game money sink; death-spiral exit | − / · / ++ |

## Diplomacy Cards

| ID | Card | Cost M | Cost I | Requires | Effect | Ally interaction |
|---|---|---|---|---|---|---|
| DIP1 | Form Alliance | 50 | **25** | < 6 allies | +1 ally | Each ally: +20 Money/yr and +1 Influence/yr, permanently |
| DIP2 | Joint Transition Project | 120 | **15** | ≥ 2 allies | +6% progress to **all three sectors** (caps respected) | The only card touching every sector; the scale payoff of diplomacy |

Losing an ally (social crisis) removes the yearly income and influence but not past
progress. Influence income: `2 + 1×allies (+1 with media)` — diplomacy compounds.

## Knowledge Tree Interactions (meta modifiers)

First-pass nodes, priced in Knowledge Points (KP, ~9–16 earned per run):

| Node | Cost | Effect on the matrix | Encoded insight |
|---|---|---|---|
| **Affordable EVs** | 6 | TRA2 cost 140 → 84 | "We know how to make electric cars people can buy" |
| **Healthy Sobriety** | 8 | AGR1/TRA3 happiness −3 → **+2** | "Bikes and plant-rich food are good for climate *and* health" |
| **Informed Public** | 8 | Every run starts with SOC1 active (free) | "People who understand accept — even demand — sufficiency" |
| **Restoration Playbook** | 5 | SNK1/SNK2 mature in 3 years instead of 5 | "We have learned to regrow ecosystems fast" |
| **Coalition Diplomacy** | 10 | DIP1 influence cost 25 → 15 | "Trust, once earned, is easier the next time" |
| **Crisis-Ready Design** | 12 | Start each run with +10 adaptation | "We build for the disasters we know are coming" |

The three sample runs assume **zero nodes** (true first run). Expected effect of a
maturing meta: Run B's archetype becomes winnable ~3–4 runs in *if* the player also
learns to lift the caps — the meta teaches the same lesson the loss did.

## Balance Watch List

- **DIP2 efficiency:** 18 progress-points for 120 M + 15 I vs ~15 for 140–150 M on single
  cards — intentionally strong (diplomacy is the scale engine) but the top dominant-strategy
  candidate (Risk #3). Levers: influence cost, per-decade limit, diminishing joint progress.
- **AGR1 at 60 M** is the cheapest progress/cost card once penalties are waived — watch pick rate.
- **SOC2** must never be strictly better than transition cards early; +3 H for 100 M is
  deliberately inefficient before the late game.
