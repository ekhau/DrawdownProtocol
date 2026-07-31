# Policy Effect Matrix — The Drawdown Protocol (Phase 1)

The card catalog: **33 cards** (schema v3) across the three sectors, sinks, society,
diplomacy, research, and the response family — plus the combo and project catalogs that
sit on top of them. Each turn the market deals **4 offers** from the available pool
(weighted by each card's `market_weight`, default 1.0, × the city archetype's tag lean);
up to five offers are funded per turn, bound by resources, and each funded offer is
consumed. Costs are paid in Money (M), Influence (I), and occasionally **Happiness (H)**;
many cards also pay **rewards** back. Card **tags** answer crises
(`03_Event_Probability_Table.md`) and build combos. Every card carries a **codex entry**
(title + real-world solution blurb, validator-enforced C14), unlocked permanently the
first time the card is played. The catalog is data (JSON files), never code (golden
rule 9).

**Sufficiency rule:** each sector's transition is capped at **70%** until at least one
card tagged *sufficiency* is played in that sector (cap rises to 100%). This encodes the
IPCC demand-side finding — technology alone cannot finish the job.

**Happiness penalty rule:** negative happiness costs on sufficiency cards are waived while
the Independent Media Fund is active or during a social-crisis policy window. The
Industrial Carbon Levy's happiness cost is a **price, not a penalty** — never waived.

## Sector Cards

| ID | Card | Sector | Cost | Tags | Effect | Rewards | Sufficiency |
|---|---|---|---|---|---|---|---|
| IND1 | Industrial Efficiency | Industry | 90 M | energy | +12% industry | — | — |
| IND2 | Clean Energy Grid | Industry | 150 M | energy | +16% industry | — | — |
| IND3 | Circular Economy | Industry | 120 M | sufficiency | +13% industry, +1 happiness; lifts cap | — | **Yes** |
| IND4 † | Industrial Symbiosis | Industry | 95 M | energy | +13% industry | +25 M | — |
| IND5 | Industrial Carbon Levy | Industry | 0 M + **6 H** | energy | +14% industry | +35 M | — |
| TRA1 | Rail & Bike Networks | Transport | 80 M | sufficiency, mobility, health | +13% transport, +2 happiness; lifts cap | — | **Yes** |
| TRA2 | Affordable EVs | Transport | 140 M | mobility | +16% transport | — | — |
| TRA3 | Walkable Cities | Transport | 60 M | sufficiency, mobility | +10% transport, −3 happiness (waivable); lifts cap | — | **Yes** |
| AGR1 | Plant-Rich Diet Campaign | Agro-economy | 60 M | sufficiency, food, health | +13% agro, −3 happiness (waivable); lifts cap | — | **Yes** |
| AGR2 | Agroecology Transition | Agro-economy | 100 M | food, water | +13% agro, +0.2 absorption | — | — |
| AGR3 † | Food Commons | Agro-economy | 75 M | food, civic | +10% agro, +1 happiness | — | — |

† unlockable — see Deck Growth below.

**IND5 is the resource-vs-resource dilemma card** (the first shipped happiness-cost
card): free money and solid progress, paid directly in public patience. It is how a rich,
unhappy run digs itself deeper — and how a stable one self-finances.

## Sink, Adaptation, Society, and Response Cards

| ID | Card | Cost M | Tags | Effect | Rewards |
|---|---|---|---|---|---|
| SNK1 | Reforestation Program | 70 | restoration, forest | +1.0 absorption/turn for 3 turns | — |
| SNK2 | Peatland & Ocean Repair | 90 | restoration, water | +0.8 absorption/turn for 3 turns; +5 adaptation | — |
| SNK3 † | Blue Carbon Program | 60 | restoration, coast | +1.2 absorption/turn for 2 turns | — |
| ADP1 | Adaptive Infrastructure | 90 | coast, relief | +15 adaptation | — |
| SOC1 | Independent Media Fund | 50 | civic | Media active for rest of run | — |
| SOC2 | Global Wellbeing Fund | 100 | health | +4 happiness | — |
| SOC3 † | Transition Festivals | 40 | civic | +2 happiness | +3 I |
| SOC4 ‡ | Public Support Fund | 60 | civic | +6 happiness | — |
| RSP1 | Emergency Relief Corps | 30 | relief, health | +2 adaptation | +3 I |
| RSP2 | Water Stewardship | 35 | water | +0.1 absorption | +10 M |
| RSP3 | Coastal Defense Works | 40 | coast | +4 adaptation | — |
| RSP4 | Community Kitchens | 25 | food, civic | +1 happiness | +2 I |
| RSP5 | Grid Repair Crews | 35 | energy, relief | +2 adaptation | +15 M |
| RSP6 † | Mutual Aid Network | 30 | relief, civic | +2 happiness | +4 I |
| HWP1 ◊ | Heatwave Response Plan | 25 | health, relief | +6 adaptation, +2 happiness | +3 I |

‡ meta-unlock (defeat lesson) · ◊ bonus-only — see Deck Growth below.

The **response family** is the crisis toolkit: cheap, broadly tagged, modest effects,
real rewards — playing one is nearly free once its answer reward lands, but it spends
the turn's tempo and a market slot.

## Research Cards (push-your-luck; odds printed on the card)

| ID | Card | Cost M | Tags | Chance | On success | On failure |
|---|---|---|---|---|---|---|
| RND1 | Fusion Moonshot | 150 | energy | **35%** | +8% all three sectors, +60 M, +1 Knowledge | −4 happiness |
| RND2 | Direct Air Capture | 100 | energy | **50%** | +2.0 absorption immediately | nothing |

Rolled on the dedicated risk RNG stream at play time; the printed odds are the whole
contract (validator C13 restricts branch ops and requires chance strictly inside 0–1).
Honest bets, never silver bullets — the success cases accelerate a transition, they do
not replace one.

## Diplomacy Cards

| ID | Card | Cost M | Cost I | Requires | Tags | Effect | Rewards |
|---|---|---|---|---|---|---|---|
| DIP1 | Form Alliance | 50 | **25** | < 6 allies | treaty | +1 ally (+40 M/turn, +2 I/turn, world drift −0.2/turn) | — |
| DIP2 | Joint Transition Project | 120 | **15** | ≥ 2 allies | treaty | +8% to all three sectors (caps respected) | — |
| DIP3 † | Climate Club | 80 | **10** | ≥ 3 allies | treaty | +7% to all three sectors | +25 M |
| DIP4 | Fund a Transition | 120 | **8** | — | treaty | **−6 Gt** off the biggest world emitter above its floor; its trend −0.3 | — |
| DIP5 | Emissions Treaty | 30 | **20** | — | treaty | Trend **−0.8** on the steepest world curve | — |

DIP4 and DIP5 are the levers on the world's actors (`01_Balance_Model.md`) and carry
raised market weights (**3.0 / 2.6**) so the global game stays reachable in every deal.
Losing an ally (unanswered social crisis) removes the income, influence and drift
damping but not past progress. Influence income: `6 + 2×allies (+2 with media)` —
diplomacy compounds.

## Combo Catalog (`data/combos.json`)

A combo fires the instant the turn's played tags cover its set; once per combo per turn;
rewards are multiplied by the chain (`1 + 0.1 × min(chain, 10)`); knowledge rewards pay
on the combo's first fire of the run only. Two or more combos in one turn trigger the
CASCADE feedback in the UI.

| Combo | Tags required | Base rewards | Effects |
|---|---|---|---|
| Green Corridor | mobility + energy | +40 M | — |
| Water Cycle | water + forest | +5 I | +0.3 absorption |
| Land & Table | food + forest | +25 M, +2 H | — |
| Streets Alive | mobility + civic | +3 H, +3 I | — |
| Public Trust | civic + health | +8 I | — |
| Blue Shield | coast + water | +20 M | +4 adaptation |
| Grand Bargain | treaty + energy + civic | +60 M, +10 I, +1 K | — |
| Drawdown Surge | forest + water + food + energy | +40 M, +1 K | +0.5 absorption |

Base rewards are ~60% above the old yearly model — a combo must justify spending two of
the turn's five plays on it. Authoring rule (validator CB5): no single card may carry a
combo's full tag set — a combo is by definition a multi-card play.

## Project Catalog (`data/projects.json`)

Three-turn (15-year) commitments: upkeep charged at launch and at each turn start;
completion grants instant effects plus a **permanent passive**; abandoning or failing to
pay applies the penalty and closes the project for the run. Max 2 active. (Validator PR1:
project length 2–6 turns.)

| Project | Upkeep /turn | Turns | On completion | Permanent passive | Abandon/fail penalty |
|---|---|---|---|---|---|
| Global Sink Trust | 90 M | 3 | +2.0 absorption | +0.8 absorption/turn | −6 H, −10 I |
| Continental Rail Compact | 100 M + 4 I | 3 | +8% all sectors | +4 influence/turn | −8 H, −12 I |
| Universal Services | 110 M | 3 | +8 happiness | +1.5 happiness/turn | −10 H, −8 I |
| World Climate Accord | 80 M + 8 I | 3 | 2 allies join | +50 money/turn | −6 H, −15 I |

## Deck Growth

**Run unlocks** († cards, condition-based, reset each run):

| Card | Unlock condition | The lesson it rewards |
|---|---|---|
| RSP6 Mutual Aid Network | 4 crises answered | Competent response builds civil society |
| IND4 Industrial Symbiosis | Industry ≥ 40% | Transformation compounds |
| AGR3 Food Commons | 4 combos fired | Synergy literacy |
| SOC3 Transition Festivals | 8 combos fired | A culture of success |
| DIP3 Climate Club | 3 allies | Coalitions open institutions |
| SNK3 Blue Carbon Program | 1 project completed | Kept promises unlock bigger ones |

**Meta unlock** (‡, permanent, validator C15): **SOC4 Public Support Fund** is earned
forever by losing a run to the revolt (`LOSS_REVOLT`) — the defeat *is* the lesson.

**Bonus-only** (◊, validator C16): **HWP1 Heatwave Response Plan** exists only when a
Record Heat Wave injects it into the market (requires H ≥ 40 at draw time) — the
design-doc reference example of an event-gifted card.

## Knowledge Tree Interactions (meta modifiers)

Seven nodes, priced in Knowledge Points (KP, floor 1 per run, ~3–12 earned):

| Node | Cost | Effect on the matrix | Encoded insight |
|---|---|---|---|
| **Affordable EVs** | 6 | TRA2 cost 140 → 84 | "We know how to make electric cars people can buy" |
| **Healthy Sobriety** | 8 | AGR1/TRA3 happiness −3 → **+2** | "Bikes and plant-rich food are good for climate *and* health" |
| **Informed Public** | 8 | Every run starts with SOC1 active (free) | "People who understand accept — even demand — sufficiency" |
| **Restoration Playbook** | 5 | SNK1/SNK2 mature in 2 turns instead of 3 | "We have learned to regrow ecosystems fast" |
| **Coalition Diplomacy** | 10 | DIP1 influence cost 25 → 15 | "Trust, once earned, is easier the next time" |
| **Crisis-Ready Design** | 12 | Start each run with +10 adaptation | "We build for the disasters we know are coming" |
| **Capital Charter** | 6 | Unlocks the **Political Capital** city archetype | "Leverage can substitute for wealth" |

## City Archetypes (`data/city_archetypes.json`)

Chosen at first boot, changeable at run end, persisted in Meta; multipliers and market
leans only, never new mechanics (validator Y1–Y3: at least 3 archetypes, valid
multipliers, at least one locked). Headless/test default is baseline (no archetype).

| Archetype | Start tilt | Income tilt | Sector tilt | Market leans | Note |
|---|---|---|---|---|---|
| **Port City** | money ×0.9, influence +8, **starts with 1 ally** | +2 influence/turn | transport ×1.3 | treaty, coast, water | The diplomat's opening |
| **Industrial City** | money ×1.4, influence −5, happiness −5 | income ×1.2 | industry ×1.5 | energy, sufficiency, health | Rich but filthy — must reinvent |
| **Political Capital** (locked: Capital Charter) | money ×0.7, influence +15 | income ×0.75, +3 influence/turn | industry ×0.9 | civic, treaty, health | Leverage over wealth |

## Balance Watch List

- **Grand Bargain repetition** (Risk #12): treaty+energy+civic is repeatable once
  diplomacy is routine — +60 M ×chain is the strongest legal money engine, now also
  gated by the market dealing the pieces. Levers: base reward, chain cap, market weight.
- **DIP4 efficiency** (Risk #3/#17): −6 Gt for 120 M + 8 I is deliberately the biggest
  one-card ledger swing in the game; the floors and the ×3.0 market weight are the
  governors. Watch pick-rate and whether home transition ever becomes irrelevant.
- **IND5 Industrial Carbon Levy**: 0 M cost with +35 M reward is money-printing priced
  in happiness; below ~40 H it is a trap by design. Watch for degenerate levy-spam in
  high-happiness runs.
- **RSP5 Grid Repair Crews** nets −20 M before rewards and +20 M answering an energy
  crunch — the closest card to free; watch pick rate.
- **World Climate Accord** stacks with ally income (+50 M/turn passive + 2 allies ≈
  +130 M/turn swing) — intentionally the strongest project, gated by 8 I/turn upkeep.
- **SOC2** must never be strictly better than transition cards early; +4 H for 100 M is
  deliberately inefficient before the late game — SOC4 (revolt lesson) is the stronger
  rescue and must stay defeat-gated.
