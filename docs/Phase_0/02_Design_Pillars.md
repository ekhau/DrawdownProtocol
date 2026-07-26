# Design Pillars — The Drawdown Protocol

Six pillars. Every feature in the MVP scope table maps to at least one of them
(see `03_MVP_Scope.md`, "Pillar" column). If a proposed feature maps to none, it is cut —
that is the Phase 0 done criterion, applied as a standing rule.

---

## 1. Readable Balance

The whole game is three dials — Money, Carbon balance, Happiness — plus the warming
thermometer. The player must always be able to answer "why did that number move?"

- **Include:** three-pillar HUD always visible; card previews showing projected effect on
  each pillar before committing; a yearly log line per change ("Overshoot stress: −0.5 happiness").
- **Include:** the +1.5 °C / +2.0 °C thresholds drawn directly on the warming gauge.
- **Reject:** hidden modifiers, more than ~6 numbers on the default HUD, simultaneous
  resolution of many opaque systems, damage formulas the player can never reconstruct.

## 2. Every Crisis Is a Door

Three events land every year — the central pressure of the turn — but each is answerable
with the right card, and each pays back competence. What goes unanswered still carries an
opportunity rider. Fear is real; despair is never the designed response.

- **Include:** visible response tags on every drawn crisis; containment plus a reward for
  answering; response cards that make aid a real strategy.
- **Include:** post-fire "rebuild better" discount on restoration cards; post-flood free
  transport rebuild; social crisis opening a one-time window for a sufficiency policy —
  the doors that open when a crisis actually strikes.
- **Include:** Overshoot escalation past +1.5 °C (heavier crisis draw weights) so pressure
  rises exactly when the science says it does; opportunity events that thin out as the
  world heats.
- **Reject:** pure-punishment events with no follow-up choice; permanent unavoidable
  death-spirals; doomer flavor text; events that undo an hour of play with one roll.

## 3. Influence, Not Authority

The player is a small group, not a world government. Scale comes from convincing others.

- **Include:** Influence as an earned-and-spent resource; allies contributing yearly money;
  joint projects that only exist with partners; disaster aid that buys goodwill.
- **Reject:** directly setting another country's policy; war, sanctions, or coercion
  mechanics; any mechanic where being alone is strictly better than allied.

## 4. Every Timeline Teaches

Rogue-lite value comes from variation plus permanent learning (golden rule 10: build
replayability pillars from day one).

- **Include:** Knowledge Points on every run end (win or lose); Knowledge nodes that encode a
  real insight and are explainable in one sentence ("bikes and plant-rich food raise health
  *and* cut carbon"); procedurally generated starting world; seeded, random event timelines.
- **Reject:** meta unlocks that are pure stat inflation with no explainable insight; a fixed
  world map; grind walls where repeating identical runs is the only path forward.

## 5. Grounded in the Science

Mechanics stay defensible against the cited sources (Paris Agreement, IPCC AR6, Project
Drawdown, EAT-Lancet). The game argues through systems, never through lecture text.

- **Include:** loss at +2.0 °C with warning at +1.5 °C; neutrality as emissions ≤ absorption;
  the 70% tech cap that makes sufficiency policies necessary to fully decarbonize a sector
  (IPCC demand-side mitigation); sink degradation under warming.
- **Reject:** silver-bullet cards (fusion, "fix-everything" geoengineering); climate-denial
  both-sidesism; moralizing pop-ups; numbers chosen for drama that contradict the sources
  without a written assumption (see `../Phase_1/06_Assumptions.md`).

## 6. Answer, Combine, Commit

The turn is a tactical puzzle with three time horizons: answer this year's crises,
combine cards into combos that compound, commit to projects that pay off in five years.
The fun is feeling all three click at once.

- **Include:** multi-card years bound by resources (never by an arbitrary one-action
  rule); combos that fire instantly with a visible banner and an escalating chain
  multiplier; five-year projects whose completion is a permanent power and whose
  abandonment costs trust; deck growth as the reward for playing well.
- **Include:** cards that pay resources back, so a well-built turn feels generative,
  not merely spent.
- **Reject:** combos that need a lookup table to understand (two to four named tags,
  always visible on the cards); hidden synergy math; projects that can be dropped
  without consequence; unlocks handed out by time instead of deeds.
