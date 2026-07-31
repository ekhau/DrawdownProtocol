# Card Catalog Data — The Drawdown Protocol (Phase 5)

The content of `data/cards.json`, `data/combos.json`, `data/projects.json`,
`data/knowledge.json` — and the three world catalogs the clock race adds:
`data/world_actors.json`, `data/city_archetypes.json`, `data/summits.json`. Every card
from `../Phase_1/04_Policy_Effect_Matrix.md` expressed in the `../Phase_4/02` resolver
schema, plus the combo, project and world catalogs the crisis-response loop feeds on.
This file is the content-pipeline deliverable (golden rule 15): schema, authoring
templates, and conventions for adding content without touching code (golden rule 9).
The shipped JSON in `src/data/` is the authoritative version; the tables in
`../Phase_1/04` mirror it for design review.

**Card text is generated, never authored.** Cost chips, reward chips, tag lists, odds
marks and effect lines render from these fields through the `../Phase_4/06` template
system — a card can never display a number the sim will not apply (pillar 1). Only
`name`, optional `flavor`, and the **codex entry** are prose — and the codex is the
one place prose is load-bearing: every card carries
`"codex": {"title", "body"}`, two or three sentences on the real-world solution it
represents (Project Drawdown, IPCC AR6, EAT-Lancet — pillar: mechanics stay grounded
in the cited science). Funding a card once, in any run, unlocks its Codex entry.

## `data/cards.json` (schema_version 3 — 33 cards: 25 starting + 6 unlockable + 1 meta-lesson + 1 bonus-only)

Representative entries showing every schema feature:

```json
{ "id": "IND5", "name": "Industrial Carbon Levy", "category": "ind",
  "cost_money": 0, "cost_influence": 0, "cost_happiness": 6,
  "tags": ["energy"], "rewards": { "money": 35 },
  "flavor": "The polluters pay. The voters notice.",
  "codex": { "title": "Carbon pricing", "body": "Carbon pricing makes polluters pay per ton..." },
  "effects": [ { "op": "sector_progress", "sector": "ind", "amount": 14, "lifts_cap": false } ] }

{ "id": "DIP4", "name": "Fund a Transition", "category": "diplomacy",
  "cost_money": 120, "cost_influence": 8, "tags": ["treaty"], "market_weight": 3.0,
  "codex": { "title": "International climate finance", "body": "..." },
  "effects": [ { "op": "actor_fund", "cut": 6.0, "trend_cut": 0.3 } ] }

{ "id": "RND1", "name": "Fusion Moonshot", "category": "research",
  "cost_money": 150, "cost_influence": 0, "tags": ["energy"],
  "codex": { "title": "Fusion energy", "body": "..." },
  "effects": [],
  "risk": { "chance": 0.35,
            "on_success": { "effects": [ { "op": "joint_progress", "amount": 8 } ],
                            "rewards": { "money": 60, "knowledge": 1 } },
            "on_failure": { "effects": [ { "op": "happiness", "amount": -4, "waivable": false } ] } } }

{ "id": "SOC4", "name": "Public Support Fund", "category": "society",
  "cost_money": 60, "cost_influence": 0, "tags": ["civic"],
  "meta_unlock": { "on": "LOSS_REVOLT" },
  "codex": { "title": "Just-transition funds", "body": "..." },
  "effects": [ { "op": "wellbeing", "amount": 6 } ] }

{ "id": "HWP1", "name": "Heatwave Response Plan", "category": "response",
  "cost_money": 25, "cost_influence": 0, "tags": ["health", "relief"],
  "bonus_only": true, "rewards": { "influence": 3 },
  "codex": { "title": "Heat action plans", "body": "..." },
  "effects": [ { "op": "adapt", "amount": 6 }, { "op": "wellbeing", "amount": 2 } ] }
```

Schema notes (all validated — `05_Data_Validation_And_Content_Pipeline.md`):

- `cost_money` / `cost_influence` / `cost_happiness` — any mix, ≥ 0 (C4). IND5 is the
  first **happiness-cost** card: 0 money + 6 happiness, returning 35 money — a
  resource-vs-resource dilemma, so the C10 self-financing warning is deliberately
  skipped for cards paid in happiness.
- `rewards` — money/influence/happiness/knowledge, ≥ 0 (C10); a money reward at or
  above the money cost draws a self-financing warning (unless happiness-paid, above).
- `tags` — from the fixed vocabulary (C12): ten combo/response tags (water, food,
  energy, mobility, forest, coast, health, civic, treaty, relief) plus the rule tags
  `sufficiency` (⇔ a `lifts_cap` effect, C6) and `restoration` (fire-discount target, A4).
- `market_weight` — optional deal weight (> 0, default 1.0; C16): the market draws
  offers proportionally to `market_weight` × the archetype's tag lean. The diplomacy
  ops carry heavy weights (DIP4 3.0, DIP5 2.6) so the world lever shows up often.
- `unlock` — optional deck-growth condition (C11): `crises_answered` / `combos` /
  `allies` / `projects_completed` (`count` ≥ 1) or `sector_progress` (`sector`, `gte`).
  Cards with `unlock` are outside the market pool until earned mid-run.
- `meta_unlock` — the lesson of a specific defeat (C15): `{"on": <ending code>}`.
  SOC4 unlocks permanently after a `LOSS_REVOLT` and enters every later run's pool
  from turn 1. Cannot combine with `unlock`.
- `bonus_only` — excluded from the market pool and from `available_cards()` (C16);
  exists only while an event's `bonus_card` injection holds it in the market
  (`heat_wave` → HWP1, see `02_Event_Catalog_Data.md`). Cannot carry unlock conditions.
- `risk` — the push-your-luck block (C13): `chance` in (0,1) exclusive, an
  `on_success` branch required, branch effects restricted to SIMPLE_OPS. RND1 Fusion
  Moonshot (35%) and RND2 Direct Air Capture (50%, sink_now 2.0 or nothing) found the
  new **`research`** category.
- `codex` — required in spirit (C14: warning if absent, error if the title is empty or
  the body under 40 chars): the real-world grounding is content, not decoration.
- `category` ∈ ind/tra/agr/sink/society/diplomacy/response/**research**.
- `reforest` effects speak in turns: `per_turn` / `turns` (SNK1 1.0×3, SNK2 0.8×3,
  SNK3 1.2×2). Sector progress amounts are tuned to the 5-year turn: 8–16 per play.

## `data/combos.json` (8 combos)

```json
{ "id": "green_corridor", "name": "Green Corridor",
  "tags_required": ["mobility", "energy"],
  "rewards": { "money": 40 },
  "effects": [],
  "flavor": "Clean vehicles need clean grids - build both, pay less." }
```

- `tags_required`: ≥ 2 tags from the vocabulary (CB2); duplicates allowed (a
  hypothetical `["forest", "forest"]` needs two forest cards).
- `rewards` and/or `effects` required (CB3); effect ops restricted to the simple set —
  no `ally`, no `media` (CB4).
- **No single card may cover a combo's whole tag set** (CB5 warning): a combo is by
  definition a multi-card play.
- Rewards were retuned ~60% up for the 5-year turn (Green Corridor 40M, Grand Bargain
  60M+10I+1K, Drawdown Surge 40M+1K+0.5 sink) — a market turn offers fewer combo
  pieces, so each completed pattern must pay for the setup.
- Full catalog in `../Phase_1/04_Policy_Effect_Matrix.md` (Green Corridor, Water Cycle,
  Land & Table, Streets Alive, Public Trust, Blue Shield, Grand Bargain, Drawdown Surge).

## `data/projects.json` (4 projects — all 3 turns = 15-year commitments)

```json
{ "id": "global_sink_trust", "name": "Global Sink Trust",
  "upkeep_money": 90, "upkeep_influence": 0, "turns": 3,
  "completion": { "effects": [ { "op": "sink_now", "amount": 2.0 } ],
                  "passive": { "absorption_per_turn": 0.8 } },
  "abandon_penalty": { "happiness": 6, "influence": 10 },
  "flavor": "A permanent endowment for the world's lungs." }
```

- `turns` 2–6 (all shipped projects: 3), non-zero upkeep, penalty required (PR1/PR3 —
  commitment must bite). Upkeeps: 90 / 100+4I / 110 / 80+8I per turn.
- `completion.effects`: simple ops plus `ally` (auto-target; the World Climate Accord
  completes with two); `completion.passive` keys: `income_money` (50),
  `income_influence` (4), `happiness_per_turn` (1.5), `absorption_per_turn` (0.8)
  (PR2).

## `data/knowledge.json` (7 nodes)

```json
{ "id": "affordable_evs", "name": "Affordable EVs", "kp_cost": 6,
  "insight": "We know how to make electric cars people can buy.",
  "patch": { "card": "TRA2", "cost_money": 84 } }

{ "id": "capital_charter", "name": "Capital Charter", "kp_cost": 6,
  "insight": "Leverage can substitute for wealth - a capital of pure politics becomes playable.",
  "grant": { "archetype": "political_capital" } }
```

`insight` is player-facing: the Knowledge Hub shows it as the node's one-sentence
explanation (pillar 4: every unlock must be explainable as a real insight). Patch keys:
`cost_money`, `cost_influence`, `effect_happiness`, `reforest_turns`
(`restoration_playbook` compresses SNK1/SNK2 to 2 turns, totals preserved). Grant keys:
`media`, `adapt`, and `archetype` — the new meta-scope grant that unlocks a locked city
archetype on the select screen.

## `data/world_actors.json` (4 blocs — the rest of the world's emission curves)

```json
{ "id": "korvat_league", "name": "Korvat Industrial League",
  "emissions": 12.0, "trend": 0.6, "floor": 2.0,
  "blurb": "A heavy-industry bloc still betting on coal. The single biggest lever on the world curve." }
```

| id | emissions | trend/turn | floor |
|---|---|---|---|
| korvat_league | 12.0 | +0.6 | 2.0 |
| azuria_union | 7.0 | +0.2 | 1.5 |
| meridian_compact | 6.0 | +0.35 | 1.0 |
| frontier_states | 5.0 | +0.45 | 1.0 |

Definitions only — live state is deep-copied into RunState at `new_run`. Validator
A1/A2: ≥ 2 actors, snake_case ids, emissions > 0, trend ≥ 0 (treaties cut it; data
never starts negative), floor in (0, emissions]. The world starts at 30 Gt against the
city's ~50 — and drifts upward every turn unless funded, treatied, or damped by allies
(`ACTOR_TREND_PER_ALLY` 0.2 each).

## `data/summits.json` (3 scheduled COPs — the mid-run sub-objectives)

```json
{ "id": "cop_2045", "name": "Global Stocktake 2045", "turn": 4,
  "goal": { "metric": "net", "lte": 45.0 },
  "reward": { "money": 80, "influence": 10 },
  "penalty": { "influence": 8, "happiness": 4 },
  "blurb": "The first great audit. Show the curve can bend, or watch the doubters win the room." }
```

| id | turn | goal (net ≤) | reward | penalty |
|---|---|---|---|---|
| cop_2045 | 4 | 45 | 80M + 10I | 8I + 4H |
| cop_2065 | 8 | 25 | 120M + 15I | 10I + 5H |
| cop_2085 | 12 | 8 | 150M + 20I + 5H | 12I + 8H |

`goal.metric` is `net` or `clock_pct`, always with an `lte` target read at that turn's
resolve. Validator S1–S3: unique turns in 2–15, reward AND penalty both required —
success and failure must each matter. `catalog.summits` is sorted by turn;
`summit_for_turn` / `next_summit` are the accessors the sim and HUD share.

## `data/city_archetypes.json` (3 archetypes — the run's "character select")

```json
{ "id": "port_city", "name": "Port City", "tagline": "Trade routes are treaty routes.",
  "money_mult": 0.9, "influence_bonus": 8, "happiness_delta": 0,
  "sector_mult": { "ind": 0.9, "tra": 1.3, "agr": 0.9 },
  "income_mult": 1.0, "influence_income_bonus": 2, "start_allies": 1,
  "market_weights": { "treaty": 1.8, "coast": 1.5, "water": 1.2 } }
```

| id | money | income | influence | sectors | market lean | note |
|---|---|---|---|---|---|---|
| port_city | ×0.9 | ×1.0, +2I/turn | +8 | tra ×1.3, ind/agr ×0.9 | treaty 1.8, coast 1.5, water 1.2 | starts with 1 ally |
| industrial_city | ×1.4 | ×1.2 | −5 (and −5 H) | ind ×1.5, agr ×0.9 | energy 1.8, sufficiency 1.4, health 1.2 | rich but filthy |
| political_capital | ×0.7 | ×0.75, +3I/turn | +15 (+2 H) | ind ×0.9 | civic 1.6, treaty 1.6, health 1.2 | **locked**: `{"unlock": {"knowledge": "capital_charter"}}` |

Applied in `RunState.new_run` as modifiers over the worldgen output, so procgen jitter
and archetype identity compose; the baseline (no archetype) is the headless default.
Validator Y1–Y3: ≥ 3 archetypes, positive multipliers, known sector/market-weight keys,
and **at least one archetype locked behind a real knowledge node** (meta-progression
must have somewhere to go).

## Authoring templates and conventions (golden rule 15)

New card checklist — no code edits at any step:

1. Copy the template below into `cards.json`; fill fields.
2. `id`: 3-letter category prefix + ordinal (`IND6`, `RSP7`); never reuse a retired id
   (analytics history keys on it). `name`: Title Case, ≤ 24 characters.
3. `category` ∈ `ind|tra|agr|sink|society|diplomacy|response|research`.
4. `tags` from the vocabulary only; check which crises the tags answer
   (`02_Event_Catalog_Data.md`) and which combos they feed — that IS the design.
   Set `market_weight` above 1.0 only when the card must reliably show up.
5. Sufficiency cards: tag `sufficiency` AND `lifts_cap: true` on their sector op.
   Risk cards: an honest `chance` and both branches. Every card: a `codex` entry with
   a real, citable solution.
6. Run the validation + fixture + corridor workflow from doc 05 before committing —
   and note that a new normal card **changes timelines by design** (it enters the
   market pool); only `bonus_only` cards are timeline-neutral additions.

```json
{ "id": "", "name": "", "category": "",
  "cost_money": 0, "cost_influence": 0, "cost_happiness": 0,
  "rewards": {}, "requires": {}, "tags": [], "market_weight": 1.0,
  "flavor": "",
  "codex": { "title": "", "body": "" },
  "effects": [] }

{ "id": "", "name": "", "tags_required": [], "rewards": {}, "effects": [], "flavor": "" }

{ "id": "", "name": "", "upkeep_money": 0, "upkeep_influence": 0, "turns": 3,
  "completion": { "effects": [], "passive": {} },
  "abandon_penalty": { "happiness": 0, "influence": 0 }, "flavor": "" }
```

Balance guardrails for authors (from `../Phase_1/04` watch list): progress-per-100-money
in the 6–14 range for non-sufficiency sector cards (C9 warning); response cards priced
so card reward + response reward stays below the avoided damage; anything touching all
three sectors must cost Influence; money rewards must stay below money costs — unless
the card is paid in happiness, which is its own political price; new happiness sources
must be weaker than SOC2 per money spent before 2070; risk cards must fail meaningfully
(a free reroll is not a bet); diplomacy ops must never out-price the home transition
per ton or the world lever becomes dominant (Risk #12).
