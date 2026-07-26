# Policy Effect Matrix — The Drawdown Protocol (Phase 1)

The card catalog: 26 cards (20 starting + 6 unlockable) across the three sectors, sinks,
society, diplomacy, and the response family — plus the combo and project catalogs that
sit on top of them. Up to five cards are played per year, bound by resources. Costs are
paid in Money (M), Influence (I), and occasionally Happiness (H); many cards also pay
**rewards** back. Card **tags** answer crises (`03_Event_Probability_Table.md`) and build
combos. The catalog is data (JSON files), never code (golden rule 9).

**Sufficiency rule:** each sector's transition is capped at **70%** until at least one
card tagged *sufficiency* is played in that sector (cap rises to 100%). This encodes the
IPCC demand-side finding — technology alone cannot finish the job.

**Happiness penalty rule:** negative happiness costs on sufficiency cards are waived while
the Independent Media Fund is active or during a social-crisis policy window.

## Sector Cards

| ID | Card | Sector | Cost M | Tags | Effect | Rewards | Sufficiency |
|---|---|---|---|---|---|---|---|
| IND1 | Industrial Efficiency | Industry | 80 | energy | +6% industry | — | — |
| IND2 | Clean Energy Grid | Industry | 150 | energy | +10% industry | — | — |
| IND3 | Circular Economy | Industry | 120 | sufficiency | +8% industry, +1 happiness; lifts cap | — | **Yes** |
| IND4 † | Industrial Symbiosis | Industry | 90 | energy | +8% industry | +20 M | — |
| TRA1 | Rail & Bike Networks | Transport | 80 | sufficiency, mobility, health | +8% transport, +2 happiness; lifts cap | — | **Yes** |
| TRA2 | Affordable EVs | Transport | 140 | mobility | +10% transport | — | — |
| TRA3 | Walkable Cities | Transport | 60 | sufficiency, mobility | +6% transport, −3 happiness (waivable); lifts cap | — | **Yes** |
| AGR1 | Plant-Rich Diet Campaign | Agro-economy | 60 | sufficiency, food, health | +8% agro, −3 happiness (waivable); lifts cap | — | **Yes** |
| AGR2 | Agroecology Transition | Agro-economy | 100 | food, water | +8% agro, +0.2 absorption | — | — |
| AGR3 † | Food Commons | Agro-economy | 70 | food, civic | +6% agro, +1 happiness | — | — |

† unlockable — see Deck Growth below.

## Sink, Adaptation, Society, and Response Cards

| ID | Card | Cost M | Tags | Effect | Rewards |
|---|---|---|---|---|---|
| SNK1 | Reforestation Program | 70 | restoration, forest | +0.3 absorption/yr for 5 years | — |
| SNK2 | Peatland & Ocean Repair | 90 | restoration, water | +0.2 absorption/yr for 5 years; +5 adaptation | — |
| SNK3 † | Blue Carbon Program | 60 | restoration, coast | +0.25 absorption/yr for 4 years | — |
| ADP1 | Adaptive Infrastructure | 90 | coast, relief | +15 adaptation | — |
| SOC1 | Independent Media Fund | 50 | civic | Media active for rest of run | — |
| SOC2 | Global Wellbeing Fund | 100 | health | +3 happiness | — |
| SOC3 † | Transition Festivals | 40 | civic | +2 happiness | +3 I |
| RSP1 | Emergency Relief Corps | 30 | relief, health | +2 adaptation | +3 I |
| RSP2 | Water Stewardship | 35 | water | +0.1 absorption | +10 M |
| RSP3 | Coastal Defense Works | 40 | coast | +4 adaptation | — |
| RSP4 | Community Kitchens | 25 | food, civic | +1 happiness | +2 I |
| RSP5 | Grid Repair Crews | 35 | energy, relief | +2 adaptation | +15 M |
| RSP6 † | Mutual Aid Network | 30 | relief, civic | +2 happiness | +4 I |

The **response family** is the crisis toolkit: cheap, broadly tagged, modest effects,
real rewards — playing one is nearly free once its answer reward lands, but it spends
the year's tempo.

## Diplomacy Cards

| ID | Card | Cost M | Cost I | Requires | Tags | Effect | Rewards |
|---|---|---|---|---|---|---|---|
| DIP1 | Form Alliance | 50 | **25** | < 6 allies | treaty | +1 ally (+20 M/yr, +1 I/yr) | — |
| DIP2 | Joint Transition Project | 120 | **15** | ≥ 2 allies | treaty | +5% to all three sectors (caps respected) | — |
| DIP3 † | Climate Club | 80 | **10** | ≥ 3 allies | treaty | +4% to all three sectors | +25 M |

Losing an ally (unanswered social crisis) removes the yearly income and influence but not
past progress. Influence income: `2 + 1×allies (+1 with media)` — diplomacy compounds.

## Combo Catalog (`data/combos.json`)

A combo fires the instant the year's played tags cover its set; once per combo per year;
rewards are multiplied by the chain (`1 + 0.1 × min(chain, 10)`); knowledge rewards pay
on the combo's first fire of the run only.

| Combo | Tags required | Base rewards | Effects |
|---|---|---|---|
| Green Corridor | mobility + energy | +25 M | — |
| Water Cycle | water + forest | +3 I | +0.15 absorption |
| Land & Table | food + forest | +15 M, +1 H | — |
| Streets Alive | mobility + civic | +2 H, +2 I | — |
| Public Trust | civic + health | +5 I | — |
| Blue Shield | coast + water | +10 M | +3 adaptation |
| Grand Bargain | treaty + energy + civic | +40 M, +8 I, +1 K | — |
| Drawdown Surge | forest + water + food + energy | +25 M, +1 K | +0.3 absorption |

Authoring rule (validator CB5): no single card may carry a combo's full tag set — a
combo is by definition a multi-card play.

## Project Catalog (`data/projects.json`)

Five-year commitments: upkeep charged at launch and at each year start; completion grants
instant effects plus a **permanent passive**; abandoning or failing to pay applies the
penalty and closes the project for the run. Max 2 active.

| Project | Upkeep /yr | Years | On completion | Permanent passive | Abandon/fail penalty |
|---|---|---|---|---|---|
| Global Sink Trust | 35 M | 5 | +1.0 absorption | +0.15 absorption/yr | −3 H, −8 I |
| Continental Rail Compact | 40 M + 2 I | 5 | +5% all sectors | +2 influence/yr | −4 H, −10 I |
| Universal Services | 45 M | 5 | +4 happiness | +0.5 happiness/yr | −6 H, −6 I |
| World Climate Accord | 30 M + 4 I | 5 | 2 allies join | +20 money/yr | −3 H, −12 I |

## Deck Growth (unlock conditions on † cards)

| Card | Unlock condition | The lesson it rewards |
|---|---|---|
| RSP6 Mutual Aid Network | 4 crises answered | Competent response builds civil society |
| IND4 Industrial Symbiosis | Industry ≥ 40% | Transformation compounds |
| AGR3 Food Commons | 4 combos fired | Synergy literacy |
| SOC3 Transition Festivals | 8 combos fired | A culture of success |
| DIP3 Climate Club | 3 allies | Coalitions open institutions |
| SNK3 Blue Carbon Program | 1 project completed | Kept promises unlock bigger ones |

## Knowledge Tree Interactions (meta modifiers)

First-pass nodes, priced in Knowledge Points (KP, ~4–18 earned per run):

| Node | Cost | Effect on the matrix | Encoded insight |
|---|---|---|---|
| **Affordable EVs** | 6 | TRA2 cost 140 → 84 | "We know how to make electric cars people can buy" |
| **Healthy Sobriety** | 8 | AGR1/TRA3 happiness −3 → **+2** | "Bikes and plant-rich food are good for climate *and* health" |
| **Informed Public** | 8 | Every run starts with SOC1 active (free) | "People who understand accept — even demand — sufficiency" |
| **Restoration Playbook** | 5 | SNK1/SNK2 mature in 3 years instead of 5 | "We have learned to regrow ecosystems fast" |
| **Coalition Diplomacy** | 10 | DIP1 influence cost 25 → 15 | "Trust, once earned, is easier the next time" |
| **Crisis-Ready Design** | 12 | Start each run with +10 adaptation | "We build for the disasters we know are coming" |

## Balance Watch List

- **Grand Bargain repetition** (Risk #12): treaty+energy+civic is repeatable every year
  once DIP2 is routine — +40 M ×chain is the strongest legal money engine. Levers: base
  reward, chain cap, or a per-run fire limit if analytics show it dominating.
- **Answer-everything slack** (Risk #13): autoplay Safe answers ~all 212 draws and still
  banks thousands late; if human play confirms it, raise crisis damages or response costs.
- **RSP5 Grid Repair Crews** nets −20 M before rewards and +12 M answering an energy
  crunch — the closest card to free; watch pick rate.
- **World Climate Accord** stacks with ally income (+20 M/yr passive + 2 allies ≈
  +60 M/yr swing) — intentionally the strongest project, gated by 4 I/yr upkeep.
- **SOC2** must never be strictly better than transition cards early; +3 H for 100 M is
  deliberately inefficient before the late game.
