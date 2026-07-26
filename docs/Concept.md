# The Drawdown Protocol

A Godot 4 prototype for a 2D isometric rogue-lite climate strategy and diplomacy simulation.

## Game Concept

### Elevator Pitch

You lead a group of people — a climate NGO, an association, or a small pioneering country — determined to steer the world to carbon neutrality between 2030 and 2100. Every year the world deals you **three crises** — droughts, floods, fires, political turmoil, and sometimes a rare opportunity — and your policy cards are how you answer them. Cards cost money, influence, or happiness and pay resources back; played together they trigger **combos** whose chains grow across the run; **five-year projects** grant permanent powers if you sustain them. Answering crises well makes your deck grow. If the world crosses the global warming limit, the run is lost — yet the knowledge you gained persists, making every new attempt start smarter.

### Player Role and Fantasy

The player is not an abstract force. They are a **group of people**: a small, credible actor on the world stage (NGO or small country) with limited money but potentially enormous influence. The fantasy is "we are the ones who showed the world it was possible":

- Convince and cooperate with other countries rather than command them.
- Spend a limited budget wisely where it moves the needle most.
- Turn each disaster into a redesign opportunity instead of merely surviving it.

### The Three Pillars

The whole game is a balancing act between three pillars, always visible on screen:

1. **Money** — the budget that funds every transformation and joint project.
2. **Carbon balance** — global emissions versus global absorption (forests, soils, oceans, engineered sinks). Neutrality means emissions ≤ absorption, not zero emissions.
3. **Happiness** — people's wellbeing and social acceptance. Policies that ignore it trigger resistance and social crises; policies that support it (active mobility, healthy food, honest media) make sufficiency acceptable and even desirable.

Pushing hard on one pillar strains the others; every meaningful decision trades between them.

### Core Loop (One Run = 2030–2100)

1. **The year opens under pressure.** Income arrives, running projects charge their upkeep, and **three random events land**: crises (drought, heat wave, mega fire, flood, crop failure, energy crunch, social crisis) and, sometimes, opportunities (a climate summit, an investment wave, a youth movement). Each shows what it will cost if ignored — and which card tags answer it.
2. **Answer with cards.** Play as many policy cards as your resources allow (up to five a year). Each card has a cost in Money / Influence / Happiness and gives back rewards in Money / Influence / Happiness / Knowledge. A card whose tag matches an open crisis **contains it on the spot** — no damage, plus a response reward. Cards are simultaneously your crisis toolkit and your transition engine: the same year's plays transform sectors, restore sinks, and win allies.
3. **Chain combos.** Cards played together synergize: complete a combo's tag set (bikes + clean grids, forests + water, diplomats + engineers + citizens) and it fires instantly with bonus resources. Every combo grows a **chain** that multiplies future combo rewards — the engine that lets a practiced coalition outrun the harder crises of the late century.
4. **Commit to projects.** Launch long-term projects that charge resources every year for five years; seeing one through grants a permanent power — passive income, growing sinks, lasting wellbeing, or new allies. Walking away, or failing to pay, burns trust.
5. **Resolve and adapt.** The simulation advances: emissions, absorption, temperature, happiness. Every crisis you left unanswered strikes — and even then opens a window to rebuild better. Read the outcome, rebalance the three pillars, repeat until 2100 — or until the world overheats.

### The Three Key Sectors

Every country's emissions come from three transformable sectors. Transformation costs money; the right sequencing is the strategic heart of a run.

| Sector | High-carbon start | Transition levers |
|---|---|---|
| **Industry** | Fossil-powered factories, linear production | Clean energy, efficiency, circular economy; residual emissions offset by sinks |
| **Transport** | Car-centric cities, fossil freight | Electric vehicles made efficient and affordable, rail, bikes and walkable cities |
| **Agro-economy** | Emission-heavy livestock, degraded land | Plant-rich diets, agroecology, rewilding freed land into carbon-absorbing forests |

### Diplomacy: The Influence Resource

**Influence** is the second currency, earned through successful projects, exemplary transitions, aid during disasters, and media presence. It is spent to:

- **Form alliances** with other countries.
- **Launch joint projects** too big for any single actor (continental rail networks, shared clean-energy grids, cross-border reforestation).
- **Unlock funding**: each ally contributes money to the shared energy transition, easing the Money pillar.

A run with few allies is a poor, slow transition; a run with many is a rich, fast one. Diplomacy is not a side system — it is the main engine of scale.

### Defeat: The Global Warming Limit

A run is lost when **global warming reaches +2.0 °C above pre-industrial levels** — the ceiling the Paris Agreement commits the world to stay "well below" while pursuing 1.5 °C [6]. Crossing **+1.5 °C** does not end the run but triggers the **Overshoot** state: extreme events become stronger and more frequent, reflecting the IPCC's finding that impacts escalate sharply between 1.5 °C and 2 °C of warming [7].

- **+1.5 °C — Warning threshold:** Overshoot begins; the pressure ramps up.
- **+2.0 °C — Defeat:** the limit for a safe human world is breached; the run ends.

### Victory: Neutrality as Balance, Many Paths

The goal is a **carbon-neutral world by 2100**. Neutrality is a balance, not a purity test: industry may still emit if enough forests and other sinks absorb the remainder. Because of this, several strategies can win, for example:

- **The Green Engine:** clean, efficient industry with residual emissions fully offset by massive reforestation and restored sinks.
- **The Sober World:** deep demand reduction — bikes, plant-rich food, sufficiency — where happiness comes from wellbeing rather than consumption, and emissions fall low enough that modest sinks suffice.
- **The Grand Alliance:** diplomacy-first; a web of allies pools money into joint mega-projects that transform all three sectors worldwide.

A winning end state must hold all three pillars: solvent finances, emissions ≤ absorption, and a population happy enough to sustain the model beyond 2100.

### Crises: Three a Year, and Cards Are the Answer

The crisis draw is the central pressure of every turn. Three events are drawn each year from a weighted deck:

- **Droughts and crop failures** — bleed money, strain food systems, weaken sinks.
- **Big heat waves** — strain health, happiness, and energy demand.
- **Tsunamis and floods** — devastate coastal infrastructure.
- **Mega fires** — destroy forests, flipping carbon sinks into carbon sources.
- **Energy crunches and social crises** — budgets bleed, allies waver, legitimacy erodes.
- **Opportunities** — summits, green investment waves, youth movements: pure upside for whoever shows up with the right card.

The deck escalates with warming: past +1.5 °C crises are drawn more often and opportunities less; social crises surge when happiness collapses and calm when independent media informs the public. Every crisis lists its **response tags** — play any card carrying one of them that year and the crisis is contained: no damage, and the world pays you back for competent leadership (money, influence, happiness, sometimes knowledge).

What you cannot answer still teaches. Unanswered events are deliberately **opportunities as much as threats**: a destroyed highway can be rebuilt as a rail line; a burned monoculture can regrow as resilient mixed forest; a social crisis can legitimize a fairer policy that was previously unacceptable. Rebuilding *better* after a disaster is often cheaper per ton of carbon than transforming intact infrastructure — the game rewards players who see openings in chaos.

### Combos: the Heart of the Fun

Cards are designed to be played in concert. Each carries tags — water, food, energy, mobility, forest, coast, health, civic, treaty, relief — and named combos fire the instant a year's plays complete their tag set:

- **Green Corridor** (mobility + energy): clean vehicles need clean grids.
- **Water Cycle** (water + forest): forests make rain; rain makes forests.
- **Grand Bargain** (treaty + energy + civic): diplomats, engineers and citizens at one table.
- **Drawdown Surge** (forest + water + food + energy): every system pulling carbon the same year.

A combo is loud and immediate: a banner, bonus resources, sometimes a direct effect on the world. Every combo fired raises the **combo chain**, and each chain step multiplies future combo rewards (up to double); a year without a combo lets the chain slip. Early combos are small change; a deep chain late in the run is how a practiced coalition funds answers to three simultaneous Overshoot-strength crises. Discovering a combo for the first time also yields Knowledge — insight, once learned, is permanent.

### Long-Term Projects: the Strategic Arc

Alongside the tactical scramble of the crisis year, the player can commit to **projects** — the Global Sink Trust, a Continental Rail Compact, Universal Services, a World Climate Accord. A project charges its upkeep every year for five years. Sustained to completion, it grants a **permanent power**: passive income, ever-growing absorption, lasting wellbeing, or new allies and deeper relations. Abandoning a project — or missing a payment because the crises drained you — cancels it and costs happiness and influence: the world remembers broken promises. Projects give a run its spine: the question is never only "how do I survive this year?" but "can I afford to keep my promises while surviving it?"

### A Deck That Grows With Your Deeds

The starting deck covers the basics; the rest of the catalog is earned in play. Answering crises unlocks mutual-aid networks; chaining combos unlocks food commons and transition festivals; winning allies unlocks the Climate Club; transforming industry unlocks industrial symbiosis; completing a project unlocks blue carbon restoration. New cards appear mid-run with fanfare — the deck's growth *is* the scoreboard of how well you have played, and it widens the answers available against the harder late-run crises.

### Rogue-lite Meta-Progression: Knowledge

Losing a run is not starting over. The group keeps its **Knowledge**: a persistent tree of tech-and-policy insights unlocked across runs, so every new timeline starts smarter. Examples of Knowledge nodes:

- **Affordable EVs:** how to make electric cars efficient and cheap enough for everyone — transport transitions cost less and go faster.
- **Healthy Sobriety:** bikes and vegetarian food are good both for the climate and for people's health — sufficiency policies now *raise* happiness instead of lowering it.
- **Informed Public:** funding independent media keeps people informed about global warming — populations accept sufficiency policies sooner and social crises are milder.

Knowledge nodes unlock new actions, cheapen existing ones, or change how populations react — they encode *understanding*, not raw power, so mastery in the meta mirrors real learning about the transition.

### Replayability

- **Procedurally generated initial world map:** the layout of countries, their starting sectors, wealth, and vulnerabilities differ every run — no fixed opening.
- **Random events:** the sequence and severity of disasters reshuffle each timeline's pressure points.
- **Multiple victory paths** interacting with both: the map and the events push each run toward a different winning strategy.

### Visuals and Aesthetics: The Beautiful Optimization

- **Early run / high-emission world:** harsh visuals — grey concrete, gridlocked highways, industrial sprawl, muted smoggy tones.
- **Transformed world:** green tram lines, bike paths, rooftop gardens, dense forests, brighter natural light.
- The target look is not "primitive"; it is advanced, lush, and harmonious (solarpunk direction). The world's visual arc *is* the score screen: players should see the transition happening tile by tile.

### Scientific Foundation

| In-Game Mechanic | Real-World Concept | Scientific Source |
|---|---|---|
| +1.5 °C warning / +2.0 °C defeat | Paris Agreement temperature goal; 1.5 °C vs 2 °C impacts | UNFCCC Paris Agreement [6]; IPCC SR1.5 [7] |
| Neutrality as emissions/absorption balance | Net zero and carbon sinks | Project Drawdown [2]; IEA net-zero pathways [5] |
| Sobriety raising happiness | Sufficiency and demand-side mitigation | IPCC AR6 WGIII, Chapter 5 [1] |
| Agro-economy diet shift | Plant-rich diets within planetary boundaries | EAT-Lancet Commission [3] |
| Event escalation past +1.5 °C | Tipping points and planetary boundaries | Stockholm Resilience Centre (Rockström et al.) [4] |

## Sources

[1] IPCC AR6 WGIII, Chapter 5: demand-side mitigation and sufficiency (avoid-shift-improve).  
[2] Project Drawdown: ranked climate solutions and sequestration impact.  
[3] EAT-Lancet Commission: Food, Planet, Health and plant-rich dietary transition.  
[4] Stockholm Resilience Centre / Rockström et al.: planetary boundaries framework.  
[5] International Energy Agency (IEA): net-zero emissions by 2050 roadmaps.  
[6] UNFCCC Paris Agreement (2015), Article 2: hold warming "well below 2 °C above pre-industrial levels" and pursue efforts to limit it to 1.5 °C.  
[7] IPCC Special Report on Global Warming of 1.5 °C (2018): impacts escalate strongly between 1.5 °C and 2 °C of warming.

## Current Prototype Status

The playable prototype in `../src/` implements this vision end-to-end: yearly turns 2030–2100 with the 3-crisis draw, multi-card play with costs and rewards, the combo chain, five-year projects, deck growth, the three-sector model with sufficiency caps, diplomacy as cards, the 12-region procgen world board, Overshoot bands and feedback loops, defeat at +2.0 °C, and Knowledge Points spent in the Knowledge tree. See `../src/README.md` for controls, architecture, verification, and deliberate deviations.
