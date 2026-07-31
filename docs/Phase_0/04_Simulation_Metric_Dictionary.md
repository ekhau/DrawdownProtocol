# Simulation Metric Dictionary — The Drawdown Protocol

Every simulation variable, its definition, unit, starting value, and expected range.
Formulas that connect them live in `../Phase_1/01_Balance_Model.md`. All tunable values
belong in data files, never hard-coded (golden rule 9).

## Core Timeline

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Year | `year` | Current calendar year; one decision turn = **5 years** (`YEARS_PER_TURN`) | year | 2030 | 2030–2100 |
| Turn | `turn` | 1-based decision-turn index; a run is exactly 15 turns (turn 1 = 2030, turn 15 = 2100) | turn | 1 | 1–15 |
| Warming | `T` | Global temperature anomaly above pre-industrial | °C | 1.30 | 1.20–2.00 (loss at ≥ 2.00; Overshoot at ≥ 1.50) |
| Climate clock | `clock_pct` | `(T − 1.0) / (2.0 − 1.0) × 100` — warming as % of the tipping track; the HUD's adversary gauge with next-turn forecast and sparkline | % | 30 | 20–100 (100% = loss) |

## Pillar 1 — Money

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Money | `M` | Spendable funds (abstract billions) | funds | 150 | 0–~1 000; healthy play keeps reserves above ~100 mid-run |
| Turn income | — | `250 + 40 × allies + project passives`, ×archetype income multiplier, reduced ×0.75 if H < 40, ×0.5 if H < 25 | funds/turn | 250 | 125–~600 |
| Card rewards | — | Resources returned by funded cards, crisis responses, summits met, and combos (money / influence / happiness / knowledge) | mixed | — | per catalog; combo rewards scaled by the chain multiplier |

## Pillar 2 — Carbon Balance

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| City gross emissions | `E_city` | Sum of the player's sector emissions (× archetype multipliers) + feedback/spike extras | GtCO2e/yr | 50.0 | ~5–55 |
| World emissions | `E_world` | Sum of the four world actor blocs' emissions; climbs by their trends every resolved turn | GtCO2e/yr | 30.0 | 5.5 (floors)–~50 |
| Absorption | `A` | Global sink capacity (forests, soils, oceans, restoration) | GtCO2e/yr | 20.0 | 5.0 (floor)–~30 |
| Net emissions | `N` | `E_city + E_world − A`; neutrality means N ≤ 0 — **and N ≤ 0 at any turn is the win** | GtCO2e/yr | +60.0 | ~−5 to +65 |
| Sector progress | `prog[s]` | Transition % for industry / transport / agro-economy | % | 0 / 0 / 0 | 0–100 (capped at 70 without a sufficiency card) |
| Sector base emissions | — | Industry 20, Transport 15, Agro-economy 15 (× archetype sector multipliers); residual 10% at full transition | GtCO2e/yr | 50 total (baseline) | 5 total at full transition |
| Sufficiency flags | `suff[s]` | Whether a sufficiency card was played in sector s (lifts cap 70→100) | bool | false | — |
| Feedback extras | `E_extra` | Emissions added by triggered feedback loops (permanent) and on-draw crisis spikes (cleared if the crisis is answered that turn) | GtCO2e/yr | 0 | 0–~4 |

## Pillar 3 — Happiness

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Happiness | `H` | Population wellbeing and social acceptance; **0 = revolt = instant loss** (`H_REVOLT`) | 0–100 | 60 | Winners hold ~55–80 through mid-run; danger below 40 (income penalty, social crises); 0 ends the run |

## Diplomacy and the World's Actors

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Influence | `I` | Diplomatic capital; earned per turn, spent on alliances, treaties and funded transitions | points | 15 | 0–~150 (uncapped in paper model; consider cap in implementation) |
| Influence income | — | `6 + 2 × allies (+2 if media)` + archetype bonus + project passives | points/turn | 6 | 6–~26 |
| Allies | `allies` | Countries in the coalition; each pays income **and damps world drift by 0.2 Gt/turn** (`ACTOR_TREND_PER_ALLY`, steepest curve first) | count | 0 (Port City: 1) | 0–6 |
| World actors | `actors[]` | The four blocs (Korvat 12.0 Gt +0.6/turn floor 2.0; Azuria 7.0 +0.2 floor 1.5; Meridian 6.0 +0.35 floor 1.0; Frontier 5.0 +0.45 floor 1.0); advance at the end of every resolved turn | Gt, Gt/turn | 30 Gt, +1.6/turn | emissions never below floors (5.5 combined) |

## Resilience (derived) and Adaptation

| Variable | Symbol | Definition | Unit | Start | Expected range |
|---|---|---|---|---|---|
| Adaptation points | `adapt` | Accumulated adaptation infrastructure | points | 0 | 0–60 |
| Resilience | `R` | **Derived:** `clamp(0.4 × H + adapt, 0, 100)`; event damage is multiplied by `1 − R/200` | 0–100 | 24 | 0–100 (R = 100 halves event damage) |

> **Reconciliation note (updated).** Plan.md's original "resilience ≤ 0" loss is still
> retired: resilience remains a **derived** event-damage modifier, never a loss gauge.
> The social loss returned in a different, more readable form: **happiness 0 is now an
> explicit revolt loss** (`LOSS_REVOLT`). Rationale: each terminal state must be one
> visible gauge (pillar: Readable Balance) — the clock, the happiness meter, or the
> calendar. Below the revolt line the spiral is still systemic first: low happiness cuts
> income and triples social-crisis draw weight long before it ends the run.

## The Crisis Turn (turn-scoped state)

| Variable | Definition | Range |
|---|---|---|
| `pending_crises[]` | The 3 events drawn at turn start: id, kind (crisis/opportunity), target region, answered state, answering card, on-draw spike | exactly 3 per turn |
| `market[]` | The turn's dealt offers: `MARKET_SIZE` (4) cards, weighted by `market_weight` × archetype tag lean, without replacement; guarantee rule ensures at least one offer answers the turn's events; event bonus cards append after | 4 + 0–1 bonus |
| `cards funded` | Card plays this turn; each funded offer is consumed; hard cap `MAX_CARDS_PER_TURN` | 0–5 |
| `tags this turn` | Multiset of tags on this turn's funded cards; drives crisis answers and combo checks | — |
| `combos this turn` | Combos fired this turn (each at most once per turn); 2+ triggers the CASCADE feedback in UI | 0–8 |

## Combos and Deck Growth (run-scoped)

| Variable | Definition | Range |
|---|---|---|
| `combo_chain` | +1 per combo fired; −1 on a comboless turn (min 0). Reward multiplier `1 + 0.1 × min(chain, 10)` | 0–~15; multiplier 1.0–2.0 |
| `combos_total` | Combos fired this run (deck-growth unlock counter) | 0–~20 |
| `crises_answered_total` | Crises + opportunities answered this run (unlock counter) | 0–45 |
| `projects_completed` | Projects sustained to completion (unlock counter) | 0–4 |
| `kp_earned` | In-run Knowledge from first-fire combo rewards, research successes and seized opportunities; added to the end-of-run KP award | 0–~4 |
| `unlocked_card_ids[]` | Cards added to the pool by unlock conditions this run | 0–6 |

## Long-Term Projects

| Variable | Definition | Range |
|---|---|---|
| `active_projects[]` | Running projects: id + turns of upkeep left (**3 turns = 15 years** each); charged at every turn start | 0–2 (`PROJECT_MAX_ACTIVE`) |
| `passives` | Aggregated completion powers: `income_money`, `income_influence`, `happiness_per_turn`, `absorption_per_turn` | permanent once earned |
| `project_history` | Terminal state per attempted project: completed / failed (unpaid upkeep) / abandoned; one attempt per run | — |

## Summits (COPs)

| Variable | Definition | Range |
|---|---|---|
| `summits[]` | Fixed-turn checkpoints from `data/summits.json`: Global Stocktake 2045 (turn 4, net ≤ 45), Accord of 2065 (turn 8, net ≤ 25), Last Horizon 2085 (turn 12, net ≤ 8); target announced in advance (HUD next-summit line + turn-start banner), evaluated against that turn's resolved net | 3 per run |
| `summit_results` | Per summit: met (reward paid) / missed (penalty applied); recorded in `TurnRecord.summit`, emitted via `summit_resolved` | — |

## Simulation State Flags

| Variable | Definition |
|---|---|
| `band` | Warming band: 0 stable (< 1.5), 1 Overshoot I (≥ 1.5), 2 Overshoot II (≥ 1.75) |
| `media` | Independent Media Fund active (suff. cards lose happiness penalty; +2 Influence/turn; social-crisis draw weight halved) |
| `window` | Social-crisis policy window open (next sufficiency card has no happiness cost) |
| `fire_discount` | Rebuild-better: next restoration card at 50% cost (set only when a fire actually strikes) |
| `flood_rebuild` | Rebuild-better: +5% transport progress free next turn (set only when a flood actually strikes) |
| `fires` | Cumulative unanswered mega fires (3 ⇒ Amazon dieback feedback) |
| `permafrost`, `ocean_weak`, `amazon` | One-time feedback loops already triggered |
| `reforest[]` | Maturing restoration programs: list of (Gt per turn, turns remaining) |
| `curve_bent_year` | First year net ≤ 0 was reached (the drawdown moment; also the win) |

## Meta-Progression (persists across runs)

| Variable | Definition | Unit | Range |
|---|---|---|---|
| Knowledge Points | `KP = decades survived ((year − 2030) ÷ 10) + sectors ≥ 70% + allies ÷ 2 + 3 if win + kp_earned`, **floor 1** — every outcome pays the meta | points/run | 1–~15 per run |
| Knowledge nodes | Unlocked entries of the Knowledge tree (Affordable EVs, Healthy Sobriety, Informed Public, Restoration Playbook, Coalition Diplomacy, Crisis-Ready Design, **Capital Charter**) | — | 7 nodes |
| `unlocked_cards` | Cards earned permanently by defeat lessons (LOSS_REVOLT ⇒ SOC4 Public Support Fund forever) | — | — |
| `codex_seen` | Cards whose codex entry is unlocked (first play of a card unlocks it permanently; codex screen on C) | — | 0–33 |
| `selected_archetype` | The chosen city archetype (Port City / Industrial City / Political Capital once unlocked); picked at first boot, changeable at run end | — | 1 of 3 (headless/test default: baseline, no archetype) |
