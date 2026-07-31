# MVP Scope — The Drawdown Protocol

Scope is a feature (golden rule 3): the MVP is the smallest version that proves the fun of
the five-year decision loop. One major system per milestone (golden rule 11): diplomacy ships
as **cards inside the existing card system**, not as a separate negotiation screen.

Every item maps to a design pillar (Phase 0 done criterion):
**P1** Readable Balance · **P2** Every Crisis Is a Door · **P3** Influence, Not Authority ·
**P4** Every Timeline Teaches · **P5** Grounded in the Science · **P6** Answer, Combine, Commit.

## Must Have (MVP)

| Feature | Pillar | Notes |
|---|---|---|
| Turn loop, 2030–2100 in **15 five-year turns**: 3 events drawn, a market of 4 offers dealt, up to 5 cards funded, Space resolves | P1, P6 | The smallest fun loop; a full run in 10–20 min |
| **Climate clock** as the explicit adversary: warming as a 0–100% gauge (+1.0 → +2.0 °C, start 30%) with next-turn forecast and history sparkline; it climbs on its own | P1, P5 | The single readout the whole run is played against |
| **World actor blocs** (4, ~30 Gt combined) whose emission curves advance every turn; each ally damps the drift; diplomacy cards (Fund a Transition, Emissions Treaty) cut them directly | P3, P5 | The local-vs-global dilemma; data in `data/world_actors.json` |
| Crisis deck (~7 crises + 3 opportunities) with band-weighted draws, response tags, containment rewards, opportunity riders, **on-draw spikes**, and **bonus-card injections** | P2, P6 | Weights in `../Phase_1/03_Event_Probability_Table.md` |
| Card catalog (**33 cards**, schema v3) with Money/Influence/**Happiness** costs, resource rewards, market weights, and a codex entry per card, loaded from data files | P1, P4, P5, P6 | Per `../Phase_1/04_Policy_Effect_Matrix.md`; data-driven (golden rule 9) |
| **Project market**: 4 offers per turn, dealt weighted (card × archetype lean) without replacement from a dedicated RNG stream; guarantee rule swaps in an answering card when the deal ignores the turn's events; funding consumes the offer | P6, P1 | Market variance is a deliberate roguelike feature |
| Combo system: ~8 named tag-set combos, instant firing, chain multiplier (+10%/step, ×2 cap, decay on comboless turns), cascade feedback on multi-combo turns | P6, P1 | Catalog in `data/combos.json`; combo tags printed on cards |
| Long-term projects (~4): **three turns (15 years)** of upkeep, permanent passive on completion, trust penalty on abandonment/failure, max 2 active | P6, P3 | Catalog in `data/projects.json` |
| **Summits (COPs)**: 3 fixed-turn checkpoints with net-emission targets announced in advance; reward on met, penalty on missed | P1, P3 | Catalog in `data/summits.json`; HUD shows the next target |
| Deck growth: unlock conditions on cards (crises answered, combos, allies, sector progress, projects completed) plus **defeat lessons** (a revolt loss permanently unlocks the Public Support Fund) and event-only bonus cards | P4, P6 | The unlock moment is a reward beat |
| Three-pillar HUD: Money, Carbon balance (city + world vs absorption), Happiness + clock gauge + next-summit line + crisis panel + chain indicator | P1, P5 | Details live in tooltips |
| Three-sector model (industry, transport, agro-economy) with progress %, residual emissions, and the 70% tech cap lifted by sufficiency cards | P5 | Core of the "sufficiency beats pure green growth" argument |
| Diplomacy as cards: Form Alliance, Joint Transition Project, Fund a Transition, Emissions Treaty, unlockable Climate Club; Influence resource; ally income and drift damping | P3 | No negotiation UI in MVP |
| **Research bets**: two push-your-luck cards (Fusion Moonshot, Direct Air Capture) with odds printed on the card, resolved on a dedicated RNG stream | P5, P6 | Honest bets, never silver bullets |
| Carbon ledger: city gross + world actors vs absorption; net drives warming; win the moment net ≤ 0, at any turn | P1, P5 | Formulas in `../Phase_1/01_Balance_Model.md` |
| 3 one-time feedback loops (permafrost, Amazon dieback, ocean sink weakening) | P2, P5 | Escalation past +1.5 °C |
| Overshoot state at +1.5 °C; hard losses at +2.0 °C and at 0 happiness (**revolt**); "survived, not neutral" loss at 2100 | P1, P5 | Every terminal state is one readable gauge |
| **City archetypes** (3, Slay-the-Spire style): chosen at first boot, changeable at run end, one locked behind a Knowledge node; stat multipliers and market leans only | P4 | Data in `data/city_archetypes.json` |
| Knowledge Points at run end (floor 1, win or lose; formula + in-run combo/opportunity Knowledge) + Knowledge tree (**7 nodes**) persisting across runs, plus codex and card unlocks in Meta | P4 | Includes the concept examples (EVs, healthy sobriety, informed public) |
| **Post-mortem** at run end: a pure heuristic over the turn log naming the pivotal turn per outcome | P1, P4 | `src/scripts/core/post_mortem.gd` |
| Procedurally generated starting world (seeded variation of starting emissions mix, sinks, money, happiness) | P4 | Parameter-level procgen; no tile map required to prove the loop |
| Deterministic seeded simulation (6 RNG streams: world, events, tiles, names, market, risk) + byte-identical JSONL replay + event log | P1 | Headless-testable; repeatable balance runs |

## Nice to Have (if time permits)

| Feature | Pillar | Notes |
|---|---|---|
| Isometric world-map view with per-region tiles | P1 | MVP can ship with an abstract dashboard board |
| Grey-to-solarpunk visual arc as sectors transform | P2 | The strongest emotional payoff; first candidate after MVP proves fun |
| Card effect forecast tooltip (exact numbers before playing) | P1 | High value, low cost |
| Save/load mid-run | — | Runs are short; low priority |
| Audio feedback set (confirm, alert, win/loss stingers) | P1 | |
| Named ally countries with flavor identities | P3 | Procgen names/parameters only |

## Out of Scope (first prototype)

| Feature | Why out |
|---|---|
| Per-country AI diplomacy, negotiation dialogue, or opinion simulation | Diplomacy-as-cards proves the fantasy first (golden rules 3, 11); world actors are curves with levers, not minds |
| Full economy simulation (trade, GDP, markets) | Three pillars carry the strategy; depth ≠ breadth |
| Per-tile world simulation of the whole globe | Parameter-level world is enough to prove the loop |
| Multiplayer | — |
| Narrative campaign / scripted story | Emergent runs are the story |
| Geoengineering / speculative tech beyond the two printed-odds research bets | Pillar 5 reject list |
| Military, sanctions, or coercion mechanics | Pillar 3 reject list |
