# Card Catalog Data — The Drawdown Protocol (Phase 5)

The content of `data/cards.json`, `data/combos.json`, `data/projects.json` and
`data/knowledge.json`: every card from `../Phase_1/04_Policy_Effect_Matrix.md` expressed
in the `../Phase_4/02` resolver schema, plus the combo and project catalogs the
crisis-response loop adds. This file is the content-pipeline deliverable (golden
rule 15): schema, authoring templates, and conventions for adding content without
touching code (golden rule 9). The shipped JSON in `src/data/` is the authoritative
version; the tables in `../Phase_1/04` mirror it for design review.

**Card text is generated, never authored.** Cost chips, reward chips, tag lists and
effect lines render from these fields through the `../Phase_4/06` template system — a
card can never display a number the sim will not apply (pillar 1). Only `name` and
optional `flavor` are prose.

## `data/cards.json` (schema_version 2 — 26 cards: 20 starting + 6 unlockable)

Representative entries showing every schema feature:

```json
{ "id": "TRA1", "name": "Rail & Bike Networks", "category": "tra",
  "cost_money": 80, "cost_influence": 0, "tags": ["sufficiency", "mobility", "health"],
  "flavor": "The fastest way through a city was never a car.",
  "effects": [ { "op": "sector_progress", "sector": "tra", "amount": 8, "lifts_cap": true },
               { "op": "happiness", "amount": 2, "waivable": false } ] }

{ "id": "RSP5", "name": "Grid Repair Crews", "category": "response",
  "cost_money": 35, "cost_influence": 0, "tags": ["energy", "relief"],
  "rewards": { "money": 15 },
  "flavor": "Keep the lights on; keep the trust on.",
  "effects": [ { "op": "adapt", "amount": 2 } ] }

{ "id": "RSP6", "name": "Mutual Aid Network", "category": "response",
  "cost_money": 30, "cost_influence": 0, "tags": ["relief", "civic"],
  "unlock": { "kind": "crises_answered", "count": 4 },
  "rewards": { "influence": 4 },
  "flavor": "The disaster plan is knowing your neighbors.",
  "effects": [ { "op": "happiness", "amount": 2, "waivable": false } ] }
```

Schema notes (all validated — `05_Data_Validation_And_Content_Pipeline.md`):

- `cost_money` / `cost_influence` / `cost_happiness` — any mix, ≥ 0 (C4).
- `rewards` — money/influence/happiness/knowledge, ≥ 0 (C10); a money reward at or above
  the money cost draws a self-financing warning.
- `tags` — from the fixed vocabulary (C12): ten combo/response tags (water, food,
  energy, mobility, forest, coast, health, civic, treaty, relief) plus the rule tags
  `sufficiency` (⇔ a `lifts_cap` effect, C6) and `restoration` (fire-discount target, A4).
- `unlock` — optional deck-growth condition (C11): `crises_answered` / `combos` /
  `allies` / `projects_completed` (`count` ≥ 1) or `sector_progress` (`sector`, `gte`).
  Cards with `unlock` are hidden from the pool until earned mid-run.
- `category` gains `response` — the cheap, broadly-tagged crisis toolkit family.

## `data/combos.json` (8 combos)

```json
{ "id": "green_corridor", "name": "Green Corridor",
  "tags_required": ["mobility", "energy"],
  "rewards": { "money": 25 },
  "effects": [],
  "flavor": "Clean vehicles need clean grids - build both, pay less." }
```

- `tags_required`: ≥ 2 tags from the vocabulary (CB2); duplicates allowed (a
  hypothetical `["forest", "forest"]` needs two forest cards).
- `rewards` and/or `effects` required (CB3); effect ops restricted to the simple set —
  no `ally`, no `media` (CB4).
- **No single card may cover a combo's whole tag set** (CB5 warning): a combo is by
  definition a multi-card play.
- Full catalog in `../Phase_1/04_Policy_Effect_Matrix.md` (Green Corridor, Water Cycle,
  Land & Table, Streets Alive, Public Trust, Blue Shield, Grand Bargain, Drawdown Surge).

## `data/projects.json` (4 projects)

```json
{ "id": "global_sink_trust", "name": "Global Sink Trust",
  "upkeep_money": 35, "upkeep_influence": 0, "years": 5,
  "completion": { "effects": [ { "op": "sink_now", "amount": 1.0 } ],
                  "passive": { "absorption_per_year": 0.15 } },
  "abandon_penalty": { "happiness": 3, "influence": 8 },
  "flavor": "A permanent endowment for the world's lungs." }
```

- `years` 2–10, non-zero upkeep, penalty required (PR1/PR3 — commitment must bite).
- `completion.effects`: simple ops plus `ally` (auto-target); `completion.passive` keys:
  `income_money`, `income_influence`, `happiness_per_year`, `absorption_per_year` (PR2).

## `data/knowledge.json` (6 nodes — unchanged)

```json
{ "id": "affordable_evs", "name": "Affordable EVs", "kp_cost": 6,
  "insight": "We know how to make electric cars people can buy.",
  "patch": { "card": "TRA2", "cost_money": 84 } }
```

`insight` is player-facing: the Knowledge Hub shows it as the node's one-sentence
explanation (pillar 4: every unlock must be explainable as a real insight).

## Authoring templates and conventions (golden rule 15)

New card checklist — no code edits at any step:

1. Copy the template below into `cards.json`; fill fields.
2. `id`: 3-letter category prefix + ordinal (`IND5`, `RSP7`); never reuse a retired id
   (analytics history keys on it). `name`: Title Case, ≤ 24 characters.
3. `category` ∈ `ind|tra|agr|sink|society|diplomacy|response`.
4. `tags` from the vocabulary only; check which crises the tags answer
   (`02_Event_Catalog_Data.md`) and which combos they feed — that IS the design.
5. Sufficiency cards: tag `sufficiency` AND `lifts_cap: true` on their sector op.
6. Run the validation + fixture + corridor workflow from doc 05 before committing.

```json
{ "id": "", "name": "", "category": "",
  "cost_money": 0, "cost_influence": 0, "cost_happiness": 0,
  "rewards": {}, "requires": {}, "tags": [],
  "flavor": "",
  "effects": [] }

{ "id": "", "name": "", "tags_required": [], "rewards": {}, "effects": [], "flavor": "" }

{ "id": "", "name": "", "upkeep_money": 0, "upkeep_influence": 0, "years": 5,
  "completion": { "effects": [], "passive": {} },
  "abandon_penalty": { "happiness": 0, "influence": 0 }, "flavor": "" }
```

Balance guardrails for authors (from `../Phase_1/04` watch list): progress-per-100-money
in the 6–14 range for non-sufficiency sector cards (C9 warning); response cards priced
so card reward + response reward stays below the avoided damage; anything touching all
three sectors must cost Influence; money rewards must stay below money costs; new
happiness sources must be weaker than SOC2 per money spent before 2070.
