# MVP Scope — The Drawdown Protocol

Scope is a feature (golden rule 3): the MVP is the smallest version that proves the fun of
the yearly decision loop. One major system per milestone (golden rule 11): diplomacy ships
as **cards inside the existing card system**, not as a separate negotiation screen.

Every item maps to a design pillar (Phase 0 done criterion):
**P1** Readable Balance · **P2** Every Crisis Is a Door · **P3** Influence, Not Authority ·
**P4** Every Timeline Teaches · **P5** Grounded in the Science.

## Must Have (MVP)

| Feature | Pillar | Notes |
|---|---|---|
| Yearly turn loop, 2030–2100 (71 turns), one card per year | P1 | The smallest fun loop; a full run in 10–20 min |
| Three-pillar HUD: Money, Carbon balance (E vs A), Happiness + warming gauge with 1.5/2.0 marks | P1, P5 | Max ~6 numbers on default HUD |
| Card catalog (~15 cards) loaded from data files | P1, P4 | Per `../Phase_1/04_Policy_Effect_Matrix.md`; data-driven (golden rule 9) |
| Three-sector model (industry, transport, agro-economy) with progress %, residual emissions, and the 70% tech cap lifted by sufficiency cards | P5 | Core of the "sufficiency beats pure green growth" argument |
| Diplomacy as cards: Form Alliance, Joint Transition Project; Influence resource; ally income | P3 | No negotiation UI in MVP |
| Carbon ledger: gross emissions vs absorption, net drives warming | P1, P5 | Formulas in `../Phase_1/01_Balance_Model.md` |
| 4 event types (heat wave, mega fire, flood/tsunami, social crisis) with opportunity riders | P2 | Probabilities in `../Phase_1/03_Event_Probability_Table.md` |
| 3 one-time feedback loops (permafrost, Amazon dieback, ocean sink weakening) | P2, P5 | Escalation past +1.5 °C |
| Overshoot state at +1.5 °C; hard loss at +2.0 °C; soft loss "survived, not neutral" at 2100 | P1, P5 | Single hard loss condition |
| Knowledge Points at run end + Knowledge tree (~6 nodes) persisting across runs | P4 | Includes the three concept examples (EVs, healthy sobriety, informed public) |
| Procedurally generated starting world (seeded variation of starting emissions mix, sinks, money, happiness) | P4 | Parameter-level procgen; no tile map required to prove the loop |
| Deterministic seeded simulation + event log | P1 | Headless-testable; repeatable balance runs |

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
| Per-country AI diplomacy, negotiation dialogue, or opinion simulation | Diplomacy-as-cards proves the fantasy first (golden rules 3, 11) |
| Full economy simulation (trade, GDP, markets) | Three pillars carry the strategy; depth ≠ breadth |
| Per-tile world simulation of the whole globe | Parameter-level world is enough to prove the loop |
| Multiplayer | — |
| Narrative campaign / scripted story | Emergent runs are the story |
| Geoengineering / speculative tech systems | Pillar 5 reject list |
| Military, sanctions, or coercion mechanics | Pillar 3 reject list |
