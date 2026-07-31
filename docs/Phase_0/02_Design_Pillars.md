# Design Pillars — The Drawdown Protocol

Six pillars. Every feature in the MVP scope table maps to at least one of them
(see `03_MVP_Scope.md`, "Pillar" column). If a proposed feature maps to none, it is cut —
that is the Phase 0 done criterion, applied as a standing rule.

---

## 1. Readable Balance

The whole game is three dials — Money, Carbon balance, Happiness — plus **the climate
clock**: one gauge from +1.0 °C (0%) to +2.0 °C (100%), with a next-turn forecast and a
history sparkline. The player must always be able to answer "why did that number move?"

- **Include:** three-pillar HUD always visible; the clock gauge as the single adversary
  readout, forecasting its own next tick; card previews showing projected effect on each
  pillar before committing; a per-turn log line per change ("Overshoot stress: −2 happiness").
- **Include:** the +1.5 °C / +2.0 °C thresholds drawn directly on the clock; the next
  summit target always on screen.
- **Reject:** hidden modifiers, more than ~6 numbers on the default HUD, simultaneous
  resolution of many opaque systems, damage formulas the player can never reconstruct.

## 2. Every Crisis Is a Door

Three events land every turn — the central pressure alongside the clock — but each is
answerable with the right card, and each pays back competence. What goes unanswered still
carries an opportunity rider. Fear is real; despair is never the designed response.

- **Include:** visible response tags on every drawn crisis; containment plus a reward for
  answering; response cards that make aid a real strategy.
- **Include:** on-draw spikes that answering defuses — a Record Heat Wave bakes +1.0 Gt of
  extra emissions into the ledger the moment it lands, dissipated if answered that turn,
  permanent if ignored.
- **Include:** events that open cards — the heat wave injects the Heatwave Response Plan
  into the market (if the city is composed enough to organize one); post-fire "rebuild
  better" discount on restoration; post-flood free transport rebuild; a social crisis
  opening a one-time window for a sufficiency policy.
- **Include:** Overshoot escalation past +1.5 °C (heavier crisis draw weights) so pressure
  rises exactly when the science says it does; opportunity events that thin out as the
  world heats.
- **Reject:** pure-punishment events with no follow-up choice; permanent unavoidable
  death-spirals; doomer flavor text; events that undo an hour of play with one roll.

## 3. Influence, Not Authority

The player is one city, not a world government. The world's four industrial blocs emit
30 Gt on their own and their curves climb every turn — scale comes from convincing them.

- **Include:** Influence as an earned-and-spent resource; allies contributing income *and*
  each damping the world blocs' drift; funded transitions abroad (the cheapest ton
  anywhere is often another bloc's coal plant) and emissions treaties that bend the
  steepest curve; joint projects that only exist with partners.
- **Include:** the local-vs-global dilemma as a standing choice: cutting at home is safe
  but slow; diplomacy is leveraged but costs Influence and trust.
- **Reject:** directly setting another bloc's policy; war, sanctions, or coercion
  mechanics; any mechanic where being alone is strictly better than allied.

## 4. Every Timeline Teaches

Rogue-lite value comes from variation plus permanent learning (golden rule 10: build
replayability pillars from day one).

- **Include:** Knowledge Points on every run end — win or lose, never less than 1; a
  post-mortem that names the pivotal turn so the lesson is explicit; Knowledge nodes that
  encode a real insight and are explainable in one sentence ("bikes and plant-rich food
  raise health *and* cut carbon"); defeat lessons — losing to a revolt permanently unlocks
  the Public Support Fund; a codex entry unlocked forever the first time a card is played;
  city archetypes that reframe the next run; procedurally generated starting world;
  seeded, random event timelines.
- **Reject:** meta unlocks that are pure stat inflation with no explainable insight; a fixed
  world map; grind walls where repeating identical runs is the only path forward.

## 5. Grounded in the Science

Mechanics stay defensible against the cited sources (Paris Agreement, IPCC AR6, Project
Drawdown, EAT-Lancet). The game argues through systems, never through lecture text.

- **Include:** loss at +2.0 °C with warning at +1.5 °C; neutrality as emissions ≤ absorption;
  the 70% tech cap that makes sufficiency policies necessary to fully decarbonize a sector
  (IPCC demand-side mitigation); sink degradation under warming; a codex entry on every
  card naming the real-world solution it encodes (validator-enforced).
- **Include:** speculative tech as honest bets, never silver bullets — the research cards
  (Fusion Moonshot, Direct Air Capture) print their odds on the card, can fail, and their
  upside never substitutes for the transition.
- **Reject:** guaranteed fix-everything cards; climate-denial both-sidesism; moralizing
  pop-ups; numbers chosen for drama that contradict the sources without a written
  assumption (see `../Phase_1/06_Assumptions.md`).

## 6. Answer, Combine, Commit

The turn is a tactical puzzle with three time horizons: answer this turn's crises,
combine cards into combos that compound, commit to projects that pay off in fifteen
years. The fun is feeling all three click at once — with a market that makes each turn's
hand different.

- **Include:** a dealt market of four offers per turn (weighted by card and city
  archetype, with a guarantee that the turn is never unanswerable) instead of a static
  pool — reading the deal is part of the puzzle; multi-card turns bound by resources
  (never by an arbitrary one-action rule); combos that fire instantly with a visible
  banner and an escalating chain multiplier, cascading when two or more fire in one turn;
  three-turn projects whose completion is a permanent power and whose abandonment costs
  trust; deck growth as the reward for playing well.
- **Include:** cards that pay resources back, so a well-built turn feels generative,
  not merely spent.
- **Reject:** combos that need a lookup table to understand (two to four named tags,
  always visible on the cards); hidden synergy math; projects that can be dropped
  without consequence; unlocks handed out by time instead of deeds.
