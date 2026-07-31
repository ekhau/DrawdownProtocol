# The Drawdown Protocol

A Godot 4 prototype for a 2D isometric rogue-lite climate strategy and diplomacy simulation.

## Game Concept

### Elevator Pitch

You lead one city-state with an outsized ambition: make the **whole world** carbon-neutral before the climate crosses its tipping point. A run is a race of **15 turns — five years each, 2030 to 2100 —** against the **Climate Clock**, a single gauge that climbs on its own every turn because the rest of the world keeps emitting without you. Each turn the world deals **three events** — droughts, floods, political crises, the occasional opportunity — and a **market of project cards** to fund with Money, Influence, or even Happiness. Answer the crises, bend the great powers' emission curves with treaties and funded transitions, chain **combos** into a compounding engine, hold your promises through **five-yearly summits** — and if the world's ledger reaches net zero before the clock strikes 100%, the run is won on the spot. Cross +2.0 °C, or let Happiness hit zero and the city revolt, and the run is lost — yet every ending, victory or defeat, pays Knowledge that makes the next timeline start smarter.

### The Adversary: the Climate Clock

The antagonist of every run is not a monster — it is a curve. The **Climate Clock** shows warming as a percentage of the run's race track: **0% at +1.0 °C, 100% at +2.0 °C — the tipping point and instant defeat** [6][7]. A run starts at 30% (+1.30 °C, roughly where the 2030s begin).

The clock escalates automatically, like the cold in Frostpunk or scaling elites in Slay the Spire: four **world blocs** emit on their own rising curves, sinks strain as warming passes +1.5 °C, and unanswered heat waves bake extra emissions permanently into the atmosphere. Do nothing and the run dies around turn 7–9. The HUD makes the race legible at all times: the clock's current percentage, a projection of next turn's rise if you do nothing, and the sparkline of the curve you are trying to bend.

- **+1.5 °C (50%) — Overshoot:** crises intensify, sinks strain, wellbeing erodes.
- **+1.75 °C (75%) — Overshoot II:** the pressure escalates sharply.
- **+2.0 °C (100%) — Defeat:** the limit for a safe human world is breached.

**Victory is carbon neutrality, whenever it comes.** The moment the world absorbs more than it emits — your city's emissions plus the world's blocs, minus all sinks — the curve bends and the run is won, whether that is 2080 or 2100 [2][5]. Reaching 2100 still net-positive is the third defeat: survival is not the goal, drawdown is.

### One City in a Warming World

The player governs one concrete city-state — but the 2 °C threshold is global. Four named **world blocs** (an industrial league, a wealthy union, a trade compact, the industrializing frontier states) emit the majority of the world's carbon on simple, visible curves that climb every turn. This creates the run's central dilemma:

- **Fix things at home** — transform your own industry, transport, and agro-economy. Safe, visible, and yours to control — but your sphere is only part of the ledger.
- **Convert the world** — spend Influence and Money on **Emissions Treaties** (bend a bloc's growth curve) and **Funded Transitions** (retire a big polluter's capacity outright: the cheapest tons on Earth are bought abroad). Costly, and it feels like paying for someone else's problem — but no run has ever been won without it.

Every ally won on the diplomatic map also damps the world's emission drift: a coalition is not flavor, it is drag on the adversary's curve.

### Player Role and Fantasy

The player is a small, credible actor on the world stage — a pioneering city-state with limited money but potentially enormous influence. The fantasy is "we are the ones who showed the world it was possible": convince and cooperate rather than command, spend a limited budget where it moves the global needle most, and turn every disaster into a redesign opportunity.

### The Three Pillars

1. **Money** — funds every market card and project. Income arrives each turn and grows with allies.
2. **Carbon balance** — the global ledger: city emissions + world blocs vs absorption (forests, soils, oceans, engineered sinks). Neutrality means emissions ≤ absorption, not zero emissions.
3. **Happiness** — wellbeing and social acceptance. Policies that ignore it trigger resistance and social crises; policies that support it make sufficiency desirable. **At zero Happiness the city revolts and the run is lost** — the transition can only go as fast as the people carry it.

Influence is the connective currency: earned by competent crisis response and alliances, spent on treaties, coalitions, and the world's curves.

### Core Loop (One Turn = Five Years)

1. **The turn opens under pressure.** Income arrives, running projects charge their upkeep, and **three random events land**: crises (drought, record heat wave, mega fire, flood, crop failure, energy crunch, social crisis) and sometimes opportunities. Each shows what it costs if ignored and which card tags answer it. Some events strike immediately — a record heat wave bakes **+1 Gt/yr into the atmosphere the moment it lands**, and only answering it that turn dissipates the spike. Some open doors: crises can **inject bonus cards into the market**, gated by your resources (the heat wave offers a Heatwave Response Plan — but only while Happiness ≥ 40 keeps the city organized enough to run one).
2. **The project market is dealt.** Four offers drawn from your growing pool — transitions, sinks, diplomacy, response programs, research moonshots. **Funding an offer consumes it; what you skip is gone with the turn.** Cards cost Money, Influence, or **Happiness** — the Industrial Carbon Levy costs nothing but public patience: a deep emissions cut and revenue, paid in −6 Happiness. Research bets print their odds on the card: the Fusion Moonshot succeeds 35% of the time and transforms everything; Direct Air Capture is a coin flip. Push your luck or buy certainty.
3. **Answer, chain, commit.** A funded card whose tag matches an open crisis contains it on the spot — no damage, plus a response reward. Tags funded together fire **combos** whose chain multiplies future payouts; a practiced engine turn cascades two or three combos at once and visibly bends the curve. Long-term **projects** (three turns, fifteen years) charge upkeep every turn and grant permanent powers when held to completion.
4. **Resolve and adapt.** The ledger closes: sinks mature and strain, warming ticks the clock, wellbeing drifts, every unanswered crisis strikes — and then the world's blocs advance their curves. On summit turns, the world judges you (below). Read the log, rebalance the pillars, repeat — until the curve bends, or the clock strikes.

### Summits: the Mid-Run Judgments

Every four turns or so a **climate summit (COP)** convenes with a target announced from the very start of the run: *net emissions below 45 by the 2045 Stocktake; below 25 by the Accord of 2065; below 8 by Last Horizon 2085.* Meet the target that turn and the world pays you back in money, influence, and hope. Miss it and the world loses faith — influence and happiness bleed. Summits give the long race its intermediate finish lines: a run is never only "win by 2100", it is always "survive the next audit".

### Starting Cities: Three Roads into the Same Storm

Runs begin by choosing a city archetype — a different strategic identity, not a stat reskin:

- **Port City** — *"Trade routes are treaty routes."* Starts allied and influence-rich; its market leans toward treaties and coastal works. The diplomatic road.
- **Industrial City** — *"The furnace that must reinvent itself."* Half again the industrial emissions and the wealth that comes with them. Spend the surplus fast or the clock buries you; its market leans energy and sufficiency.
- **Political Capital** — *"Poor in funds, rich in leverage."* Income runs a quarter short but influence flows; civic and treaty cards abound. **Locked** until the Capital Charter is bought in the Knowledge tree — a meta-progression goal in itself.

### Crises: Cards Are the Answer

The three-a-turn event draw is the tactical pressure of every turn, escalating with the warming band: droughts and crop failures bleed money and sinks, record heat waves strain health and spike emissions, floods devastate coasts, mega fires flip forests from sink to source, social crises cost allies and legitimacy — and opportunities (treaty conferences, investment waves, youth movements) are pure upside for whoever shows up with the right card. What you cannot answer still teaches: unanswered disasters open rebuild-better windows, because reconstruction is often the cheapest transformation.

### Combos and the Run That Explodes

Cards carry tags — water, food, energy, mobility, forest, coast, health, civic, treaty, relief — and named combos fire the instant a turn's funded tags complete their set: **Green Corridor** (mobility + energy), **Water Cycle** (water + forest), **Grand Bargain** (treaty + energy + civic), **Drawdown Surge** (forest + water + food + energy). Every combo grows a **chain** that multiplies future combo rewards up to double; a comboless turn lets it slip. A well-built engine turn late in the run — cascade banners, the clock gauge flashing green, the curve visibly plunging — is the game's Balatro moment, and it is usually the turn the run is won.

### Defeat Teaches: the Post-Mortem

Every run ends with a **post-mortem** that names the pivotal turn: *"Turn 4 (2045): the Stocktake target slipped away — the world stopped believing there."* *"Happiness collapsed hardest on turn 6: the carbon levy landed during a heat wave."* Overheats point at the worst unanswered turn, revolts at the collapse that started them, timeouts at the ledger block left standing (usually the world's blocs, untouched by diplomacy). The mistake is named so the next attempt can answer it — and some defeats pay forward directly: losing a run to the revolt permanently unlocks the **Public Support Fund**, the card that softens exactly that trap.

### Rogue-lite Meta-Progression: Knowledge and the Codex

Losing a run is not starting over. Every ending — win or loss — pays **Knowledge Points**, spent in a persistent tree of insights: Affordable EVs, Healthy Sobriety, an Informed Public, the Restoration Playbook, Coalition Diplomacy, Crisis-Ready Design, the Capital Charter. Nodes cheapen cards, change how populations react, or unlock the third city — they encode understanding, not raw power.

Alongside it grows the **Codex of real solutions**: funding any card for the first time — in any run — permanently unlocks a short entry on the real-world solution it represents, from Kalundborg's industrial symbiosis to Ahmedabad's heat action plan, from Project Drawdown's food-waste ranking to the Montreal Protocol. The collection is the game quietly teaching what the cards stand for.

### Replayability

- **Procedurally generated world map** — regions, vulnerabilities, and starting conditions differ every run.
- **The market and the draw** — each turn's dealt offers and events reshuffle every timeline's pressure points; sometimes the shop does not save you, and the next run's plan changes because of it.
- **Three archetypes, multiple victory paths** — green-engine, sober-world, and grand-alliance strategies all reach neutrality by different ledgers.

### Visuals and Aesthetics: The Beautiful Optimization

- **Early run / high-emission world:** harsh visuals — grey concrete, gridlocked highways, industrial sprawl, muted smoggy tones.
- **Transformed world:** green tram lines, bike paths, rooftop gardens, dense forests, brighter natural light.
- The target look is not "primitive"; it is advanced, lush, and harmonious (solarpunk direction). The world's visual arc *is* the score screen — and the Climate Clock plunging into green is its climax.

### Scientific Foundation

| In-Game Mechanic | Real-World Concept | Scientific Source |
|---|---|---|
| The Climate Clock: +1.5 °C warning / +2.0 °C defeat | Paris Agreement temperature goal; 1.5 °C vs 2 °C impacts | UNFCCC Paris Agreement [6]; IPCC SR1.5 [7] |
| Victory = neutrality as emissions/absorption balance, any year | Net zero and carbon sinks | Project Drawdown [2]; IEA net-zero pathways [5] |
| World blocs bent by treaties and funded transitions | International climate finance (JETPs), climate clubs, sectoral treaties | IEA [5]; Montreal Protocol precedent |
| Sufficiency raising happiness; revolt at zero | Sufficiency and demand-side mitigation; just-transition backlash | IPCC AR6 WGIII, Chapter 5 [1] |
| Agro-economy diet shift | Plant-rich diets within planetary boundaries | EAT-Lancet Commission [3] |
| Event escalation past +1.5 °C; on-draw emission spikes | Tipping points and compound extremes | Stockholm Resilience Centre (Rockström et al.) [4] |
| Codex entries on every card | Ranked, real mitigation solutions | Project Drawdown [2] and per-card sources |

## Sources

[1] IPCC AR6 WGIII, Chapter 5: demand-side mitigation and sufficiency (avoid-shift-improve).  
[2] Project Drawdown: ranked climate solutions and sequestration impact.  
[3] EAT-Lancet Commission: Food, Planet, Health and plant-rich dietary transition.  
[4] Stockholm Resilience Centre / Rockström et al.: planetary boundaries framework.  
[5] International Energy Agency (IEA): net-zero emissions by 2050 roadmaps.  
[6] UNFCCC Paris Agreement (2015), Article 2: hold warming "well below 2 °C above pre-industrial levels" and pursue efforts to limit it to 1.5 °C.  
[7] IPCC Special Report on Global Warming of 1.5 °C (2018): impacts escalate strongly between 1.5 °C and 2 °C of warming.

## Current Prototype Status

The playable prototype in `../src/` implements this vision end-to-end: the 15-turn race 2030–2100 with the Climate Clock gauge, the 3-event draw with on-draw spikes and bonus-card injections, the per-turn project market with happiness-cost and push-your-luck cards, four world blocs bent by treaties/funded transitions/allies, three selectable city archetypes (one meta-locked), summits on turns 4/8/12, the combo chain with cascade feedback, three-turn projects, deck growth, the revolt and tipping-point defeats with early neutrality victory, the run-end post-mortem, and the Codex + Knowledge tree meta. See `../src/README.md` for controls, architecture, verification, and deliberate deviations.
